----------------------------------- MULLIGAN -----------------------------------
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
			data[ownerColor]["mulliganCount"] = 0
			button.editButton({ index = 1, label = "Mulligans: 0" })
			return
		end
		-- left-click: only the owning player may mulligan their own hand
		if playerColor ~= ownerColor then
			return
		end
		if nMullClick == nil then
			nMullClick = 1
		else
			nMullClick = nMullClick + 1
		end
		Wait.time(function()
			nMullClick = 0
		end, 0.5)

		local proceed = true
		local playmat = data[playerColor]["playmat"]
		for k, v in pairs(playmat.getObjects()) do
			if (v.type == "Card" or v.type == "Deck") and nMullClick < 2 then
				proceed = false
			end
		end
		if not proceed then
			if mulliganSatety == nil then
				mulliganSatety = true
			end
			if mulliganSatety then
				Player[playerColor].broadcast(
					"Cards detected in the play area = accidental mulligan press in the middle of a game?\n"
						.. "If you still wish to mulligan, [b]double click[/b] the button."
				)
				mulliganSatety = false
				Wait.time(function()
					mulliganSatety = true
				end, 10)
			end
			return
		end

		buttonCooldown(button, 2)

		local deck = getDeckFromZone(data[playerColor]["libraryZone"])
		if deck ~= nil then
			data[playerColor]["mulliganNumber"] = 7
			-- first click draws the opening hand (0 mulligans); each later click is a mulligan
			data[playerColor]["mulliganCount"] = (data[playerColor]["mulliganCount"] or 0) + 1
			button.editButton({
				index = 1,
				label = "Mulligans: " .. (data[playerColor]["mulliganCount"] - 1),
			})
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

	-- step 2: exile the current hand (stacked just past the library, like move2exile)
	local zone = data[playerColor]["libraryZone"]
	local exileRotY = zone.getRotation().y + exileRot
	local exilePos = zone.getPosition() + zone.getTransformForward():scale(exileFor)
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

