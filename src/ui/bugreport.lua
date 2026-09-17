-------------------------------- BUG REPORTS -----------------------------------
-- Player-facing issue reporter. Any seated player opens the panel from the
-- report button, fills in a title + description, picks a type (bug report /
-- feature request) and submits. The request is POSTed to our Cloudflare Worker,
-- which holds the GitHub token as a secret and files the issue on our behalf --
-- the token must NEVER ship inside the mod, since the save file is readable by
-- anyone who has it.
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
		UI.setAttribute("bugReportHint", "text", "Describe what went wrong and how to reproduce it.")
	else
		UI.setAttribute("bugReportHint", "text", "Describe the feature or change you'd like.")
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
		-- SteamID64: stable + unique, but self-asserted -- the Worker cannot verify
		-- it (TTS exposes no Steam auth ticket), so treat it as a strong hint only.
		reporterId = player.steam_id,
		reporterColor = player.color,
		version = VERSION,
	}

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
	if resp.response_code == 429 then
		broadcastToColor("You're submitting reports too quickly -- wait a minute and try again.", color, { 1, 0.6, 0.2 })
		return
	end
	if resp.response_code ~= nil and resp.response_code >= 400 then
		broadcastToColor("Report was rejected (HTTP " .. tostring(resp.response_code) .. ").", color, { 1, 0.3, 0.3 })
		return
	end
	broadcastToColor("Thanks! Your report was submitted.", color, { 0.4, 1, 0.4 })
end
