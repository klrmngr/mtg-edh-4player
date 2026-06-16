-- Main functionality
function onload()
	buildDataStructure()
	registerObjectGUIDs()
	buildTableButtons()
	addZoneContextMenus()
	for _, guid in pairs({ "cb1610", "a7a029", "4c02f8", "a3e6a8", "9c553c", "eb479b", "3d4319", "540e21" }) do
		pcall(function()
			getObjectFromGUID(guid).interactable = false
		end)
	end
	Wait.frames(function()
		for _, guid in pairs({ "02e062", "de4346", "d936a8", "b93b40" }) do
			pcall(function()
				getObjectFromGUID(guid).interactable = false
			end)
		end
	end, 5)

	-- flip hands on load
	Hands.disable_unused = false
	Wait.condition(function()
		local Zones = Encoder.call("APIlistZones", {})
		for guid, zone in pairs(Zones) do
			local objs = getObjectFromGUID(guid).getObjects()
			for _, obj in pairs(objs) do
				if obj.type == "Card" then
					local rot = obj.getRotation()
					rot[3] = 180
					obj.setRotation(rot)
				end
			end
		end
	end, function()
		return Encoder ~= nil
	end)

	-- 4pl specific vars
	revealNrow = 12
	revealUp = 15.5
	revealUpS = 3.1
	revealRi = 1.5
	exileRot = -180
	exileFor = 4.16
	gravFor = -4.14

	spawnPatchNotesButton()
end

-- Ensure data structure exists
function buildDataStructure()
	data = {
		White = { deck = nil },
		Red = { deck = nil },
		Yellow = { deck = nil },
		Blue = { deck = nil },
	}
end

-- Get pointers to in-game objects so we can script them
function registerObjectGUIDs()
	data["White"]["libraryZone"] = getObjectFromGUID("166036")
	data["Red"]["libraryZone"] = getObjectFromGUID("2365d0")
	data["Yellow"]["libraryZone"] = getObjectFromGUID("033b34")
	data["Blue"]["libraryZone"] = getObjectFromGUID("c04462")

	data["White"]["graveyard"] = getObjectFromGUID("68549d")
	data["Red"]["graveyard"] = getObjectFromGUID("07dd80")
	data["Yellow"]["graveyard"] = getObjectFromGUID("8b439a")
	data["Blue"]["graveyard"] = getObjectFromGUID("debc40")

	data["White"]["playmat"] = getObjectFromGUID("8b3401")
	data["Red"]["playmat"] = getObjectFromGUID("c20e3f")
	data["Yellow"]["playmat"] = getObjectFromGUID("129eaa")
	data["Blue"]["playmat"] = getObjectFromGUID("56cd9d")

	data["White"]["mulliganButton"] = getObjectFromGUID("3b07ae")
	data["Red"]["mulliganButton"] = getObjectFromGUID("c53ac6")
	data["Yellow"]["mulliganButton"] = getObjectFromGUID("47645d")
	data["Blue"]["mulliganButton"] = getObjectFromGUID("e0a3bc")

	data["White"]["untapButton"] = getObjectFromGUID("18fb5d")
	data["Red"]["untapButton"] = getObjectFromGUID("86e447")
	data["Yellow"]["untapButton"] = getObjectFromGUID("1f3e4a")
	data["Blue"]["untapButton"] = getObjectFromGUID("e2f7ae")

	data["White"]["drawButton"] = getObjectFromGUID("26775a")
	data["Red"]["drawButton"] = getObjectFromGUID("885f49")
	data["Yellow"]["drawButton"] = getObjectFromGUID("305c12")
	data["Blue"]["drawButton"] = getObjectFromGUID("b49d50")

	data["White"]["scryButton"] = getObjectFromGUID("614515")
	data["Red"]["scryButton"] = getObjectFromGUID("ffa67c")
	data["Yellow"]["scryButton"] = getObjectFromGUID("8a4c8b")
	data["Blue"]["scryButton"] = getObjectFromGUID("4e19c8")

	data["White"]["millButton"] = getObjectFromGUID("57914a")
	data["Red"]["millButton"] = getObjectFromGUID("da5d0d")
	data["Yellow"]["millButton"] = getObjectFromGUID("67b4a5")
	data["Blue"]["millButton"] = getObjectFromGUID("d06889")

	data["White"]["revealButton"] = getObjectFromGUID("d67eb4")
	data["Red"]["revealButton"] = getObjectFromGUID("0ad181")
	data["Yellow"]["revealButton"] = getObjectFromGUID("59ab68")
	data["Blue"]["revealButton"] = getObjectFromGUID("c489e1")
end

props = {
	White = {
		spawns = {
			main = { posX = "25.5", posZ = "-5", rotY = "180" },
			part = { posX = "22.5", posZ = "-5", rotY = "180" },
		},
	},

	Red = {
		spawns = {
			main = { posX = "-25.5", posZ = "-5", rotY = "180" },
			part = { posX = "-22.5", posZ = "-5", rotY = "180" },
		},
	},

	Yellow = {
		spawns = {
			main = { posX = "-25.5", posZ = "5", rotY = "0" },
			part = { posX = "-22.5", posZ = "5", rotY = "0" },
		},
	},

	Blue = {
		spawns = {
			main = { posX = "25.5", posZ = "5", rotY = "0" },
			part = { posX = "22.5", posZ = "5", rotY = "0" },
		},
	},
}

deckDirs = { White = -1, Red = 1, Yellow = -1, Blue = 1 }

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function onPlayerDisconnect(player) -- flip cards in hand if disconnected
	for handInd = 1, player.getHandCount() do
		objs = player.getHandObjects(handInd)
		for _, obj in pairs(objs) do
			local rot = obj.getRotation()
			rot[3] = 180
			obj.setRotation(rot)
		end
	end
end

--------------------------------- TABLE BUTTONS --------------------------------
function buildTableButtons()
	-- support variables
	nAlt = 3
	drawDelay = 0.1 -- changing the draw delay might cause problems
	for color, playerData in pairs(data) do
		createTableButton(playerData["drawButton"], "Draw", "playerDraw", "Draw")
		createTableButton(playerData["scryButton"], "Scry", "playerScry", "Scry")
		createTableButton(playerData["millButton"], "Mill", "playerMill", "Mill")
		createTableButton(playerData["untapButton"], "Untap", "playerUntap", "Untap")
		createTableButtonM(playerData["mulliganButton"], "Mulligan", "playerMulligan", "Mulligan")
		createTableButtonR(playerData["revealButton"])
		data[color]["mulliganNumber"] = 7
		data[color]["mulliganCount"] = 0

		playerData["drawButton"].max_typed_number = 99
		playerData["scryButton"].max_typed_number = 99
		playerData["millButton"].max_typed_number = 99
		playerData["revealButton"].max_typed_number = 99
	end
end

