--------------------------------- CONTEXT MENU ---------------------------------

function addZoneContextMenus()
	for color, playerData in pairs(data) do
		for _, obj in pairs(playerData["libraryZone"].getObjects()) do
			if obj.type == "Deck" and not (obj.getName():lower():find("planechase")) then
				obj.addContextMenuItem("Cascade for X", deckCascade)
				obj.addContextMenuItem("Reveal until Type", deckSeachType)
				addLandContextMenus(obj)
			end
		end
		for _, obj in pairs(playerData["playmat"].getObjects()) do
			if obj.type == "Card" then
				obj.addContextMenuItem("Make Token Copy", cardToken)
				if obj.getDescription():lower():find("cascade") then
					obj.addContextMenuItem("Cascade", cardCascade)
				end
			end
		end
		for _, obj in pairs(Player[color].getHandObjects(1)) do
			obj.addContextMenuItem("Sort Hand by CMC", sortHands)
			obj.addContextMenuItem("Random Discard", randomDiscard)
		end
	end
end

-- Global
addContextMenuItem("have a response", function(c)
	broadcastToAll(Player[c].steam_name .. " has a response!", stringColorToRGB(c))
end)
addContextMenuItem("could you not", function(c)
	broadcastToAll(Player[c].steam_name .. ' asks: [999999]"Could you not?"[-]', stringColorToRGB(c))
end)
addContextMenuItem("hand counts", function(c)
	local s = "number of cards in hands:"
	for _, p in pairs(Player.getPlayers()) do
		local n = #p.getHandObjects()
		if n < 10 then
			n = "0" .. n
		end
		s = s .. "\n[" .. Color[p.color]:toHex() .. "]" .. n
	end
	Player[c].broadcast(s .. "[-]", { 0.7, 0.7, 0.7 })
end)

-- function onObjectSpawn(obj)
--   -- Card "Encoder Menu" context item
--   if obj.type ~= "Card" then return end
--   obj.hide_when_face_down=true
--   obj.setHiddenFrom({})
--   Wait.condition(function()
--     if Encoder ~= nil and obj~=nil then
--       obj.addContextMenuItem('Encoder Menu',toggleEncMenu)
--     end
--   end, function() return obj==nil or not(obj.spawning) end, 1)
-- end

-- zone specific context menu items
function onObjectEnterZone(zone, obj)
	if obj == nil or not (obj.type == "Card" or obj.type == "Deck") then
		return
	end
	if obj.getName():lower():find("planechase") then
		return
	end
	-- land tracker: note lands entering a player's land zone (see landtracker.lua)
	trackLandEnter(zone, obj)
	local inHandZone = false
	local inPlayZone = false
	local inLibrZone = false
	for _, oZone in pairs(obj.getZones()) do
		if Encoder ~= nil then
			local encZones = Encoder.call("APIlistZones", {})
			local encZone = encZones[oZone.getGUID()]
			if encZone and encZone.name:match("_1") then
				inHandZone = true
			end
		end
		for _, col in pairs(Player.getAvailableColors()) do
			if oZone == data[col]["playmat"] then
				inPlayZone = true
			end
			if oZone == data[col]["libraryZone"] then
				inLibrZone = true
			end
		end
	end
	obj.clearContextMenu()
	if obj.type == "Card" then
		-- obj.addContextMenuItem('Encoder Menu',toggleEncMenu)
	end
	if obj.type == "Card" and inPlayZone then
		obj.addContextMenuItem("Make Token Copy", cardToken)
		if obj.getDescription():lower():find("cascade") then
			obj.addContextMenuItem("Cascade", cardCascade)
		end
	end
	if obj.type == "Card" and inHandZone then
		obj.addContextMenuItem("Sort Hand by CMC", sortHands)
		obj.addContextMenuItem("Random Discard", randomDiscard)
	end
	if obj.type == "Deck" and inLibrZone then
		obj.addContextMenuItem("Cascade for X", deckCascade)
		obj.addContextMenuItem("Reveal until Type", deckSeachType)
		addLandContextMenus(obj)
		-- obj.addContextMenuItem('Get Basic Land',deckRamp)
		obj.setScale({ 1, 1, 1 })
	end
end

