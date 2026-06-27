# Self-hosted Scryfall image cache (for the TTS mod)

Scryfall blocks TTS's default UnityPlayer User-Agent because mods load
hundreds/thousands of card images directly and uncached. The fix is to **cache
our own copy** from their bulk data and serve it from our own host, so during
gameplay TTS hits *us* instead of Scryfall.

We serve from **Cloudflare R2** (object storage): upload the images once, point a
custom domain at the bucket, and Cloudflare serves them with free egress and edge
caching. No always-on origin server needed.

```
TTS (UnityPlayer UA) ──► Cloudflare edge cache ──► R2 bucket (magic-cards)
                                                    ▲ rclone sync (weekly)
                                  scryfall_mirror.py (weekly, polite) ──► Scryfall
```

> An alternative "run your own origin" approach (nginx + Cloudflare Tunnel) lives
> in `selfhost/`. It works but requires the host machine to stay online; R2 is
> preferred for a public mod. The steps below are the R2 path.

## 1. Build the mirror (one-time, ~21 GB, ~2.5–3 h)
```bash
.venv/bin/python scryfall_mirror.py --out ./scryfall-mirror
```
Re-runs are incremental/resumable. (Pillow is required for the baseline re-encode;
it's in `.venv`.) Re-run weekly to pick up new cards.

## 2. Domain on Cloudflare
Domain `klrmngr.com` is on Cloudflare (Porkbun nameservers point to Cloudflare).
Images are served at **`img.klrmngr.com`**.

## 3. Create the R2 bucket + custom domain
1. Cloudflare → **R2** → enable it (requires a payment card on file; ~$0.17/mo
   for ~21 GB).
2. **Create bucket** `magic-cards`.
3. Bucket → **Settings → Custom Domains → Connect Domain** → `img.klrmngr.com`.
   (A specific `img` record overrides the Porkbun `*` wildcard automatically.)

## 4. Create an R2 API token + configure rclone
1. R2 → **Manage R2 API Tokens → Create** → **Object Read & Write** (scope to the
   bucket). Copy the **Access Key ID**, **Secret Access Key** (shown once), and the
   **S3 endpoint** `https://<account-id>.r2.cloudflarestorage.com`.
2. Put them in `~/.config/rclone/rclone.conf` (keep the secret off-screen — edit
   the file directly, don't paste it anywhere shared):
   ```ini
   [r2]
   type = s3
   provider = Cloudflare
   access_key_id = ...
   secret_access_key = ...
   endpoint = https://<account-id>.r2.cloudflarestorage.com
   region = auto
   acl = private
   ```

## 5. Upload to R2
```bash
rclone sync ./scryfall-mirror r2:magic-cards \
  --header-upload "Cache-Control: public, max-age=31536000, immutable" \
  --s3-no-check-bucket --exclude ".manifest.json" \
  --transfers 16 --checkers 16 --stats 30s --stats-one-line
```
- `--s3-no-check-bucket`: the token is bucket-scoped (can't do account-level
  bucket checks).
- `--exclude ".manifest.json"`: keep the bucket images-only.

Verify (a TTS-like User-Agent must work, since it's our host, not Scryfall):
```bash
curl -I -A "UnityPlayer/2021.3 (UnityWebRequest/1.0)" \
  "https://img.klrmngr.com/large/front/e/0/e056b55f-82ed-4fe0-ab0c-bb20fa4a218a.jpg"
```

## 6. Maximize cache hit rate (keeps R2 reads ~free at scale)
A read only costs an R2 **Class B** op + bandwidth on a Cloudflare cache **miss**.
Cached hits are free. To keep the hit rate high:
1. ✅ Objects are uploaded with `Cache-Control: public, max-age=31536000, immutable`.
2. **Caching → Tiered Cache → enable** (free). Consolidates misses across POPs so
   fewer requests reach R2.
3. **Caching → Cache Rules → Create**: If *Hostname equals `img.klrmngr.com`* →
   *Eligible for cache*, Edge TTL *Respect origin*. Belt-and-suspenders.

Watch the R2 dashboard the first month to confirm Class B ops stay low.

## 7. Point the mod at the cache
In `src/scryfall.lua`, make `proxyImageURL` a plain host-swap, then `make` and push:
```lua
function proxyImageURL(url)
	if type(url) ~= "string" or url == "" then
		return url
	end
	-- serve Scryfall card images from our own R2-backed cache instead
	return (url:gsub("https?://cards%.scryfall%.io", "https://img.klrmngr.com"))
end
```
Then re-Fix / re-import in TTS (`python tts_push.py --log` to watch for any
`load image failed` lines).

> Do this **after** the full upload finishes — R2 has no miss-fallback, so a
> not-yet-uploaded card would 404.

## 8. Keep it fresh (weekly)
```cron
0 5 * * 1  cd /home/klrmngr/code/'MTG EDH 4-player (χ)' && .venv/bin/python scryfall_mirror.py --out ./scryfall-mirror && ~/.local/bin/rclone sync ./scryfall-mirror r2:magic-cards --header-upload "Cache-Control: public, max-age=31536000, immutable" --s3-no-check-bucket --exclude ".manifest.json" >> /tmp/scryfall_mirror.log 2>&1
```

## Cost at scale (~5M reads/day ≈ 150M/mo, ~20 TB egress)
- **Egress:** $0 (R2 free egress — the reason to use R2; ~$1,700/mo on S3).
- **Class B reads:** only cache misses hit R2; 10M/mo free. High hit rate → ~$0–2/mo.
- **Class A writes:** full upload ~120k ops; 1M/mo free → $0. Weekly syncs are tiny.
- **Storage:** ~21 GB → ~$0.17/mo.
- **Realistic total:** ~$0–3/month, dominated by storage.

## Optional: zero broken images for brand-new cards
Between weekly syncs, a card released that day isn't in R2 yet → 404. To cover it,
add a small **Cloudflare Worker** in front of the bucket that, on a 404, falls back
to the weserv proxy and caches the result. Optional.

## Compliance notes
- `scryfall_mirror.py` uses the **bulk-data** endpoints (not per-card scraping), a
  **custom User-Agent** with contact/repo, and a **≤9 req/s** rate limit.
- Card images are immutable per URL → cached long (1 year) at Cloudflare.
- Attribute Scryfall + Wizards of the Coast in the mod; don't expose this cache as
  a general public Scryfall image API.
- Consider emailing Scryfall to describe the setup — they explicitly asked mod
  authors to cache their own copy.
