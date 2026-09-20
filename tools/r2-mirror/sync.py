#!/usr/bin/env python3
"""Mirror all English Scryfall large-tier card images into an R2 bucket.

Prefers Scryfall's native large webp (the `display` variant, ~42% the size of the
JPG) and falls back to the `large` JPG only when no webp is offered — no conversion.
Keys mirror Scryfall's own CDN paths, so the two land under different prefixes, e.g.:
    display/front/2/2/22001352-9e3d-41dc-96b9-1ec4b8970fba.webp   (preferred)
    large/front/2/2/22001352-9e3d-41dc-96b9-1ec4b8970fba.jpg      (fallback)

The <uuid> is the *card* id, not a content hash, so upstream art changes land on
the key we already mirrored. Scryfall does this routinely during spoiler season:
a card previewed by a non-English account (e.g. @mtgjp) ships with that language's
art under the English id, and the real scan is swapped in days later — sometimes
in place, without bumping the ?<timestamp> cache-buster on the URL. So "already
mirrored" is only safe once a card has been out a while; see CHURN_DAYS below.
"""

import datetime
import gzip
import hashlib
import json
import os
import sys
import time
from urllib.parse import urlparse

import boto3
import requests

DRY_RUN = "--dry-run" in sys.argv
BUCKET = os.environ.get("R2_BUCKET") or "mtg-cards"
ACCOUNT_ID = os.environ["R2_ACCOUNT_ID"]
UA = {"User-Agent": "klrmngr-cdn/1.0", "Accept": "application/json"}
IMG_HEADERS = {"User-Agent": "klrmngr-cdn/1.0", "Accept": "image/webp,image/jpeg,*/*"}
DELAY = 0.05  # polite gap between image requests

# How long a card's art stays "in flux" after release. Keys this recent are
# re-checked against upstream every run instead of being skipped as mirrored.
CHURN_DAYS = int(os.environ.get("R2_CHURN_DAYS") or 60)

# Grace period after CHURN_DAYS during which settled keys get their cache-control
# flipped from the short TTL to immutable. Wide enough that a sync run every few
# months still catches everything on its way out of the churn window.
GRADUATE_DAYS = int(os.environ.get("R2_GRADUATE_DAYS") or 90)

# Long-lived images are immutable; churning ones must stay revalidatable, or a
# client that cached the placeholder art holds it for a year after we fix R2.
CACHE_SETTLED = "public, max-age=31536000, immutable"
CACHE_CHURNING = "public, max-age=86400"

# Overwriting an R2 object does not touch Cloudflare's cache -- the edge keeps
# serving the bytes *and* the cache-control it stored on first fetch, per PoP,
# for the full max-age. Corrected art therefore needs an explicit purge, or it
# stays wrong at the edge for up to a year. Optional: absent these, the run still
# fixes the origin and just warns.
CF_ZONE_ID = os.environ.get("CF_ZONE_ID")
CF_PURGE_TOKEN = os.environ.get("CF_PURGE_TOKEN")
PUBLIC_HOST = os.environ.get("R2_PUBLIC_HOST") or "img.klrmngr.com"
PURGE_BATCH = 100  # Cloudflare's per-request cap on Free/Pro/Business

S3 = boto3.client(
    "s3",
    endpoint_url=f"https://{ACCOUNT_ID}.r2.cloudflarestorage.com",
    aws_access_key_id=os.environ["R2_KEY"],
    aws_secret_access_key=os.environ["R2_SECRET"],
    region_name="auto",
)


def existing_objects():
    """Every key already mirrored under the large-tier prefixes, mapped to its ETag.

    R2 returns the content MD5 as the ETag for single-part puts (all of ours), and
    Scryfall's CDN serves the same MD5 as its own ETag — so the two compare directly
    and a re-check costs one HEAD rather than a download.
    """
    objs = {}
    paginator = S3.get_paginator("list_objects_v2")
    for prefix in ("large/", "display/"):
        for page in paginator.paginate(Bucket=BUCKET, Prefix=prefix):
            for obj in page.get("Contents", []):
                objs[obj["Key"]] = obj["ETag"].strip('"')
    return objs


