--------------------------------- SETTINGS -------------------------------------
-- Per-player settings. Each player opens a private settings panel from the gear
-- button in their UI; the panel is shown only to them via the same visibility
-- rules the Scryfall panels use (visibleOpenRules / visibleCloseRules). Values
-- are stored per colour in playerSettings and persisted across save/load.
--
-- NOTE: the panel is a single shared widget set. A toggle always writes to the
-- *acting* player's settings (player.color), so storage stays correctly
-- per-player; only the on-screen toggle states would be shared if two players
-- happened to have the panel open at the same instant.

-- default value for every setting, applied to each colour on load
settingsDefaults = {
	oppDrawTriggers = false, -- notify this player about draw triggers (theirs / others')
	                         -- default off: feature is unfinished / somewhat buggy
	drawSkipReminder = true, -- warn (and stop the draw) on a "skip your draw step" card
	abilityRestrictions = false, -- remind on tapping a permanent whose activated abilities are prohibited
	                             -- default off: feature is unfinished / somewhat buggy
	searchRestrictions = true, -- block fetchland resolution when a tutor/search-hate card is in play
	landTracker = true,      -- track / show lands entered this turn on this player's mat
	fetchPreviews = true,    -- float library-land previews above this player's fetchlands
	fetchFromClone = false,  -- read those previews from the game-start deck clone instead of
	                         -- the live library, so an opponent's hidden removal (Praetor's
	                         -- Grasp, etc.) can't leak which land left. Off = live library.
	commanderQOL = true,     -- spawn the per-commander QOL buttons (Etali trigger, Ral grid)
	cmdrDamageAutoLife = true, -- commander-damage tracker deltas auto-adjust this player's life
	seedbornUntap = true,    -- this player's Seedborn Muse untaps their board on others' untap steps
	dfcLandFlip = true,      -- flip a double-faced card to its land back face in the land zone
	fetchSurveil = false,    -- auto-surveil/scry when a fetched land has an ETB surveil/scry trigger
	fetchEntersTapped = false, -- tap a fetched land whose text (or the fetchland) says it enters tapped
	goblinStickers = true,   -- deal goblin sticker cards when a "_____ Goblin" starts in the library
	keepPregameFlow = false, -- show the centre-mat Keep button and run the pregame-action announcement
	revealResetSecs = 30,    -- seconds of inactivity before the reveal count resets
}

-- panel toggle id -> settings key it controls
settingsToggleIds = {
	setOppDrawTriggers = "oppDrawTriggers",
	setDrawSkipReminder = "drawSkipReminder",
	setAbilityRestrictions = "abilityRestrictions",
	setSearchRestrictions = "searchRestrictions",
	setLandTracker = "landTracker",
	setFetchPreviews = "fetchPreviews",
	setFetchFromClone = "fetchFromClone",
	setCommanderQOL = "commanderQOL",
	setCmdrDamageAutoLife = "cmdrDamageAutoLife",
	setSeedbornUntap = "seedbornUntap",
	setDfcLandFlip = "dfcLandFlip",
	setFetchSurveil = "fetchSurveil",
	setFetchEntersTapped = "fetchEntersTapped",
	setGoblinStickers = "goblinStickers",
	setKeepPregameFlow = "keepPregameFlow",
}

-- colour -> { key = value }
playerSettings = playerSettings or {}

settingsColors = { "White", "Red", "Yellow", "Blue" }

-- settings the host can enforce on everyone (booleans only). When a key is
-- enforced, getSetting returns the enforced value for every colour and each
-- player's own toggle for it is greyed out. Defaults: nothing enforced, all
-- enforced values false.
enforceableKeys = {
	"oppDrawTriggers",
	"drawSkipReminder",
	"abilityRestrictions",
	"searchRestrictions",
	"landTracker",
	"fetchPreviews",
	"fetchFromClone",
	"commanderQOL",
	"cmdrDamageAutoLife",
	"seedbornUntap",
	"dfcLandFlip",
	"fetchSurveil",
	"fetchEntersTapped",
	"goblinStickers",
	"keepPregameFlow",
}

-- key -> { enforced = bool, value = bool }
enforcedSettings = enforcedSettings or {}

function initEnforced()
	enforcedSettings = enforcedSettings or {}
	for _, key in ipairs(enforceableKeys) do
		local e = enforcedSettings[key] or {}
		if e.enforced == nil then
			e.enforced = false
		end
		if e.value == nil then
			e.value = false
		end
		enforcedSettings[key] = e
	end
