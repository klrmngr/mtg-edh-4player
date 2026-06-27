#!/usr/bin/env python3
"""
Download Scryfall card images in bulk into a local mirror, so a self-hosted
image cache (e.g. weserv/images behind Cloudflare) can serve them to Tabletop
Simulator without hammering Scryfall.

Why this exists: Scryfall blocks TTS's default UnityPlayer User-Agent because
mods load hundreds/thousands of card images directly and uncached, which has
taken their site down. Their guidance is to download the bulk data and cache
your own copy. This does exactly that:

  1. GET https://api.scryfall.com/bulk-data and pick a set (default: default_cards)
  2. Stream its JSON (one card object per line) and collect every image URL at
     the chosen size(s)
  3. Download each image once -- rate-limited, with a custom User-Agent -- and
     re-encode JPEGs to BASELINE (TTS cannot decode progressive JPEGs)
  4. Store them mirroring Scryfall's path layout, e.g.
        <out>/large/front/e/0/<uuid>.jpg
     so the serving layer only has to swap the host:
        cards.scryfall.io/large/front/e/0/<uuid>.jpg -> img.yourdomain/large/...

Resumable + incremental: a manifest records each image's Scryfall "?<timestamp>";
reruns skip unchanged files and only re-fetch re-scanned art.

Compliance: custom User-Agent, global rate limit (<=~10 req/s), uses the
bulk-data endpoints (not per-card API scraping). Set --user-agent to your real
contact/repo. See https://scryfall.com/docs/api.

Usage:
    python scryfall_mirror.py --out /srv/scryfall-mirror
    python scryfall_mirror.py --out ./mirror --size large,png --workers 8 --rate 9
    python scryfall_mirror.py --out ./mirror --limit 50    # quick test
    python scryfall_mirror.py --out ./mirror --raw         # store originals, no re-encode

Re-encoding needs Pillow (pip install pillow) unless you pass --raw.
"""

import argparse
import io
import json
import os
import sys
import threading
import time
import urllib.error
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from urllib.parse import urlsplit

BULK_ENDPOINT = "https://api.scryfall.com/bulk-data"
DEFAULT_UA = (
    "mtg-edh-4player-tts-cache/0.1 "
    "(+https://github.com/klrmngr/mtg-edh-4player; kaimingzhang1234@gmail.com)"
)
SIZES = ("small", "normal", "large", "png")

try:
    from PIL import Image

    HAVE_PIL = True
except ImportError:
    HAVE_PIL = False


def http_get(url: str, ua: str, accept: str = "", timeout: int = 60):
    req = urllib.request.Request(url, headers={"User-Agent": ua})
    if accept:
        req.add_header("Accept", accept)
    return urllib.request.urlopen(req, timeout=timeout)


class RateLimiter:
    """Thread-safe global cap of `rate` requests per second."""

    def __init__(self, rate: float):
        self.min_interval = 1.0 / rate if rate > 0 else 0.0
        self.lock = threading.Lock()
        self.next_time = 0.0

    def wait(self) -> None:
        with self.lock:
            now = time.monotonic()
            slot = max(now, self.next_time)
            self.next_time = slot + self.min_interval
        delay = slot - time.monotonic()
        if delay > 0:
            time.sleep(delay)


class Stats:
    def __init__(self):
        self.lock = threading.Lock()
        self.counts = {"downloaded": 0, "skipped": 0, "missing": 0, "error": 0}
        self.bytes = 0

    def bump(self, key: str, nbytes: int = 0) -> None:
        with self.lock:
            self.counts[key] += 1
            self.bytes += nbytes

    def done(self) -> int:
        with self.lock:
            return sum(self.counts.values())


def get_bulk_entry(type_: str, ua: str) -> dict:
    with http_get(BULK_ENDPOINT, ua, accept="application/json") as r:
        data = json.load(r)
    for entry in data.get("data", []):
        if entry.get("type") == type_:
            return entry
    avail = ", ".join(e.get("type", "?") for e in data.get("data", []))
    raise SystemExit(f"bulk type {type_!r} not found. Available: {avail}")


def collect_jobs(download_uri: str, ua: str, sizes, limit: int) -> dict:
    """Stream the bulk JSON (one card per line) -> {relpath: image_url}."""
    jobs: dict = {}
    with http_get(download_uri, ua, timeout=600) as r:
        for raw in r:  # the file is one card object per line
            line = raw.strip().rstrip(b",")
            if not line or line == b"[" or line == b"]":
                continue
            try:
                card = json.loads(line)
            except json.JSONDecodeError:
                continue
            if card.get("image_status") == "missing":
                continue
            faces = []
            if isinstance(card.get("image_uris"), dict):
                faces.append(card["image_uris"])
            for face in card.get("card_faces") or []:
                if isinstance(face.get("image_uris"), dict):
                    faces.append(face["image_uris"])
            for imgs in faces:
                for size in sizes:
                    url = imgs.get(size)
                    if url:
                        jobs[urlsplit(url).path.lstrip("/")] = url
            if limit and len(jobs) >= limit:
                break
    return jobs


