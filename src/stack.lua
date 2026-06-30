-- Stack tracker
-- A FILO list of cards cast into a lane that starts next to the Patch Notes
-- button and grows toward the centre of the table.

-- ----------------------------------------------------------------------------
-- The stack itself: a FILO list of cards cast into the central lane. Each card's
-- position is a function of its index -- newer spells sit shifted right (+x) and
-- up (+y), so the last-in card ends up on top and resolves first.

stackList = {} -- stackList[1] = bottom (first cast), stackList[#] = top (resolves first); entries are { guid, owner }

stackBasePos = { x = -39.0, y = 1.2, z = 0.0 } -- first cast card lands here, next to the Patch Notes button (at x=-42); stack grows right (+x)
stackStepX = 1.2 -- each later card shifts this far right (small step = cards overlap)
stackStepY = 0.25 -- ...and this far up
stackCardRot = { 0, 180, 0 } -- lay flat, face up

-- glow colour applied to a cast card, by the seat of the player who cast it
stackGlowColors = {
	White = { 1, 1, 1 },
	Red = { 1, 0, 0 },
	Yellow = { 1, 1, 0 },
	Blue = { 0, 0.35, 1 },
}

-- right-click "Cast" on a hand card: push it onto the stack and lay it out.
-- the card is passed in directly (hand cards aren't in getSelectedObjects)
function castCard(card, ply)
	if card == nil or card.type ~= "Card" then
		return
	end
	-- encode the spell so it picks up the mod's button/menu system
	if Encoder ~= nil then
		Encoder.call("APIencodeObject", { obj = card })
	end
	addCardToStack(card, ply)
end

-- push a prepared card onto the stack: detach from hand, glow, track, place.
-- (does not encode or rebuild buttons -- callers do that beforehand if needed,
-- so a card's custom labels survive)
function addCardToStack(card, ply)
	-- detach from the hand zone, otherwise it just snaps back to the hand
	card.use_hands = false
	card.use_gravity = true
	-- glow in the caster's colour so it's clear who owns the spell
	card.highlightOn(stackGlowColors[ply] or { 1, 1, 1 })
	table.insert(stackList, { guid = card.getGUID(), owner = ply })
	-- a new spell on the stack hands priority back around the table
	priorityPassed = {}
	-- only the new card needs placing; everything below it is already locked in place
	placeStackCard(card, #stackList)
end

-- right-click "Add to Stack" on a card already on the table: clone it (like Make
-- Token Copy), stamp the copy "Effect", and put the copy on the stack.
function cardEffect(ply)
	local card = Player[ply].getSelectedObjects()[1]
	Player[ply].clearSelectedObjects()
	if card == nil or card.type ~= "Card" or Encoder == nil then
		return
	end
	local cardDat = card.getData()
	cardDat.Transform.posY = cardDat.Transform.posY + 0.2
	Encoder.call("APIencodeObject", { obj = card })
	local flip = Encoder.call("APIgetFlip", { obj = card })
	local moduleData = Encoder.call("APIobjGetProps", { obj = card })
	local valueData = Encoder.call("APIobjGetAllData", { obj = card })
	local eCard = spawnObjectData({ data = cardDat })
	Wait.condition(function()
		if eCard == nil or Encoder == nil then
			return
		end
		Encoder.call("APIencodeObject", { obj = eCard })
		Encoder.call("APIobjSetAllData", { obj = eCard, data = valueData })
		Encoder.call("APIobjSetProps", { obj = eCard, data = moduleData })
		if flip < 0 then
			Encoder.call("APIFlip", { obj = eCard })
		end
		Encoder.call("APIrebuildButtons", { obj = eCard })
		-- stamp our own "Effect" label after the encoder's buttons are built
		addEffectLabel(eCard)
		addCardToStack(eCard, ply)
	end, function()
		return eCard == nil or not eCard.spawning
	end)
end

-- a small "Effect" label on the card, styled like the token designator's "Token"
function addEffectLabel(card)
	local flip = Encoder and Encoder.call("APIgetFlip", { obj = card }) or 1
	card.createButton({
		label = "Effect",
		click_function = "stackEffectNoop",
		function_owner = Global,
		scale = { 0.5, 0.5, 0.5 },
		position = { 0, 0.28 * flip, -1.7 },
		height = 300,
		width = 800,
		font_size = 250,
		rotation = { 0, 0, 90 - 90 * flip },
		font_color = { 1, 1, 1 },
		color = { 0.1, 0.1, 0.1 },
	})
end

function stackEffectNoop() end

-- "!stack": list what's currently on the stack, top (resolves first) to bottom
function listStack(pl)
	if #stackList == 0 then
		broadcastToColor("The stack is empty.", pl.color, { 1, 0.85, 0.2 })
		return
	end
	broadcastToColor("Stack (top resolves first):", pl.color, { 1, 1, 1 })
	for i = #stackList, 1, -1 do
		local entry = stackList[i]
		local card = getObjectFromGUID(entry.guid)
		local name = card and card.getName():match("^[^\n]+") or "(missing)"
		local rank = #stackList - i + 1
		broadcastToColor(rank .. ". " .. name, pl.color, stackGlowColors[entry.owner] or { 1, 1, 1 })
	end
end

-- world position for the card at the given stack index
function stackPos(index)
	return {
		x = stackBasePos.x + (index - 1) * stackStepX,
		y = stackBasePos.y + (index - 1) * stackStepY,
		z = stackBasePos.z,
	}
end

-- move one card to its slot, then lock it once it has settled so it can't fall
function placeStackCard(card, index)
	card.setLock(false)
	card.setPositionSmooth(stackPos(index), false, true)
	card.setRotationSmooth(stackCardRot, false, true)
	Wait.condition(function()
		if card ~= nil then
			card.setLock(true)
		end
	end, function()
		return card == nil or not card.isSmoothMoving()
	end)
end

-- ----------------------------------------------------------------------------
-- Priority. Players pass priority with the buttons next to the Patch Notes
-- button; when everyone seated has passed, the top of the stack is ready to
-- resolve. "Rest of turn" keeps a player passing until the next turn starts.

stackSeats = { "White", "Red", "Yellow", "Blue" }
priorityPassed = {} -- colours that have passed since the last spell / resolution
priorityRestOfTurn = {} -- colours auto-passing until the turn changes

function isStackSeat(color)
	for _, c in ipairs(stackSeats) do
		if c == color then
			return true
		end
	end
	return false
end

-- have all seated players passed (counting rest-of-turn passers)?
function allPlayersPassed()
	for _, c in ipairs(stackSeats) do
		if Player[c].seated and not (priorityPassed[c] or priorityRestOfTurn[c]) then
			return false
		end
	end
	return true
end

function passPriority(obj, color, alt)
	if not isStackSeat(color) then
		return
	end
	priorityPassed[color] = true
	broadcastToAll(color .. " passed priority.", stackGlowColors[color] or { 1, 1, 1 })
	resolveIfAllPassed()
end

function passPriorityRestOfTurn(obj, color, alt)
	if not isStackSeat(color) then
		return
	end
	-- toggle: click again to take priority back for the rest of the turn
	if priorityRestOfTurn[color] then
		priorityRestOfTurn[color] = nil
		priorityPassed[color] = nil
		broadcastToAll(color .. " is taking priority again this turn.", stackGlowColors[color] or { 1, 1, 1 })
		return
	end
	priorityRestOfTurn[color] = true
	priorityPassed[color] = true
	broadcastToAll(color .. " passes priority for the rest of the turn.", stackGlowColors[color] or { 1, 1, 1 })
	resolveIfAllPassed()
end

-- once everyone has passed, the top of the stack is ready to resolve
function resolveIfAllPassed()
	if not allPlayersPassed() then
		return
	end
	priorityPassed = {}
	if #stackList > 0 then
		broadcastToAll("All players passed -- the top of the stack resolves.", { 1, 1, 1 })
		resolveTop()
	else
		broadcastToAll("All players passed with an empty stack.", { 0.8, 0.8, 0.8 })
	end
end

-- resolve the top spell: pop it off the stack and just unlock it for now
function resolveTop()
	local entry = table.remove(stackList)
	if entry == nil then
		return
	end
	local card = getObjectFromGUID(entry.guid)
	if card ~= nil then
		card.setLock(false)
	end
end

-- called from onPlayerTurnStart: a new turn clears the rest-of-turn passes
function clearPriorityRestOfTurn()
	priorityRestOfTurn = {}
	priorityPassed = {}
end

-- ----------------------------------------------------------------------------
-- The priority buttons, spawned as small locked tiles next to the Patch Notes
-- button (which lives at x=-42, z=0).

STACK_BTN_TAG = "stack_priority_button"

function spawnStackButtons()
	-- clear any leftover tiles so reloads don't stack duplicates
	for _, obj in ipairs(getAllObjects()) do
		if obj.getGMNotes() == STACK_BTN_TAG then
			destroyObject(obj)
		end
	end
	spawnPriorityButton({ -42, 1.1, 4 }, "pass\npriority", "passPriority", "pass priority")
	spawnPriorityButton({ -42, 1.1, 8 }, "pass priority\nrest of turn", "passPriorityRestOfTurn", "pass priority for the rest of the turn")
end

function spawnPriorityButton(pos, label, clickFn, tooltip)
	spawnObject({
		type = "BlockSquare",
		position = pos,
		rotation = { 0, 90, 0 },
		scale = { 1.1, 0.2, 0.9 },
		callback_function = function(obj)
			obj.setName((label:gsub("\n", " ")))
			obj.setGMNotes(STACK_BTN_TAG)
			obj.setColorTint({ 0.12, 0.12, 0.14 })
			obj.interactable = false
			obj.setLock(true)
			obj.createButton({
				click_function = clickFn,
				function_owner = self,
				label = label,
				position = { 0, 0.6, 0 },
				width = 950,
				height = 650,
				font_size = 160,
				color = { 0.95, 0.95, 0.95, 1 },
				font_color = { 0, 0, 0, 1 },
				tooltip = tooltip,
			})
		end,
	})
end
