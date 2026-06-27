------------------------------------- DRAW -------------------------------------
function playerDraw(button, playerColor, alt)
	if button == data[playerColor]["drawButton"] then
		if not alt then
			buttonPress(button, drawDelay * 0.75)
			draw1(playerColor)
		else
			buttonPress(button, drawDelay * nAlt)
			buttonCooldown(button, drawDelay * nAlt)
			Wait.time(function()
				draw1(playerColor)
			end, drawDelay, nAlt)
		end
	else
		warnNotYours(button, playerColor)
	end
end

function draw1(playerColor)
	local card = getCardFromZone(data[playerColor]["libraryZone"])
	if card ~= nil then
		--interactTrigger(card)
		Wait.condition(function()
			card.deal(1, playerColor, 1)
		end, function()
			return not card.spawning
		end)
	end
end

------------------------------------- MILL -------------------------------------
function playerMill(button, playerColor, alt)
	if button == data[playerColor]["millButton"] then
		if not alt then
			buttonPress(button, drawDelay * 0.75)
			mill1(playerColor)
		else
			buttonPress(button, drawDelay * nAlt)
			buttonCooldown(button, drawDelay * nAlt)
			Wait.time(function()
				mill1(playerColor)
			end, drawDelay, nAlt)
		end
	else
		warnNotYours(button, playerColor)
	end
end

function mill1(playerColor)
	local card = getCardFromZone(data[playerColor]["libraryZone"])
	if card ~= nil then
		local gravPos = data[playerColor]["graveyard"].getPosition()
		local targPos = { x = gravPos.x, y = 3, z = gravPos.z }
		--interactTrigger(card)
		local cardRot = card.getRotation()
		cardRot.z = 0
		card.setRotationSmooth(cardRot, false, true)
		card.setPositionSmooth(targPos, false, true)
		Wait.time(function()
			checkMoveSuccess(card, targPos, playerColor)
		end, 0.5)
	end
end

------------------------------------- SCRY -------------------------------------
function playerScry(button, playerColor, alt)
	if button == data[playerColor]["scryButton"] then
		if not alt then
			buttonPress(button, drawDelay * 0.75)
			scry1(playerColor)
		else
			buttonPress(button, drawDelay * nAlt)
			buttonCooldown(button, drawDelay * nAlt)
			Wait.time(function()
				scry1(playerColor)
			end, drawDelay, nAlt)
		end
	else
		warnNotYours(button, playerColor)
	end
end

function scry1(playerColor)
	local card = getCardFromZone(data[playerColor]["libraryZone"])
	if card ~= nil then
		Wait.condition(function()
			card.deal(1, playerColor, 2)
			Encoder.call("APIencodeObject", { obj = card })
			Encoder.call("APIobjEnableProp", { obj = card, propID = "πScry" })
		end, function()
			return not card.spawning
		end)
	end
end

-- deal() works stupidly with non-primary hand
-- (card arrives and floats for 5 seconds before taking formation with other cards)
-- using setPositionSmooth() does not have this problem but
-- using default hand position always sends the card into the middle, changing the order of cards
-- so.. the function below gets the right-ish side of the zone
function getHand2Pos(playerColor)
	local pos = Player[playerColor].getHandTransform(2).position
	local sca = Player[playerColor].getHandTransform(2).scale
	local rig = Player[playerColor].getHandTransform(2).right
	local targPos = pos:add(rig:scale(sca.x * 0.55))
	-- {x=pos.x+sca.x*rig.x*0.65,y=pos.y+sca.x*rig.y*0.65+1.5,z=pos.z+sca.x*rig.z*0.65}
	return targPos
end

