----------------------------------- MULLIGAN -----------------------------------
function playerMulligan(button, playerColor, alt)
	if button == data[playerColor]["mulliganButton"] then
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
			if not alt then
				data[playerColor]["mulliganNumber"] = 7
			else
				data[playerColor]["mulliganNumber"] = data[playerColor]["mulliganNumber"] - 1
				if data[playerColor]["mulliganNumber"] < 1 then
					data[playerColor]["mulliganNumber"] = 1
				end
			end
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

