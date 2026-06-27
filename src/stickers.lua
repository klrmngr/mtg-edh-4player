------------------------------- GOBLIN STICKERS --------------------------------
-- When a game starts (the same hook as Etali/Ral -- see bumpMulliganCount) with a
-- "_____ Goblin" card in the player's library (deck), deal that player 3 random
-- sticker cards from the locked bag onto their board, once. Each dealt card's name
-- is three words; we write the word with the most unique vowels (y counts), every
-- vowel capitalised, plus the count, into its π Notepad.

GOBLIN_STICKER_BAG = "3d4dca" -- locked infinite bag of sticker cards
GOBLIN_STICKER_COUNT = 3
goblinStickerSpacing = 2.5 -- gap between dealt cards along the mat's right axis
goblinStickerForward = 0 -- offset along the mat's forward axis (tune placement)

-- the "_____ Goblin" card: first-line name is underscores followed by "goblin"
function isGoblinName(name)
	return mainCardName(name):lower():match("^_+%s*goblin") ~= nil
end

-- does this player's library (deck) contain the "_____ Goblin" card? scans the
-- library zone for the deck (or any loose cards) and checks their card names
function libraryHasGoblin(color)
	local lz = data[color] and data[color]["libraryZone"]
	if lz == nil then
		return false
	end
	for _, obj in ipairs(lz.getObjects()) do
		if obj.type == "Card" then
			if isGoblinName(obj.getName()) then
				return true
			end
		elseif obj.type == "Deck" then
			for _, c in ipairs(obj.getObjects()) do
				if isGoblinName(c.name) then
					return true
				end
			end
		end
	end
	return false
end

-- game-start hook: once per player, deal the stickers if they have the Goblin
function refreshGoblinStickers(color)
	if data[color] == nil or data[color]["goblinStickersDealt"] then
		return
	end
	if not libraryHasGoblin(color) then
		return
	end
	data[color]["goblinStickersDealt"] = true
	dealGoblinStickers(color)
end

-- n distinct random entries from a list
function pickRandomEntries(list, n)
	local pool = {}
	for _, v in ipairs(list) do
		table.insert(pool, v)
	end
	local out = {}
	for _ = 1, math.min(n, #pool) do
		local idx = math.random(#pool)
		table.insert(out, pool[idx])
		table.remove(pool, idx)
	end
	return out
end

-- destroy this player's previously dealt sticker cards
function clearGoblinStickers(color)
	if data[color] == nil then
		return
	end
	for _, card in ipairs(data[color]["goblinStickers"] or {}) do
		if card ~= nil then
			pcall(function()
				destroyObject(card)
			end)
		end
	end
	data[color]["goblinStickers"] = {}
end

-- pull a fresh deck of 10 sticker cards from the infinite bag (a clone, so the bag
-- isn't depleted), then deal 3 random cards from it. Replaces any previous stickers.
function dealGoblinStickers(color)
	local bag = getObjectFromGUID(GOBLIN_STICKER_BAG)
	if bag == nil then
		return
	end
	clearGoblinStickers(color) -- replace any previously dealt stickers (resets the list)
	local mat = data[color]["playmat"]
	local stagePos = mat.getPosition()
	stagePos.y = 6 -- stage the deck above the board, out of the way
	bag.takeObject({
		position = stagePos,
		smooth = false,
		callback_function = function(deck)
			Wait.condition(function()
				dealFromStickerDeck(color, deck)
			end, function()
				return deck == nil or not deck.spawning
			end)
		end,
	})
end

-- deal 3 random cards from a freshly-pulled sticker deck onto color's board,
-- centred in a row with their sticker notes, then discard the rest of the deck
function dealFromStickerDeck(color, deck)
	if deck == nil then
		return
	end
	deck.setLock(true) -- keep the staging deck from falling onto the board
	local cards = deck.getObjects()
	if cards == nil or #cards == 0 then
		pcall(function()
			destroyObject(deck)
		end)
		return
	end
	local picks = pickRandomEntries(cards, GOBLIN_STICKER_COUNT)
	local mat = data[color]["playmat"]
	for i, entry in ipairs(picks) do
		local pos = mat.getPosition()
			+ mat.getTransformRight():scale((i - (#picks + 1) / 2) * goblinStickerSpacing)
			+ mat.getTransformForward():scale(goblinStickerForward)
		pos.y = 3
		local card = deck.takeObject({
			guid = entry.guid,
			position = pos,
			rotation = { 0, mat.getRotation().y, 0 },
			smooth = false,
		})
		if card ~= nil then
			table.insert(data[color]["goblinStickers"], card)
			whenSettled(card, function(c)
				setCardNotepad(c, stickerNotepad(mainCardName(c.getName())))
			end)
		end
	end
	-- discard the leftover deck once the takes have processed
	Wait.time(function()
		if deck ~= nil then
			pcall(function()
				destroyObject(deck)
			end)
		end
	end, 1)
end
