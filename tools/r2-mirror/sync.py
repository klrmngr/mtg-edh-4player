#!/usr/bin/env python3
"""Mirror all English Scryfall card images (large JPGs) into an R2 bucket.

Keys mirror Scryfall's own CDN paths, e.g.:
    large/front/2/2/22001352-9e3d-41dc-96b9-1ec4b8970fba.jpg

The <uuid> is Scryfall's content-addressed image id, so re-scanned art lands
as a new key; runs only ever upload keys not already in the bucket.
"""

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
IMG_HEADERS = {"User-Agent": "klrmngr-cdn/1.0", "Accept": "image/jpeg,*/*"}
DELAY = 0.05  # polite gap between image downloads

S3 = boto3.client(
    "s3",
    endpoint_url=f"https://{ACCOUNT_ID}.r2.cloudflarestorage.com",
    aws_access_key_id=os.environ["R2_KEY"],
    aws_secret_access_key=os.environ["R2_SECRET"],
    region_name="auto",
)


def existing_keys():
    """Every key already under large/ in the bucket."""
    keys = set()
    for page in S3.get_paginator("list_objects_v2").paginate(Bucket=BUCKET, Prefix="large/"):
        for obj in page.get("Contents", []):
            keys.add(obj["Key"])
    return keys


def bulk_default_cards():
    """Download and return the Scryfall default_cards bulk array."""
    index = requests.get("https://api.scryfall.com/bulk-data", headers=UA, timeout=30).json()
    uri = next(b["download_uri"] for b in index["data"] if b["type"] == "default_cards")
    return requests.get(uri, headers=UA, timeout=120).json()


def card_images(card):
    """Yield (key, url) for the large JPG of each face, key = Scryfall CDN path."""
    urls = []
    if "image_uris" in card:
        urls.append(card["image_uris"]["large"])
    else:
        for face in card.get("card_faces", []):
            if "image_uris" in face:
                urls.append(face["image_uris"]["large"])
    for url in urls:
        yield urlparse(url).path.lstrip("/"), url


def main():
    print("listing bucket...", flush=True)
    have = existing_keys()
    print(f"  {len(have)} images already mirrored", flush=True)

    print("fetching bulk data...", flush=True)
    cards = bulk_default_cards()
    print(f"  {len(cards)} cards in default_cards", flush=True)

    uploaded = 0
    failed = 0
    for card in cards:
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
                img = requests.get(url, headers=IMG_HEADERS, timeout=30)
                img.raise_for_status()
                ctype = img.headers.get("Content-Type", "")
                if ctype != "image/jpeg":
                    raise ValueError(f"unexpected content-type {ctype!r}")
                S3.put_object(
                    Bucket=BUCKET,
                    Key=key,
                    Body=img.content,
                    ContentType="image/jpeg",
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
