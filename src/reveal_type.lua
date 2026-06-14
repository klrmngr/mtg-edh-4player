--------------------------------------------------------------------------------
-- revealUntilType
function deckSeachType(ply)
	Player[ply].clearSelectedObjects()
	local UIactive = UI.getAttribute("SearchTypePanel", "active")
	local usingCol = UI.getAttribute("SearchTypePanel", "visibility")
	if UIactive == "False" then
		UIactive = false
	else
		UIactive = true
	end
	if UIactive and usingCol ~= ply then
		if Turns.turn_color ~= ply then
			Player[ply].broadcast(
				"Only one person at the table can use this function at a time.\n"
					.. usingCol
					.. " is currently using the interface"
			)
			Player[usingCol].broadcast(
				"Only one person at the table can use this function at a time.\n"
					.. ply
					.. " wants to use the interface"
			)
			return
		else
			Player[usingCol].broadcast("It is " .. ply .. "'s turn and they need to use the interface")
		end
	end

	searchTypeVect = {
		land = false,
		creature = false,
		artifact = false,
		enchantment = false,
		planeswalker = false,
		instant = false,
		sorcery = false,
	}
	seachTypeCustom = ""
	repeatSearchX = nil

	UI.setAttribute("repeatX", "text", "")
	UI.setAttribute("typeCustom", "text", "")
	for type, _ in pairs(searchTypeVect) do
		UI.setAttribute(type, "isOn", "False")
		UI.setAttribute(type, "textColor", "rgb(1,1,1)")
	end

	UI.setAttribute("SearchTypePanel", "visibility", ply)
	UI.setAttribute("SearchTypePanel", "active", "True")
end

function STcancel(ply)
	UI.setAttribute("SearchTypePanel", "active", "False")
end

function STokay(player)
	UI.setAttribute("SearchTypePanel", "active", "False")
	ply = player.color
	if data[ply] == nil then
		Player[ply].broadcast("Your color is " .. ply .. ". Are you seated at the table?")
		return
	end
	local deck = getDeckFromZone(data[ply]["libraryZone"])
	if deck == nil then
		Player[ply].broadcast("no deck found in your library zone")
		return
	end
	searchTypes = {}
	for type, toggle in pairs(searchTypeVect) do
		if toggle then
			table.insert(searchTypes, type)
		end
	end
	if seachTypeCustom ~= "" then
		table.insert(searchTypes, seachTypeCustom)
	end
	enterSearchTypes(deck, ply, searchTypes)
end

function UItypeToggle(player, val, id)
	searchTypeVect[id] = (val == "True")
end

function UItypeCustom(player, val, id)
	seachTypeCustom = val
end

function UIrepeatSearchType(player, val, id)
	repeatSearchX = tonumber(val)
	repeatN = 0
end

function enterSearchTypes(deck, ply, searchTypes)
	if #searchTypes > 0 then
		local rot = deck.getRotation()
		rot.z = 180
		deck.setRotation(rot)
		revealUntilType(deck, ply, searchTypes)
	else
		Player[ply].broadcast("you did not select any card-types to look for", ply)
	end
end

