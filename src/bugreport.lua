-------------------------------- BUG REPORTS -----------------------------------
-- Player-facing issue reporter. Any seated player opens the panel from the
-- report button, fills in a title + description, picks a type (bug report /
-- feature request) and submits. The request is POSTed to our Cloudflare Worker,
-- which holds the GitHub token as a secret and files the issue on our behalf --
-- the token must NEVER ship inside the mod, since the save file is readable by
-- anyone who has it. A bug report additionally attaches a serialized snapshot of
-- every table object so a maintainer can reproduce the exact board state.
--
-- The panel widgets are a single shared set (same as the settings panel): the
-- title/description/type are mirrored into one shared draft as they're edited,
-- and the submitting player is attributed at submit time.

-- POST target: the dedicated report worker (separate from the img.klrmngr.com
-- image host). A POST to /report files a GitHub issue. See
-- tools/r2-worker/src/worker.js.
bugReportURL = "https://report.klrmngr.com/report"

-- Weak, ships-in-the-save shared key. This is NOT a secret (anyone with the mod
-- can read it) -- it only turns away trivial drive-by POSTs. The Worker enforces
-- it only when REPORT_KEY is configured there.
bugReportKey = "mtg-edh-4player"

-- one shared in-progress report, matching the shared panel widgets
bugReportDraft = bugReportDraft or { type = "Bug report", title = "", description = "" }

-- is the current draft a bug report (vs a feature request)?
function bugReportIsBug()
	return bugReportDraft.type ~= "Feature request"
end

-- swap the hint line to match the selected type
function updateBugReportHint()
	if bugReportIsBug() then
		UI.setAttribute("bugReportHint", "text", "Bug reports attach a snapshot of the current table.")
	else
		UI.setAttribute("bugReportHint", "text", "Feature requests are filed as-is (no table snapshot).")
	end
end

function openBugReport(player)
	if player == nil or player.color == "Grey" then
		return
	end
	-- reset the shared draft + widgets so a stale entry from a previous open
	-- doesn't carry over
	bugReportDraft = { type = "Bug report", title = "", description = "" }
	UI.setAttribute("bugTitleInput", "text", "")
	UI.setAttribute("bugDescInput", "text", "")
	-- best-effort reset of the dropdown to its first option; a no-op on TTS
	-- builds that ignore it, in which case the user's next pick re-syncs the draft
	UI.setAttribute("bugTypeDropdown", "value", "0")
	updateBugReportHint()
	visibleOpenRules(player.color, "BugReportPanel")
end

function closeBugReport(player)
	visibleCloseRules(player, "BugReportPanel")
end

function bugReportTitle(player, value, id)
	bugReportDraft.title = value or ""
end

function bugReportDesc(player, value, id)
	bugReportDraft.description = value or ""
end

-- Dropdown onValueChanged: TTS passes the selected option's text as `value`
function bugReportType(player, value, id)
	bugReportDraft.type = value or "Bug report"
	updateBugReportHint()
end

-- A bug report attaches a serialized snapshot of every table object (a functional
-- save a maintainer can respawn, not a screenshot -- TTS has no Lua screenshot
-- API). Serialising every object is heavy, so it runs in a coroutine that yields
-- between objects (see bugReportSnapshotCoro); doing it inline froze the game on
-- submit. One in-flight report is tracked here while its snapshot builds.
bugReportPending = nil

function submitBugReport(player)
	if player == nil or player.color == "Grey" then
		return
	end
	local title = (bugReportDraft.title or ""):gsub("^%s+", ""):gsub("%s+$", "")
	if title == "" then
		broadcastToColor("Enter a title before submitting.", player.color, { 1, 0.4, 0.4 })
		return
	end
	if bugReportPending ~= nil then
		broadcastToColor("A report is already being submitted...", player.color, { 1, 0.85, 0.2 })
		return
	end
	local isBug = bugReportIsBug()
	broadcastToColor(
		"Submitting your " .. (isBug and "bug report" or "feature request") .. "...",
		player.color,
		{ 1, 0.85, 0.2 }
	)

	bugReportPending = {
		isBug = isBug,
		title = title,
		description = bugReportDraft.description or "",
		reporter = player.steam_name or player.color,
		-- SteamID64: stable + unique, but self-asserted -- the Worker cannot verify
		-- it (TTS exposes no Steam auth ticket), so treat it as a strong hint only.
		reporterId = player.steam_id,
		reporterColor = player.color,
		color = player.color,
	}
	visibleCloseRules(player, "BugReportPanel")

	if isBug then
		-- Capture the table across frames so the game stays responsive; the
		-- coroutine hands off to sendBugReport() when the snapshot is ready.
		startLuaCoroutine(Global, "bugReportSnapshotCoro")
	else
		sendBugReport()
	end
