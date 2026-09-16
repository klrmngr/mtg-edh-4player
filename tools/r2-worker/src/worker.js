// Front the mtg-cards R2 bucket. Serve hits straight from R2; on a miss,
// return 404 and — only for a legitimately-shaped card key — file a GitHub
// issue so a genuinely missing mirror surfaces as a tracked bug.
//
// The point is to catch "a card image the sync should have uploaded is gone",
// NOT to log every scanner probing for /.env or /wp-login.php. Two gates keep
// the issue tracker clean:
//   1. Shape filter  — the path must match an expected image key, or we just
//                      404 silently and never touch GitHub.
//   2. KV dedup      — a given missing key files at most one issue per TTL,
//                      so bots retrying the same URL don't spam.

// display/front/2/2/<uuid>.webp   or   large/back/a/b/<uuid>.jpg
// The two shard chars mirror the first two of the uuid, matching Scryfall's paths.
const CARD_KEY = /^(display|large)\/(front|back)\/[0-9a-f]\/[0-9a-f]\/[0-9a-f-]{36}\.(webp|jpg)$/;

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);

    // Players file bugs / feature requests from inside the mod via POST /report.
    if (request.method === "POST" && url.pathname === "/report") {
      return handleReport(request, env);
    }

    if (request.method !== "GET" && request.method !== "HEAD") {
      return new Response("Method Not Allowed", { status: 405 });
    }

    const key = decodeURIComponent(url.pathname.slice(1));
    const object = await env.BUCKET.get(key);

    if (object) {
      const headers = new Headers();
      object.writeHttpMetadata(headers);           // Content-Type from the stored object
      headers.set("etag", object.httpEtag);
      headers.set("cache-control", "public, max-age=31536000, immutable");
      return new Response(request.method === "HEAD" ? null : object.body, { headers });
    }

    // Miss. File an issue in the background so the client still gets its 404 fast.
    if (CARD_KEY.test(key)) {
      ctx.waitUntil(reportMissing(key, request, env));
    }
    return new Response("Not found", { status: 404 });
  },
};

async function reportMissing(key, request, env) {
  try {
    // Dedup: first requester of this key within the TTL wins.
    if (await env.SEEN.get(key)) return;
    await env.SEEN.put(key, "1", { expirationTtl: Number(env.DEDUP_TTL_SECONDS) });

    const cf = request.cf || {};
    const body = [
      `A card image was requested but is missing from the \`mtg-cards\` bucket.`,
      ``,
      `- **Key:** \`${key}\``,
      `- **URL:** ${request.url}`,
      `- **Referer:** ${request.headers.get("referer") || "(none)"}`,
      `- **Country:** ${cf.country || "?"}`,
      `- **First seen:** ${new Date().toISOString()}`,
      ``,
      `Likely a gap in the Scryfall mirror — re-run \`tools/r2-mirror/sync.py\`.`,
    ].join("\n");

    const resp = await fetch(`https://api.github.com/repos/${env.GITHUB_REPO}/issues`, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${env.GITHUB_TOKEN}`,
        "Accept": "application/vnd.github+json",
        "User-Agent": "mtg-cdn-worker",           // GitHub rejects requests without a UA
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        title: `Missing card image: ${key}`,
        body,
        labels: ["missing-image", "cdn"],
      }),
    });

    if (!resp.ok) {
      // Roll back the dedup marker so a transient GitHub failure retries next time.
      await env.SEEN.delete(key);
      console.error(`GitHub issue failed: ${resp.status} ${await resp.text()}`);
    }
  } catch (e) {
    console.error("reportMissing error", e);
  }
}

// Handle an in-game bug report / feature request: stash any table snapshot in
// R2, then file a labelled GitHub issue and return its URL to the mod.
async function handleReport(request, env) {
  // Weak anti-spam gate. REPORT_KEY ships inside the mod, so it is NOT a real
  // secret -- it only turns away drive-by POSTs that don't send the header.
  if (env.REPORT_KEY && request.headers.get("x-report-key") !== env.REPORT_KEY) {
    return json({ error: "forbidden" }, 403);
  }

  let payload;
  try {
    payload = await request.json();
  } catch {
    return json({ error: "invalid JSON" }, 400);
  }

  const title = String(payload.title || "").trim().slice(0, 200);
  if (!title) return json({ error: "title required" }, 400);

  const description = String(payload.description || "").slice(0, 8000);
  const isBug = payload.type !== "feature";
  const reporter = String(payload.reporter || "unknown").slice(0, 100);
  const reporterColor = String(payload.reporterColor || "").slice(0, 20);
  const version = String(payload.version || "?").slice(0, 40);

  // A bug report carries a serialized table snapshot; stash it in R2 and link it
  // so the issue stays small and the save is one click away.
  let saveUrl = null;
  if (isBug && typeof payload.save === "string" && payload.save.length > 0) {
    const stamp = new Date().toISOString().replace(/[:.]/g, "-");
    const key = `bug-reports/${stamp}-${crypto.randomUUID().slice(0, 8)}.json`;
    try {
      await env.BUCKET.put(key, payload.save, {
        httpMetadata: { contentType: "application/json" },
      });
      saveUrl = `${new URL(request.url).origin}/${key}`;
    } catch (e) {
      console.error("snapshot upload failed", e);
    }
  }

  const bodyLines = [
    description || "_(no description provided)_",
    "",
    "---",
    `- **Reporter:** ${reporter}${reporterColor ? ` (${reporterColor})` : ""}`,
    `- **Table version:** ${version}`,
    `- **Filed via:** in-game report button`,
  ];
  if (saveUrl) bodyLines.push(`- **Table snapshot:** ${saveUrl}`);

  const labels = isBug ? ["bug", "in-game-report"] : ["enhancement", "in-game-report"];
  const issueTitle = `${isBug ? "[Bug] " : "[Feature] "}${title}`;

  const resp = await fetch(`https://api.github.com/repos/${env.GITHUB_REPO}/issues`, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${env.GITHUB_TOKEN}`,
      "Accept": "application/vnd.github+json",
      "User-Agent": "mtg-edh-report-worker",   // GitHub rejects requests without a UA
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ title: issueTitle, body: bodyLines.join("\n"), labels }),
  });

  if (!resp.ok) {
    console.error(`GitHub issue failed: ${resp.status} ${await resp.text()}`);
    return json({ error: "github rejected", status: resp.status }, 502);
  }

  const issue = await resp.json();
  return json({ ok: true, issueUrl: issue.html_url, number: issue.number }, 201);
}

function json(obj, status = 200) {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