function revealUntilType(deck, playerColor, searchTypes)
	if deck == nil then
		return
	end

	if cardToPlay ~= nil then
		Player[playerColor].broadcast("You need to decline (✗) or accept (✓) the previous card.", { 0.7, 0.7, 0.7 })
		return
	end

	nCards = 0
	cardFound = false
	for _, card in pairs(deck.getObjects()) do
		nCards = nCards + 1
		for _, searchType in pairs(searchTypes) do
			if card.nickname:lower():find(searchType:lower()) then
				cardFound = true
				break
			end
		end
		if cardFound then
			break
		end
	end

	if not cardFound then
		Player[playerColor].broadcast("No valid cards found, skipping the procedure", playerColor)
		repeatSearchX = nil
		repeatCascadeX = nil
		return
	end

	libZone = data[playerColor]["libraryZone"]
	libPos = libZone.getPosition()
	cDeck = nil
	cardToPlay = nil
	deckDir = deckDirs[playerColor]

	-- move any objects in the area out of the way -------------------------------
	local origPos = libPos + libZone.getTransformRight():scale(3.75 * deckDir)
	origPos[2] = 1
	local castPars = {
		origin = origPos,
		direction = vector(0, 0, 1),
		type = 3,
		size = { 5, 4, 3 },
		max_distance = 0,
	}
	local castOutput = Physics.cast(castPars)
	for _, castO in pairs(castOutput) do
		local hitObj = castO.hit_object
		if hitObj.type == "Card" or hitObj.type == "Deck" then
			local hitObjPos = hitObj.getPosition()
			local hitObjRelPos = libZone.positionToLocal(hitObjPos)
			local origRelPos = libZone.positionToLocal(castPars.origin)
			local newObjRelPos = hitObjRelPos
			if hitObjRelPos[3] < (origRelPos[3] - 0.1) then
				newObjRelPos[3] = origRelPos[3] - 4 / libZone.getScale().z
			else
				newObjRelPos[3] = origRelPos[3] + 3.2 / libZone.getScale().z
			end
			local newObjPos = libZone.positionToWorld(newObjRelPos)
			hitObj.setPositionSmooth(newObjPos, false, true)
			checkPosMove(newObjPos, libZone)
		end
	end
	------------------------------------------------------------------------------

	types = ""
	for i, type in ipairs(searchTypes) do
		types = types .. type
		if i < #searchTypes then
			types = types .. "/"
		end
	end

	if repeatSearchX ~= nil then
		Player[playerColor].broadcast(
			tostring(repeatN + 1) .. "/" .. tostring(repeatSearchX) .. " revealing cards until type: " .. types,
			playerColor
		)
	else
		Player[playerColor].broadcast("revealing cards until type: " .. types, playerColor)
	end

	for cardNo = 1, nCards do
		doneCascading = false
		Wait.time(function()
			local card = getCardFromZone(data[playerColor]["libraryZone"])
			if card == nil then
				return
			end
			local targPos = libPos
			if cardNo < nCards then
				targPos = libPos + card.getTransformRight():scale(2.5 * deckDir)
				targPos.y = 3 + cardNo * 0.05
				if cardNo == 1 then
					cDeck = card
				end
			else
				targPos = libPos + card.getTransformRight():scale(5 * deckDir)
				targPos.y = 3
				cardToPlay = card
				cardToPlay.highlightOn(stringColorToRGB(playerColor), 10)
			end
			local cardRot = card.getRotation()
			cardRot.z = 0
			card.setRotationSmooth(cardRot, false, true)
			card.setPositionSmooth(targPos, false, true)
		end, cardNo * drawDelay)
	end

	-- wait until all the cards are done cascading
	Wait.time(function()
		if cardToPlay then
			Wait.condition(function()
				doneCascading = true
			end, function()
				return (cardToPlay == nil or cardToPlay.resting)
			end)
			-- reset encoder object data
			Encoder.call("APIencodeObject", { obj = cardToPlay })
			Encoder.call("APIdisableEncoding", { obj = cardToPlay })
			cardToPlay.setGMNotes(playerColor) -- save the owner of card to only allow them to click buttons

			-- create buttons on card to accept or decline casting it
			-- decline
			local backpars = { -- background frame
				label = "",
				tooltip = "",
				click_function = "null",
				position = { -0.5, 0.2, 2 },
				width = 500,
				height = 400,
				font_size = 400,
				scale = { 0.75, 0.75, 0.75 },
				rotation = { 0, 0, 180 },
				color = { 0.7, 0.7, 0.7 },
				font_color = { 1, 1, 1 },
			}
			cardToPlay.createButton(backpars)
			local forgpars = backpars
			forgpars.label = "✗"
			forgpars.tooltip = "[b]DO NOT CAST THE CARD[/b]\nmove all the other\n"
				.. "cards to the bottom of the\nlibrary in random order"
			forgpars.click_function = "declineCascade"
			forgpars.rotation = { 0, 0, 0 }
			forgpars.font_color = stringColorToRGB(playerColor)
			forgpars.color = { 0.16, 0.16, 0.16 }
			forgpars.hover_color = { 0.4, 0.4, 0.4 }
			forgpars.scale = { 0.67, 0.67, 0.67 }
			cardToPlay.createButton(forgpars)

			-- accept
			local backpars = { -- background frame
				label = "",
				tooltip = "",
				click_function = "null",
				position = { 0.5, 0.2, 2 },
				width = 500,
				height = 400,
				font_size = 400,
				scale = { 0.75, 0.75, 0.75 },
				rotation = { 0, 0, 180 },
				color = { 0.7, 0.7, 0.7 },
				font_color = { 1, 1, 1 },
			}
			cardToPlay.createButton(backpars)
			local forgpars = backpars
			forgpars.label = "✓"
			forgpars.tooltip = "[b]CAST THE CARD[/b]\nmove all the other\n"
				.. "cards to the bottom of the\nlibrary in random order"
			forgpars.click_function = "acceptCascade"
			forgpars.rotation = { 0, 0, 0 }
			forgpars.font_color = stringColorToRGB(playerColor)
			forgpars.color = { 0.16, 0.16, 0.16 }
			forgpars.hover_color = { 0.4, 0.4, 0.4 }
			forgpars.scale = { 0.67, 0.67, 0.67 }
			cardToPlay.createButton(forgpars)
		end
	end, nCards * drawDelay + 0.75)
end

