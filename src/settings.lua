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
	commanderQOL = true,     -- spawn the per-commander QOL buttons (Etali trigger, Ral grid)
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
	setCommanderQOL = "commanderQOL",
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
	"commanderQOL",
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
	-- the land tracker display is passive, so refresh it the moment it's toggled
	if key == "landTracker" then
		refreshLandTrackerText(player.color)
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
