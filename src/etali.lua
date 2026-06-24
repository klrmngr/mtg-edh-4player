------------------------------------ ETALI -------------------------------------
-- Reveal the top of every player's library until a nonland is hit: each land
-- revealed goes to that player's exile, and the first nonland from each deck is
-- placed in front of the player who clicked Etali. Land detection reuses the
-- cascade "-1" CMC sentinel (see getCMC).
function playerEtali(button, clickerColor, alt)
	if data[clickerColor] == nil then
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
	Player[clickerColor].broadcast("Etali: revealing each library until a nonland", clickerColor)
	for color, _ in pairs(data) do
		etaliRevealNext(color, clickerColor)
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

-- how far above the playmat (toward table centre) the etali cards are staged,
-- and how long a moved card glows in its owner's colour
etaliAbove = -12.5
etaliGlow = 30

-- send a revealed land to its owner's exile (mirrors move2exile placement) and
-- glow it in the owner's colour so everyone can see whose card moved
function etaliExile(ownerColor, card)
	local zone = data[ownerColor]["libraryZone"]
	local rot = card.getRotation()
	rot.z = 0
	rot.y = zone.getRotation().y + exileRot
	local pos = zone.getPosition() + zone.getTransformForward():scale(exileFor)
	pos.y = 3
	card.setRotationSmooth(rot, false, true)
	card.setPositionSmooth(pos, false, true)
	card.highlightOn(stringColorToRGB(ownerColor), etaliGlow)
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
	card.highlightOn(stringColorToRGB(ownerColor), etaliGlow)
end