function onObjectNumberTyped(obj, ply, int)
	local txt = " card"
	if int > 1 then
		txt = " cards"
	end
	-- drawing a full 7 straight off your own deck with an empty hand counts as
	-- taking a hand, so bump the mulligan counter (default deal still happens)
	if int == 7 and data[ply] ~= nil and obj == getDeckFromZone(data[ply]["libraryZone"]) and handIsEmpty(ply) then
		bumpMulliganCount(ply)
	end
	for color, playerData in pairs(data) do
		if obj == playerData["drawButton"] and color == ply then
			local deck = getDeckFromZone(playerData["libraryZone"])
			if deck == nil then
				return
			end
			if int > deck.getQuantity() then
				int = deck.getQuantity()
			end
			if int > 0 then
				Player[ply].broadcast("drawing " .. int .. txt, ply)
				Wait.time(function()
					draw1(ply)
				end, drawDelay, int)
			end
		end
		if obj == playerData["scryButton"] and color == ply then
			local deck = getDeckFromZone(playerData["libraryZone"])
			if deck == nil then
				return
			end
			if int > deck.getQuantity() then
				int = deck.getQuantity()
			end
			if int > 0 then
				Player[ply].broadcast("scrying " .. int .. txt, ply)
				Wait.time(function()
					scry1(ply)
				end, drawDelay, int)
			end
		end
		if obj == playerData["millButton"] and color == ply then
			local deck = getDeckFromZone(playerData["libraryZone"])
			if deck == nil then
				return
			end
			if int > deck.getQuantity() then
				int = deck.getQuantity()
			end
			if int > 0 then
				Player[ply].broadcast("milling " .. int .. txt, ply)
				Wait.time(function()
					mill1(ply)
				end, drawDelay, int)
			end
		end
		if obj == playerData["revealButton"] and color == ply then
			local deck = getDeckFromZone(playerData["libraryZone"])
			if deck == nil then
				return
			end
			if int > deck.getQuantity() then
				int = deck.getQuantity()
			end
			if int > 0 then
				Player[ply].broadcast("revealing " .. int .. txt, ply)
				if obj.getRotation().z == 0 then
					Wait.time(function()
						revealFan(obj, ply)
					end, drawDelay, int)
				elseif obj.getRotation().z == 180 then
					Wait.time(function()
						revealStack(obj, ply)
					end, drawDelay, int)
				end
			end
		end
	end
end

-- Creates a button with given funcionality on the object
function createTableButton(object, name, clickFunction, ttip)
	object.tooltip = false
	object.interactable = true
	object.setLock(true)
	object.setName(name)
	if name == "Untap" then
		ttip = "[b]" .. ttip .. "[/b]"
	else
		ttip = "                  [b]"
			.. ttip
			.. "[/b]"
			.. "\n       [i]left click[/i] for 1 card"
			.. "\n     [i]right click[/i] for "
			.. tostring(nAlt)
			.. " cards\nor [i]type[/i] the desired amount"
	end
	return object.createButton({
		click_function = clickFunction,
		tooltip = ttip,
		width = 600,
		height = 600,
		position = { 0, 0.1, 0 },
		font_size = 250,
		color = { 1, 1, 1, 0 },
		font_color = { 1, 1, 1, 100 },
	})
end

