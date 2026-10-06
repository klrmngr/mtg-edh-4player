-------------------------------------- PING --------------------------------------
-- A handful of "ping" commanders get a "Ping" button on the card itself while it
-- sits on a playmat (see card_triggers.lua), gated by the mat owner's
-- commanderQOL setting.
--
-- Clicking it reduces every opponent's life by 1 (life loss reuses loseLife, so
-- it announces and updates each Life_Tracker exactly like other scripted drains).

registerCardTrigger({
	names = {
		"Ob Nixilis, Captive Kingpin",
		"Vivi Ornitier",
		"Crystal, Inhuman Princess",
	},
	setting = "commanderQOL",
	buttons = {
		{
			click_function = "playerObNixPing",
			label = "Ping",
			tooltip = "                  [b]Ping[/b]\neach opponent loses 1 life",
		},
	},
})

-- button handler: only the owning player may activate their Ping. Every other
-- colour in the game loses 1 life (loseLife no-ops when a player has no
-- Life_Tracker, so absent seats are skipped).
function playerObNixPing(obj, clickerColor, alt)
	local ownerColor = cardTriggerController(obj, clickerColor, "Ping")
	if ownerColor == nil then
		return
	end
	Player[ownerColor].broadcast(ownerColor .. " pinged opponents for 1", ownerColor)
	for color, _ in pairs(data) do
		if color ~= ownerColor then
			loseLife(color, 1, "Ping")
		end
	end
end
