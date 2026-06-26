------------------------------------ ETALI -------------------------------------
-- "Etali, Primal Conqueror" gets a per-owner "Etali Trigger" button. It is NOT on
-- the table by default: when a game starts (the opening-hand snapshot -- see
-- reset.lua / bumpMulliganCount) we check that player's command zone, and if their
-- commander is Etali we attach the button there (see command_buttons.lua for the
-- shared placement/detection). It persists until the next game start at which the
-- player no longer has Etali.
--
-- Clicking it reveals the top of every player's library until a nonland is hit:
-- each land revealed goes to that player's exile, and the first nonland from each
-- deck is placed in front of the owner. Land detection reuses cardIsLand.

ETALI_COMMANDER_NAME = "Etali, Primal Conqueror"

-- game-start hook: the Etali button should be present iff the player has the
-- Etali commander in their command zone at this moment. Clear first so a reload
-- (where the zone may keep a stale button) can't leave a duplicate.
function refreshEtaliButton(color)
	if data[color] == nil then
		return
	end
	removeCommandZoneButton(color, "playerEtali")
	if commandZoneHasCommander(color, ETALI_COMMANDER_NAME) then
		addCommandZoneButton(color, {
			click_function = "playerEtali",
			label = "Etali Trigger",
			tooltip = "                  [b]Etali[/b]\nreveal each library until a nonland:\n  lands go to that player's exile,\n  the nonland comes to you",
		})
	end
end

-- button handler: only the owning player may activate their Etali. Reveal the
-- top of every player's library until a nonland is hit -- each land goes to that
-- player's exile, the first nonland from each deck is placed in front of the
-- owner. Land detection reuses the cascade "-1" CMC sentinel (see getCMC).
function playerEtali(obj, clickerColor, alt)
	local ownerColor = commandZoneOwnerOf(obj)
	if ownerColor == nil then
		return
	end
	if clickerColor ~= ownerColor then
		Player[clickerColor].broadcast("Only " .. ownerColor .. " may activate this Etali.")
		return
	end
	if etaliRunning then
		return
	end
	etaliRunning = true
	Wait.time(function()
		etaliRunning = false
	end, 3)

	etaliPlaced = 0
	-- clear glows from any earlier trigger, and remember whose turn this glow
	-- belongs to so it can be cleared when *that* player's turn ends
	clearEtaliGlows()
	etaliTriggerColor = ownerColor
	Player[ownerColor].broadcast("Etali: revealing each library until a nonland", ownerColor)
	for color, _ in pairs(data) do
		etaliRevealNext(color, ownerColor)
	end
end

-- pull the top card of ownerColor's library and route it (land -> exile,
-- nonland -> in front of the clicker, and stop revealing that deck)
function etaliRevealNext(ownerColor, clickerColor)
	local card = getCardFromZone(data[ownerColor]["libraryZone"])
	if card == nil then
		return -- empty library
	end
	Wait.condition(function()
		local isLand = cardIsLand(card)
		if isLand then
			etaliExile(ownerColor, card)
			Wait.time(function()
				etaliRevealNext(ownerColor, clickerColor)
			end, 0.45)
		else
			etaliPlaceNonland(clickerColor, ownerColor, card)
		end
	end, function()
		return not card.spawning
	end)
end

-- how far above the playmat (toward table centre) the etali cards are staged
etaliAbove = -12.5

-- cards lit by the current Etali trigger, and the colour of the player who
-- triggered it. The glow lasts until that player's own turn ends (see
-- maybeClearEtaliGlows, called from onPlayerTurnStart).
etaliGlowingCards = {}
etaliTriggerColor = nil

-- glow a card in its owner's colour until the turn ends, tracking it for cleanup
function etaliGlow(card, ownerColor)
	card.highlightOn(stringColorToRGB(ownerColor))
	table.insert(etaliGlowingCards, card)
end

-- turn off every Etali glow now
function clearEtaliGlows()
	for _, card in ipairs(etaliGlowingCards) do
		if card ~= nil then
			pcall(function()
				card.highlightOff()
			end)
		end
	end
	etaliGlowingCards = {}
	etaliTriggerColor = nil
end

-- clear the glow only when the player who triggered Etali has just ended their
-- turn (not on every player's turn in the cycle)
function maybeClearEtaliGlows(endedColor)
	if etaliTriggerColor ~= nil and endedColor == etaliTriggerColor then
		clearEtaliGlows()
	end
end

-- send a revealed land to its owner's dedicated exile zone (anchoring to that
-- zone's position keeps it correct no matter how the zones are rotated) and glow
-- it in the owner's colour so everyone can see whose card moved
function etaliExile(ownerColor, card)
	local zone = data[ownerColor]["exileZone"]
	local rot = card.getRotation()
	rot.z = 0
	rot.y = zone.getRotation().y
	local pos = zone.getPosition()
	pos.y = 3
	card.setRotationSmooth(rot, false, true)
	card.setPositionSmooth(pos, false, true)
	etaliGlow(card, ownerColor)
end

-- place a revealed nonland face up in a row above the clicking player's mat,
-- glowing in the card owner's colour so everyone can see whose card moved
function etaliPlaceNonland(clickerColor, ownerColor, card)
	local mat = data[clickerColor]["playmat"]
	local i = etaliPlaced or 0
	etaliPlaced = i + 1
	local pos = mat.getPosition()
		+ mat.getTransformRight():scale((i - 1.5) * 3)
		+ mat.getTransformForward():scale(etaliAbove)
	pos.y = 3
	card.setRotationSmooth({ 0, mat.getRotation().y, 0 }, false, true)
	card.setPositionSmooth(pos, false, true)
	etaliGlow(card, ownerColor)
end
