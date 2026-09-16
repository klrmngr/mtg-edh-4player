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

-- POST target: the same Worker/domain that fronts the card bucket. A GET serves
-- images; a POST to /report files an issue. See tools/r2-worker/src/worker.js.
bugReportURL = "https://img.klrmngr.com/report"

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

-- Serialize every table object into one JSON blob. This is a functional save (a
-- maintainer can respawn it), not a screenshot -- TTS has no Lua screenshot API.
function captureTableSnapshot()
	local objects = {}
	for _, obj in ipairs(getAllObjects()) do
		local ok, dat = pcall(function()
			return obj.getData()
		end)
		if ok and dat ~= nil then
			table.insert(objects, dat)
		end
	end
	local snapshot = {
		version = VERSION,
		capturedAt = os.time(),
		objectCount = #objects,
		objects = objects,
	}
	local ok, encoded = pcall(JSON.encode, snapshot)
	if ok then
		return encoded
	end
	return JSON.encode({ version = VERSION, capturedAt = os.time(), error = "snapshot encode failed" })
end

function submitBugReport(player)
	if player == nil or player.color == "Grey" then
		return
	end
	local title = (bugReportDraft.title or ""):gsub("^%s+", ""):gsub("%s+$", "")
	if title == "" then
		broadcastToColor("Enter a title before submitting.", player.color, { 1, 0.4, 0.4 })
		return
	end
	local isBug = bugReportIsBug()
	broadcastToColor(
		"Submitting your " .. (isBug and "bug report" or "feature request") .. "...",
		player.color,
		{ 1, 0.85, 0.2 }
	)

	local payload = {
		type = isBug and "bug" or "feature",
		title = title,
		description = bugReportDraft.description or "",
		reporter = player.steam_name or player.color,
		reporterColor = player.color,
		version = VERSION,
	}
	if isBug then
		payload.save = captureTableSnapshot()
	end

	local headers = {
		["Content-Type"] = "application/json",
		["X-Report-Key"] = bugReportKey,
	}
	local color = player.color
	WebRequest.custom(bugReportURL, "POST", true, JSON.encode(payload), headers, function(resp)
		bugReportDone(resp, color)
	end)
	visibleCloseRules(player, "BugReportPanel")
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