end

-- Serialize every object into a JSON array one at a time, yielding every few
-- objects so the game doesn't freeze, then hand the assembled snapshot to
-- sendBugReport(). Each object is encoded on its own and the pieces are
-- concatenated, so the whole nested table is never encoded in a single blocking
-- call. Runs as a TTS coroutine (must return 1 when done).
function bugReportSnapshotCoro()
	local parts = {}
	local count = 0
	local objs = getAllObjects()
	for i, obj in ipairs(objs) do
		local ok, dat = pcall(function()
			return obj.getData()
		end)
		if ok and dat ~= nil then
			local ok2, enc = pcall(JSON.encode, dat)
			if ok2 then
				parts[#parts + 1] = enc
				count = count + 1
			end
		end
		if i % 5 == 0 then
			coroutine.yield(0)
		end
	end
	if bugReportPending == nil then
		return 1
	end
	-- Assemble by hand: the objects are already encoded JSON, so this is a plain
	-- string concat, not another full encode of the nested data.
	bugReportPending.save = table.concat({
		'{"version":', JSON.encode(VERSION),
		',"capturedAt":', tostring(os.time()),
		',"objectCount":', tostring(count),
		',"objects":[', table.concat(parts, ","), "]}",
	})
	sendBugReport()
	return 1
end

-- Build the POST body from the pending report and fire it. A snapshot, if
-- present, is already valid JSON and is spliced in raw (no second escape pass);
-- the Worker parses it and re-stringifies it on its side, off the game thread.
function sendBugReport()
	local p = bugReportPending
	if p == nil then
		return
	end
	local body
	if p.save ~= nil then
		body = table.concat({
			'{"type":', JSON.encode(p.isBug and "bug" or "feature"),
			',"title":', JSON.encode(p.title),
			',"description":', JSON.encode(p.description),
			',"reporter":', JSON.encode(p.reporter),
			',"reporterId":', JSON.encode(p.reporterId or ""),
			',"reporterColor":', JSON.encode(p.reporterColor),
			',"version":', JSON.encode(VERSION),
			',"save":', p.save, "}",
		})
	else
		body = JSON.encode({
			type = p.isBug and "bug" or "feature",
			title = p.title,
			description = p.description,
			reporter = p.reporter,
			reporterId = p.reporterId,
			reporterColor = p.reporterColor,
			version = VERSION,
		})
	end

	local headers = {
		["Content-Type"] = "application/json",
		["X-Report-Key"] = bugReportKey,
	}
	local color = p.color
	bugReportPending = nil
	WebRequest.custom(bugReportURL, "POST", true, body, headers, function(resp)
		bugReportDone(resp, color)
	end)
end

function bugReportDone(resp, color)
	if resp.is_error then
		broadcastToColor("Report failed to send (" .. tostring(resp.error) .. ").", color, { 1, 0.3, 0.3 })
		return
	end
	if not resp.is_done then
		return
	end
	if resp.response_code ~= nil and resp.response_code >= 400 then
		broadcastToColor("Report was rejected (HTTP " .. tostring(resp.response_code) .. ").", color, { 1, 0.3, 0.3 })
		return
	end
	local ok, data = pcall(JSON.decode, resp.text)
	if ok and type(data) == "table" and data.issueUrl then
		broadcastToColor("Thanks! Issue filed: " .. tostring(data.issueUrl), color, { 0.4, 1, 0.4 })
	else
		broadcastToColor("Thanks! Your report was submitted.", color, { 0.4, 1, 0.4 })
	end
end