end

-- pull the settings key out of a host-panel widget id ("hostEnf_<key>" /
-- "hostVal_<key>"), or nil if the prefix doesn't match
function hostKeyFromId(id, prefix)
	if id ~= nil and id:sub(1, #prefix) == prefix then
		return id:sub(#prefix + 1)
	end
	return nil
end

-- fill in any missing colours / keys with defaults; called from onload after any
-- saved state has been restored
function initSettings()
	playerSettings = playerSettings or {}
	for _, color in ipairs(settingsColors) do
		playerSettings[color] = playerSettings[color] or {}
		for key, def in pairs(settingsDefaults) do
			if playerSettings[color][key] == nil then
				playerSettings[color][key] = def
			end
		end
	end
end

-- read a setting for a colour. A host-enforced setting overrides every player's
-- own value; otherwise fall back to the player's value, then the default.
function getSetting(color, key)
	local e = enforcedSettings[key]
	if e ~= nil and e.enforced then
		return e.value
	end
	local s = playerSettings[color]
	if s ~= nil and s[key] ~= nil then
		return s[key]
	end
	return settingsDefaults[key]
end

---------------------------------- PERSISTENCE ---------------------------------
-- TTS serialises the Global script state via onSave; we stash playerSettings in
-- it and read it back in onload(saved). Tolerant of a nil / malformed blob.
-- Both casings are defined because this table's entry point is lower-case
-- onload(); whichever name TTS calls, the other is simply dead.
function saveSettings()
	return JSON.encode({ playerSettings = playerSettings, enforcedSettings = enforcedSettings })
end

function restoreSettings(saved)
	if saved ~= nil and saved ~= "" then
		local ok, decoded = pcall(JSON.decode, saved)
		if ok and type(decoded) == "table" then
			if type(decoded.playerSettings) == "table" then
				playerSettings = decoded.playerSettings
			end
			if type(decoded.enforcedSettings) == "table" then
				enforcedSettings = decoded.enforcedSettings
			end
		end
	end
	initSettings()
	initEnforced()
end

function onSave()
	return saveSettings()
end

function onsave()
	return saveSettings()
end

-------------------------------- SEARCH FILTER ---------------------------------
-- The player panel scrolls; the search box at the top filters it. Each setting
-- row has a stable id (row_<key>) plus a bag of keywords. Typing hides every row
-- whose keywords don't contain the query, and hides the section headers while a
-- query is active (they'd otherwise float above empty space).
settingsSearchRows = {
	{ id = "row_oppDrawTriggers", text = "opponent draw trigger alerts triggers" },
	{ id = "row_drawSkipReminder", text = "draw step skip reminder state based" },
	{ id = "row_abilityRestrictions", text = "cant activate ability reminder cannot state based" },
	{ id = "row_searchRestrictions", text = "tutor search restriction blocks fetch state based" },
	{ id = "row_cmdrDamageAutoLife", text = "commander damage adjusts life automation" },
	{ id = "row_seedbornUntap", text = "seedborn muse untap state based" },
	{ id = "row_dfcLandFlip", text = "flip dfc double faced land face automation" },
	{ id = "row_fetchSurveil", text = "fetched land surveil scry automation fetch" },
	{ id = "row_fetchEntersTapped", text = "fetched land enters tapped automation fetch" },
	{ id = "row_landTracker", text = "land entered tracker display" },
	{ id = "row_fetchPreviews", text = "fetchland previews display fetch" },
	{ id = "row_fetchFromClone", text = "show all possible fetchables clone display fetch" },
	{ id = "row_commanderQOL", text = "commander qol buttons etali ral" },
	{ id = "row_goblinStickers", text = "goblin stickers game" },
	{ id = "row_keepPregameFlow", text = "keep pregame flow game" },
	{ id = "row_revealResetSecs", text = "reveal reset seconds misc" },
}

settingsSearchHeaders = {
	"hdr_triggers", "hdr_stateBased", "hdr_automation",
	"hdr_display", "hdr_commander", "hdr_game", "hdr_misc",
}

-- restore every row + header to visible (no active query)
function clearSettingsSearch()
	for _, r in ipairs(settingsSearchRows) do
		UI.setAttribute(r.id, "active", "true")
	end
	for _, h in ipairs(settingsSearchHeaders) do
		UI.setAttribute(h, "active", "true")
	end
end

-- InputField handler: filter the panel to rows matching the query. Headers are
-- hidden while filtering since a section may end up empty.
function settingsSearch(player, value, id)
	local q = (value or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
	if q == "" then
		clearSettingsSearch()
		return
	end
	for _, h in ipairs(settingsSearchHeaders) do
		UI.setAttribute(h, "active", "false")
	end
	for _, r in ipairs(settingsSearchRows) do
		UI.setAttribute(r.id, "active", r.text:find(q, 1, true) ~= nil and "true" or "false")
	end
end

-- host panel mirrors the player panel: same row ids prefixed "hostrow_", same
-- keyword bags. The legend row is never hidden so the ENF/ON columns stay labelled.
hostSearchRows = {
	{ id = "hostrow_oppDrawTriggers", text = "opponent draw trigger alerts triggers" },
	{ id = "hostrow_drawSkipReminder", text = "draw step skip reminder state based" },
	{ id = "hostrow_abilityRestrictions", text = "cant activate ability reminder cannot state based" },
	{ id = "hostrow_searchRestrictions", text = "tutor search restriction blocks fetch state based" },
	{ id = "hostrow_cmdrDamageAutoLife", text = "commander damage adjusts life automation" },
	{ id = "hostrow_seedbornUntap", text = "seedborn muse untap state based" },
	{ id = "hostrow_dfcLandFlip", text = "flip dfc double faced land face automation" },
	{ id = "hostrow_fetchSurveil", text = "fetched land surveil scry automation fetch" },
	{ id = "hostrow_fetchEntersTapped", text = "fetched land enters tapped automation fetch" },
	{ id = "hostrow_landTracker", text = "land entered tracker display" },
	{ id = "hostrow_fetchPreviews", text = "fetchland previews display fetch" },
	{ id = "hostrow_fetchFromClone", text = "show all possible fetchables clone display fetch" },
	{ id = "hostrow_commanderQOL", text = "commander qol buttons etali ral" },
	{ id = "hostrow_goblinStickers", text = "goblin stickers game" },
	{ id = "hostrow_keepPregameFlow", text = "keep pregame flow game" },
}

hostSearchHeaders = {
	"hosthdr_triggers", "hosthdr_stateBased", "hosthdr_automation",
	"hosthdr_display", "hosthdr_commander", "hosthdr_game",
}

function clearHostSettingsSearch()
	for _, r in ipairs(hostSearchRows) do
		UI.setAttribute(r.id, "active", "true")
	end
	for _, h in ipairs(hostSearchHeaders) do
		UI.setAttribute(h, "active", "true")
	end
end

function hostSettingsSearch(player, value, id)
	local q = (value or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
	if q == "" then
		clearHostSettingsSearch()
		return
	end
	for _, h in ipairs(hostSearchHeaders) do
		UI.setAttribute(h, "active", "false")
	end
	for _, r in ipairs(hostSearchRows) do
		UI.setAttribute(r.id, "active", r.text:find(q, 1, true) ~= nil and "true" or "false")
	end
end

-------------------------------- PLAYER PANEL ----------------------------------
-- set each per-player toggle's enabled state to match host enforcement: an
-- enforced setting is locked (non-interactable) and shows the enforced value; an
-- unenforced setting is editable and, when a viewer colour is given, shows that
-- player's own value.
function applyEnforcementToPlayerPanel(color)
	for id, key in pairs(settingsToggleIds) do
		local e = enforcedSettings[key]
		if e ~= nil and e.enforced then
			UI.setAttribute(id, "isOn", e.value and "True" or "False")
			UI.setAttribute(id, "interactable", "false")
		else
			UI.setAttribute(id, "interactable", "true")
			if color ~= nil then
				UI.setAttribute(id, "isOn", getSetting(color, key) and "True" or "False")
			end
		end
	end
end

-- reflect the opening player's stored settings into the shared widgets, lock any
-- host-enforced ones, then show the panel only to them
function openSettings(player)
	if player == nil or player.color == "Grey" then
		return
	end
	local color = player.color
	applyEnforcementToPlayerPanel(color)
	UI.setAttribute("setRevealResetSecs", "text", tostring(getSetting(color, "revealResetSecs")))
	-- start every open with an empty search box and all rows shown
	UI.setAttribute("settingsSearchInput", "text", "")
	clearSettingsSearch()
	visibleOpenRules(color, "SettingsPanel")
end

function closeSettings(player)
	visibleCloseRules(player, "SettingsPanel")
end

-- a toggle changed: write the acting player's setting (ignored if the host has
-- enforced it)
function settingsToggle(player, value, id)
	local key = settingsToggleIds[id]
	if key == nil or player == nil then
		return
	end
	local e = enforcedSettings[key]
	if e ~= nil and e.enforced then
		-- locked by the host; snap the widget back to the enforced value
		UI.setAttribute(id, "isOn", e.value and "True" or "False")
		return
	end
	playerSettings[player.color] = playerSettings[player.color] or {}
	local on = (value == "True" or value == true)
	playerSettings[player.color][key] = on
	UI.setAttribute(id, "isOn", on and "True" or "False")
	-- the land tracker + fetch previews are passive, so refresh them the moment they
	-- are toggled (fetchFromClone changes the preview source, so refresh it too)
	if key == "landTracker" then
		refreshLandTrackerText(player.color)
	elseif key == "fetchPreviews" or key == "fetchFromClone" then
		refreshFetchPreviewsForColor(player.color)
	elseif key == "keepPregameFlow" then
		refreshKeepButton(player.color)
	end
end

--------------------------------- HOST PANEL -----------------------------------
-- second, host-only menu: per setting an "enforced" toggle and a "value" toggle.
-- Enforcing a setting forces it on every player (via getSetting) and greys out
-- their own toggle; unenforcing hands control back to each player.

function refreshAllLandTrackers()
	for _, color in ipairs(settingsColors) do
		refreshLandTrackerText(color)
	end
end

function refreshAllKeepButtons()
	for _, color in ipairs(settingsColors) do
		refreshKeepButton(color)
	end
end

function openHostSettings(player)
	if player == nil then
		return
	end
	if not player.host then
		broadcastToColor("Host settings are host-only.", player.color, { 0.9, 0.5, 0.2 })
		return
	end
	for _, key in ipairs(enforceableKeys) do
		local e = enforcedSettings[key]
		UI.setAttribute("hostEnf_" .. key, "isOn", e.enforced and "True" or "False")
		UI.setAttribute("hostVal_" .. key, "isOn", e.value and "True" or "False")
		-- the value only matters while enforced, so lock it otherwise
		UI.setAttribute("hostVal_" .. key, "interactable", e.enforced and "true" or "false")
	end
	-- start every open with an empty search box and all rows shown
	UI.setAttribute("hostSearchInput", "text", "")
	clearHostSettingsSearch()
	visibleOpenRules(player.color, "HostSettingsPanel")
end

function closeHostSettings(player)
	visibleCloseRules(player, "HostSettingsPanel")
end

function hostToggleEnforced(player, value, id)
	if player == nil or not player.host then
		return
	end
	local key = hostKeyFromId(id, "hostEnf_")
	if key == nil or enforcedSettings[key] == nil then
		return
	end
	local on = (value == "True" or value == true)
	enforcedSettings[key].enforced = on
	UI.setAttribute(id, "isOn", on and "True" or "False")
	UI.setAttribute("hostVal_" .. key, "interactable", on and "true" or "false")
	applyEnforcementToPlayerPanel(nil)
	if key == "landTracker" then
		refreshAllLandTrackers()
	elseif key == "fetchPreviews" or key == "fetchFromClone" then
		refreshAllFetchPreviews()
	elseif key == "keepPregameFlow" then
		refreshAllKeepButtons()
	end
end

function hostToggleValue(player, value, id)
	if player == nil or not player.host then
		return
	end
	local key = hostKeyFromId(id, "hostVal_")
	if key == nil or enforcedSettings[key] == nil then
		return
	end
	local on = (value == "True" or value == true)
	enforcedSettings[key].value = on
	UI.setAttribute(id, "isOn", on and "True" or "False")
	applyEnforcementToPlayerPanel(nil)
	if key == "landTracker" then
		refreshAllLandTrackers()
	elseif key == "fetchPreviews" or key == "fetchFromClone" then
		refreshAllFetchPreviews()
	elseif key == "keepPregameFlow" then
		refreshAllKeepButtons()
	end
end

-- reveal-reset timeout committed
function settingsRevealReset(player, value, id)
	if player == nil then
		return
	end
	local n = tonumber(value)
	if n == nil or n < 1 then
		n = settingsDefaults.revealResetSecs
	end
	n = math.floor(n)
	playerSettings[player.color] = playerSettings[player.color] or {}
	playerSettings[player.color].revealResetSecs = n
	UI.setAttribute("setRevealResetSecs", "text", tostring(n))
end
