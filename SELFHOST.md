# Self-hosted Scryfall image cache (for the TTS mod)

Scryfall blocks TTS's default UnityPlayer User-Agent because mods load
hundreds/thousands of card images directly and uncached. The fix is to **cache
our own copy** from their bulk data and serve that, so during gameplay TTS hits
*our* host instead of Scryfall.

```
TTS ──► Cloudflare (edge cache + TLS) ──► nginx (local mirror) ──► weserv (misses only) ──► Scryfall
                                                                   scryfall_mirror.py (weekly, polite)
```

## 1. Build the mirror (one-time, ~12 GB, ~2.5–3 h)
```bash
.venv/bin/python scryfall_mirror.py --out ./scryfall-mirror
```
Re-runs are incremental/resumable. Re-run weekly (cron) to pick up new cards.

## 2. Get a domain (Porkbun) and put it on Cloudflare (free)
1. Buy a domain on Porkbun.
2. Add the domain to a free Cloudflare account ("Add a site").
3. Cloudflare gives you two nameservers. In Porkbun: **Domain → Authoritative
   Nameservers → Change** to Cloudflare's two NS. Wait for it to go active
   (minutes–hours).

## 3. Create a Cloudflare Tunnel
1. Cloudflare **Zero Trust → Networks → Tunnels → Create a tunnel** (type:
   *Cloudflared*). Name it e.g. `tts-img`.
2. Copy the tunnel **token** → `cp selfhost/.env.example selfhost/.env` and paste
   it as `TUNNEL_TOKEN=...`.
3. Add a **Public Hostname** to the tunnel:
   - Subdomain: `img`  ·  Domain: `yourdomain.com`
   - Service: **HTTP** → `img:80`   (the compose service name)

No port-forwarding needed — `cloudflared` dials out.

## 4. Start the stack
```bash
cd selfhost
docker compose up -d
docker compose run --rm img nginx -t   # sanity-check the nginx config
```
Test it:
```bash
curl -I https://img.yourdomain.com/healthz
# a real card (note: served from the mirror; query is ignored):
curl -I "https://img.yourdomain.com/large/front/e/0/e056b55f-82ed-4fe0-ab0c-bb20fa4a218a.jpg"
```

## 5. (Recommended) Cloudflare cache rule
Cloudflare caches image extensions by default, but to be safe:
**Caching → Cache Rules → Create** → If hostname equals `img.yourdomain.com` →
*Eligible for cache*, Edge TTL: *Respect origin* (nginx sends 1-year immutable).

## 6. Point the mod at your host
In `src/scryfall.lua`, replace the weserv-based `proxyImageURL` body with a plain
host-swap, then `make` and push:
```lua
function proxyImageURL(url)
	if type(url) ~= "string" or url == "" then
		return url
	end
	-- send Scryfall card images to our own cache instead
	return (url:gsub("https?://cards%.scryfall%.io", "https://img.yourdomain.com"))
end
```
Then re-Fix / re-import in TTS (use `python tts_push.py --log` to watch for any
`load image failed` lines).

## 7. Keep it fresh
Weekly cron for incremental updates:
```cron
0 5 * * 1  cd /home/klrmngr/code/'MTG EDH 4-player (χ)' && .venv/bin/python scryfall_mirror.py --out ./scryfall-mirror >> /tmp/scryfall_mirror.log 2>&1
```

## Compliance notes
- `scryfall_mirror.py` uses the **bulk-data** endpoints (not per-card scraping),
  a **custom User-Agent** with contact/repo, and a **≤9 req/s** rate limit.
- Card images are immutable per URL → cached long (1 year) at nginx + Cloudflare.
- Attribute Scryfall + Wizards of the Coast in the mod; don't expose this cache
  as a general public Scryfall image API.
- Consider emailing Scryfall to describe the setup — they explicitly asked mod
  authors to cache their own copy.
