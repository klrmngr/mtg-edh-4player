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
		local isLand = getCMC(card.getName(), card.getDescription()) == "-1"
		if isLand then
			etaliExile(ownerColor, card)
			Wait.time(function()
				etaliRevealNext(ownerColor, clickerColor)
			end, 0.45)
		else
			etaliPlaceNonland(clickerColor, card)
		end
	end, function()
		return not card.spawning
	end)
end

-- send a revealed land to its owner's exile (mirrors move2exile placement)
function etaliExile(ownerColor, card)
	local zone = data[ownerColor]["libraryZone"]
	local rot = card.getRotation()
	rot.z = 0
	rot.y = zone.getRotation().y + exileRot
	local pos = zone.getPosition() + zone.getTransformForward():scale(exileFor)
	pos.y = 3
	card.setRotationSmooth(rot, false, true)
	card.setPositionSmooth(pos, false, true)
end

-- place a revealed nonland face up in a row in front of the clicking player
function etaliPlaceNonland(clickerColor, card)
	local mat = data[clickerColor]["playmat"]
	local i = etaliPlaced or 0
	etaliPlaced = i + 1
	local pos = mat.getPosition() + mat.getTransformRight():scale((i - 1.5) * 3)
	pos.y = 3
	card.setRotationSmooth({ 0, mat.getRotation().y, 0 }, false, true)
	card.setPositionSmooth(pos, false, true)
end
