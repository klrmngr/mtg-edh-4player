----------------------------------- MULLIGAN -----------------------------------
mulliganResetDelay = 300 -- auto-reset the count after this many seconds idle

-- bump a player's mulligan counter and refresh the on-table label
function bumpMulliganCount(color)
	-- a bump while the count sits at 0 is a fresh opening hand (the very first one,
	-- or the first after a right-click / inactivity reset): (re)snapshot the board
	-- for the reset button while the library is still complete (see reset.lua)
	if (data[color]["mulliganCount"] or 0) == 0 then
		captureResetSnapshot(color, true)
		-- show/hide this player's commander buttons based on their command zone now
		refreshEtaliButton(color)
		refreshRalButton(color)
	end
	data[color]["mulliganCount"] = (data[color]["mulliganCount"] or 0) + 1
	data[color]["mulliganButton"].editButton({
		index = 1,
		label = "Mulligans: " .. (data[color]["mulliganCount"] - 1),
	})
	-- restart the idle timer: if the count isn't touched again in time, reset it
	if data[color]["mulliganResetTimer"] ~= nil then
		Wait.stop(data[color]["mulliganResetTimer"])
	end
	data[color]["mulliganResetTimer"] = Wait.time(function()
		resetMulliganCount(color)
	end, mulliganResetDelay)
end

-- reset a player's mulligan counter to 0 and cancel any pending idle timer
function resetMulliganCount(color)
	if data[color]["mulliganResetTimer"] ~= nil then
		Wait.stop(data[color]["mulliganResetTimer"])
		data[color]["mulliganResetTimer"] = nil
	end
	data[color]["mulliganCount"] = 0
	data[color]["mulliganButton"].editButton({ index = 1, label = "Mulligans: 0" })
end

function handIsEmpty(color)
	for _, obj in pairs(Player[color].getHandObjects(1)) do
		if obj.tag == "Card" then
			return false
		end
	end
	return true
end

function playerMulligan(button, playerColor, alt)
	-- identify which player's mulligan button was clicked (not necessarily the clicker)
	local ownerColor = nil
	for color, pdata in pairs(data) do
		if button == pdata["mulliganButton"] then
			ownerColor = color
			break
		end
	end
	if ownerColor ~= nil then
		if alt then
			-- right-click: anyone may reset this player's mulligan count
			resetMulliganCount(ownerColor)
			return
		end
		-- left-click: only the owning player may mulligan their own hand
		if playerColor ~= ownerColor then
			return
		end
		-- with cards already in the play area, require a double-click so an
		-- accidental mid-game press doesn't wipe the board into a mulligan
		local cardsInPlay = false
		for _, v in pairs(data[playerColor]["playmat"].getObjects()) do
			if v.type == "Card" or v.type == "Deck" then
				cardsInPlay = true
				break
			end
		end
		if cardsInPlay and not isDoubleClick("mull_" .. playerColor) then
			Player[playerColor].broadcast(
				"Cards detected in the play area = accidental mulligan press in the middle of a game?\n"
					.. "If you still wish to mulligan, [b]double click[/b] the button."
			)
			return
		end

		buttonCooldown(button, 2)

		local deck = getDeckFromZone(data[playerColor]["libraryZone"])
		if deck ~= nil then
			data[playerColor]["mulliganNumber"] = 7
			-- first click draws the opening hand (0 mulligans); each later click is a mulligan
			bumpMulliganCount(playerColor)
			local objs = Player[playerColor].getHandObjects(1)
			for _, obj in pairs(objs) do
				if obj.tag == "Card" then
					deck.putObject(obj)
				end
			end
			Wait.time(function()
				deck.shuffle()
			end, 0.1, 7)

			Wait.time(function()
				if smartMulligan then -- ensure 2-5 lands in hand
					local nMulls = 0
					local keepTrying = true
					while keepTrying do
						nMulls = nMulls + 1
						deck.shuffle()
						local nLands = 0
						local cards = deck.getObjects()
						for i = 1, 7 do
							if cards[i].name:lower():find("land") then
								nLands = nLands + 1
							end
						end
						if (nLands >= 3 and nLands <= 4) or nMulls >= 3 then
							keepTrying = false
						end
					end
				end
				deck.deal(data[playerColor]["mulliganNumber"], playerColor, 1)
			end, 0.8)
			-- Wait.time(function() sortHands(playerColor) end, 1.5)
		end
	end
end

-------------------------------- SERUM POWDER ----------------------------------
-- Exile the current hand and draw a fresh one of the same size.
-- Hand size = min(7, 7 + 2 - mulliganCount). mulliganCount is the displayed
-- mulligan number + 1, so the opening hand and the first mulligan both draw 7,
-- then it drops by one per additional mulligan.
function playerSerumPowder(button, playerColor, alt)
	if button ~= data[playerColor]["mulliganButton"] then
		return
	end
	if data[playerColor]["serumCooldown"] then
		return
	end

	local handSize = math.min(7, 7 + 2 - (data[playerColor]["mulliganCount"] or 0))

	-- step 1: the hand must hold exactly handSize cards before powdering
	local cards = {}
	for _, obj in pairs(Player[playerColor].getHandObjects(1)) do
		if obj.tag == "Card" then
			table.insert(cards, obj)
		end
	end
	if #cards ~= handSize then
		Player[playerColor].broadcast(
			"Serum Powder: expected " .. handSize .. " cards in hand but found " .. #cards .. "."
		)
		return
	end

	local deck = getDeckFromZone(data[playerColor]["libraryZone"])
	if deck == nil then
		Player[playerColor].broadcast("Serum Powder: no library found.")
		return
	end

	data[playerColor]["serumCooldown"] = true
	Wait.time(function()
		data[playerColor]["serumCooldown"] = false
	end, 2)
	buttonPress(button, 0.5)

	-- step 2: exile the current hand (stacked on the dedicated exile zone, which
	-- keeps placement correct regardless of how the zones are rotated)
	local zone = data[playerColor]["exileZone"]
	local exileRotY = zone.getRotation().y
	local exilePos = zone.getPosition()
	local i = 0
	for _, card in pairs(cards) do
		card.use_hands = false
		card.use_gravity = true
		local rot = card.getRotation()
		rot.z = 0
		rot.y = exileRotY
		card.setRotationSmooth(rot, false, true)
		card.setPositionSmooth({ x = exilePos.x, y = 3 + i * 0.4, z = exilePos.z }, false, true)
		i = i + 1
	end
	Wait.time(function()
		for _, card in pairs(cards) do
			if card ~= nil then
				card.use_hands = true
			end
		end
	end, 1.5)

	-- step 3: draw a fresh hand of the same size
	Wait.time(function()
		deck.deal(handSize, playerColor, 1)
	end, 1.0)
end

