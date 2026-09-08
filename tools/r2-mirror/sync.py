#!/usr/bin/env python3
"""Mirror all English Scryfall large-tier card images into an R2 bucket.

Prefers Scryfall's native large webp (the `display` variant, ~42% the size of the
JPG) and falls back to the `large` JPG only when no webp is offered — no conversion.
Keys mirror Scryfall's own CDN paths, so the two land under different prefixes, e.g.:
    display/front/2/2/22001352-9e3d-41dc-96b9-1ec4b8970fba.webp   (preferred)
    large/front/2/2/22001352-9e3d-41dc-96b9-1ec4b8970fba.jpg      (fallback)

The <uuid> is Scryfall's content-addressed image id, so re-scanned art lands
as a new key; runs only ever upload keys not already in the bucket.
"""

import gzip
import json
import os
import sys
import time
from urllib.parse import urlparse

import boto3
import requests

DRY_RUN = "--dry-run" in sys.argv
BUCKET = os.environ.get("R2_BUCKET", "mtg-cards")
ACCOUNT_ID = os.environ["R2_ACCOUNT_ID"]
UA = {"User-Agent": "klrmngr-cdn/1.0", "Accept": "application/json"}
IMG_HEADERS = {"User-Agent": "klrmngr-cdn/1.0", "Accept": "image/webp,image/jpeg,*/*"}
DELAY = 0.05  # polite gap between image downloads

S3 = boto3.client(
    "s3",
    endpoint_url=f"https://{ACCOUNT_ID}.r2.cloudflarestorage.com",
    aws_access_key_id=os.environ["R2_KEY"],
    aws_secret_access_key=os.environ["R2_SECRET"],
    region_name="auto",
)


def existing_keys():
    """Every key already mirrored under the large-tier prefixes (large/ jpg, display/ webp)."""
    keys = set()
    paginator = S3.get_paginator("list_objects_v2")
    for prefix in ("large/", "display/"):
        for page in paginator.paginate(Bucket=BUCKET, Prefix=prefix):
            for obj in page.get("Contents", []):
                keys.add(obj["Key"])
    return keys


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


def main():
    print("listing bucket...", flush=True)
    have = existing_keys()
    print(f"  {len(have)} images already mirrored", flush=True)

    print("fetching bulk data...", flush=True)
    uploaded = 0
    failed = 0
    for card in bulk_default_cards():
        if card.get("lang") != "en":
            continue
        for key, url in card_images(card):
            if key in have:
                continue
            if DRY_RUN:
                have.add(key)  # count once even if seen again
                uploaded += 1
                print(f"  would upload {key}", flush=True)
                continue
            try:
                ctype = "image/webp" if key.endswith(".webp") else "image/jpeg"
                img = requests.get(url, headers=IMG_HEADERS, timeout=30)
                img.raise_for_status()
                got = img.headers.get("Content-Type", "")
                if got != ctype:
                    raise ValueError(f"unexpected content-type {got!r} (wanted {ctype})")
                S3.put_object(
                    Bucket=BUCKET,
                    Key=key,
                    Body=img.content,
                    ContentType=ctype,
                    CacheControl="public, max-age=31536000, immutable",
                )
                have.add(key)
                uploaded += 1
                if uploaded % 500 == 0:
                    print(f"  uploaded {uploaded}...", flush=True)
                time.sleep(DELAY)
            except Exception as e:  # noqa: BLE001 - keep going on individual failures
                failed += 1
                print(f"  FAIL {key}: {e}", file=sys.stderr, flush=True)

    verb = "would upload" if DRY_RUN else "new"
    print(f"done: {uploaded} {verb}, {failed} failed, {len(have)} total", flush=True)
    if failed:
        sys.exit(1)


if __name__ == "__main__":
    main()
