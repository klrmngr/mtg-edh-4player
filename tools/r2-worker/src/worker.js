// Backs the in-game bug reporter for the MTG EDH mod. A single dedicated worker
// on report.klrmngr.com:
//   POST /report   -- file a bug report / feature request as a GitHub issue.
//
// The GitHub token is a Worker secret (env.GITHUB_TOKEN) and must NEVER ship in
// the mod: the save file is readable by anyone who has it.

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    // Players file bugs / feature requests from inside the mod.
    if (request.method === "POST" && url.pathname === "/report") {
      return handleReport(request, env);
    }

    return new Response("Not found", { status: 404 });
  },
};

// Handle an in-game bug report / feature request: file a labelled GitHub issue
// and return its URL to the mod.
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
  // SteamID64 is all digits; strip anything else so the profile link can't be
  // used to inject markup. This identity is self-asserted by the mod and NOT
  // verified server-side -- surface it as a hint, never as proof.
  const reporterId = String(payload.reporterId || "").replace(/\D/g, "").slice(0, 20);
  const version = String(payload.version || "?").slice(0, 40);

  // Rate limit: 1 report / minute / person. Key on the SteamID when present --
  // every in-game report is POSTed from the HOST's IP, so an IP key would
  // throttle the whole table; the SteamID makes it per-player. It's self-asserted
  // (spoofable), but this only guards against accidental spam / mashing submit.
  const rlKey = reporterId || request.headers.get("cf-connecting-ip") || "anon";
  const { success } = await env.REPORT_LIMITER.limit({ key: rlKey });
  if (!success) {
    return json({ error: "rate_limited" }, 429);
  }

  const bodyLines = [
    description || "_(no description provided)_",
    "",
    "---",
    `- **Reporter:** ${reporter}${reporterColor ? ` (${reporterColor})` : ""}`,
    `- **Steam ID (unverified):** ${reporterId ? `[${reporterId}](https://steamcommunity.com/profiles/${reporterId})` : "(none)"}`,
    `- **Table version:** ${version}`,
    `- **Filed via:** in-game report button`,
  ];

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
    return json({ error: "submit failed" }, 502);
  }

  // Don't leak where the issue lives (repo URL / number) back to players.
  return json({ ok: true }, 201);
}

function json(obj, status = 200) {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
