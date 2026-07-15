#!/usr/bin/env python3
"""Snapshot every image key currently in the R2 bucket into manifest.json.

This is 'your side' of the diff: sync.py compares Scryfall's bulk data
against these keys to find missing cards. Run once to seed it, or anytime
you want to refresh the cached inventory from the real bucket state.
"""

import json
import os

import boto3

BUCKET = os.environ.get("R2_BUCKET", "mtg-cards")

S3 = boto3.client(
    "s3",
    endpoint_url=f"https://{os.environ['R2_ACCOUNT_ID']}.r2.cloudflarestorage.com",
    aws_access_key_id=os.environ["R2_KEY"],
    aws_secret_access_key=os.environ["R2_SECRET"],
    region_name="auto",
)

keys = []
for page in S3.get_paginator("list_objects_v2").paginate(Bucket=BUCKET, Prefix="large/"):
    for obj in page.get("Contents", []):
        keys.append(obj["Key"])

keys.sort()
with open("manifest.json", "w") as f:
    json.dump(keys, f)

print(f"wrote manifest.json with {len(keys)} keys")