def bulk_default_cards():
    """Yield each card from Scryfall's default_cards bulk file (gzipped JSONL)."""
    index = requests.get("https://api.scryfall.com/bulk-data", headers=UA, timeout=30).json()
    uri = next(b["jsonl_download_uri"] for b in index["data"] if b["type"] == "default_cards")
    resp = requests.get(uri, headers=UA, timeout=300, stream=True)
    resp.raise_for_status()
    resp.raw.decode_content = False  # the body is a gzip file, not HTTP content-encoding
    with gzip.GzipFile(fileobj=resp.raw) as gz:
        for line in gz:
            line = line.strip()
            if line:
                yield json.loads(line)


def card_images(card):
    """Yield (key, url) for the large-tier image of each face, key = Scryfall CDN path.

    Prefer the native webp (`display`, ~42% the size); fall back to the `large` JPG
    only when no webp is offered. No conversion — whatever upstream serves is mirrored.
    """
    faces = []
    if "image_uris" in card:
        faces.append(card["image_uris"])
    else:
        for face in card.get("card_faces", []):
            if "image_uris" in face:
                faces.append(face["image_uris"])
    for iu in faces:
        url = iu.get("display") or iu.get("large")
        if url:
            yield urlparse(url).path.lstrip("/"), url


def release_age(card):
    """Days since the card's release; negative if unreleased, None if undated."""
    released = card.get("released_at")
    if not released:
        return None
    try:
        return (datetime.date.today() - datetime.date.fromisoformat(released)).days
    except ValueError:
        return None


def upstream_etag(url):
    """Scryfall's ETag (the content MD5) for an image, or None if it didn't serve one."""
    resp = requests.head(url, headers=IMG_HEADERS, timeout=30, allow_redirects=True)
    resp.raise_for_status()
    return resp.headers.get("ETag", "").strip('"') or None


def restamp(key, cache):
    """Rewrite a key's cache-control in place, server-side — no download, no egress.

    list_objects_v2 doesn't report cache-control, so we can't tell what a key
    currently carries; this is cheap enough to just apply unconditionally.
    """
    S3.copy_object(
        Bucket=BUCKET,
        Key=key,
        CopySource={"Bucket": BUCKET, "Key": key},
        MetadataDirective="REPLACE",
        ContentType="image/webp" if key.endswith(".webp") else "image/jpeg",
        CacheControl=cache,
    )


def purge_edge(keys):
    """Drop Cloudflare's cached copies of these keys. Returns the number purged.

    Only keys whose bytes or cache-control actually moved need this; a brand-new
    key has nothing cached yet, and a key graduating to immutable is already
    serving the right bytes.
    """
    if not keys:
        return 0
    if not (CF_ZONE_ID and CF_PURGE_TOKEN):
        print(
            f"  WARN {len(keys)} keys changed but CF_ZONE_ID/CF_PURGE_TOKEN are unset —\n"
            f"       R2 is correct, the edge will serve stale copies until TTL expiry",
            file=sys.stderr,
            flush=True,
        )
        return 0

    purged = 0
    for i in range(0, len(keys), PURGE_BATCH):
        batch = [f"https://{PUBLIC_HOST}/{k}" for k in keys[i : i + PURGE_BATCH]]
        try:
            resp = requests.post(
                f"https://api.cloudflare.com/client/v4/zones/{CF_ZONE_ID}/purge_cache",
                headers={"Authorization": f"Bearer {CF_PURGE_TOKEN}"},
                json={"files": batch},
                timeout=30,
            )
            resp.raise_for_status()
            body = resp.json()
            if not body.get("success"):
                raise ValueError(body.get("errors") or body)
            purged += len(batch)
        except Exception as e:  # noqa: BLE001 - origin is already fixed; don't fail the run
            print(f"  WARN purge batch {i // PURGE_BATCH}: {e}", file=sys.stderr, flush=True)
        time.sleep(DELAY)
    return purged