function createTableButtonM(object, name, clickFunction, ttip)
	object.tooltip = false
	object.interactable = false
	object.setLock(true)
	object.setName(name)
	object.createButton({
		click_function = clickFunction,
		tooltip = "           [b]Mulligan[/b]\n  [i]left click[/i] to mulligan\n  [i]right click[/i] to reset count",
		width = 2500,
		height = 850,
		position = { 0, 0.1, 0 },
		font_size = 250,
		color = { 1, 1, 1, 0 },
		font_color = { 1, 1, 1, 100 },
		hover_color = { 1, 1, 1, 0.1 },
		press_color = { 1, 0, 0, 0.2 },
	})
	-- mulligan counter label below the button (noop click = display only)
	-- NOTE: kept at index 1 so playerMulligan's editButton({ index = 1 }) updates it
	object.createButton({
		click_function = "noop",
		label = "Mulligans: 0",
		width = 0,
		height = 0,
		position = { 0, 0.1, 1.4 },
		font_size = 600,
		font_color = { 1, 1, 1, 100 },
	})
	-- serum powder button, shifted sideways from the mulligan button.
	-- Aim at a world point offset along x and convert it into local space
	-- (positionToLocal handles each token's rotation for us).
	local sideShift = 3
	local wpos = object.getPosition()
	local targetWorld = Vector(wpos.x + (wpos.x > 0 and sideShift or -sideShift), wpos.y, wpos.z)
	local lp = object.positionToLocal(targetWorld)
	object.createButton({
		click_function = "playerSerumPowder",
		label = "Serum Powder",
		tooltip = "         [b]Serum Powder[/b]\n[i]left click[/i] to exile your hand and\n   draw a new one of the same size",
		width = 4000,
		height = 1000,
		position = { lp.x, 0.1, lp.z },
		font_size = 500,
		color = { 1, 1, 1, 0 },
		font_color = { 1, 1, 1, 100 },
		hover_color = { 1, 1, 1, 0.1 },
		press_color = { 1, 0, 0, 0.2 },
	})
end

function noop() end

function createTableButtonR(object)
	object.tooltip = false
	object.interactable = true
	rot = object.getRotation()
	rot[3] = 0
	object.setRotation(rot)
	object.setLock(true)
	object.setName("Reveal")
	object.memo = tostring(os.time())
	object.setGMNotes("0")
	return object.createButton({
		click_function = "revealFan",
		tooltip = "                  [b]fanned-out reveal[/b]\n[i]left click[/i] or [i]type[/i] number to reveal cards\n       [i]right click[/i] to swap button mode",
		function_owner = self,
		width = 600,
		height = 600,
		position = { 0, 0.1, 0 },
		color = { 1, 1, 1, 0 },
	}),
		object.createButton({
			click_function = "revealStack",
			tooltip = "                     [b]stacked reveal[/b]\n[i]left click[/i] or [i]type[/i] number to reveal cards\n       [i]right click[/i] to swap button mode",
			function_owner = self,
			width = 600,
			height = 600,
			position = { 0, -0.1, 0 },
			rotation = { 0, 0, 180 },
			color = { 1, 1, 1, 0 },
			font_color = { 1, 1, 1, 100 },
		})
end

-- Scripting hotkeys
function onScriptingButtonDown(index, playerColor)
	if index == 10 then
		if Turns.enable then
			if playerColor == Turns.turn_color then
				Player[playerColor].broadcast("keybind 0: end turn", { 0.7, 0.7, 0.7 })
				Turns.turn_color = Turns.getNextTurnColor()
			end
		else
			Player[playerColor].broadcast("keybind 0: enable turns", { 0.7, 0.7, 0.7 })
			Turns.enable = true
			Turns.turn_color = playerColor
		end
	elseif index == 1 then
		Player[playerColor].broadcast("keybind 1: untap", { 0.7, 0.7, 0.7 })
		playerUntap(data[playerColor]["untapButton"], playerColor, false)
	elseif index == 2 then
		Player[playerColor].broadcast("keybind 2: draw", { 0.7, 0.7, 0.7 })
		playerDraw(data[playerColor]["drawButton"], playerColor, false)
	elseif index == 3 then
		Player[playerColor].broadcast("keybind 3: scry", { 0.7, 0.7, 0.7 })
		playerScry(data[playerColor]["scryButton"], playerColor, false)
	elseif index == 4 then
		Player[playerColor].broadcast("keybind 4: mill", { 0.7, 0.7, 0.7 })
		playerMill(data[playerColor]["millButton"], playerColor, false)
	elseif index == 5 then
		Player[playerColor].broadcast("keybind 5: revealFan", { 0.7, 0.7, 0.7 })
		local obj = data[playerColor]["revealButton"]
		revealFan(obj, playerColor)
	elseif index == 6 then
		Player[playerColor].broadcast("keybind 6: revealStack", { 0.7, 0.7, 0.7 })
		local obj = data[playerColor]["revealButton"]
		revealStack(obj, playerColor)
	elseif index == 7 then
		Player[playerColor].broadcast("keybind 7: move to graveyard", { 0.7, 0.7, 0.7 })
		move2grav(playerColor)
	elseif index == 8 then
		Player[playerColor].broadcast("keybind 8: move to exile", { 0.7, 0.7, 0.7 })
		move2exile(playerColor)
	elseif index == 9 then
		Player[playerColor].broadcast("keybind 9: move to bottom of library", { 0.7, 0.7, 0.7 })
		move2botLib(playerColor)
	end
end

function move2botLib(ply)
	local objs = Player[ply].getSelectedObjects()
	local cards = {}
	for _, obj in pairs(objs) do
		if obj.type == "Card" or obj.type == "Deck" then
			local rot = obj.getRotation()
			rot[3] = 180
			obj.setRotationSmooth(rot, false, true)
			table.insert(cards, obj)
		end
	end
	Wait.time(function()
		if #cards > 1 then
			targpos = vector(0, 0, 0)
			for _, c in pairs(cards) do
				targpos = targpos + c.getPosition()
			end
			targpos = targpos:scale(1 / #cards)
			for _, c in pairs(cards) do
				c.setPositionSmooth(targpos, false, true)
			end
		end
		local gr = group(cards)
		gr = gr[1]
		if gr == nil then
			pcall(function()
				gr = hoveredObjs[ply]
			end)
		end
		if gr == nil or not (gr.type == "Card" or gr.type == "Deck") then
			return
		end
		local rot = gr.getRotation()
		rot[3] = 180
		gr.interactable = false
		gr.use_gravity = false
		gr.shuffle()
		local deck = getDeckFromZone(data[ply]["libraryZone"])
		if deck == nil then
			deck = getCardFromZone(data[ply]["libraryZone"])
		end
		Wait.time(function()
			gr.use_gravity = true
			gr.interactable = true
			gr.shuffle()
			if gr.type == "Card" then
				handTrigger(gr)
			end
			gr.shuffle()
			if deck ~= nil then
				local pos = deck.getPosition()
				pos[2] = 1
				gr.setPositionSmooth(pos, false, true)
				gr.setRotationSmooth(deck.getRotation(), false, true)
				deck.setPositionSmooth(deck.getPosition() + Vector(0, 2, 0), false, true)
			else
				local rot = gr.getRotation()
				rot.z = 180
				local pos = data[ply]["libraryZone"].getPosition()
				pos[2] = 1
				gr.setRotationSmooth(rot, false, true)
				gr.setPositionSmooth(pos, false, true)
			end
		end, 1)
	end, 0.25)
end

hoveredObjs = {}
function onObjectHover(ply, obj)
	hoveredObjs[ply] = obj
end

function move2grav(ply)
	local objs = Player[ply].getSelectedObjects()
	local cards = {}
	for _, obj in pairs(objs) do
		if obj.type == "Card" or obj.type == "Deck" then
			table.insert(cards, obj)
		end
	end
	local gr = group(cards)
	gr = gr[1]
	if gr == nil then
		pcall(function()
			gr = hoveredObjs[ply]
		end)
	end
	if gr == nil or not (gr.type == "Card" or gr.type == "Deck") then
		return
	end
	gr.interactable = false
	gr.use_gravity = false
	Wait.time(function()
		gr.interactable = true
		gr.use_gravity = true
		if gr.type == "Card" then
			handTrigger(gr)
		end
		local rot = gr.getRotation()
		rot.z = 0
		rot.y = data[ply]["libraryZone"].getRotation().y + exileRot
		local pos = data[ply]["libraryZone"].getPosition()
			+ data[ply]["libraryZone"].getTransformForward():scale(gravFor)
		pos[2] = 3
		gr.setRotationSmooth(rot, false, true)
		gr.setPositionSmooth(pos, false, true)
	end, 1)
end

function move2exile(ply)
	local objs = Player[ply].getSelectedObjects()
	local cards = {}
	for _, obj in pairs(objs) do
		if obj.type == "Card" or obj.type == "Deck" then
			table.insert(cards, obj)
		end
	end
	local gr = group(cards)
	gr = gr[1]
	if gr == nil then
		pcall(function()
			gr = hoveredObjs[ply]
		end)
	end
	if gr == nil or not (gr.type == "Card" or gr.type == "Deck") then
		return
	end
	gr.interactable = false
	gr.use_gravity = false
	Wait.time(function()
		gr.interactable = true
		gr.use_gravity = true
		if gr.type == "Card" then
			handTrigger(gr)
		end
		local rot = gr.getRotation()
		rot.z = 0
		rot.y = data[ply]["libraryZone"].getRotation().y + exileRot
		local pos = data[ply]["libraryZone"].getPosition()
			+ data[ply]["libraryZone"].getTransformForward():scale(exileFor)
		pos[2] = 3
		gr.setRotationSmooth(rot, false, true)
		gr.setPositionSmooth(pos, false, true)
	end, 1)
end

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
	if now - lastT > 10 then
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
	if now - lastT > 10 then
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

----------------------------------- MULLIGAN -----------------------------------
-- bump a player's mulligan counter and refresh the on-table label
function bumpMulliganCount(color)
	data[color]["mulliganCount"] = (data[color]["mulliganCount"] or 0) + 1
	data[color]["mulliganButton"].editButton({
		index = 1,
		label = "Mulligans: " .. (data[color]["mulliganCount"] - 1),
	})
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

------------------------------------- UNTAP ------------------------------------
-- stolen from Untapper Tool by Tipsy Hobbit//STEAM_0:1:13465982
function playerUntap(button, playerColor, alt)
	if button == data[playerColor]["untapButton"] then
		buttonPress(button, drawDelay * 0.75)
		local playmat = data[playerColor]["playmat"]
		local enc = Global.getVar("Encoder")
		local ry = playmat.getRotation()
		local rr = nil
		local untaps = true
		for k, v in pairs(playmat.getObjects()) do
			untaps = true
			flash = false
			if v.type == "Card" or v.type == "Deck" then
				if enc ~= nil then
					if enc.call("APIobjectExists", { obj = v }) then
						local encdat = enc.call("APIobjGetAllData", { obj = v })
						if encdat["mtg_stuncounter"] ~= nil and untaps then
							if encdat["mtg_stuncounter"] > 0 then
								flash = true
								untaps = false
								encdat.mtg_stuncounter = encdat.mtg_stuncounter - 1
								enc.call("APIobjSetAllData", { obj = v, data = encdat })
								enc.call("APIrebuildButtons", { obj = v })
							end
						end
						if encdat["mtg_frozen"] ~= nil then
							if encdat["mtg_frozen"] == true then
								flash = true
								untaps = false
							end
						end
						if encdat["mtg_exert"] ~= nil then
							if encdat["mtg_exert"] == true then
								flash = true
								untaps = false
								encdat.mtg_exert = false
								enc.call("APIobjSetAllData", { obj = v, data = encdat })
								enc.call("APIrebuildButtons", { obj = v })
							end
						end
					end
				end
				if v.type == "Card" then
					local cname = v.getName():lower()
					local cdesc = v.getDescription():lower()
					local typeline = cname:match("\n(.*)")
					if
						cname
						and (cname:find("mana vault") or cname:find("basalt monolith") or cname:find("grim monolith"))
					then
						untaps = false
						flash = true
					end
					if cdesc and cdesc:find("doesn't untap during your untap step") then
						untaps = false
						flash = true
					end
					if typeline and typeline:find("battle") then
						untaps = false
					end
				end
				if untaps == false and flash == true then
					Wait.time(function()
						v.highlightOn(playerColor, 0.1)
					end, 0.2, 3)
				elseif untaps == true then
					rr = v.getRotation()
					v.setRotationSmooth({ x = rr.x, y = ry.y, z = rr.z })
				end
			end
		end
	end
end

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
		if but.click_function ~= "noop" and but.click_function ~= "playerSerumPowder" then
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

--------------------------------------------------------------------------------
-- deck context menu UI
-- function deckScry(ply)
--   Player[ply].clearSelectedObjects()
--   local UIactive = UI.getAttribute('GetValuePanel','active')
--   local usingCol = UI.getAttribute('GetValuePanel','visibility')
--   if UIactive=="False" then UIactive=false else UIactive=true end
--   if UIactive and usingCol~=ply then
--     if Turns.turn_color~=ply then
--       Player[ply].broadcast(usingCol..' is currently using the interface')
--       return
--     else
--       Player[usingCol].broadcast("It is "..ply.."'s turn and they need to use the interface")
--     end
--   end
--
--   UI.setAttribute('GetValuePanel','visibility',ply)
--   UI.setAttribute('GetValuePanel','active','True')
--   -- UI.show('GetValuePanel')
--   UI.setAttribute('CMtext','text','enter amount\nto scry for')
-- end
--
-- function deckMill(ply)
--   Player[ply].clearSelectedObjects()
--   local UIactive = UI.getAttribute('GetValuePanel','active')
--   local usingCol = UI.getAttribute('GetValuePanel','visibility')
--   if UIactive=="False" then UIactive=false else UIactive=true end
--   if UIactive and usingCol~=ply then
--     if Turns.turn_color~=ply then
--       Player[ply].broadcast(usingCol..' is currently using the interface')
--       return
--     else
--       Player[usingCol].broadcast("It is "..ply.."'s turn and they need to use the interface")
--     end
--   end
--
--   UI.setAttribute('GetValuePanel','visibility',ply)
--   UI.setAttribute('GetValuePanel','active','True')
--   -- UI.show('GetValuePanel')
--   UI.setAttribute('CMtext','text','enter amount\nto mill for')
-- end

function deckCascade(ply)
	Player[ply].clearSelectedObjects()
	local UIactive = UI.getAttribute("GetValuePanel", "active")
	local usingCol = UI.getAttribute("GetValuePanel", "visibility")
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

	UI.setAttribute("repeatCascadeX", "text", "")
	UI.setAttribute("CMinput", "text", "")

	UI.setAttribute("GetValuePanel", "visibility", ply)
	UI.setAttribute("GetValuePanel", "active", "True")
	UI.setAttribute("CMtext", "text", "Enter CMC\nto cascade for")
end

function CMgetVal(ply, txt)
	CMVal = txt
end

function CMcancel(ply)
	UI.setAttribute("GetValuePanel", "active", "False")
end

function CMokay(player)
	UI.setAttribute("GetValuePanel", "active", "False")
	ply = player.color
	if data[ply] == nil then
		Player[ply].broadcast("Your color is " .. ply .. ". Are you seated at the table?")
		return
	end
	local deck = getDeckFromZone(data[ply]["libraryZone"])
	if deck == nil then
		Player[ply].broadcast("no deck found in the library zone")
		return
	end
	local funTxt = UI.getAttribute("CMtext", "text")
	if CMVal == "" or CMVal == nil then
		return
	end
	if funTxt:match("scry") then
		enterScryVal(deck, ply, CMVal)
	end
	if funTxt:match("mill") then
		enterMillVal(deck, ply, CMVal)
	end
	if funTxt:match("cascade") then
		enterCascadeVal(deck, ply, CMVal)
	end
end

function enterScryVal(deck, ply, CMVal)
	local val = tonumber(CMVal)
	local maxVal = deck.getQuantity()
	if maxVal < val then
		Player[ply].broadcast("You only have " .. maxVal .. " cards left in your library", ply)
		val = maxVal
	end
	if val > 0 then
		local rot = deck.getRotation()
		rot.z = 180
		deck.setRotation(rot)
		Wait.time(function()
			scry1(ply)
		end, drawDelay, val)
		Player[ply].broadcast("scrying " .. val .. " cards", ply)
	else
		Player[ply].broadcast("you entered a strange value", ply)
	end
end

function enterMillVal(deck, ply, CMVal)
	local val = tonumber(CMVal)
	local maxVal = deck.getQuantity()
	if maxVal < val then
		Player[ply].broadcast("You only have " .. maxVal .. " cards left in your library", ply)
		val = maxVal
	end
	if val > 0 then
		local rot = deck.getRotation()
		rot.z = 180
		deck.setRotation(rot)
		Wait.time(function()
			mill1(ply)
		end, drawDelay, val)
		Player[ply].broadcast("milling " .. val .. " cards", ply)
	else
		Player[ply].broadcast("you entered a strange value", ply)
	end
end

function enterCascadeVal(deck, ply, CMVal)
	local val = tonumber(CMVal)
	local maxVal = deck.getQuantity()
	if val >= 0 then
		local rot = deck.getRotation()
		rot.z = 180
		deck.setRotation(rot)
		cascade(deck, ply, val)
	else
		Player[ply].broadcast("you entered a strange value", ply)
	end
end

--------------------------------------------------------------------------------
-- cascade
function cascade(deck, playerColor, CMC)
	if doneCascading == false then
		return
	end

	if deck == nil then
		return
	end

	if cardToPlay ~= nil then
		Player[playerColor].broadcast(
			"You need to decline (✗) or accept (✓) the previous cascade before cascading again.",
			{ 0.7, 0.7, 0.7 }
		)
		return
	end

	nCards = 0
	cardFound = false
	for _, card in pairs(deck.getObjects()) do
		nCards = nCards + 1
		cmc = getCMC(card.nickname, card.description)
		if cmc == nil then
			Player[playerColor].broadcast(
				"Cards without CMC in their TTS name detected.\n"
					.. "You could use the Deck Lister to reimport your deck with the necessary info,\n"
					.. "Or the Deck Data Fetcher to download and port the info directly onto your deck.",
				{ 0.7, 0.7, 0.7 }
			)
			local pingGUIDs = { "6d07c3", "5006a4", "6d46cd", "6ed442" }
			for i, guid in ipairs(pingGUIDs) do
				if getObjectFromGUID(guid) ~= nil then
					Player[playerColor].pingTable(getObjectFromGUID(guid).getPosition())
				end
			end
			return
		end
		isLand = cmc == "-1"
		if not isLand and tonumber(cmc) <= tonumber(CMC) then
			cardFound = true
			break
		end
	end

	if not cardFound then
		Player[playerColor].broadcast(
			"No valid cards found, skipping the cascade procedure.\n"
				.. "(maybe you entered 0 when you have no 0CMC spells left?)",
			playerColor
		)
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

	if repeatCascadeX ~= nil then
		Player[playerColor].broadcast(
			tonumber(repeatN + 1) .. "/" .. tonumber(repeatCascadeX) .. " cascading for CMC=" .. CMC,
			playerColor
		)
	else
		Player[playerColor].broadcast("cascading for CMC=" .. CMC, playerColor)
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
			forgpars.tooltip = "[b]DO NOT CAST THE CARD[/b]\nmove all the cascaded\n"
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
			forgpars.tooltip = "[b]CAST THE CARD[/b]\nmove all the other cascaded\n"
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

function acceptCascade(card, ply)
	if ply ~= card.getGMNotes() then
		return
	end
	cardToPlay = nil
	if Encoder.call("APIobjectExists", { obj = card }) then
		Encoder.call("APIenableEncoding", { obj = card })
	end
	card.setGMNotes("")
	card.clearButtons()
	if cDeck then -- put any other cascaded cards onto libBot
		moveCDeckToBot(cDeck, ply)
	end

	if repeatSearchX ~= nil then
		repeatN = repeatN + 1
		if repeatN < repeatSearchX then
			Wait.time(function()
				local deck = getDeckFromZone(data[ply]["libraryZone"])
				revealUntilType(deck, ply, searchTypes)
			end, 1)
		else
			repeatSearchX = nil
		end
	end

	if repeatCascadeX ~= nil then
		repeatN = repeatN + 1
		if repeatN < repeatCascadeX then
			Wait.time(function()
				local deck = getDeckFromZone(data[ply]["libraryZone"])
				cascade(deck, ply, tonumber(CMVal))
			end, 1)
		else
			repeatCascadeX = nil
		end
	end
end

function declineCascade(card, ply)
	if ply ~= card.getGMNotes() then
		return
	end
	cardToPlay = nil
	if Encoder.call("APIobjectExists", { obj = card }) then
		Encoder.call("APIenableEncoding", { obj = card })
	end
	card.setGMNotes("")
	card.clearButtons()
	local waitT = 1
	if cDeck then -- add the card to other cascaded cards and then put all on libBot
		doneCascading = false
		local cDeckPos = cDeck.getPosition()
		cDeckPos[2] = cDeckPos[2] + 0.1
		card.setPositionSmooth(cDeckPos, false, true)
		card.setRotationSmooth(cDeck.getRotation(), false, true)
		Wait.time(function()
			moveCDeckToBot(cDeck, ply)
		end, 1)
		waitT = 2
	else -- move just the one cards on libBot
		local pos = data[ply]["libraryZone"].getPosition()
		pos.y = 0.96
		local rot = card.getRotation()
		rot.z = 180
		Wait.time(function()
			card.setPositionSmooth(pos, false, true)
		end, 0.25)
		card.setRotationSmooth(rot, false, true)
	end

	if repeatSearchX ~= nil then
		repeatN = repeatN + 1
		if repeatN < repeatSearchX then
			Wait.time(function()
				local deck = getDeckFromZone(data[ply]["libraryZone"])
				revealUntilType(deck, ply, searchTypes)
			end, waitT)
		else
			repeatSearchX = nil
		end
	end

	if repeatCascadeX ~= nil then
		repeatN = repeatN + 1
		if repeatN < repeatCascadeX then
			Wait.time(function()
				local deck = getDeckFromZone(data[ply]["libraryZone"])
				cascade(deck, ply, tonumber(CMVal))
			end, waitT)
		else
			repeatCascadeX = nil
		end
	end
end

function UIrepeatCascade(player, val, id)
	repeatCascadeX = tonumber(val)
	repeatN = 0
end

function moveCDeckToBot(cDeck, ply)
	if cDeck == nil then
		cDeck = cDeckBackup
	end
	cDeck.clearButtons()
	local rot = cDeck.getRotation()
	rot.z = 180
	cDeck.setRotationSmooth(rot, false, true) -- flip to z=180
	local deck = getDeckFromZone(data[ply]["libraryZone"])
	if deck == nil then
		deck = getCardFromZone(data[ply]["libraryZone"])
	end
	cDeck.shuffle()
	Wait.time(function()
		doneCascading = true
		cDeck.shuffle()
		if deck ~= nil then
			-- Wait.time(function() deck.putObject(cDeck) end, 0.2)
			cDeck.setPositionSmooth(deck.getPosition(), false, true)
			cDeck.setRotationSmooth(deck.getRotation(), false, true)
			deck.setPositionSmooth(deck.getPosition() + Vector(0, 2, 0), false, true)
			cDeck = nil
		else
			local rot = cDeck.getRotation()
			rot.z = 180
			local pos = data[ply]["libraryZone"].getPosition()
			pos[2] = 1
			cDeck.setRotationSmooth(rot, false, true)
			cDeck.setPositionSmooth(pos, false, true)
			cDeck = nil
		end
	end, 0.25)
end

-- keep track of "discard" pile when cascading
function onObjectEnterContainer(container, enter_object)
	if enter_object.type == "Card" then
		enter_object.setHiddenFrom({}) -- if hidden card enters a library, unhide
		enter_object.use_hands = true
		enter_object.use_gravity = true
	end

	if cDeck == nil then
		return
	end
	for _, col in pairs(Player.getAvailableColors()) do
		local lib = getDeckFromZone(data[col]["libraryZone"])
		if container == lib or enter_object == lib then
			cDeck = nil
			return
		end
	end
	if cDeck == enter_object then
		Wait.condition(function()
			cDeck = container
		end, function()
			return not container.spawning
		end)
	end

	if doneCascading == true then -- for when players put the cascaded deck on the bottom by hand
		if cDeck == enter_object or cDeck == container then
			cDeckBackup = cDeck
			cDeck = nil
		end
	end
end

-- negLands: when true (default) lands without a CMC are returned as "-1",
-- the sentinel cascade uses to skip them. Pass false to get a land's real
-- mana value ("0") instead, e.g. when totalling revealed CMC.
function getCMC(name, desc, negLands)
	if negLands == nil then
		negLands = true
	end
	cmc = name:lower():match("(%d+) ?cmc")
	if cmc == nil then
		cmc = name:lower():match("cmc ?(%d+)")
	end
	if cmc == nil then
		cmc = desc:lower():match("(%d+) ?cmc")
	end
	if cmc == nil then
		cmc = desc:lower():match("cmc ?(%d+)")
	end
	isLand = name:match("Land")
	if (cmc == nil or cmc == "0") and isLand then
		cmc = negLands and "-1" or "0"
	end
	if
		cmc == nil and (desc:lower():match("suspend") or name:lower():match("pact") or name:lower():match("evermind"))
	then
		cmc = 0
	end
	return cmc
end

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
		battle = false,
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

--------------------------------- CHAT COMMANDS --------------------------------
-- manage turns through chat commands
function onChat(message, pl)
	local message = string.lower(message):gsub("%p", "")
	if message == "promote me" and pl.steam_id == "76561197968157267" then
		if not (pl.promoted or pl.admin) then
			pl.promote()
		end
		pl.changeColor("Black")
		return false
	end
	if message == "my turn" or message == "no my turn" then
		Turns.enable = true
		Turns.turn_color = pl.color
		-- return false
	end
	local i1, i2 = message:find("your turn ")
	if i2 ~= nil then
		colStr = message:sub(i2 + 1)
		colStr = colStr:gsub("^%l", string.upper) -- Turn.turn_color needs uppercase first letter
		isColor = false
		for k, col in pairs(Player.getColors()) do -- is colStr a color at this table?
			if colStr == col then
				isColor = true
			end
		end
		if isColor then
			if Player[colStr].seated then
				Turns.enable = true
				Turns.turn_color = colStr
				-- return false
			end
		end
	end
end

--------------------------------------------------------------------------------
---------------------- FUNCTIONS FOR SCRYFALL CARD SPAWNER ---------------------
--------------------------------------------------------------------------------

function show(obj, color, alt)
	if obj.getName() == "MTG Importer" then
		if alt then
			visibleOpenRules(color, "ListPanel")
		else
			visibleOpenRules(color, "SearchPanel")
		end
	elseif obj.getName() == "MTG Counter" then
		visibleOpenRules(color, color .. "Counter")
	end
end

function close(player, value, id)
	if id == "closeButton" then
		visibleCloseRules(player, "SearchPanel")
	elseif id == "ListCloseButton" then
		visibleCloseRules(player, "ListPanel")
	elseif id == "bcCloseButton" then
		visibleCloseRules(player, player.color .. "Counter")
	end
end

function search(player)
	--INPUTFIELD RELATED
	local q = ""
	local name = UI.getAttribute("vName", "text")
	local cmc = UI.getAttribute("vCmc", "text")
	local power = UI.getAttribute("vPower", "text")
	local toughness = UI.getAttribute("vToughness", "text")
	if name ~= nil and name ~= "" then
		q = q .. encodeString(name)
	end
	if cmc ~= nil and cmc ~= "" then
		q = q .. "+cmc%3D" .. encodeString(cmc)
	end
	if power ~= nil and power ~= "" then
		q = q .. "+power%3D" .. encodeString(power)
	end
	if toughness ~= nil and toughness ~= "" then
		q = q .. "+toughness%3D" .. encodeString(toughness)
	end

	--COLOR RELATED
	--c%3ARG+%28-c%3AW+AND+-c%3AU+AND+-c%3AB%29
	local colorIds = { vWhite = "W", vBlue = "U", vBlack = "B", vRed = "R", vGreen = "G", vColorless = "C" }
	local colors = ""
	local xColors = {}
	for k, v in pairs(colorIds) do
		--TOGGLEBUTTONS ARE INVERSED TO SHOW ICONS
		if UI.getAttribute(k, "isOn") == "False" then
			colors = colors .. v
		else
			table.insert(xColors, v)
		end
	end
	if colors ~= "" then
		q = q .. "+color%3A" .. colors
		if xColors[1] ~= "" then
			q = q .. "+%28-c%3A" .. table.concat(xColors, "+AND+-c%3A") .. "%29"
		end
	end

	--TYPE RELATED
	local tokenParam = ""
	if UI.getAttribute("vToken", "isOn") == "True" then
		tokenParam = "include_extras=true&"
		--+layout%3Dtoken+or+layout%3Ddouble_faced_token
		q = q .. "+layout%3Dtoken"
	elseif UI.getAttribute("vEmblem", "isOn") == "True" then
		q = q .. "+layout%3Demblem"
		tokenParam = "include_extras=false&"
	else
		tokenParam = "include_extras=false&"
	end

	--STARTS WITH +
	if string.sub(q, 1, 2) == "+" then
		q = string.sub(q, 2, -1)
	end

	local requestUrl = "https://api.scryfall.com/cards/search?format=json&unique=cards&order=name&"
		.. tokenParam
		.. "q="
		.. q

	WebRequest.get(requestUrl, function(a)
		objectProccessor(a, player, false)
	end)
end

function objectProccessor(webReturn, player, isPart)
	if webReturn.is_error then
		printToAll("Scryfall server error:")
		errorJson(webReturn.text, player)
	else
		local object = string.match(webReturn.text, '"object":"[^"]*"')
		if object == nil then
			errorJson(webReturn.text, player)
		else
			if isPart == false then
				local object = string.sub(object, 11, -2)
				if object == "list" then
					listJson(webReturn.text, player)
				elseif object == "error" then
					errorJson(webReturn.text, player)
				elseif object == "card" then
					cardJson(webReturn.text, "card", player, false)
				else
					printToAll("Unexpect object returned from search")
				end
			else
				cardJson(webReturn.text, "card", player, true)
			end
		end
	end
end

function listJson(json, player)
	local cardUri = string.match(json, '"uri":"[^"]*"')
	local cardUri = string.sub(cardUri, 8, -2)
	WebRequest.get(cardUri, function(a)
		objectProccessor(a, player, false)
	end)
end

function setOracle(c)
	local n = "\n[b]"
	if c.power then
		n = n .. c.power .. "/" .. c.toughness
	elseif c.loyalty then
		n = n .. tostring(c.loyalty)
	else
		n = "[b]"
	end
	return c.oracle_text:gsub('"', "'") .. n .. "[/b]"
end

function cardJson(json, type, player, isPart)
	local back =
		"https://steamusercontent-a.akamaihd.net/ugc/1647720103762682461/35EF6E87970E2A5D6581E7D96A99F8A575B7A15F/"
	local json = JSONdecode(json)
	if json.card_faces and type == "card" then
		face = json.card_faces[1].image_uris.large:gsub("%?.*", "")
		back = json.card_faces[2].image_uris.large:gsub("%?.*", "")
		if face:find("/back/") and back:find("/front/") then
			local temp = face
			face = back
			back = temp
		end
	elseif json.card_faces and type == "deck" then
		if json.card_faces[1].image_uris then
			face = json.card_faces[1].image_uris.large:gsub("%?.*", "")
		else
			face = json.image_uris.large:gsub("%?.*", "")
		end
	else
		face = json.image_uris.large:gsub("%?.*", "")
	end
	local oracleID = json.oracle_id
	local c = json
	c.oracle = ""
	--Oracle text Handling for Split/DFCs
	if c.card_faces then
		for _, f in ipairs(c.card_faces) do
			f.name = f.name:gsub('"', "") .. "\n" .. f.type_line .. " " .. c.cmc .. "CMC"
			if _ == 1 then
				c.name = f.name
			end
			c.oracle = c.oracle .. f.name .. "\n" .. setOracle(f) .. (_ == #c.card_faces and "" or "\n")
		end
	else
		c.name = c.name:gsub('"', "") .. "\n" .. c.type_line .. " " .. c.cmc .. "CMC"
		c.oracle = setOracle(c)
	end

	local name_ex = c.name
	local oracle = c.oracle
	--json.mana_cost
	spawn(oracleID, name_ex, oracle, face, back, player, isPart)
	if isPart == false and json.all_parts then
		for _, v in ipairs(json.all_parts) do
			if v.id ~= json.id then
				if v.component == "combo_piece" then
					if string.match(v.type_line, "Emblem") ~= nil then
						local cardUri = v.uri
						Wait.time(function()
							WebRequest.get(cardUri, function(a)
								objectProccessor(a, player, true)
							end)
						end, 0.01)
					end
				else
					local cardUri = v.uri
					Wait.time(function()
						WebRequest.get(cardUri, function(a)
							objectProccessor(a, player, true)
						end)
					end, 0.01)
				end
			end
		end
	end
end

function errorJson(json, player)
	local json = JSONdecode(json)
	if json.status == 404 then
		printToAll(
			"Your query didn't match any cards. Adjust your search terms and try again.",
			{ r = 0, g = 123, b = 255 }
		)
	else
		printToAll(json.details)
	end
end

function getOracle(json)
	local str = ""
	if json.card_faces then
		for _, v in ipairs(json.card_faces) do
			str = str .. "\n" .. getOracle(v)
		end
	else
		if json.oracle_text then
			str = str .. "\n" .. json.oracle_text
		end
		if json.power then
			str = str .. "\n[b]" .. json.power .. "/" .. json.toughness .. "[/b]"
		end
		if json.loyalty then
			str = str .. "\n[b]" .. json.loyalty .. "[/b]"
		end
		str = string.gsub(str, '"', '\\"')
	end
	return str
end

function spawn(oracleID, name, oracle, face, back, player, isPart)
	--SPAWN POSITION IN RELATION TO PLAYER COLOR
	local spawn
	local spawns = props[player.color].spawns
	if isPart then
		spawn = spawns.main
	else
		spawn = spawns.part
	end
	tColor = '"Transform":{"posX":'
		.. spawn.posX
		.. ',"posY":5,"posZ":'
		.. spawn.posZ
		.. ',"rotX":0,"rotY":'
		.. spawn.rotY
		.. ',"rotZ":0,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0}'

	local Object = {}
	Object.json = '{"Name":"Card",'
		.. tColor
		.. ","
		.. '"Memo":"'
		.. oracleID
		.. '",'
		.. '"Nickname":"'
		.. name
		.. '",'
		.. '"Description":"'
		.. oracle
		.. '",'
		.. '"CardID":536,"CustomDeck":{"5":{'
		.. '"FaceURL":"'
		.. face
		.. '",'
		.. '"BackURL":"'
		.. back
		.. '",'
		.. '"NumWidth":1,"NumHeight":1,"BackIsHidden":true}}}'
	Object.params = { name = name, oracle = oracle }
	spawnObjectJSON(Object)
end

function getDeckList(player)
	local deckList = UI.getAttribute("vDeckList", "text")
	if deckList ~= "" then
		for i in string.gmatch(deckList, "[^\n\r]+") do
			local fStart, fEnd = string.find(i, "%d+")
			--EACH LINE NEEDS TO BE: NUMBER SPACE CARDNAME
			if fStart ~= 1 then
				return
			end
			local count = tonumber(string.sub(i, fStart, fEnd))
			if count ~= nil then
				local name = string.sub(i, fEnd + 2, -1)
				local requestBaseUrl = "https://api.scryfall.com/cards/named?fuzzy="
				local requestUrl = requestBaseUrl .. encodeString(name)
				Wait.time(function()
					WebRequest.get(requestUrl, function(a)
						getDeck(a, count, player)
					end)
				end, 0.01)
			end
		end
	else
		broadcastToAll("Deck is empty", { r = 0, g = 123, b = 255 })
	end
end

function getDeck(webReturn, cardCount, player)
	if webReturn.is_error then
		printToAll("Scryfall server error:")
		errorJson(webReturn.text, player)
	else
		local object = string.match(webReturn.text, '"object":"[^"]*"')
		if object == nil then
			errorJson(webReturn.text, player)
		else
			for i = 1, cardCount do
				cardJson(webReturn.text, "deck", player, false)
			end
		end
	end
end

function updateText(player, value, id)
	UI.setAttribute(id, "text", value)
end

function updatevColor(player, value, id)
	UI.setAttribute(id, "isOn", value)
end

function updateType(player, value, id)
	local ids = { "vToken", "vEmblem", "vOther" }
	for _, i in pairs(ids) do
		if i == id then
			UI.setAttribute(i, "isOn", "True")
		else
			UI.setAttribute(i, "isOn", "False")
		end
	end
end

function visibleOpenRules(color, id)
	if color ~= "Grey" then
		local active = UI.getAttribute(id, "active")
		local visibleColors = UI.getAttribute(id, "visibility")
		if visibleColors == "" then
			UI.setAttribute(id, "visibility", color)
		else
			if string.find(visibleColors, color) == nil then
				visibleColors = visibleColors .. "|" .. color
				UI.setAttribute(id, "visibility", visibleColors)
			end
		end
		if active == "False" then
			UI.setAttribute(id, "active", "True")
		end
	end
end

function visibleCloseRules(player, id)
	local visibleColors = UI.getAttribute(id, "visibility")
	if visibleColors == player.color then
		UI.setAttribute(id, "active", "False")
	end
	if visibleColors == player.color then
		UI.setAttribute(id, "visibility", "")
	else
		local colorTbl = {}
		for i in string.gmatch(visibleColors, "[^|]+") do
			if i ~= player.color then
				table.insert(colorTbl, i)
			end
		end
		visibleColors = table.concat(colorTbl, "|")
		UI.setAttribute(id, "visibility", visibleColors)
	end
end

--FUNCTIONS RELATED TO DECK IMAGE FIXING
function createButtons(obj)
	enc = Global.getVar("Encoder")
	if enc ~= nil then
		if obj.is_face_down then
			flip = -1
		else
			flip = 1
		end
		scaler = { x = 1, y = 1, z = 1 }
		temp = " Fix Images "
		barSize, fsize, offset_x, offset_y =
			enc.call("APIformatButton", { str = temp, font_size = 90, max_len = 90, xJust = 0, yJust = 0 })
		obj.createButton({
			label = temp,
			click_function = "fixDeck",
			function_owner = self,
			position = {
				(0 + offset_x) * flip * scaler.x,
				0.28 * flip * scaler.z,
				(-1.65 + offset_y) * scaler.y,
			},
			height = 170,
			width = barSize,
			font_size = fSize,
			rotation = { 0, 0, 90 - 90 * flip },
		})
	end
end

function fixDeck(obj, color)
	if obj.type == "Deck" then
		local deck = obj
		for _, card in ipairs(deck.getObjects()) do
			if card.nickname ~= nil and card.nickname ~= "" then
				local count = 1
				local name = card.nickname
				local requestBaseUrl = "https://api.scryfall.com/cards/named?fuzzy="
				local requestUrl = requestBaseUrl .. encodeString(name)
				Wait.time(function()
					WebRequest.get(requestUrl, function(a)
						getDeck(a, count, Player[color])
					end)
				end, 0.01)
			end
		end
	elseif obj.type == "Card" and obj.getName() ~= nil and obj.getName() ~= "" then
		local name = obj.getName()
		local requestBaseUrl = "https://api.scryfall.com/cards/named?fuzzy="
		local requestUrl = requestBaseUrl .. encodeString(name)
		WebRequest.get(requestUrl, function(a)
			objectProccessor(a, Player[color], false)
		end)
	end
end

--PERCENT ENCODING
function encodeChar(chr)
	return string.format("%%%X", string.byte(chr))
end

function encodeString(str)
	local output, t = string.gsub(str, "[^%w]", encodeChar)
	return output
end

-------------------------------- PATCH NOTES -----------------------------------
-- Version currently deployed. Bump this when cutting a new release.
VERSION = "v0.1.3"

local PATCH_NOTES_TAG = "patchNotesButton"
local RELEASES_API = "https://api.github.com/repos/klrmngr/mtg-edh-4player/releases"

-- spawn a clickable tile off to the side of the table (called from onload)
function spawnPatchNotesButton()
	-- remove any leftover patch-notes tile so reloads don't stack duplicates
	for _, obj in ipairs(getAllObjects()) do
		if obj.getGMNotes() == PATCH_NOTES_TAG then
			destroyObject(obj)
		end
	end
	spawnObject({
		type = "BlockSquare",
		position = { -42, 1.1, 0 },
		rotation = { 0, 90, 0 },
		scale = { 1.1, 0.2, 0.9 },
		callback_function = function(obj)
			obj.setName("Patch Notes")
			obj.setGMNotes(PATCH_NOTES_TAG)
			obj.setColorTint({ 0.12, 0.12, 0.14 })
			obj.interactable = false
			-- lock at the spawn position so it can't fall off the table edge
			obj.setLock(true)
			obj.createButton({
				click_function = "showPatchNotes",
				function_owner = self,
				label = VERSION .. "\npatchnotes",
				position = { 0, 0.6, 0 },
				width = 950,
				height = 650,
				font_size = 200,
				color = { 0.95, 0.95, 0.95, 1 },
				font_color = { 0, 0, 0, 1 },
				tooltip = "click to view the patch notes",
			})
		end,
	})
end

-- click handler: fetch every release and show the combined patch notes
function showPatchNotes(obj, color, alt)
	if color == "Grey" then
		return
	end
	WebRequest.get(RELEASES_API, function(req)
		if req.is_error then
			broadcastToColor("Patch notes: couldn't reach GitHub (" .. tostring(req.error) .. ")", color, { 1, 0.4, 0.4 })
			return
		end
		local releases = JSONdecode(req.text)
		if type(releases) ~= "table" then
			broadcastToColor("Patch notes: couldn't parse releases.", color, { 1, 0.4, 0.4 })
			return
		end
		local parts = {}
		for _, rel in ipairs(releases) do
			local tag = rel.tag_name or rel.name or "?"
			local notes = ""
			if type(rel.body) == "string" then
				notes = cleanPatchNotes(rel.body)
			end
			table.insert(parts, "<b>" .. tag .. "</b>\n" .. notes)
		end
		UI.setAttribute("PatchNotesTitle", "text", "Patch Notes")
		UI.setValue("PatchNotesText", table.concat(parts, "\n\n"))
		visibleOpenRules(color, "PatchNotesPanel")
	end)
end

function closePatchNotes(player, value, id)
	visibleCloseRules(player, "PatchNotesPanel")
end

-- turn one release's GitHub-generated body into a clean, readable change list
function cleanPatchNotes(body)
	body = body:gsub("\r", "")
	-- drop the auto-generated sections we don't want
	body = body:gsub("%s*## New Contributors.*", "") -- New Contributors (+ anything after)
	body = body:gsub("%s*%*%*Full Changelog%*%*:.*", "") -- Full Changelog line
	body = body:gsub("## What's Changed%s*", "") -- redundant with the version header
	-- strip the "by @user in <pr-url>" trailer and collapse markdown links to text
	body = body:gsub(" by @%S+ in %S+", "")
	body = body:gsub("%[(.-)%]%((.-)%)", "%1")
	-- markdown -> TTS rich text
	body = body:gsub("%*%*(.-)%*%*", "<b>%1</b>")
	body = body:gsub("## (.-)\n", "<b>%1</b>\n")
	body = body:gsub("\n%s*%* ", "\n• ")
	body = body:gsub("^%* ", "• ")
	-- trim surrounding whitespace
	body = body:gsub("^%s+", ""):gsub("%s+$", "")
	return body
end
--------------------------------------------------------------------------------
-- pie's manual "JSONdecode" for scryfall's api output
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- which fields to extract?
-- these need to be in the order the appear in the json text
normal_card_keys = {
	"object",
	"id",
	"oracle_id",
	"name",
	"printed_name", --for non-EN cards
	"lang",
	"layout",
	"image_uris",
	"mana_cost",
	"cmc",
	"type_line",
	"printed_type_line", --for non-EN cards
	"oracle_text",
	"printed_text", --for non-EN cards
	"loyalty",
	"power",
	"toughness",
	"loyalty",
	"set",
	"collector_number",
}

image_uris_keys = { -- "image_uris":{
	"small",
	"normal",
	"large",
}

related_card_keys = { -- "all_parts":[{"object":"related_card",
	"id",
	"component",
	"name",
	"uri",
}

card_face_keys = { -- "card_faces":[{"object":"card_face",
	"name",
	"printed_name", --for non-EN cards
	"mana_cost",
	"type_line",
	"printed_type_line", --for non-EN cards
	"oracle_text",
	"printed_text", --for non-EN cards
	"power",
	"toughness",
	"loyalty",
	"image_uris",
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function JSONdecode(txt)
	local txtBeginning = txt:sub(1, 16)
	local jsonType = txtBeginning:match('{"object":"(%w+)"')

	-- not scryfall? use normal JSONdecode
	if not (jsonType == "card" or jsonType == "list") then
		return JSON.decode(txt)
	end

	------------------------------------------------------------------------------
	-- parse list: extract each card, and parse it separately
	-- used when one wants to decode a whole list
	if jsonType == "list" then
		local txtBeginning = txt:sub(1, 80)
		local nCards = txtBeginning:match('"total_cards":(%d+)')
		local cardEnd = 0
		local cardDats = {}
		for i = 1, nCards do -- could insert max number cards to parse here
			local cardStart = string.find(txt, '{"object":"card"', cardEnd + 1)
			local cardEnd = findClosingBracket(txt, cardStart)
			local cardDat = JSONdecode(txt:sub(cardStart, cardEnd))
			table.insert(cardDats, cardDat)
		end
		local dat = { object = "list", total_cards = nCards, data = cardDats } --ignoring hast_more...
		return dat
	end

	------------------------------------------------------------------------------
	-- parse card

	txt = txt:gsub("}", ",}") -- comma helps parsing last element in an array

	local cardDat = {}
	local all_parts_i = string.find(txt, '"all_parts":')
	local card_faces_i = string.find(txt, '"card_faces":')

	-- if all_parts exist
	if all_parts_i ~= nil then
		local st = string.find(txt, "%[", all_parts_i)
		local en = findClosingBracket(txt, st)
		local all_parts_txt = txt:sub(all_parts_i, en)
		local all_parts = {}
		-- remove all_parts snip from the main text
		txt = txt:sub(1, all_parts_i - 1) .. txt:sub(en + 2, -1)
		-- parse all_parts_txt for each related_card
		st = 1
		local cardN = 0
		while st ~= nil do
			st = string.find(all_parts_txt, '{"object":"related_card"', st)
			if st ~= nil then
				cardN = cardN + 1
				en = findClosingBracket(all_parts_txt, st)
				local related_card_txt = all_parts_txt:sub(st, en)
				st = en
				local s, e = 1, 1
				local related_card = {}
				for i, key in ipairs(related_card_keys) do
					val, s = getKeyValue(related_card_txt, key, s)
					related_card[key] = val
				end
				table.insert(all_parts, related_card)
				if cardN > 30 then
					break
				end -- avoid inf loop if something goes strange
			end
			cardDat.all_parts = all_parts
		end
	end

	-- if card_faces exist
	if card_faces_i ~= nil then
		local st = string.find(txt, "%[", card_faces_i)
		local en = findClosingBracket(txt, st)
		local card_faces_txt = txt:sub(card_faces_i, en)
		local card_faces = {}
		-- remove card_faces snip from the main text
		txt = txt:sub(1, card_faces_i - 1) .. txt:sub(en + 2, -1)

		-- parse card_faces_txt for each card_face
		st = 1
		local cardN = 0
		while st ~= nil do
			st = string.find(card_faces_txt, '{"object":"card_face"', st)
			if st ~= nil then
				cardN = cardN + 1
				en = findClosingBracket(card_faces_txt, st)
				local card_face_txt = card_faces_txt:sub(st, en)
				st = en
				local s, e = 1, 1
				local card_face = {}
				for i, key in ipairs(card_face_keys) do
					val, s = getKeyValue(card_face_txt, key, s)
					card_face[key] = val
				end
				table.insert(card_faces, card_face)
				if cardN > 4 then
					break
				end -- avoid inf loop if something goes strange
			end
			cardDat.card_faces = card_faces
		end
	end

	-- normal card (or what's left of it after removing card_faces and all_parts)
	st = 1
	for i, key in ipairs(normal_card_keys) do
		val, st = getKeyValue(txt, key, st)
		cardDat[key] = val
	end

	return cardDat
end

--------------------------------------------------------------------------------
-- returns data for one card at a time from a scryfall's "object":"list"
function getNextCardDatFromList(txt, startHere)
	if startHere == nil then
		startHere = 1
	end

	local cardStart = string.find(txt, '{"object":"card"', startHere)
	if cardStart == nil then
		print("error: no more cards in list")
		startHere = nil
		return nil, nil, nil
	end

	local cardEnd = findClosingBracket(txt, cardStart)
	if cardEnd == nil then
		print("error: no more cards in list")
		startHere = nil
		return nil, nil, nil
	end

	-- startHere is not a local variable, so it's possible to just do:
	-- getNextCardFromList(txt) and it will keep giving the next card or nil if there's no more
	startHere = cardEnd + 1

	local cardDat = JSONdecode(txt:sub(cardStart, cardEnd))

	return cardDat, cardStart, cardEnd
end

--------------------------------------------------------------------------------
function findClosingBracket(txt, st) -- find paired {} or []
	local ob, cb = "{", "}"
	local pattern = "[{}]"
	if txt:sub(st, st) == "[" then
		ob, cb = "[", "]"
		pattern = "[%[%]]"
	end
	local txti = st
	local nopen = 1
	while nopen > 0 do
		if txti == nil then
			return nil
		end
		txti = string.find(txt, pattern, txti + 1)
		if txt:sub(txti, txti) == ob then
			nopen = nopen + 1
		elseif txt:sub(txti, txti) == cb then
			nopen = nopen - 1
		end
	end
	return txti
end

--------------------------------------------------------------------------------
function getKeyValue(txt, key, st)
	local str = '"' .. key .. '":'
	local st = string.find(txt, str, st)
	local en = nil
	local value = nil
	if st ~= nil then
		if key == "image_uris" then -- special case for scryfall's image_uris table
			value = {}
			local s = st
			for i, k in ipairs(image_uris_keys) do
				local val, s = getKeyValue(txt, k, s)
				value[k] = val
			end
			en = s
		elseif txt:sub(st + #str, st + #str) ~= '"' then -- not a string
			en = string.find(txt, ',"', st + #str + 1)
			value = tonumber(txt:sub(st + #str, en - 1))
		else -- a string
			en = string.find(txt, '",', st + #str + 1)
			value = txt:sub(st + #str + 1, en - 1):gsub('\\"', '"'):gsub("\\n", "\n"):gsub("(\\u....)", "")
		end
	end
	if type(value) == "string" then
		value = value:gsub(",}", "}") -- get rid of the previously inserted comma
	end
	return value, en
end