function onObjectLeaveZone(zone, obj)
	if obj == nil or not (obj.type == "Card" or obj.type == "Deck") then
		return
	end
	if obj.getName():lower():find("planechase") then
		return
	end
	local inHandZone = false
	local inPlayZone = false
	local inLibrZone = false
	for _, oZone in pairs(obj.getZones()) do
		if Encoder ~= nil then
			local encZones = Encoder.call("APIlistZones", {})
			local encZone = encZones[oZone.getGUID()]
			if encZone and encZone.name:match("_1") then
				inHandZone = true
			end
		end
		for _, col in pairs(Player.getAvailableColors()) do
			if oZone == data[col]["playmat"] then
				inPlayZone = true
			end
			if oZone == data[col]["libraryZone"] then
				inLibrZone = true
			end
		end
	end
	obj.clearContextMenu()
	if obj.type == "Card" then
		-- obj.addContextMenuItem('Encoder Menu',toggleEncMenu)
	end
	if obj.type == "Card" and inPlayZone then
		obj.addContextMenuItem("Make Token Copy", cardToken)
		if obj.getDescription():lower():find("cascade") then
			obj.addContextMenuItem("Cascade", cardCascade)
		end
	end
	if obj.type == "Card" and inHandZone then
		obj.addContextMenuItem("Sort Hand by CMC", sortHands)
		obj.addContextMenuItem("Random Discard", randomDiscard)
	end
	if obj.type == "Deck" and inLibrZone then
		obj.addContextMenuItem("Cascade for X", deckCascade)
		obj.addContextMenuItem("Reveal until Type", deckSeachType)
		addLandContextMenus(obj)
		-- obj.addContextMenuItem('Get Basic Land',deckRamp)
		obj.setScale({ 1, 1, 1 })
	end
end

function addLandContextMenus(deck)
	local plains, island, mountain, swamp, forest, wastes = false, false, false, false, false, false
	for _, card in pairs(deck.getObjects()) do
		local cname = card.name:lower():gsub("%p", "")
		if cname:find("basic") and cname:find("land") and cname:find("plains") then
			plains = true
		end
		if cname:find("basic") and cname:find("land") and cname:find("island") then
			island = true
		end
		if cname:find("basic") and cname:find("land") and cname:find("mountain") then
			mountain = true
		end
		if cname:find("basic") and cname:find("land") and cname:find("swamp") then
			swamp = true
		end
		if cname:find("basic") and cname:find("land") and cname:find("forest") then
			forest = true
		end
		if cname:find("basic") and cname:find("land") and cname:find("wastes") then
			wastes = true
		end
	end

	if plains then
		deck.addContextMenuItem("Get Basic Plains", deckRampW)
	end
	if island then
		deck.addContextMenuItem("Get Basic Island", deckRampU)
	end
	if mountain then
		deck.addContextMenuItem("Get Basic Mountain", deckRampR)
	end
	if swamp then
		deck.addContextMenuItem("Get Basic Swamp", deckRampB)
	end
	if forest then
		deck.addContextMenuItem("Get Basic Forest", deckRampG)
	end
	if wastes then
		deck.addContextMenuItem("Get Basic Wastes", deckRampWa)
	end
end

function deckRampW(ply)
	local deck = getDeckFromZone(data[ply]["libraryZone"])
	if deck == nil then
		return
	end
	for i, card in ipairs(deck.getObjects()) do
		local cname = card.name:lower():gsub("%p", "")
		if cname:find("basic") and cname:find("land") and cname:find("plains") then
			local rot = deck.getRotation()
			local pos = deck.getPosition()
			local rig = deck.getTransformRight()
			rot[3] = 0
			pos = pos + rig:scale(deckDirs[ply] * 2.4)
			deck.takeObject({ index = i - 1, position = pos, rotation = rot })
			break
		end
	end
	Wait.time(function()
		deck.shuffle()
	end, 0.1, 5)
end

function deckRampU(ply)
	local deck = getDeckFromZone(data[ply]["libraryZone"])
	if deck == nil then
		return
	end
	for i, card in ipairs(deck.getObjects()) do
		local cname = card.name:lower():gsub("%p", "")
		if cname:find("basic") and cname:find("land") and cname:find("island") then
			local rot = deck.getRotation()
			local pos = deck.getPosition()
			local rig = deck.getTransformRight()
			rot[3] = 0
			pos = pos + rig:scale(deckDirs[ply] * 2.4)
			deck.takeObject({ index = i - 1, position = pos, rotation = rot })
			break
		end
	end
	Wait.time(function()
		deck.shuffle()
	end, 0.1, 5)
end