def main():
    print("listing bucket...", flush=True)
    have = existing_objects()
    print(f"  {len(have)} images already mirrored", flush=True)
    print(
        f"re-checking art for cards released within {CHURN_DAYS} days, "
        f"graduating those {CHURN_DAYS}-{CHURN_DAYS + GRADUATE_DAYS} days out",
        flush=True,
    )

    print("fetching bulk data...", flush=True)
    uploaded = 0
    refreshed = 0
    graduated = 0
    failed = 0
    stale = []  # keys whose cached copy at the edge no longer matches R2
    for card in bulk_default_cards():
        if card.get("lang") != "en":
            continue
        age = release_age(card)
        churning = age is not None and age <= CHURN_DAYS
        graduating = age is not None and CHURN_DAYS < age <= CHURN_DAYS + GRADUATE_DAYS
        for key, url in card_images(card):
            mirrored = have.get(key)

            if mirrored is not None and graduating:
                if DRY_RUN:
                    graduated += 1
                    continue
                try:
                    restamp(key, CACHE_SETTLED)
                    graduated += 1
                except Exception as e:  # noqa: BLE001 - cosmetic; never fail the run
                    print(f"  WARN graduate {key}: {e}", file=sys.stderr, flush=True)
                continue

            if mirrored is not None and not churning:
                continue

            if DRY_RUN:
                if mirrored is None:
                    have[key] = ""
                    uploaded += 1
                    print(f"  would upload {key}", flush=True)
                else:
                    # HEAD is read-only, so the preview can be exact rather than
                    # just listing everything in the window as a maybe.
                    try:
                        if upstream_etag(url) != mirrored:
                            refreshed += 1
                            print(f"  would refresh {key}", flush=True)
                    except Exception as e:  # noqa: BLE001 - preview only
                        print(f"  WARN head {key}: {e}", file=sys.stderr, flush=True)
                    stale.append(key)  # bytes and/or cache-control move either way
                    time.sleep(DELAY)
                continue

            try:
                ctype = "image/webp" if key.endswith(".webp") else "image/jpeg"
                cache = CACHE_CHURNING if churning else CACHE_SETTLED

                if mirrored:
                    # Cheap HEAD first: unchanged art costs headers, not a body.
                    try:
                        if upstream_etag(url) == mirrored:
                            # Bytes match, but the key may still be stamped immutable
                            # from an earlier run — and this is a card whose art can
                            # still move, so it has to stay revalidatable. The edge
                            # cached the old header too, so this needs a purge to land.
                            restamp(key, cache)
                            stale.append(key)
                            time.sleep(DELAY)
                            continue
                    except Exception:  # noqa: BLE001 - HEAD flaky, fall through to GET
                        pass

                img = requests.get(url, headers=IMG_HEADERS, timeout=30)
                img.raise_for_status()
                got = img.headers.get("Content-Type", "")
                if got != ctype:
                    raise ValueError(f"unexpected content-type {got!r} (wanted {ctype})")

                digest = hashlib.md5(img.content).hexdigest()
                if digest == mirrored:
                    restamp(key, cache)  # same reason as the HEAD path above
                    stale.append(key)
                    time.sleep(DELAY)
                    continue

                S3.put_object(
                    Bucket=BUCKET,
                    Key=key,
                    Body=img.content,
                    ContentType=ctype,
                    CacheControl=cache,
                )
                have[key] = digest
                if mirrored:
                    refreshed += 1
                    stale.append(key)
                    print(f"  refreshed {key} ({mirrored[:8]} -> {digest[:8]})", flush=True)
                else:
                    uploaded += 1
                    if uploaded % 500 == 0:
                        print(f"  uploaded {uploaded}...", flush=True)
                time.sleep(DELAY)
            except Exception as e:  # noqa: BLE001 - keep going on individual failures
                failed += 1
                print(f"  FAIL {key}: {e}", file=sys.stderr, flush=True)

    if DRY_RUN:
        purged = 0
        print(f"  would purge {len(stale)} keys from the edge", flush=True)
    else:
        print(f"purging {len(stale)} changed keys from the edge...", flush=True)
        purged = purge_edge(stale)

    verb = "would upload" if DRY_RUN else "new"
    print(
        f"done: {uploaded} {verb}, {refreshed} refreshed, {graduated} graduated, "
        f"{purged} purged, {failed} failed, {len(have)} total",
        flush=True,
    )
    if failed:
        sys.exit(1)


if __name__ == "__main__":
    main()
