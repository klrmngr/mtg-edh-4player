------------------------------------ ETALI -------------------------------------
-- "Etali, Primal Conqueror" gets a per-owner activation button. It is NOT on the
-- table by default: when a game starts (the opening-hand snapshot -- see
-- reset.lua / bumpMulliganCount) we look at that player's command zone, and if
-- their commander is Etali we attach a button to that command zone. The button
-- persists until the next game start at which that player no longer has Etali in
-- their command zone.
--
-- The button lives directly on the command-zone scripting zone (same trick the
-- land tracker uses on the playmat zones) so it renders as floating white text
-- with no tile, and its text is counter-scaled by the zone's scale so it isn't
-- stretched. Clicking it reveals the top of every player's library until a nonland
-- is hit: each land revealed goes to that player's exile, and the first nonland
-- from each deck is placed in front of the owner. Land detection reuses cardIsLand.

ETALI_COMMANDER_NAME = "Etali, Primal Conqueror"
-- The command-zone scripting zone is a ~3-unit-tall box, so its centre sits ~1.5
-- above the table. We aim at a world point on the table, behind the zone, then
-- convert it into the zone's local space. Flip etaliButtonBehind's sign if
-- "behind" comes out as "in front".
etaliButtonDrop = 1.5 -- world units down from the zone centre to the table
etaliButtonLift = 0.05 -- small lift so the text sits just above the table
etaliButtonBehind = 2.5 -- world units behind the zone, along its forward axis

-- a TTS card name carries its type line on following newlines (e.g.
-- "Etali, Primal Conqueror\nLegendary Creature ..."), so match only the first line
function isEtaliName(name)
	if name == nil then
		return false
	end
	local firstLine = tostring(name):match("^[^\r\n]*") or ""
	return firstLine == ETALI_COMMANDER_NAME
end

-- does this player's command zone currently hold the Etali commander? handles a
-- lone commander card as well as a stacked deck (e.g. partners)
function commandZoneHasEtali(color)
	local cz = data[color] and data[color]["commandZone"]
	if cz == nil then
		return false
	end
	for _, obj in ipairs(cz.getObjects()) do
		if obj.type == "Card" then
			if isEtaliName(obj.getName()) then
				return true
			end
		elseif obj.type == "Deck" then
			for _, c in ipairs(obj.getObjects()) do
				if isEtaliName(c.name) then
					return true
				end
			end
		end
	end
	return false
end

-- game-start hook: the Etali button should be present iff the player has the
-- Etali commander in their command zone at this moment. Always clear first so a
-- reload (where the zone may keep a stale button) can't leave a duplicate.
function refreshEtaliButton(color)
	if data[color] == nil then
		return
	end
	removeEtaliButton(color)
	if commandZoneHasEtali(color) then
		addEtaliButton(color)
	end
end

-- attach the Etali button to the player's command-zone scripting zone
function addEtaliButton(color)
	local cz = data[color] and data[color]["commandZone"]
	if cz == nil then
		return
	end
	-- aim at a point on the table behind the zone, then convert to the zone's
	-- local space (positionToLocal handles the zone's rotation/scale for us)
	local world = cz.getPosition() + cz.getTransformForward():scale(etaliButtonBehind)
	world.y = world.y - etaliButtonDrop + etaliButtonLift
	local lp = cz.positionToLocal(world)
	-- counter-scale the button by the zone scale so the text renders un-stretched
	local s = cz.getScale()
	cz.createButton({
		click_function = "playerEtali",
		function_owner = self,
		label = "Etali Trigger",
		tooltip = "                  [b]Etali[/b]\nreveal each library until a nonland:\n  lands go to that player's exile,\n  the nonland comes to you",
		position = { lp.x, lp.y, lp.z },
		scale = { 1 / s.x, 1 / s.y, 1 / s.z },
		width = 2000,
		height = 500,
		font_size = 250,
		color = { 1, 1, 1, 0 },
		font_color = { 1, 1, 1, 100 },
		hover_color = { 1, 1, 1, 0.1 },
		press_color = { 1, 0, 0, 0.2 },
	})
end

-- remove any Etali button(s) from the player's command-zone scripting zone
function removeEtaliButton(color)
	local cz = data[color] and data[color]["commandZone"]
	if cz == nil then
		return
	end
	local buttons = cz.getButtons()
	if buttons == nil then
		return
	end
	-- collect matching indices, then remove high-to-low so indices don't shift
	local indices = {}
	for _, b in ipairs(buttons) do
		if b.click_function == "playerEtali" then
			table.insert(indices, b.index)
		end
	end
	table.sort(indices, function(a, b)
		return a > b
	end)
	for _, idx in ipairs(indices) do
		cz.removeButton(idx)
	end
end

-- map a command-zone object back to its owner colour
function etaliOwnerOf(obj)
	for color, pdata in pairs(data) do
		if pdata["commandZone"] == obj then
			return color
		end
	end
	return nil
end

-- button handler: only the owning player may activate their Etali. Reveal the
-- top of every player's library until a nonland is hit -- each land goes to that
-- player's exile, the first nonland from each deck is placed in front of the
-- owner. Land detection reuses the cascade "-1" CMC sentinel (see getCMC).
function playerEtali(obj, clickerColor, alt)
	local ownerColor = etaliOwnerOf(obj)
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