function deckRampR(ply)
	local deck = getDeckFromZone(data[ply]["libraryZone"])
	if deck == nil then
		return
	end
	for i, card in ipairs(deck.getObjects()) do
		local cname = card.name:lower():gsub("%p", "")
		if cname:find("basic") and cname:find("land") and cname:find("mountain") then
			local rot = deck.getRotation()
			local pos = deck.getPosition()
			local rig = deck.getTransformRight()
			rot[3] = 0
			pos = pos + rig:scale(deckDirs[ply] * 2.4)
			deck.takeObject({ index = i - 1, position = pos, rotation = rot })
			break
		end
	end
	Wait.time(function()
		deck.shuffle()
	end, 0.1, 5)
end

function deckRampB(ply)
	local deck = getDeckFromZone(data[ply]["libraryZone"])
	if deck == nil then
		return
	end
	for i, card in ipairs(deck.getObjects()) do
		local cname = card.name:lower():gsub("%p", "")
		if cname:find("basic") and cname:find("land") and cname:find("swamp") then
			local rot = deck.getRotation()
			local pos = deck.getPosition()
			local rig = deck.getTransformRight()
			rot[3] = 0
			pos = pos + rig:scale(deckDirs[ply] * 2.4)
			deck.takeObject({ index = i - 1, position = pos, rotation = rot })
			break
		end
	end
	Wait.time(function()
		deck.shuffle()
	end, 0.1, 5)
end

function deckRampG(ply)
	local deck = getDeckFromZone(data[ply]["libraryZone"])
	if deck == nil then
		return
	end
	for i, card in ipairs(deck.getObjects()) do
		local cname = card.name:lower():gsub("%p", "")
		if cname:find("basic") and cname:find("land") and cname:find("forest") then
			local rot = deck.getRotation()
			local pos = deck.getPosition()
			local rig = deck.getTransformRight()
			rot[3] = 0
			pos = pos + rig:scale(deckDirs[ply] * 2.4)
			deck.takeObject({ index = i - 1, position = pos, rotation = rot })
			break
		end
	end
	Wait.time(function()
		deck.shuffle()
	end, 0.1, 5)
end

function deckRampWa(ply)
	local deck = getDeckFromZone(data[ply]["libraryZone"])
	if deck == nil then
		return
	end
	for i, card in ipairs(deck.getObjects()) do
		local cname = card.name:lower():gsub("%p", "")
		if cname:find("basic") and cname:find("land") and cname:find("wastes") then
			local rot = deck.getRotation()
			local pos = deck.getPosition()
			local rig = deck.getTransformRight()
			rot[3] = 0
			pos = pos + rig:scale(deckDirs[ply] * 2.4)
			deck.takeObject({ index = i - 1, position = pos, rotation = rot })
			break
		end
	end
	Wait.time(function()
		deck.shuffle()
	end, 0.1, 5)
end

function toggleEncMenu(ply)
	objs = Player[ply].getSelectedObjects()
	for i, obj in pairs(objs) do
		obj.setLock(true)
		Encoder.call("APIencodeObject", { obj = obj })
		local objRot = obj.getRotation()
		local cardFlip = 1
		if objRot[3] > 90 and objRot[3] < 270 then
			cardFlip = -1
		end
		local encFlip = Encoder.call("APIgetFlip", { obj = obj })
		if encFlip ~= cardFlip then
			Encoder.call("APIFlip", { obj = obj })
		end
		Encoder.call("APIobjToggleMenu", { obj = obj, menuID = "πMenu" })
		Encoder.call("APIrebuildButtons", { obj = obj })
		Wait.frames(function()
			obj.setLock(false)
		end, 1)
	end
end

function cardToken(ply)
	objs = Player[ply].getSelectedObjects()
	card = objs[1]
	Player[ply].clearSelectedObjects()
	if card.type ~= "Card" then
		return
	end
	local newPos = card.getPosition() + card.getTransformForward():scale(-3.2)
	local cardDat = card.getData()
	cardDat.Transform.posX = newPos.x
	cardDat.Transform.posY = newPos.y + 0.1
	cardDat.Transform.posZ = newPos.z
	Encoder.call("APIencodeObject", { obj = card })
	local flip = Encoder.call("APIgetFlip", { obj = card })
	local moduleData = Encoder.call("APIobjGetProps", { obj = card })
	local valueData = Encoder.call("APIobjGetAllData", { obj = card })
	local tCard = spawnObjectData({ data = cardDat })
	Wait.Condition(function()
		if tCard == nil or Encoder == nil then
			return
		end
		Encoder.call("APIencodeObject", { obj = tCard })
		Encoder.call("APIobjSetAllData", { obj = tCard, data = valueData })
		Encoder.call("APIobjSetProps", { obj = tCard, data = moduleData })
		if flip < 0 then
			Encoder.call("APIFlip", { obj = tCard })
		end
		Encoder.call("APIobjEnableProp", { obj = tCard, propID = "MTG_Token" })
		Encoder.call("APIrebuildButtons", { obj = tCard })
	end, function()
		return tCard == nil or not tCard.spawning
	end)
