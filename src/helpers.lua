----------------------------------- UNIVERSAL ----------------------------------

-- this should get the highest resting card from the library zones
-- works if there are extra cards flipped face up on top of the deck
-- (personally, I play with a bunch of decks that keep the top card of the library revealed)
-- works if there is just one card remaining in the zone, too
function getCardFromZone(zone)
	local card = nil
	local highY = 0
	local highObj = nil
	local objects = zone.getObjects()
	for i, obj in pairs(objects) do
		if obj.type == "Deck" or (obj.type == "Card" and obj.use_gravity) then
			if obj.getPosition().y > highY then
				highY = obj.getPosition().y
				highObj = obj
			end
		end
	end
	if highObj ~= nil then
		if highObj.type == "Deck" then -- pull one card from the top of the deck
			local deck = highObj
			local cardPresent, card = pcall(deck.takeObject)
			if cardPresent and card.type == "Card" then
				deck.setLock(true)
				Wait.frames(function()
					deck.setLock(false)
				end, 1)
				card.use_hands = true
				gravityTrigger(card)
				return card
			end
		elseif highObj.type == "Card" then
			local card = highObj
			card.use_hands = true
			gravityTrigger(card)
			return card
		end
	end
	return card -- if nil?
end

function getDeckFromZone(zone)
	local deck = nil
	local objects = zone.getObjects()
	for i, obj in pairs(objects) do
		if obj.type == "Deck" then
			deck = obj
			return deck
		end
	end
	return deck
end

-- button press animation
function buttonPress(button, T)
	local posUp = button.getPosition()
	local posDown = button.getPosition()
	posUp.y = 1
	posDown.y = 0.9
	local downT = T
	if downT < 0.05 then
		downT = 0.05
	end
	button.setPositionSmooth(posDown, false, true)
	Wait.time(function()
		button.setPositionSmooth(posUp, false, true)
	end, downT)
end

-- rotate all buttons on the object upside down for the cooldown timer
function buttonCooldown(button, T)
	buts = button.getButtons()
	for i, but in pairs(buts) do
		-- skip display-only labels and the serum powder button so their text
		-- isn't mirrored during a neighbouring button's cooldown
		if but.click_function ~= "noop" and but.click_function ~= "playerSerumPowder" and but.click_function ~= "playerEtali" then
			local oldRot = but.rotation
			local ind = but.index
			button.editButton({ index = ind, rotation = { x = oldRot.x, y = oldRot.y, z = 180 } })
			Wait.time(function()
				button.editButton({ index = ind, rotation = { x = oldRot.x, y = oldRot.y, z = 0 } })
			end, T)
		end
	end
end

-- check that the card made it to it's target, if not, teleport it
function checkMoveSuccess(card, targetPos, playerColor)
	if card == nil then -- the card is gone, probably stacked into a deck already
		return
	end
	-- use hands orientation to determine which coordinate to use to check position
	-- currently only set up to work with hands rotated 0,90,180,270 degrees
	local handForw = Player[playerColor].getHandTransform(2).forward
	local posDiff = 0
	if math.abs(handForw.z) > 0.5 then
		posDiff = math.abs(card.getPosition().z - targetPos.z)
	elseif math.abs(handForw.x) > 0.5 then
		posDiff = math.abs(card.getPosition().x - targetPos.x)
	end
	if posDiff > 1 then
		card.setPosition(targetPos)
	end
end

-- for hiding cards
function allBut(playerColor)
	local players = {}
	for key, color in pairs(Color.list) do
		if color ~= playerColor then
			table.insert(players, color)
		end
	end
	return players
end
function unhide(card)
	if card ~= nil then
		card.setHiddenFrom({})
	end
end

-- turns off gravity on the card for a few frames (prevents it from falling back onto a deck)
function gravityTrigger(obj)
	if obj ~= nil then
		obj.use_gravity = false
		Wait.time(function()
			gravOn(obj)
		end, 0.2)
	end
end
function gravOn(obj)
	if obj ~= nil then
		obj.use_gravity = true
	end
end

function interactTrigger(obj)
	if obj ~= nil then
		obj.interactable = false
		Wait.time(function()
			interactOn(obj)
		end, 0.2)
	end
end
function interactOn(obj)
	if obj ~= nil then
		obj.interactable = true
	end
end

function handTrigger(obj)
	if obj ~= nil then
		obj.use_hands = false
		Wait.time(function()
			handOn(obj)
		end, 0.1)
	end
end
function handOn(obj)
	if obj ~= nil then
		obj.use_hands = true
	end
end

function null() end

