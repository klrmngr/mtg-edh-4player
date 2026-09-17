-------------------------------------- PING --------------------------------------
-- A handful of "ping" commanders get a per-owner "Ping" button. Like the Etali
-- trigger it is NOT on the table by default: when a game starts (the opening-hand
-- snapshot -- see bumpMulliganCount) we check that player's command zone, and if
-- their commander is one of PING_COMMANDER_NAMES we attach the button there (see
-- command_buttons.lua for the shared placement/detection). It persists until the
-- next game start at which the player no longer has a ping commander.
--
-- Clicking it reduces every opponent's life by 1 (life loss reuses loseLife, so
-- it announces and updates each Life_Tracker exactly like other scripted drains).

PING_COMMANDER_NAMES = {
	"Ob Nixilis, Captive Kingpin",
	"Vivi Ornitier",
	"Crystal, Inhuman Princess",
}

-- does this player's command zone hold any of the ping commanders?
function hasPingCommander(color)
	for _, name in ipairs(PING_COMMANDER_NAMES) do
		if commandZoneHasCommander(color, name) then
			return true
		end
	end
	return false
end

-- game-start hook: the Ping button should be present iff the player has a ping
-- commander in their command zone at this moment. Clear first so a reload (where
-- the zone may keep a stale button) can't leave a duplicate.
function refreshObNixButton(color)
	if data[color] == nil then
		return
	end
	removeCommandZoneButton(color, "playerObNixPing")
	if getSetting(color, "commanderQOL") and hasPingCommander(color) then
		addCommandZoneButton(color, {
			click_function = "playerObNixPing",
			label = "Ping",
			tooltip = "                  [b]Ping[/b]\neach opponent loses 1 life",
		})
	end
end

-- button handler: only the owning player may activate their Ping. Every other
-- colour in the game loses 1 life (loseLife no-ops when a player has no
-- Life_Tracker, so absent seats are skipped).
function playerObNixPing(obj, clickerColor, alt)
	local ownerColor = commandZoneOwnerOf(obj)
	if ownerColor == nil then
		return
	end
	if clickerColor ~= ownerColor then
		Player[clickerColor].broadcast("Only " .. ownerColor .. " may use this Ping.")
		return
	end
	Player[ownerColor].broadcast(ownerColor .. " pinged opponents for 1", ownerColor)
	for color, _ in pairs(data) do
		if color ~= ownerColor then
			loseLife(color, 1, "Ping")
		end
	end
end