end

function cardCascade(ply)
	objs = Player[ply].getSelectedObjects()
	card = objs[1]
	Player[ply].clearSelectedObjects()
	if card.type ~= "Card" then
		return
	end
	local proceed = false
	for _, obj in pairs(data[ply]["playmat"].getObjects()) do
		if obj == card then
			proceed = true
		end
	end
	if proceed then
		local cmc = getCMC(card.getName(), card.getDescription())
		local val = cmc - 1
		local deck = getDeckFromZone(data[ply]["libraryZone"])
		if val >= 0 and deck ~= nil then
			local rot = deck.getRotation()
			rot.z = 180
			deck.setRotation(rot)
			cascade(deck, ply, val)
		end
	end
end

-- sort hands by CMC
function sortHands(ply)
	Player[ply].clearSelectedObjects()
	for handInd = 1, Player[ply].getHandCount() do
		local cards = Player[ply].getHandObjects(handInd)
		local cmcs = {}
		local poss = {}
		noCMCs = false
		for i, card in ipairs(cards) do
			if card.type == "Card" then
				cmc = getCMC(card.getName(), card.getDescription())
				if cmc == nil then
					cmc = "-2"
					noCMCs = true
				end
				table.insert(cmcs, { id = i, cmc = cmc })
				table.insert(poss, card.getPosition())
			end
		end
		table.sort(cmcs, function(a, b)
			return tonumber(a.cmc) < tonumber(b.cmc)
		end)

		if noCMCs then
			Player[ply].broadcast(
				"No CMC info found in the card names or description.\n"
					.. "You could use the Deck Lister to reimport your deck with the necessary info,\n"
					.. "Or the Deck Data Fetcher to download and port the info directly onto your deck.",
				{ 0.7, 0.7, 0.7 }
			)
			local pingGUIDs = { "6d07c3", "5006a4", "6d46cd", "6ed442" }
			for i, guid in ipairs(pingGUIDs) do
				if getObjectFromGUID(guid) ~= nil then
					Player[ply].pingTable(getObjectFromGUID(guid).getPosition())
				end
			end
		else
			-- for i,v in ipairs(cmcs) do
			-- cards[v.id].setPosition(poss[i])
			-- end

			for i, v in ipairs(cmcs) do
				cards[v.id].setHiddenFrom(allBut(ply))
				cards[v.id].setLock(true)
				Wait.frames(function()
					cards[v.id].setPositionSmooth(poss[i], false, false)
				end, 1)
			end

			Wait.frames(function()
				Wait.condition(function()
					for i, v in ipairs(cmcs) do
						cards[v.id].setLock(false)
						cards[v.id].setPosition(poss[i])
						Wait.frames(function()
							cards[v.id].setHiddenFrom({})
						end, 20)
					end
				end, function()
					local doneMoving = true
					for _, card in pairs(cards) do
						if card.isSmoothMoving() then
							doneMoving = false
						end
					end
					return doneMoving
				end)
			end, 5)
		end
	end
end

function randomDiscard(ply)
	local cards = Player[ply].getHandObjects(1)
	Player[ply].clearSelectedObjects()
	local discardN = math.random(#cards)
	Wait.time(function()
		discardN = math.random(#cards)
		cards[discardN].highlightOn({ 1, 1, 1 }, 0.1)
	end, 0.1, 20)
	Wait.time(function()
		Wait.time(function()
			cards[discardN].highlightOn({ 1, 0, 0 }, 0.05)
		end, 0.1, 10)
	end, 2)
	Wait.time(function()
		discardCard(cards[discardN], ply)
	end, 3)
end

function discardCard(card, playerColor)
	Player[playerColor].clearSelectedObjects()
	local gravPos = data[playerColor]["graveyard"].getPosition()
	local target = { x = gravPos.x, y = 3, z = gravPos.z }
	local cardRot = card.getRotation()
	cardRot.z = 0
	card.setRotationSmooth(cardRot, false, true)
	Wait.time(function()
		handTrigger(card)
		card.setPositionSmooth(target, false, true)
	end, 0.2)
	Wait.time(function()
		checkMoveSuccess(card, target, playerColor)
	end, 0.5)
end