def download_one(url, out_dir, ua, limiter, reencode, quality, manifest, mlock, stats):
    rel = urlsplit(url).path.lstrip("/")
    ts = urlsplit(url).query  # Scryfall's "?<timestamp>" -- changes on re-scan
    dest = os.path.join(out_dir, rel)

    with mlock:
        unchanged = manifest.get(rel) == ts
    if unchanged and os.path.exists(dest):
        stats.bump("skipped")
        return

    body = None
    for attempt in range(5):
        try:
            limiter.wait()
            with http_get(url, ua, timeout=60) as r:
                body = r.read()
            break
        except urllib.error.HTTPError as e:
            if e.code == 404:
                stats.bump("missing")
                return
            if e.code == 429:
                time.sleep(int(e.headers.get("Retry-After", "5")))
                continue
            if 500 <= e.code < 600:
                time.sleep(2**attempt)
                continue
            stats.bump("error")
            return
        except Exception:
            time.sleep(2**attempt)
    if body is None:
        stats.bump("error")
        return

    os.makedirs(os.path.dirname(dest), exist_ok=True)
    tmp = dest + ".tmp"
    try:
        if reencode and dest.lower().endswith((".jpg", ".jpeg")):
            # baseline JPEG -- TTS/Unity cannot decode progressive JPEGs
            img = Image.open(io.BytesIO(body))
            if img.mode != "RGB":
                img = img.convert("RGB")
            img.save(tmp, "JPEG", quality=quality, progressive=False, optimize=True)
        else:
            with open(tmp, "wb") as f:
                f.write(body)
        os.replace(tmp, dest)
    except Exception:
        if os.path.exists(tmp):
            os.remove(tmp)
        stats.bump("error")
        return

    with mlock:
        manifest[rel] = ts
    stats.bump("downloaded", len(body))


def save_manifest(path: str, manifest: dict, mlock: threading.Lock) -> None:
    tmp = path + ".tmp"
    with mlock:
        snapshot = dict(manifest)
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(snapshot, f)
    os.replace(tmp, path)


def main() -> None:
    ap = argparse.ArgumentParser(description="Mirror Scryfall card images locally.")
    ap.add_argument("--out", default="./scryfall-mirror", help="output directory")
    ap.add_argument(
        "--type",
        default="default_cards",
        help="bulk set: default_cards (all printings, EN), unique_artwork, oracle_cards, all_cards",
    )
    ap.add_argument("--size", default="large", help="comma list of: " + ",".join(SIZES))
    ap.add_argument("--workers", type=int, default=8, help="concurrent downloads")
    ap.add_argument("--rate", type=float, default=9.0, help="global max requests/sec to Scryfall")
    ap.add_argument("--quality", type=int, default=92, help="re-encoded JPEG quality")
    ap.add_argument("--raw", action="store_true", help="store originals, skip JPEG re-encode")
    ap.add_argument("--limit", type=int, default=0, help="cap number of images (for testing)")
    ap.add_argument("--user-agent", default=DEFAULT_UA, help="User-Agent sent to Scryfall")
    args = ap.parse_args()

    sizes = [s.strip() for s in args.size.split(",") if s.strip()]
    bad = [s for s in sizes if s not in SIZES]
    if bad:
        raise SystemExit(f"invalid --size {bad}; choose from {', '.join(SIZES)}")

    reencode = not args.raw
    if reencode and not HAVE_PIL:
        raise SystemExit(
            "re-encoding needs Pillow: pip install pillow  (or pass --raw to store originals)"
        )
    if "kaimingzhang1234@gmail.com" in args.user_agent:
        print("[warn] using the default User-Agent -- set --user-agent with your own contact")

    out_dir = os.path.abspath(args.out)
    os.makedirs(out_dir, exist_ok=True)
    manifest_path = os.path.join(out_dir, ".manifest.json")
    manifest = {}
    if os.path.exists(manifest_path):
        try:
            with open(manifest_path, encoding="utf-8") as f:
                manifest = json.load(f)
        except Exception:
            pass
    mlock = threading.Lock()

    entry = get_bulk_entry(args.type, args.user_agent)
    print(
        f"[bulk] {entry['name']} updated {entry['updated_at']} "
        f"({entry['size'] / 1e6:.0f} MB JSON)"
    )
    print(f"[bulk] streaming {entry['download_uri']}")
    jobs = collect_jobs(entry["download_uri"], args.user_agent, sizes, args.limit)
    total = len(jobs)
    print(f"[bulk] {total} unique images at size(s) {','.join(sizes)} -> {out_dir}")

    limiter = RateLimiter(args.rate)
    stats = Stats()
    stop = threading.Event()

    def reporter():
        start = time.monotonic()
        while not stop.wait(3.0):
            done = stats.done()
            el = time.monotonic() - start
            rps = done / el if el else 0
            eta = (total - done) / rps if rps else 0
            c = stats.counts
            print(
                f"[{done}/{total}] dl={c['downloaded']} skip={c['skipped']} "
                f"miss={c['missing']} err={c['error']} "
                f"{stats.bytes / 1e6:.0f}MB {rps:.0f}/s ETA {eta / 60:.0f}m"
            )
            save_manifest(manifest_path, manifest, mlock)

    rt = threading.Thread(target=reporter, daemon=True)
    rt.start()

    try:
        with ThreadPoolExecutor(max_workers=args.workers) as ex:
            for url in jobs.values():
                ex.submit(
                    download_one,
                    url, out_dir, args.user_agent, limiter,
                    reencode, args.quality, manifest, mlock, stats,
                )
    except KeyboardInterrupt:
        print("\n[stop] interrupted -- saving manifest")
    finally:
        stop.set()
        rt.join(timeout=2)
        save_manifest(manifest_path, manifest, mlock)

    c = stats.counts
    print(
        f"[done] downloaded={c['downloaded']} skipped={c['skipped']} "
        f"missing={c['missing']} errors={c['error']} "
        f"total={stats.bytes / 1e6:.0f}MB in {out_dir}"
    )


if __name__ == "__main__":
    main()
