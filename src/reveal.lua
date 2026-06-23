------------------------------------ REVEAL ------------------------------------
function revealFan(button, ply, alt)
	if button ~= data[ply]["revealButton"] then
		return
	end
	if alt then
		local rot = button.getRotation()
		rot[3] = 180
		button.setRotation(rot)
		return
	end
	local card = getCardFromZone(data[ply]["libraryZone"])
	local hexPrefix = "[" .. Color[ply]:toHex() .. "]"
	buttonPress(button, drawDelay)
	if card == nil then
		return
	end
	local libZone = data[ply]["libraryZone"]
	local now = os.time()
	local lastT = tonumber(button.memo)
	local nRevealed = tonumber(button.getGMNotes())
	if now - lastT > 30 then
		nRevealed = 0
		revealedCMC = revealedCMC or {}
		revealedCMC[ply] = 0
	end
	button.memo = tostring(now)
	local nUp = math.floor(nRevealed / revealNrow)
	local nSide = nRevealed - nUp * revealNrow
	local forw = libZone.getTransformForward()
	local righ = libZone.getTransformRight()
	local pos = libZone.getPosition()
		+ forw:scale(revealUp + revealUpS * nUp)
		+ righ:scale(deckDirs[ply] * 2.25 * (nSide + revealRi))
	local rot = libZone.getRotation()
	rot[2] = rot[2] + 180
	rot[3] = 0
	checkPosMove(pos, libZone)
	card.setPositionSmooth(pos, false, true)
	card.setRotationSmooth(rot, false, true)
	card.highlightOn(stringColorToRGB(ply), 10)
	nRevealed = nRevealed + 1
	button.setGMNotes(tostring(nRevealed))
	tallyRevealCMC(ply, hexPrefix, nRevealed, card)
end

function revealStack(button, ply, alt)
	if button ~= data[ply]["revealButton"] then
		return
	end
	if alt then
		local rot = button.getRotation()
		rot[3] = 0
		button.setRotation(rot)
		return
	end
	local card = getCardFromZone(data[ply]["libraryZone"])
	local hexPrefix = "[" .. Color[ply]:toHex() .. "]"
	buttonPress(button, drawDelay)
	if card == nil then
		return
	end
	local libZone = data[ply]["libraryZone"]
	local now = os.time()
	local lastT = tonumber(button.memo)
	local nRevealed = tonumber(button.getGMNotes())
	if now - lastT > 30 then
		nRevealed = 0
		revealedCMC = revealedCMC or {}
		revealedCMC[ply] = 0
	end
	button.memo = tostring(now)
	local righ = libZone.getTransformRight()
	local pos = libZone.getPosition() + vector(0, 2, 0) + righ:scale(deckDirs[ply] * 2.4)
	local rot = libZone.getRotation()
	rot[2] = rot[2] + 180
	rot[3] = 0
	card.setPositionSmooth(pos, false, true)
	card.setRotationSmooth(rot, false, true)
	nRevealed = nRevealed + 1
	button.setGMNotes(tostring(nRevealed))
	tallyRevealCMC(ply, hexPrefix, nRevealed, card)
end

-- accumulate revealed CMC (lands count as 0) and broadcast the running total;
-- cards whose CMC can't be parsed are flagged and left out of the tally
function tallyRevealCMC(ply, hexPrefix, nRevealed, card)
	revealedCMC = revealedCMC or {}
	revealedCMC[ply] = revealedCMC[ply] or 0
	local cmc = getCMC(card.getName(), card.getDescription(), false)
	local flag = ""
	if cmc == nil then
		flag = " [FF8800][b](CMC?)[/b][-]"
	else
		revealedCMC[ply] = revealedCMC[ply] + tonumber(cmc)
	end
	broadcastToAll(
		hexPrefix
			.. "[b]"
			.. nRevealed
			.. ":[/b][-] "
			.. card.getName():gsub("\n", " | ")
			.. flag
			.. "  [b]total CMC: "
			.. revealedCMC[ply]
			.. "[/b]"
	)
end

function checkPosMove(pos, libZone)
	local castPos = pos
	castPos[2] = 1
	local castPars = {
		origin = castPos,
		type = 3,
		size = { 1, 4, 1.5 },
		direction = vector(0, 0, 1),
		max_distance = 0,
	}
	local castOutput = Physics.cast(castPars)
	for _, castO in pairs(castOutput) do
		local hitObj = castO.hit_object
		if hitObj.type == "Card" or hitObj.type == "Deck" then
			local objPos = hitObj.getPosition()
			if math.abs(objPos.z) > 7 then
				local relPos = libZone.positionToLocal(pos)
				local relPosObj = libZone.positionToLocal(objPos)
				local newRelPos = relPosObj
				newRelPos[3] = relPos[3] + 3.1 / libZone.getScale().z
				local newPos = libZone.positionToWorld(newRelPos)
				checkPosMove(newPos, libZone)
				hitObj.setPositionSmooth(newPos, false, true)
			end
		end
	end
end

