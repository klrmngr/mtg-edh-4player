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
}

-- colour -> { key = value }
playerSettings = playerSettings or {}

settingsColors = { "White", "Red", "Yellow", "Blue" }

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

-- read a setting for a colour, falling back to the default
function getSetting(color, key)
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
	return JSON.encode({ playerSettings = playerSettings })
end

function restoreSettings(saved)
	if saved ~= nil and saved ~= "" then
		local ok, decoded = pcall(JSON.decode, saved)
		if ok and type(decoded) == "table" and type(decoded.playerSettings) == "table" then
			playerSettings = decoded.playerSettings
		end
	end
	initSettings()
end

function onSave()
	return saveSettings()
end

function onsave()
	return saveSettings()
end

------------------------------------ PANEL -------------------------------------
-- reflect the opening player's stored settings into the shared widgets, then
-- show the panel only to them
function openSettings(player)
	if player == nil or player.color == "Grey" then
		return
	end
	local color = player.color
	for id, key in pairs(settingsToggleIds) do
		UI.setAttribute(id, "isOn", getSetting(color, key) and "True" or "False")
	end
	UI.setAttribute("setRevealResetSecs", "text", tostring(getSetting(color, "revealResetSecs")))
	visibleOpenRules(color, "SettingsPanel")
end

function closeSettings(player)
	visibleCloseRules(player, "SettingsPanel")
end

-- a toggle changed: write the acting player's setting
function settingsToggle(player, value, id)
	local key = settingsToggleIds[id]
	if key == nil or player == nil then
		return
	end
	playerSettings[player.color] = playerSettings[player.color] or {}
	local on = (value == "True" or value == true)
	playerSettings[player.color][key] = on
	UI.setAttribute(id, "isOn", on and "True" or "False")
	-- the land tracker display is passive, so refresh it the moment it's toggled
	if key == "landTracker" then
		refreshLandTrackerText(player.color)
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
