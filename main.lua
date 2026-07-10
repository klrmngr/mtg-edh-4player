-- Main functionality
function onload(saved)
	restoreSettings(saved)
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
	gravFor = -4.14

	spawnPatchNotesButton()
	checkForUpdate()
	spawnLandTrackerText()
	initFetchlands()
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

	-- dedicated land scripting zone on each playmat (where lands are played)
	data["White"]["landZone"] = getObjectFromGUID("c24ef0")
	data["Red"]["landZone"] = getObjectFromGUID("772714")
	data["Yellow"]["landZone"] = getObjectFromGUID("00f87d")
	data["Blue"]["landZone"] = getObjectFromGUID("e63cad")

	-- command-zone scripting zones (one per player), used by the reset button to
	-- snapshot/restore commanders
	data["White"]["commandZone"] = getObjectFromGUID("8fc485")
	data["Red"]["commandZone"] = getObjectFromGUID("750cd5")
	data["Yellow"]["commandZone"] = getObjectFromGUID("c451cd")
	data["Blue"]["commandZone"] = getObjectFromGUID("879cc5")

	-- exile scripting zones (one per player); the reset button clears these too
	data["White"]["exileZone"] = getObjectFromGUID("d614cb")
	data["Red"]["exileZone"] = getObjectFromGUID("878032")
	data["Yellow"]["exileZone"] = getObjectFromGUID("ee5024")
	data["Blue"]["exileZone"] = getObjectFromGUID("bc8e3c")

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

	-- life trackers identify their owner via their Description (a colour name)
	for _, guid in ipairs({ "23e485", "37e533", "395037", "448880" }) do
		local tracker = getObjectFromGUID(guid)
		if tracker ~= nil then
			local owner = tracker.getDescription()
			if data[owner] ~= nil then
				data[owner]["lifeTracker"] = tracker
			end
		end
	end

	-- Commander-damage trackers grouped by the player who *receives* the damage.
	-- A tracker's Description is its *source* colour (the dealer), not the
	-- recipient -- a player's own board holds one tracker per opponent, so the
	-- recipient is the colour missing from that cluster. The GUID lists below
	-- capture that recipient -> trackers mapping.
	data["White"]["commanderDamage"] = { "0f6598", "6b6e1f", "b748df" }
	data["Red"]["commanderDamage"] = { "4bfa09", "95eb63", "d5907a" }
	data["Yellow"]["commanderDamage"] = { "45331a", "484c38", "906d4b" }
	data["Blue"]["commanderDamage"] = { "8d172a", "bfcf4a", "f43e61" }
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
	-- (the Etali button is no longer here -- it spawns under the command zone only
	-- when a player starts a game with Etali, Primal Conqueror as their commander;
	-- see etali.lua)
	-- reset button, directly under the mulligan counter (z = 1.4)
	object.createButton({
		click_function = "playerReset",
		label = "Reset",
		tooltip = "              [b]Reset Board[/b]\n[i]double-click[/i] to restore your library,\n   board, and commander to game start",
		width = 2500,
		height = 700,
		position = { 0, 0.1, 2.8 },
		font_size = 250,
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
		-- anchor on the dedicated exile zone so placement survives zone rotation
		local zone = data[ply]["exileZone"]
		local rot = gr.getRotation()
		rot.z = 0
		rot.y = zone.getRotation().y
		local pos = zone.getPosition()
		pos[2] = 3
		gr.setRotationSmooth(rot, false, true)
		gr.setPositionSmooth(pos, false, true)
	end, 1)
end

------------------------------------ REVEAL ------------------------------------
-- world position of the n-th card (0-based) in the fanned-reveal layout above
-- ply's library, and the matching face-up rotation. The library zone was rotated
-- ~180°, so the offsets are negated and the card facing drops the old +180.
-- Shared by the reveal buttons and the Ral abilities.
function revealFanPos(ply, n)
	local libZone = data[ply]["libraryZone"]
	local nUp = math.floor(n / revealNrow)
	local nSide = n - nUp * revealNrow
	local forw = libZone.getTransformForward()
	local righ = libZone.getTransformRight()
	return libZone.getPosition()
		+ forw:scale(-(revealUp + revealUpS * nUp))
		+ righ:scale(-deckDirs[ply] * 2.25 * (nSide + revealRi))
end

function revealFanRot(ply)
	local rot = data[ply]["libraryZone"].getRotation()
	rot[3] = 0
	return rot
end

function revealFan(button, ply, alt)
	if button ~= data[ply]["revealButton"] then
		warnNotYours(button, ply)
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
	if now - lastT > getSetting(ply, "revealResetSecs") then
		nRevealed = 0
		revealedCMC = revealedCMC or {}
		revealedCMC[ply] = 0
	end
	button.memo = tostring(now)
	local pos = revealFanPos(ply, nRevealed)
	local rot = revealFanRot(ply)
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
		warnNotYours(button, ply)
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
	if now - lastT > getSetting(ply, "revealResetSecs") then
		nRevealed = 0
		revealedCMC = revealedCMC or {}
		revealedCMC[ply] = 0
	end
	button.memo = tostring(now)
	-- as in revealFan: the library zone was rotated ~180°, so negate the side
	-- offset and drop the old +180 on the card facing
	local righ = libZone.getTransformRight()
	local pos = libZone.getPosition() + vector(0, 2, 0) + righ:scale(-deckDirs[ply] * 2.4)
	local rot = libZone.getRotation()
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
		-- deal goblin sticker cards if their commander is "_____ Goblin" (once)
		refreshGoblinStickers(color)
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
			-- re-arm goblin stickers so the next opening hand re-deals (manual reset
			-- only -- the inactivity timer must not wipe stickers mid-game)
			data[ownerColor]["goblinStickersDealt"] = nil
			return
		end
		-- left-click: only the owning player may mulligan their own hand
		if playerColor ~= ownerColor then
			warnNotYours(button, playerColor)
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
		warnNotYours(button, playerColor)
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

	-- there must actually be a Serum Powder card in hand to powder
	local hasPowder = false
	for _, card in ipairs(cards) do
		if mainCardName(card.getName()):lower() == "serum powder" then
			hasPowder = true
			break
		end
	end
	if not hasPowder then
		Player[playerColor].broadcast("Serum Powder: no Serum Powder card in your hand.")
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

----------------------------------- BOARD RESET ----------------------------------
-- A per-player "Reset" button (under the mulligan count) restores that player's
-- board to its game-start state. At the opening hand (the first mulligan bump,
-- detected the same way mulligans are) we snapshot the full library deck and the
-- command zone. Double-clicking Reset destroys that player's Card/Deck objects
-- across their library, hand, battlefield (playmat), graveyard, command zone, and
-- exile, then respawns the snapshot deck + commander(s) and re-shuffles the
-- library. It also restores the player's life to 40 and zeroes the commander
-- damage they've taken from each colour.
--
-- Limitations: cards sitting outside every tracked zone (loose on the table, or
-- taken by another player) and token creatures (Custom_Token) are not destroyed.

resetDoubleClickSecs = 0.5
-- take the game-start snapshot for a player. Called from bumpMulliganCount on
-- each fresh opening hand (count at 0), while the library is still complete. This
-- clone is the single source of truth for both the board reset and the
-- clone-sourced fetch previews (see fetchland.lua).
--
-- Without force, an existing snapshot is kept. Even with force we refuse to
-- overwrite a fuller clone with a smaller (mid-game / degraded) library: a fresh
-- opening hand drawn after cards have been deleted must NOT replace the complete
-- game-start deck, or a later reset would restore an incomplete deck. A genuinely
-- new game restores every card to the library first, so its count matches (or
-- exceeds) the old clone and overwrites as expected.
function captureResetSnapshot(color, force)
	if data[color] == nil then
		return
	end
	local existing = data[color]["resetSnapshot"]
	if existing ~= nil and not force then
		return
	end
	-- the full library deck, before the opening hand is drawn
	local deck = getDeckFromZone(data[color]["libraryZone"])
	if deck == nil then
		return -- no deck to clone right now; keep any existing snapshot
	end
	local deckData = deck.getData()
	local deckCount = deckData.ContainedObjects and #deckData.ContainedObjects or 0
	-- don't degrade a good clone with a smaller library (deleted cards mid-game)
	if existing ~= nil and existing.deckCount ~= nil and deckCount < existing.deckCount then
		return
	end
	local snap = { commanders = {}, deckData = deckData, deckCount = deckCount }
	-- whatever is sitting in the command zone (commander, partner, ...)
	local cz = data[color]["commandZone"]
	if cz ~= nil then
		for _, obj in ipairs(cz.getObjects()) do
			if obj.type == "Card" or obj.type == "Deck" then
				table.insert(snap.commanders, obj.getData())
			end
		end
	end
	data[color]["resetSnapshot"] = snap
end

-- button handler: owner-only, double-click to confirm
function playerReset(button, color, alt)
	local ownerColor = nil
	for c, pdata in pairs(data) do
		if button == pdata["mulliganButton"] then
			ownerColor = c
			break
		end
	end
	if ownerColor == nil or color ~= ownerColor then
		warnNotYours(button, color)
		return
	end
	if isDoubleClick("reset_" .. ownerColor, resetDoubleClickSecs) then
		doBoardReset(ownerColor)
	else
		Player[color].broadcast("Double-click Reset to restore your board to its game-start state.")
	end
end

-- destroy the player's cards across their tracked areas, then respawn the snapshot
function doBoardReset(color)
	local snap = data[color] and data[color]["resetSnapshot"]
	if snap == nil then
		Player[color].broadcast("Reset: no game-start snapshot yet -- draw your opening hand first.")
		return
	end

	-- clear fetch previews + land-tracker state for this player up front, while
	-- the soon-to-be-destroyed lands are still in their zone
	local lz = data[color]["landZone"]
	if lz ~= nil then
		for _, obj in ipairs(lz.getObjects()) do
			clearFetchPreviews(obj.getGUID())
		end
	end
	landsEnteredThisTurn[color] = {}
	refreshLandTrackerText(color)

	-- 1. destroy this player's Card/Deck objects across their areas
	local seen = {}
	local function wipe(objs)
		for _, obj in ipairs(objs) do
			if obj ~= nil and (obj.type == "Card" or obj.type == "Deck") and not seen[obj.getGUID()] then
				seen[obj.getGUID()] = true
				pcall(function()
					destroyObject(obj)
				end)
			end
		end
	end
	for _, zone in ipairs({
		data[color]["libraryZone"],
		data[color]["graveyard"],
		data[color]["playmat"],
		data[color]["commandZone"],
		data[color]["exileZone"],
	}) do
		if zone ~= nil then
			wipe(zone.getObjects())
		end
	end
	wipe(Player[color].getHandObjects(1))

	-- 2. respawn the snapshot deck + commanders at their captured transforms
	if snap.deckData ~= nil then
		spawnObjectData({ data = snap.deckData })
	end
	for _, cdata in ipairs(snap.commanders or {}) do
		spawnObjectData({ data = cdata })
	end

	-- 3. re-shuffle the freshly spawned library once it settles
	Wait.time(function()
		local deck = getDeckFromZone(data[color]["libraryZone"])
		if deck ~= nil then
			pcall(function()
				deck.shuffle()
			end)
		end
	end, 1)

	-- 4. restore life to 40 and zero the commander damage taken from each colour
	resetLifeAndCommanderDamage(color)

	-- 5. reset the mulligan counter back to 0
	resetMulliganCount(color)

	Player[color].broadcast("Board reset to game-start state.")
end

-- restore a player's life to 40 and reset every Commander Damage tracker that
-- records damage dealt *to* them (one per opposing colour) back to 0
function resetLifeAndCommanderDamage(color)
	local tracker = data[color] and data[color]["lifeTracker"]
	if tracker ~= nil then
		pcall(function()
			tracker.call("resetLife")
		end)
	end

	local trackers = data[color] and data[color]["commanderDamage"]
	if trackers ~= nil then
		for _, guid in ipairs(trackers) do
			local obj = getObjectFromGUID(guid)
			if obj ~= nil then
				pcall(function()
					obj.call("reset_val")
				end)
			end
		end
	end
end

-- Called by a Commander Damage tracker when its value changes (clicks or typed
-- input). Find the player whose board that tracker belongs to and apply the
-- change to their life: a positive delta is damage taken (lose that much life),
-- a negative delta is a correction (gain it back). Tracker resets don't call
-- this, so a board reset's separate life-to-40 step isn't double-counted.
function commanderDamageDealt(params)
	if params == nil or params.guid == nil or params.delta == nil then
		return
	end
	for color, pdata in pairs(data) do
		local trackers = pdata["commanderDamage"]
		if trackers ~= nil then
			for _, guid in ipairs(trackers) do
				if guid == params.guid then
					loseLife(color, params.delta, "commander damage")
					return
				end
			end
		end
	end
end
-------------------------- COMMAND-ZONE COMMANDER BUTTONS -----------------------
-- Shared machinery for per-player buttons that appear on a command-zone scripting
-- zone when a specific commander is detected there at game start (see
-- bumpMulliganCount). Used by the Etali trigger and the Ral coin-flip features.
--
-- A button lives directly on the command-zone scripting zone so it renders as
-- floating white text with no tile, counter-scaled by the zone's scale so it
-- isn't stretched, on a table-level point behind the zone.

-- The command-zone scripting zone is a ~3-unit-tall box, so its centre sits ~1.5
-- above the table. We aim at a world point on the table, behind the zone, then
-- convert it into the zone's local space. Flip czButtonBehind's sign if "behind"
-- comes out as "in front".
czButtonDrop = 1.5 -- world units down from the zone centre to the table
czButtonLift = 0.05 -- small lift so the text sits just above the table
czButtonBehind = 2.5 -- world units behind the zone, along its forward axis

-- a TTS card name carries its type line on following newlines (e.g.
-- "Etali, Primal Conqueror\nLegendary Creature ..."), so match only the first line
function commanderNameMatches(name, target)
	if name == nil then
		return false
	end
	local firstLine = tostring(name):match("^[^\r\n]*") or ""
	return firstLine == target
end

-- does this player's command zone currently hold a commander with this name?
-- handles a lone commander card as well as a stacked deck (e.g. partners)
function commandZoneHasCommander(color, name)
	local cz = data[color] and data[color]["commandZone"]
	if cz == nil then
		return false
	end
	for _, obj in ipairs(cz.getObjects()) do
		if obj.type == "Card" then
			if commanderNameMatches(obj.getName(), name) then
				return true
			end
		elseif obj.type == "Deck" then
			for _, c in ipairs(obj.getObjects()) do
				if commanderNameMatches(c.name, name) then
					return true
				end
			end
		end
	end
	return false
end

-- attach a button to the player's command-zone scripting zone, at the standard
-- spot. opts = { click_function, label, tooltip, right, forward } where right and
-- forward are optional world-unit offsets from the standard spot (for grids)
function addCommandZoneButton(color, opts)
	local cz = data[color] and data[color]["commandZone"]
	if cz == nil then
		return
	end
	-- aim at a point on the table behind the zone (plus any grid offset), then
	-- convert to the zone's local space (positionToLocal handles rotation/scale)
	local world = cz.getPosition()
		+ cz.getTransformForward():scale(czButtonBehind + (opts.forward or 0))
		+ cz.getTransformRight():scale(opts.right or 0)
	world.y = world.y - czButtonDrop + czButtonLift
	local lp = cz.positionToLocal(world)
	-- counter-scale the button by the zone scale so the text renders un-stretched
	local s = cz.getScale()
	cz.createButton({
		click_function = opts.click_function,
		function_owner = self,
		label = opts.label,
		tooltip = opts.tooltip,
		position = { lp.x, lp.y, lp.z },
		scale = { 1 / s.x, 1 / s.y, 1 / s.z },
		width = opts.width or 2000,
		height = opts.height or 500,
		font_size = opts.font_size or 250,
		color = { 1, 1, 1, 0 },
		font_color = { 1, 1, 1, 100 },
		hover_color = { 1, 1, 1, 0.1 },
		press_color = { 1, 0, 0, 0.2 },
	})
end

-- remove any button(s) with this click_function from the player's command zone
function removeCommandZoneButton(color, clickFn)
	local cz = data[color] and data[color]["commandZone"]
	if cz == nil then
		return
	end
	local buttons = cz.getButtons()
	if buttons == nil then
		return
	end
	-- collect matching indices, then remove high-to-low so indices don't shift
	local indices = {}
	for _, b in ipairs(buttons) do
		if b.click_function == clickFn then
			table.insert(indices, b.index)
		end
	end
	table.sort(indices, function(a, b)
		return a > b
	end)
	for _, idx in ipairs(indices) do
		cz.removeButton(idx)
	end
end

-- set the label of the command-zone button(s) with this click_function
function setCommandZoneButtonLabel(color, clickFn, label)
	local cz = data[color] and data[color]["commandZone"]
	if cz == nil then
		return
	end
	for _, b in ipairs(cz.getButtons() or {}) do
		if b.click_function == clickFn then
			cz.editButton({ index = b.index, label = label })
		end
	end
end

-- map a command-zone object back to its owner colour
function commandZoneOwnerOf(obj)
	for color, pdata in pairs(data) do
		if pdata["commandZone"] == obj then
			return color
		end
	end
	return nil
end
------------------------------------ ETALI -------------------------------------
-- "Etali, Primal Conqueror" gets a per-owner "Etali Trigger" button. It is NOT on
-- the table by default: when a game starts (the opening-hand snapshot -- see
-- reset.lua / bumpMulliganCount) we check that player's command zone, and if their
-- commander is Etali we attach the button there (see command_buttons.lua for the
-- shared placement/detection). It persists until the next game start at which the
-- player no longer has Etali.
--
-- Clicking it reveals the top of every player's library until a nonland is hit:
-- each land revealed goes to that player's exile, and the first nonland from each
-- deck is placed in front of the owner. Land detection reuses cardIsLand.

ETALI_COMMANDER_NAME = "Etali, Primal Conqueror"

-- game-start hook: the Etali button should be present iff the player has the
-- Etali commander in their command zone at this moment. Clear first so a reload
-- (where the zone may keep a stale button) can't leave a duplicate.
function refreshEtaliButton(color)
	if data[color] == nil then
		return
	end
	removeCommandZoneButton(color, "playerEtali")
	if getSetting(color, "commanderQOL") and commandZoneHasCommander(color, ETALI_COMMANDER_NAME) then
		addCommandZoneButton(color, {
			click_function = "playerEtali",
			label = "Etali Trigger",
			tooltip = "                  [b]Etali[/b]\nreveal each library until a nonland:\n  lands go to that player's exile,\n  the nonland comes to you",
		})
	end
end

-- button handler: only the owning player may activate their Etali. Reveal the
-- top of every player's library until a nonland is hit -- each land goes to that
-- player's exile, the first nonland from each deck is placed in front of the
-- owner. Land detection reuses the cascade "-1" CMC sentinel (see getCMC).
function playerEtali(obj, clickerColor, alt)
	local ownerColor = commandZoneOwnerOf(obj)
	if ownerColor == nil then
		return
	end
	if clickerColor ~= ownerColor then
		Player[clickerColor].broadcast("Only " .. ownerColor .. " may activate this Etali.")
		return
	end
	if etaliRunning then
		return
	end
	etaliRunning = true
	Wait.time(function()
		etaliRunning = false
	end, 3)

	etaliPlaced = 0
	-- clear glows from any earlier trigger, and remember whose turn this glow
	-- belongs to so it can be cleared when *that* player's turn ends
	clearEtaliGlows()
	etaliTriggerColor = ownerColor
	Player[ownerColor].broadcast("Etali: revealing each library until a nonland", ownerColor)
	for color, _ in pairs(data) do
		etaliRevealNext(color, ownerColor)
	end
end

-- pull the top card of ownerColor's library and route it (land -> exile,
-- nonland -> in front of the clicker, and stop revealing that deck)
function etaliRevealNext(ownerColor, clickerColor)
	local card = getCardFromZone(data[ownerColor]["libraryZone"])
	if card == nil then
		return -- empty library
	end
	Wait.condition(function()
		local isLand = cardIsLand(card)
		if isLand then
			etaliExile(ownerColor, card)
			Wait.time(function()
				etaliRevealNext(ownerColor, clickerColor)
			end, 0.45)
		else
			etaliPlaceNonland(clickerColor, ownerColor, card)
		end
	end, function()
		return not card.spawning
	end)
end

-- how far above the playmat (toward table centre) the etali cards are staged
etaliAbove = -12.5

-- cards lit by the current Etali trigger, and the colour of the player who
-- triggered it. The glow lasts until that player's own turn ends (see
-- maybeClearEtaliGlows, called from onPlayerTurnStart).
etaliGlowingCards = {}
etaliTriggerColor = nil

-- glow a card in its owner's colour until the turn ends, tracking it for cleanup
function etaliGlow(card, ownerColor)
	card.highlightOn(stringColorToRGB(ownerColor))
	table.insert(etaliGlowingCards, card)
end

-- turn off every Etali glow now
function clearEtaliGlows()
	for _, card in ipairs(etaliGlowingCards) do
		if card ~= nil then
			pcall(function()
				card.highlightOff()
			end)
		end
	end
	etaliGlowingCards = {}
	etaliTriggerColor = nil
end

-- clear the glow only when the player who triggered Etali has just ended their
-- turn (not on every player's turn in the cycle)
function maybeClearEtaliGlows(endedColor)
	if etaliTriggerColor ~= nil and endedColor == etaliTriggerColor then
		clearEtaliGlows()
	end
end

-- send a revealed land to its owner's dedicated exile zone (anchoring to that
-- zone's position keeps it correct no matter how the zones are rotated) and glow
-- it in the owner's colour so everyone can see whose card moved
function etaliExile(ownerColor, card)
	local zone = data[ownerColor]["exileZone"]
	local rot = card.getRotation()
	rot.z = 0
	rot.y = zone.getRotation().y
	local pos = zone.getPosition()
	pos.y = 3
	card.setRotationSmooth(rot, false, true)
	card.setPositionSmooth(pos, false, true)
	etaliGlow(card, ownerColor)
end

-- place a revealed nonland face up in a row above the clicking player's mat,
-- glowing in the card owner's colour so everyone can see whose card moved
function etaliPlaceNonland(clickerColor, ownerColor, card)
	local mat = data[clickerColor]["playmat"]
	local i = etaliPlaced or 0
	etaliPlaced = i + 1
	local pos = mat.getPosition()
		+ mat.getTransformRight():scale((i - 1.5) * 3)
		+ mat.getTransformForward():scale(etaliAbove)
	pos.y = 3
	card.setRotationSmooth({ 0, mat.getRotation().y, 0 }, false, true)
	card.setPositionSmooth(pos, false, true)
	etaliGlow(card, ownerColor)
end
------------------------------------- RAL --------------------------------------
-- "Ral, Monsoon Mage" gets a small button cluster by the command zone, present
-- only when a game starts with Ral in the command zone (see command_buttons.lua)
-- and cleared at the next game start without Ral.
--
-- Top row = two clickable counters (Strm = storm, Ral = instants/sorceries cast),
-- centred over the bottom row of three ability buttons (flip + two placeholders).
-- Counters left-click +1, right-click -1, clamped at 0, like commander tax but in
-- steps of one.

RAL_COMMANDER_NAME = "Ral, Monsoon Mage"

-- layout (tune to taste). Columns are spaced along the zone's right axis, rows
-- along its forward axis.
ralColGap = 1.7 -- horizontal gap between adjacent columns (world units)
ralRowOffset = 0.4 -- half the vertical gap between the two rows
ralButtonWidth = 900
ralButtonHeight = 425
ralButtonFont = 210

-- the bottom-row ability buttons (left to right). flip works; rest are placeholders.
ralAbilities = {
	{
		click_function = "playerCoinFlip",
		label = "flip",
		tooltip = "                  [b]Ral, Monsoon Mage[/b]\n[i]left click[/i] to flip a coin",
	},
	{
		click_function = "playerRalUlt",
		label = "ult",
		tooltip = "                  [b]Ral ultimate[/b]\nexile the top 8 of your library;\ninstants & sorceries go to a row\non top of your board",
	},
	{
		click_function = "playerPif",
		label = "pif",
		tooltip = "                  [b]Past in Flames[/b]\nmove instants & sorceries from your\ngraveyard to a row on top of your board\n(flashback)",
	},
}

-- the top-row counters (left to right: storm, instants/sorceries)
ralCounterDefs = {
	{ key = "storm", name = "Strm", click_function = "ralStormCounter" },
	{ key = "spells", name = "Ral", click_function = "ralSpellCounter" },
}

-- per-color counter values, (re)set to zero whenever the grid is spawned
ralCounts = {}

-- cards staged by the ult (freecast) and pif (flashback) this turn, per color, so
-- they can be resolved when that player's turn ends (see ralEndOfTurnCleanup)
ralFreecastCards = {}
ralFlashbackCards = {}

-- game-start hook: present the Ral grid iff the player has Ral in their command
-- zone right now. Clear first so a reload can't leave duplicates.
function refreshRalButton(color)
	if data[color] == nil then
		return
	end
	-- clear every Ral button (abilities + counters) so a reload can't duplicate them
	for _, b in ipairs(ralAbilities) do
		removeCommandZoneButton(color, b.click_function)
	end
	for _, def in ipairs(ralCounterDefs) do
		removeCommandZoneButton(color, def.click_function)
	end
	if not getSetting(color, "commanderQOL") or not commandZoneHasCommander(color, RAL_COMMANDER_NAME) then
		return
	end
	ralCounts[color] = { storm = 0, spells = 0 }
	addRalGrid(color)
end

-- place the cluster: top row = two counters (centred), bottom row = three
-- abilities. The zone's forward axis is inverted here (the cluster is built under
-- the zone), so the top row uses -ralRowOffset and the bottom row +ralRowOffset.
function addRalGrid(color)
	-- top row: the two counters, centred over the three abilities below
	local counterCols = { -ralColGap / 2, ralColGap / 2 }
	for i, def in ipairs(ralCounterDefs) do
		addCommandZoneButton(color, {
			click_function = def.click_function,
			label = def.name .. ": " .. ralCounts[color][def.key],
			tooltip = def.name .. " -- [i]left click[/i] +1, [i]right click[/i] -1",
			right = counterCols[i],
			forward = -ralRowOffset,
			width = ralButtonWidth,
			height = ralButtonHeight,
			font_size = ralButtonFont,
		})
	end
	-- bottom row: the three ability buttons, centred on the zone
	local abilityCols = { -ralColGap, 0, ralColGap }
	for i, b in ipairs(ralAbilities) do
		addCommandZoneButton(color, {
			click_function = b.click_function,
			label = b.label,
			tooltip = b.tooltip,
			right = abilityCols[i],
			forward = ralRowOffset,
			width = ralButtonWidth,
			height = ralButtonHeight,
			font_size = ralButtonFont,
		})
	end
end

-- bump a counter by delta (clamped at 0) and refresh its label
function ralBump(color, def, delta)
	if ralCounts[color] == nil then
		return
	end
	ralCounts[color][def.key] = math.max(0, ralCounts[color][def.key] + delta)
	setCommandZoneButtonLabel(color, def.click_function, def.name .. ": " .. ralCounts[color][def.key])
end

-- adjust one counter (+1 left click, -1 right click, clamped at 0) and refresh
-- its label. Like commander tax, anyone at the table may click it.
function ralAdjustCounter(obj, alt, def)
	local owner = commandZoneOwnerOf(obj)
	if owner == nil then
		return
	end
	ralBump(owner, def, alt and -1 or 1)
end

function ralStormCounter(obj, color, alt)
	ralAdjustCounter(obj, alt, ralCounterDefs[1])
end

-- the instants/sorceries counter also feeds storm, so adjust both by the same step
function ralSpellCounter(obj, color, alt)
	local owner = commandZoneOwnerOf(obj)
	if owner == nil then
		return
	end
	local delta = alt and -1 or 1
	ralBump(owner, ralCounterDefs[2], delta) -- instants/sorceries
	ralBump(owner, ralCounterDefs[1], delta) -- also bump storm
end

-- placeholder Ral abilities -- no-op until they're implemented
function ralPlaceholder() end

-- button handler: only the owning player may flip. Every flip bumps both counters
-- by 1; a tails also costs the flipper 1 life. Announce the result to the table.
function playerCoinFlip(obj, clickerColor, alt)
	local ownerColor = commandZoneOwnerOf(obj)
	if ownerColor == nil then
		return
	end
	if clickerColor ~= ownerColor then
		Player[clickerColor].broadcast("Only " .. ownerColor .. " may flip this coin.")
		return
	end
	-- every flip counts toward storm and instants/sorceries cast
	ralBump(ownerColor, ralCounterDefs[1], 1)
	ralBump(ownerColor, ralCounterDefs[2], 1)
	if math.random(2) == 1 then
		broadcastToAll(ownerColor .. " flips a coin: Heads", stringColorToRGB(ownerColor))
	else
		loseLife(ownerColor, 1, "coin flip") -- tails: the flipper loses 1 life
		broadcastToAll(ownerColor .. " flips a coin: Tails (-1 life)", stringColorToRGB(ownerColor))
	end
end

-------------------------------- RAL ULTIMATE ----------------------------------
-- Exile the top 8 cards of the owner's library: instants & sorceries go into a
-- row on top of their board, everything else into their exile zone.
ralUltCount = 8
ralUltNote = "free to play until end of turn (ral ult)" -- written to each spell's π Notepad
ralPifNote = "flashback (past in flames)" -- ditto, for Past in Flames

-- button handler: owner-only, guarded against double-fire while cards animate
function playerRalUlt(obj, clickerColor, alt)
	local owner = commandZoneOwnerOf(obj)
	if owner == nil then
		return
	end
	if clickerColor ~= owner then
		Player[clickerColor].broadcast("Only " .. owner .. " may use Ral's ultimate.")
		return
	end
	if ralUltRunning then
		return
	end
	ralUltRunning = true
	Wait.time(function()
		ralUltRunning = false
	end, 3)
	ralUltPlaced = 0
	ralFreecastCards[owner] = ralFreecastCards[owner] or {}
	Player[owner].broadcast("Ral ultimate: exiling the top " .. ralUltCount .. " of your library", owner)
	ralUltNext(owner, ralUltCount)
end

-- pull the next top card and route it (instant/sorcery -> board row, else exile),
-- then continue until the requested count is reached or the library is empty
function ralUltNext(color, remaining)
	if remaining <= 0 then
		return
	end
	local card = getCardFromZone(data[color]["libraryZone"])
	if card == nil then
		return -- empty library
	end
	Wait.condition(function()
		if cardIsInstantOrSorcery(card) then
			ralPlaceSpell(color, card, ralUltNote)
		else
			ralUltExile(color, card)
		end
		Wait.time(function()
			ralUltNext(color, remaining - 1)
		end, 0.35)
	end, function()
		return not card.spawning
	end)
end

-- lay an instant/sorcery into the fanned-reveal layout above the library (same
-- placement the reveal buttons use) and tag it with the given π Notepad note
function ralPlaceSpell(color, card, note)
	local i = ralUltPlaced or 0
	ralUltPlaced = i + 1
	local pos = revealFanPos(color, i)
	checkPosMove(pos, data[color]["libraryZone"])
	card.setPositionSmooth(pos, false, true)
	card.setRotationSmooth(revealFanRot(color), false, true)
	setCardNotepad(card, note)
	-- track for end-of-turn resolution
	if note == ralUltNote then
		table.insert(ralFreecastCards[color], card)
	elseif note == ralPifNote then
		table.insert(ralFlashbackCards[color], card)
	end
end

-- send everything else to the owner's dedicated exile zone (cf. etaliExile)
function ralUltExile(color, card)
	moveCardToZone(card, data[color]["exileZone"])
end

-- drop a card face up at a zone's position (rotation-proof, like etaliExile)
function moveCardToZone(card, zone)
	if card == nil or zone == nil then
		return
	end
	local rot = card.getRotation()
	rot.z = 0
	rot.y = zone.getRotation().y
	local pos = zone.getPosition()
	pos.y = 3
	card.setRotationSmooth(rot, false, true)
	card.setPositionSmooth(pos, false, true)
end

-- is this card currently a loose object inside the given scripting zone?
function cardInZone(card, zone)
	if card == nil or zone == nil then
		return false
	end
	for _, o in ipairs(zone.getObjects()) do
		if o == card then
			return true
		end
	end
	return false
end

------------------------- RAL END-OF-TURN RESOLUTION ---------------------------
-- When the Ral player's turn ends: clear the π note on every card we staged this
-- turn, then send uncast flashback (pif) cards that aren't in exile to the
-- graveyard, and uncast freecast (ult) cards that aren't in the graveyard to exile.
function ralEndOfTurnCleanup(color)
	if data[color] == nil then
		return
	end
	-- flashback cards stay if already exiled, otherwise return to the graveyard
	resolveRalCards(ralFlashbackCards[color], data[color]["exileZone"], data[color]["graveyard"])
	-- freecast cards stay if already in the graveyard, otherwise stay exiled
	resolveRalCards(ralFreecastCards[color], data[color]["graveyard"], data[color]["exileZone"])
	ralFlashbackCards[color] = {}
	ralFreecastCards[color] = {}
	-- reset this turn's storm / instants-sorceries counters too
	if ralCounts[color] ~= nil then
		ralCounts[color] = { storm = 0, spells = 0 }
		for _, def in ipairs(ralCounterDefs) do
			setCommandZoneButtonLabel(color, def.click_function, def.name .. ": 0")
		end
	end
end

-- clear each card's note, then move it to destZone unless it's already in keepZone
function resolveRalCards(cards, keepZone, destZone)
	for _, card in ipairs(cards or {}) do
		pcall(function()
			if card == nil then
				return
			end
			setCardNotepad(card, "")
			if not cardInZone(card, keepZone) then
				moveCardToZone(card, destZone)
			end
		end)
	end
end

----------------------------- PAST IN FLAMES (pif) -----------------------------
-- Move every instant/sorcery in the owner's graveyard to the spell row (same spot
-- as the ult), tagged "flashback". Nothing is exiled; non-spells stay put.
function playerPif(obj, clickerColor, alt)
	local owner = commandZoneOwnerOf(obj)
	if owner == nil then
		return
	end
	if clickerColor ~= owner then
		Player[clickerColor].broadcast("Only " .. owner .. " may use Past in Flames.")
		return
	end
	if ralPifRunning then
		return
	end
	ralPifRunning = true
	Wait.time(function()
		ralPifRunning = false
	end, 3)
	ralUltPlaced = 0
	ralFlashbackCards[owner] = ralFlashbackCards[owner] or {}

	local gy = data[owner] and data[owner]["graveyard"]
	if gy == nil then
		return
	end
	-- build a queue of "pullers"; each returns one instant/sorcery card object,
	-- whether it is loose in the graveyard or stacked inside a deck there
	local queue = {}
	for _, o in ipairs(gy.getObjects()) do
		if o.type == "Card" then
			if cardIsInstantOrSorcery(o) then
				table.insert(queue, function()
					return o
				end)
			end
		elseif o.type == "Deck" then
			for _, e in ipairs(o.getObjects()) do
				if nameIsInstantOrSorcery(e.name) then
					table.insert(queue, function()
						local ok, card = pcall(function()
							return o.takeObject({ guid = e.guid, smooth = false })
						end)
						return ok and card or nil
					end)
				end
			end
		end
	end

	if #queue == 0 then
		Player[owner].broadcast("Past in Flames: no instants or sorceries in your graveyard.", owner)
		return
	end
	Player[owner].broadcast("Past in Flames: flashback for your graveyard instants & sorceries", owner)
	pifNext(owner, queue, 1)
end

-- process the queue one card at a time, waiting for each to settle before the next
function pifNext(color, queue, idx)
	if idx > #queue then
		return
	end
	local card = queue[idx]()
	if card == nil then
		pifNext(color, queue, idx + 1)
		return
	end
	Wait.condition(function()
		ralPlaceSpell(color, card, ralPifNote)
		Wait.time(function()
			pifNext(color, queue, idx + 1)
		end, 0.35)
	end, function()
		return not card.spawning
	end)
end
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
--------------------------------- LAND TRACKER ---------------------------------
-- Per-player land / mana display. This will eventually replace the standalone
-- Land_Zone_Manager object. For now it renders text anchored to each player's
-- playmat zone (same spot the old manager used) and tracks the lands that have
-- entered each player's land zone this turn.
--
-- "A land entering the battlefield this turn" = a land card (see cardIsLand) that
-- enters that player's landZone and was NOT in the landZone when their turn
-- began. The lands' names are listed in the display.

-- screen-space placement copied from the old Land_Zone_Manager.createButtons
landTrackerHeight = 0.10 -- local Y above the zone
landTrackerPosZ = 0.6 -- local Z (further "forward")
landTrackerSpacing = 0.05 -- gap between stacked lines

-- per-color state
landsEnteredThisTurn = {} -- color -> array of { guid, name } entered this turn
landZoneBaseline = {} -- color -> set of land guids present at this player's turn start
glowingLands = {} -- card objects currently glowing (lands played this turn)

-- create the display on every playmat zone and initialise tracking state
function spawnLandTrackerText()
	for color, _ in pairs(data) do
		createLandTrackerButtons(color)
		landsEnteredThisTurn[color] = {}
		landZoneBaseline[color] = {}
	end
	-- the active player's turn is already underway on load, so snapshot their
	-- baseline now (we missed their onPlayerTurnStart)
	if Turns ~= nil and Turns.turn_color ~= nil and data[Turns.turn_color] ~= nil then
		resetLandTracker(Turns.turn_color)
	end
	for color, _ in pairs(data) do
		refreshLandTrackerText(color)
	end
end

function createLandTrackerButtons(color)
	local mat = data[color]["playmat"]
	if mat == nil then
		return
	end
	mat.clearButtons()

	-- text is scaled by the inverse of the zone scale so it renders at a
	-- consistent size regardless of how big the playmat zone is
	local scale = mat.getScale()
	local textScale = { 1 / scale.x, 1 / scale.y, 1 / scale.z }

	-- White/Yellow display on the right, Blue/Red on the left (old layout)
	local posX = 0.5
	if color == "Blue" or color == "Red" then
		posX = -0.5
	end

	-- index 0: lands entered this turn
	mat.createButton({
		click_function = "null",
		function_owner = Global,
		label = "Lands this turn: none",
		position = { posX, landTrackerHeight, landTrackerPosZ },
		scale = textScale,
		width = 0,
		height = 0,
		font_size = 250,
		font_color = { 1, 1, 1 },
	})
end

----------------------------------- TURN LOGIC ----------------------------------

-- at the start of a player's turn the previous turn has ended, so stop the
-- glow on any lands played during it; then snapshot the lands already in the
-- starting player's land zone and clear their entered-this-turn list
function onPlayerTurnStart(player_color_start, player_color_previous)
	clearLandGlows()
	-- the previous player's turn just ended -- drop their Etali glow if it's theirs
	maybeClearEtaliGlows(player_color_previous)
	-- and resolve their staged Ral ult/pif cards
	ralEndOfTurnCleanup(player_color_previous)
	if data[player_color_start] ~= nil then
		resetLandTracker(player_color_start)
	end
end

-- turn off the glow on every land that was played this turn
function clearLandGlows()
	for _, card in ipairs(glowingLands) do
		if card ~= nil then
			pcall(function()
				card.highlightOff()
			end)
		end
	end
	glowingLands = {}
end

function resetLandTracker(color)
	landsEnteredThisTurn[color] = {}
	landZoneBaseline[color] = {}
	local zone = data[color]["landZone"]
	if zone ~= nil then
		for _, obj in ipairs(zone.getObjects()) do
			if cardIsLand(obj) then
				landZoneBaseline[color][obj.getGUID()] = true
			end
		end
	end
	refreshLandTrackerText(color)
end

---------------------------------- ENTER LOGIC ----------------------------------

-- which player's land zone is this, if any
function landZoneColor(zone)
	for color, _ in pairs(data) do
		if data[color]["landZone"] == zone then
			return color
		end
	end
	return nil
end

-- called from onObjectEnterZone (see context_menus.lua). Records a land that
-- entered a land zone and didn't start the turn there.
function trackLandEnter(zone, obj)
	-- ignore fetchland preview copies (see fetchland.lua)
	if obj ~= nil and obj.hasTag("FetchPreview") then
		return
	end
	-- a face-down card isn't a land on the battlefield (morph/manifest/face-down
	-- drop), even though its hidden name still matches cardIsLand
	if obj ~= nil and obj.is_face_down then
		return
	end
	local color = landZoneColor(zone)
	if color == nil or not cardIsLand(obj) then
		return
	end
	-- respect the owner's land-tracker setting
	if not getSetting(color, "landTracker") then
		return
	end
	-- wait for the card to come to rest before counting it: a card being drawn
	-- animates through the land zone without stopping, and must not be counted as
	-- a land played this turn. whenSettledInZone skips it if it left in transit.
	whenSettledInZone(obj, zone, function()
		registerLandEntered(color, obj)
	end)
end

-- record a land that has actually settled in a player's land zone this turn
function registerLandEntered(color, obj)
	-- re-check: it may have been flipped face-down between entering and settling
	if obj.is_face_down then
		return
	end
	local guid = obj.getGUID()
	-- ignore lands that were already in the zone when the turn began
	if landZoneBaseline[color] and landZoneBaseline[color][guid] then
		return
	end
	landsEnteredThisTurn[color] = landsEnteredThisTurn[color] or {}
	-- don't list the same card twice (e.g. nudged out and back in)
	for _, e in ipairs(landsEnteredThisTurn[color]) do
		if e.guid == guid then
			return
		end
	end
	table.insert(landsEnteredThisTurn[color], { guid = guid, name = mainCardName(obj.getName()) })
	-- glow the land grey until the end of the turn
	obj.highlightOn({ 0.5, 0.5, 0.5 })
	table.insert(glowingLands, obj)
	refreshLandTrackerText(color)
end

------------------------------------ DISPLAY ------------------------------------

function refreshLandTrackerText(color)
	local mat = data[color]["playmat"]
	if mat == nil then
		return
	end
	-- blank the display entirely when the owner has the tracker turned off
	if not getSetting(color, "landTracker") then
		mat.editButton({ index = 0, label = "" })
		return
	end
	local names = {}
	for _, e in ipairs(landsEnteredThisTurn[color] or {}) do
		table.insert(names, e.name)
	end
	local label
	if #names == 0 then
		label = "Lands this turn: none"
	else
		label = "Lands this turn (" .. #names .. "):\n" .. table.concat(names, "\n")
	end
	mat.editButton({ index = 0, label = label })
end
------------------------- ACTIVATED-ABILITY RESTRICTIONS -------------------------
-- Some static cards read "Activated abilities of <type> can't be activated"
-- (Linvala -> creatures, Karn the Great Creator -> artifacts, Collector Ouphe ->
-- artifacts, ...). When a player taps a permanent of an affected type while such
-- a card is on the battlefield, privately remind them that the tapped card's
-- activated abilities are prohibited, and by what.
--
-- This is a heads-up only -- it doesn't stop anything, and tapping isn't always
-- an ability activation (it can be an attack, crew, convoke, ...), so treat the
-- message as a reminder. It also matches by type line, so it can't tell apart
-- "artifacts your opponents control" from your own.

-- base card types we recognise inside a restriction clause (matched against both
-- the clause and each permanent's type line)
restrictedAbilityTypes = { "artifact", "creature", "land", "enchantment", "planeswalker", "battle" }

-- pull the affected types out of one card's description (its oracle text, set by
-- the importer). Returns a set (type -> true), or nil if the card carries no
-- "activated abilities of <type> can't be activated" clause.
function cardRestrictedTypes(desc)
	if desc == nil or desc == "" then
		return nil
	end
	-- normalise the curly apostrophe scryfall sometimes uses in "can't"
	desc = desc:lower():gsub("\226\128\153", "'")
	local found = nil
	for clause in desc:gmatch("activated abilities of (.-) can't be activated") do
		for _, t in ipairs(restrictedAbilityTypes) do
			if clause:find(t, 1, true) then
				found = found or {}
				found[t] = true
			end
		end
	end
	return found
end

-- is this object a face-up card sitting out on the battlefield (i.e. not held in
-- a player's hand and not tucked inside a container)? getAllObjects already skips
-- cards inside decks/bags, so we only need to drop hand cards and face-down ones.
function isBattlefieldCard(obj)
	if obj == nil or obj.type ~= "Card" or obj.is_face_down then
		return false
	end
	for _, z in ipairs(obj.getZones() or {}) do
		if z.type == "Hand" then
			return false
		end
	end
	return true
end

-- scan the battlefield and return the restrictions currently in force as a map of
-- type -> { source card display name -> true }
function currentAbilityRestrictions()
	local map = {}
	for _, obj in ipairs(getAllObjects()) do
		if isBattlefieldCard(obj) then
			local types = cardRestrictedTypes(obj.getDescription())
			if types ~= nil then
				local name = mainCardName(obj.getName())
				for t, _ in pairs(types) do
					map[t] = map[t] or {}
					map[t][name] = true
				end
			end
		end
	end
	return map
end

-- a card lies flat on the table; tapping turns it 90 degrees about the vertical
-- axis. Untapped rest is y 0 or 180 (both 0 mod 180), tapped is 90 or 270 (both
-- 90 mod 180), so "tapped" is simply spin ~90 mod 180 regardless of table side.
function spinIsTapped(angle)
	if angle == nil then
		return false
	end
	local m = angle % 180
	return m > 45 and m < 135
end

-- sorted list of a set's keys, for a stable message
function sortedSetKeys(set)
	local out = {}
	for k, _ in pairs(set) do
		table.insert(out, k)
	end
	table.sort(out)
	return out
end

-- on tap of a restricted-type permanent, privately remind the tapping player
function onObjectRotate(object, spin, flip, player_color, old_spin, old_flip)
	-- tapping/untapping a fetchland hides/shows its library previews
	fetchlandRotate(object, spin, old_spin)
	-- only fire on the untapped -> tapped transition (ignore flips and untaps)
	if not spinIsTapped(spin) or spinIsTapped(old_spin) then
		return
	end
	if not isBattlefieldCard(object) then
		return
	end
	-- respect the tapping player's ability-restriction reminder setting
	if not getSetting(player_color, "abilityRestrictions") then
		return
	end
	local line = cardTypeLine(object)
	if line == "" then
		return
	end
	local restrictions = currentAbilityRestrictions()
	if next(restrictions) == nil then
		return
	end

	-- which of this card's types are restricted, and what's prohibiting them?
	local sources = {}
	local hit = false
	for t, srcSet in pairs(restrictions) do
		if line:find(t, 1, true) then
			hit = true
			for name, _ in pairs(srcSet) do
				sources[name] = true
			end
		end
	end
	if not hit then
		return
	end

	broadcastToColor(
		mainCardName(object.getName())
			.. ": activated abilities are prohibited by "
			.. table.concat(sortedSetKeys(sources), ", ")
			.. ".",
		player_color,
		{ 0.9, 0.3, 0.3 }
	)
end
--------------------------------- FETCHLANDS ----------------------------------
-- When a fetch-style land ("Search your library for a <type> [or <type>] card
-- ... put it onto the battlefield") sits in a player's land zone, show small
-- previews of the matching lands still in that player's library, floating above
-- the fetchland. The previews are locked, non-interactable copies -- they do
-- nothing on click (yet). The real cards stay in the library untouched.

-- the land subtypes a fetch can name
fetchSubtypes = { "plains", "island", "swamp", "mountain", "forest", "wastes" }

-- preview layout (tunable, mirrors moon-mtg-equip's 0.475 scale)
fetchPreviewScale = 0.475
fetchPreviewUp = 2.6 -- distance "above" the fetchland (along its forward)
fetchPreviewSpacing = 1.2 -- horizontal gap between previews
fetchPreviewPerRow = 6 -- wrap to a new (higher) row after this many
fetchPreviewRowStep = 1.8 -- vertical gap between wrapped rows

-- fetchland guid -> array of spawned preview objects
fetchPreviews = {}
-- fetchland guid -> spawn generation; bumped on every clear so an in-flight
-- staggered spawn (see showFetchPreviews) knows to stop
fetchPreviewGen = {}
-- preview guid -> { color, fetchGuid, cardGuid, name } for resolving double-clicks
fetchPreviewData = {}
fetchDoubleClickSecs = 0.5

-- If the card is a fetch-style land, describe what it can search for; otherwise
-- return nil. Result: { subtypes = {...}, requireBasic = bool, anyBasic = bool }.
--   subtypes    - named land subtypes the fetch lists (e.g. island, mountain)
--   requireBasic - the fetch says "basic", so only basic lands qualify
--   anyBasic    - "basic land" with no named subtype: any basic land qualifies
function fetchLandTargets(card)
	if not cardIsLand(card) then
		return nil
	end
	local desc = (card.getDescription() or ""):lower()
	if not desc:find("search your library") or not desc:find("onto the battlefield") then
		return nil
	end
	local phrase = desc:match("search your library for (.-) card") or desc
	-- "basic Island, ..." / "basic land" restrict to basics; "nonbasic" does not
	local requireBasic = phrase:find("basic") ~= nil and phrase:find("nonbasic") == nil
	local subtypes = {}
	for _, t in ipairs(fetchSubtypes) do
		if phrase:find(t) then
			table.insert(subtypes, t)
		end
	end
	local anyBasic = requireBasic and #subtypes == 0
	if #subtypes == 0 and not anyBasic then
		return nil
	end
	return { subtypes = subtypes, requireBasic = requireBasic, anyBasic = anyBasic }
end

-- does a library card (matched on its nickname / type line) satisfy the fetch?
function fetchCardMatches(nickname, targets)
	-- match only against the type line, not the card name: nicknames are
	-- "<name>\n<type line> <cmc>CMC", and a name can contain a subtype substring
	-- (e.g. Misty Rainforest -> "forest") that must not count as a match
	local typeLine = cardTypeLine(nickname)
	if not typeLine:find("land") then
		return false
	end
	local isBasic = typeLine:find("basic land") ~= nil
	-- "basic land card" with no named subtype: any basic land
	if targets.anyBasic then
		return isBasic
	end
	-- a fetch that names "basic <subtype>" only takes basic lands of that subtype
	if targets.requireBasic and not isBasic then
		return false
	end
	for _, t in ipairs(targets.subtypes) do
		if typeLine:find(t) then
			return true
		end
	end
	return false
end

-- remove the previews belonging to a fetchland
function clearFetchPreviews(guid)
	-- invalidate any in-flight staggered spawn for this fetchland
	fetchPreviewGen[guid] = (fetchPreviewGen[guid] or 0) + 1
	local list = fetchPreviews[guid]
	if list == nil then
		return
	end
	for _, p in ipairs(list) do
		if p ~= nil then
			fetchPreviewData[p.getGUID()] = nil
			pcall(function()
				destroyObject(p)
			end)
		end
	end
	fetchPreviews[guid] = nil
end

-- spawn the preview row(s) above a fetchland from the matching library cards
function showFetchPreviews(zone, fetch)
	local color = landZoneColor(zone)
	if color == nil then
		return
	end
	-- respect the owner's fetchland-preview setting
	if not getSetting(color, "fetchPreviews") then
		return
	end
	local targets = fetchLandTargets(fetch)
	if targets == nil then
		return
	end
	clearFetchPreviews(fetch.getGUID())
	-- a tapped fetchland is spent; don't show previews for it
	if spinIsTapped(fetch.getRotation().y) then
		return
	end

	-- source the matching lands from either the live library (default -- accurate,
	-- but an opponent's hidden removal would leak which land left) or the frozen
	-- game-start deck clone (fetchFromClone -- immune to hidden removals, at the
	-- cost of not reflecting cards legitimately drawn/fetched since game start).
	-- resolveFetch always searches the live library, so a stale clone entry just
	-- no-ops on click.
	local contained
	if getSetting(color, "fetchFromClone") then
		local snap = data[color]["resetSnapshot"]
		if snap == nil or snap.deckData == nil then
			return -- no game-start clone yet (opening hand not drawn); nothing to show
		end
		contained = snap.deckData.ContainedObjects or {}
	else
		local deck = getDeckFromZone(data[color]["libraryZone"])
		if deck == nil then
			return
		end
		contained = deck.getData().ContainedObjects or {}
	end
	local matches = {}
	local seen = {} -- dedupe identical lands and skip blank / face-down (nameless) cards
	for _, cardData in ipairs(contained) do
		if fetchCardMatches(cardData.Nickname, targets) then
			local name = mainCardName(cardData.Nickname)
			if name ~= "" and not seen[name] then
				seen[name] = true
				table.insert(matches, cardData)
			end
		end
	end

	fetchPreviews[fetch.getGUID()] = {}
	-- orient previews to the land zone (consistent "above"), not the card, which
	-- the player may have rotated. Build unit direction vectors from the zone's
	-- yaw via trig so they're independent of how TTS scales transform vectors.
	-- "Above" on the mat is -forward.
	local rot = { 0, zone.getRotation().y, 0 }
	local yaw = math.rad(zone.getRotation().y)
	local fwd = { x = math.sin(yaw), z = math.cos(yaw) }
	local rgt = { x = math.cos(yaw), z = -math.sin(yaw) }
	local base = fetch.getPosition()
	local fetchGuid = fetch.getGUID()
	-- generation was just bumped by clearFetchPreviews above; capture it so the
	-- staggered spawn below stops if a newer call supersedes this one
	local gen = fetchPreviewGen[fetchGuid]

	-- spawn the previews one per frame rather than all at once -- spawning every
	-- matching land in a single frame causes a visible stutter
	local function spawnPreview(i)
		if i > #matches then
			return
		end
		-- abort if this run was superseded (cleared/re-shown) or the fetch moved
		if fetchPreviewGen[fetchGuid] ~= gen or not zoneContains(zone, fetch) then
			return
		end
		local idx = i - 1
		local row = math.floor(idx / fetchPreviewPerRow)
		local col = idx % fetchPreviewPerRow
		local nInRow = math.min(fetchPreviewPerRow, #matches - row * fetchPreviewPerRow)
		local offRight = (col - (nInRow - 1) / 2) * fetchPreviewSpacing
		local offFwd = -(fetchPreviewUp + row * fetchPreviewRowStep)
		local pos = {
			x = base.x + fwd.x * offFwd + rgt.x * offRight,
			y = base.y + 0.5,
			z = base.z + fwd.z * offFwd + rgt.z * offRight,
		}
		local cardData = matches[i]
		-- tag the copy so the land tracker / fetch logic ignore it
		cardData.Tags = { "FetchPreview" }
		-- force the small scale in the data too (in case the spawn param is ignored)
		cardData.Transform = cardData.Transform or {}
		cardData.Transform.scaleX = fetchPreviewScale
		cardData.Transform.scaleY = fetchPreviewScale
		cardData.Transform.scaleZ = fetchPreviewScale
		local preview = spawnObjectData({
			data = cardData,
			position = pos,
			rotation = rot,
			scale = { fetchPreviewScale, fetchPreviewScale, fetchPreviewScale },
			callback_function = function(obj)
				obj.setVar("noencode", true)
				obj.setLock(true)
				-- only the land zone's owner sees their own fetch previews
				obj.setInvisibleTo(allBut(color))
				-- record what this preview resolves to, and add a click target
				fetchPreviewData[obj.getGUID()] = {
					color = color,
					fetchGuid = fetchGuid,
					cardGuid = cardData.GUID,
					name = mainCardName(cardData.Nickname),
				}
				obj.createButton({
					click_function = "fetchPreviewClick",
					function_owner = Global,
					label = "",
					position = { 0, 0.3, 0 },
					rotation = { 0, 0, 0 },
					width = 1500,
					height = 2100,
					scale = { 1, 1, 1 },
					color = { 0, 0, 0, 0 },
				})
			end,
		})
		-- the list may have been cleared between scheduling and now
		if fetchPreviews[fetchGuid] ~= nil then
			table.insert(fetchPreviews[fetchGuid], preview)
		end
		Wait.frames(function()
			spawnPreview(i + 1)
		end, 1)
	end
	spawnPreview(1)
end

-- double-click handler on a preview: only the land zone's owner can resolve it
function fetchPreviewClick(obj, color, alt)
	local info = fetchPreviewData[obj.getGUID()]
	if info == nil or color ~= info.color then
		return
	end
	if isDoubleClick(obj.getGUID(), fetchDoubleClickSecs) then
		resolveFetch(info)
	end
end

-- map a spelled-out (or numeric) count to a number, e.g. "two" -> 2
function wordToCount(w)
	local words = {
		one = 1, two = 2, three = 3, four = 4, five = 5,
		six = 6, seven = 7, eight = 8, nine = 9, ten = 10,
	}
	return words[w] or tonumber(w)
end

-- is this object a basic land? (checks the type line in its "<name>\n<type>" nickname)
function cardIsBasicLand(obj)
	if obj == nil or obj.type ~= "Card" or obj.hasTag("FetchPreview") then
		return false
	end
	return cardTypeLine(obj):find("basic land") ~= nil
end

-- how many basic lands does this player control (in their land zone)?
function countBasicLands(color)
	local zone = data[color] and data[color]["landZone"]
	if zone == nil then
		return 0
	end
	local n = 0
	for _, obj in ipairs(zone.getObjects()) do
		if cardIsBasicLand(obj) then
			n = n + 1
		end
	end
	return n
end

-- how many lands (basic or not) does this player control, in their land zone?
-- skips fetch preview copies floating above their fetchlands
function countLands(color)
	local zone = data[color] and data[color]["landZone"]
	if zone == nil then
		return 0
	end
	local n = 0
	for _, obj in ipairs(zone.getObjects()) do
		if obj.type == "Card" and not obj.hasTag("FetchPreview") and cardIsLand(obj) then
			n = n + 1
		end
	end
	return n
end

-- does the fetchland itself put the fetched land onto the battlefield tapped?
-- Most "fetch a basic tapped" lands (Evolving Wilds, Terramorphic Expanse, ...)
-- always do. Fabled Passage is the exception: it untaps the land if you already
-- control N or more lands (counting Fabled Passage itself), so this must be
-- evaluated before the fetchland leaves the battlefield.
function fetchlandForcesTapped(fetch, color)
	if fetch == nil then
		return false
	end
	local desc = (fetch.getDescription() or ""):lower()
	if desc:find("onto the battlefield tapped") == nil and desc:find("into play tapped") == nil then
		return false
	end
	local word = desc:match("if you control (%a+) or more lands")
	if word ~= nil then
		local need = wordToCount(word)
		if need ~= nil and countLands(color) >= need then
			return false
		end
	end
	return true
end

-- does this land enter the battlefield tapped for `color`? matches the common
-- templates: "<land> comes into play tapped", "<land> enters the battlefield
-- tapped", and "... tapped unless ...". The "tapped unless you control N or more
-- basic lands" clause (tango/battle lands) is evaluated against the player's
-- basics; any other "unless" clause defaults to entering tapped.
function landEntersTapped(card, color)
	if card == nil then
		return false
	end
	local desc = (card.getDescription() or ""):lower()
	if
		desc:find("enters the battlefield tapped") == nil
		and desc:find("enters tapped") == nil
		and desc:find("comes into play tapped") == nil
	then
		return false
	end
	-- tango/battle lands: untapped once the player controls enough basics
	local word = desc:match("tapped unless you control (%a+) or more basic land")
	if word ~= nil then
		local need = wordToCount(word)
		if need ~= nil then
			return countBasicLands(color) < need
		end
	end
	return true
end

-- orient a freshly fetched land to the player's untapped rotation (the land
-- zone's), then tap it (90 degrees) if the fetchland forced it tapped or the
-- land's own text says it enters tapped
function orientFetchedLand(card, baseY, color, forcedTapped)
	if card == nil then
		return
	end
	local y = baseY
	if forcedTapped or landEntersTapped(card, color) then
		y = baseY + 90
	end
	card.setRotationSmooth({ 0, y, 0 }, false, true)
end

-- how many cards does this land's "when ~ enters the battlefield, surveil/scry N"
-- trigger look at? returns 0 if it has no such enters-the-battlefield trigger.
function surveilOnEnter(card)
	if card == nil then
		return 0
	end
	local desc = (card.getDescription() or ""):lower()
	local n = desc:match("enters the battlefield, surveil (%d+)")
		or desc:match("enters, surveil (%d+)")
		or desc:match("enters the battlefield, scry (%d+)")
	return tonumber(n) or 0
end

-- run any "enters the battlefield" trigger of a freshly fetched land. For surveil
-- lands, auto-surveil for the player using the same scry primitive as the Scry
-- button, after the post-fetch library shuffle has settled.
function fetchedLandETB(card, color)
	local n = surveilOnEnter(card)
	if n <= 0 then
		return
	end
	Wait.time(function()
		Wait.time(function()
			scry1(color)
		end, drawDelay, n)
	end, 0.9)
	Player[color].broadcast("Surveil " .. n .. " from " .. mainCardName(card.getName()) .. ".")
end

-- phrases / names identifying face-up battlefield cards that restrict library
-- searches. Kept specific so they never match a fetchland's or tutor's own
-- beneficial "search your library for..." text.
searchRestrictionPhrases = {
	"can't search",                    -- Leonin Arbiter, Stranglehold, Ashiok, Dream Render
	"top four cards of that library",  -- Aven Mindcensor
	"top four cards of their library", -- (wording variant)
}
searchRestrictionNames = {
	"opposition agent", -- takes control of the searching player
}

-- list of distinct card names currently imposing a search restriction
function searchRestrictionsInPlay()
	local names = {}
	local seen = {}
	for color, _ in pairs(data) do
		local mat = data[color]["playmat"]
		if mat ~= nil then
			for _, v in pairs(mat.getObjects()) do
				if v.type == "Card" and not v.is_face_down then
					local desc = (v.getDescription() or ""):lower()
					local cname = (v.getName() or ""):lower()
					local hit = false
					for _, p in ipairs(searchRestrictionPhrases) do
						if desc:find(p, 1, true) then
							hit = true
							break
						end
					end
					if not hit then
						for _, nm in ipairs(searchRestrictionNames) do
							if cname:find(nm, 1, true) then
								hit = true
								break
							end
						end
					end
					if hit then
						local n = mainCardName(v.getName())
						if not seen[n] then
							seen[n] = true
							table.insert(names, n)
						end
					end
				end
			end
		end
	end
	return names
end

-- carry out a fetch: lose 1 life (only if the land says so), pull the chosen
-- land next to the fetchland, and send the fetchland to the graveyard
function resolveFetch(info)
	local color = info.color
	local fetch = getObjectFromGUID(info.fetchGuid)

	-- tutor/search hate (Aven Mindcensor, Leonin Arbiter, Opposition Agent, ...):
	-- don't perform the search at all. Send the fetchland to the graveyard and
	-- have the player resolve the (restricted) search by hand.
	if getSetting(color, "searchRestrictions") then
		local blockers = searchRestrictionsInPlay()
		if #blockers > 0 then
			-- the fetch's "pay 1 life" is a cost, so it's still paid
			if fetch ~= nil and (fetch.getDescription() or ""):lower():find("pay 1 life") then
				loseLife(color, 1, mainCardName(fetch.getName()))
			end
			if fetch ~= nil then
				discardCard(fetch, color)
			end
			clearFetchPreviews(info.fetchGuid)
			broadcastToColor(
				"Search restricted by " .. table.concat(blockers, ", ")
					.. " -- fetchland sent to graveyard; resolve the search manually.",
				color,
				{ 0.9, 0.3, 0.3 }
			)
			return
		end
	end

	-- 1. lose 1 life, but only if the fetchland actually says "pay 1 life"
	-- (some lands -- Evolving Wilds, panoramas, etc. -- fetch for free)
	if fetch ~= nil and (fetch.getDescription() or ""):lower():find("pay 1 life") then
		loseLife(color, 1, mainCardName(fetch.getName()))
	end

	-- decide whether the fetchland forces the land in tapped, while the fetchland
	-- and the player's current lands are all still on the battlefield (matters for
	-- Fabled Passage, which counts itself toward its "4 or more lands" check)
	local forcedTapped = fetchlandForcesTapped(fetch, color)

	-- 2. pull the chosen land from the library, place it exactly where the
	-- fetchland sits (the fetchland is sent to the graveyard right after, so it
	-- frees up that spot). Orient it to the land zone (untapped), never to the
	-- fetchland -- which may itself be tapped/rotated -- then tap it afterwards
	-- only if it enters tapped.
	local baseY = data[color]["landZone"].getRotation().y
	local landPos
	if fetch ~= nil then
		local b = fetch.getPosition()
		landPos = { x = b.x, y = b.y + 1, z = b.z }
	else
		landPos = data[color]["landZone"].getPosition()
	end
	-- find the chosen land in the library by name (deck.getObjects() gives live
	-- guids/indexes; the GUID captured at preview time isn't reliable) and take
	-- exactly that card by index
	local deck = getDeckFromZone(data[color]["libraryZone"])
	local taken = false
	if deck ~= nil then
		for _, entry in ipairs(deck.getObjects()) do
			if mainCardName(entry.name) == info.name then
				pcall(function()
					deck.takeObject({
						index = entry.index,
						position = landPos,
						rotation = { 0, baseY, 0 },
						smooth = true,
						callback_function = function(obj)
							orientFetchedLand(obj, baseY, color, forcedTapped)
							fetchedLandETB(obj, color)
						end,
					})
				end)
				taken = true
				break
			end
		end
	end
	if not taken then
		-- fallback: the land is a loose card in the library, not inside a deck
		local loose = getObjectFromGUID(info.cardGuid)
		if loose ~= nil then
			loose.setPositionSmooth(landPos, false, true)
			orientFetchedLand(loose, baseY, color, forcedTapped)
			fetchedLandETB(loose, color)
		end
	end

	-- shuffle the library after fetching (let the take settle, then re-fetch the
	-- deck in case it changed)
	if taken then
		Wait.time(function()
			local d = getDeckFromZone(data[color]["libraryZone"])
			if d ~= nil then
				pcall(function()
					d.shuffle()
				end)
			end
		end, 0.5)
	end

	-- 3. send the fetchland to the graveyard (reuse the discard placement)
	if fetch ~= nil then
		discardCard(fetch, color)
	end

	-- previews are no longer valid
	clearFetchPreviews(info.fetchGuid)
end

-- subtract n life from a player's Life_Tracker and update its display, then
-- announce it in the same format the Life_Tracker uses for manual changes
-- ("<Color> lost N life |total|"), so scripted life loss reads identically. When
-- a source is given it's named too ("<Color> lost N life from <source> |total|").
function loseLife(color, n, source)
	local tracker = data[color] and data[color]["lifeTracker"]
	if tracker == nil then
		return
	end
	local count = tonumber(tracker.getVar("count")) or 0
	count = count - n
	tracker.setVar("count", count)
	tracker.editButton({ index = 0, label = tostring(count) })
	tracker.call("updateSave")
	if n ~= 0 then
		local verb, amt = "lost", n
		if n < 0 then
			verb, amt = "gained", -n
		end
		local from = ""
		if source ~= nil and source ~= "" then
			from = " from " .. source
		end
		printToAll(
			color .. "[999999] " .. verb .. " " .. amt .. " life" .. from .. " [-]|" .. count .. "|",
			stringColorToRGB(color)
		)
	end
end

-- event hooks (called from onObjectEnterZone / onObjectLeaveZone)
function fetchlandEnter(zone, obj)
	if obj == nil or obj.hasTag("FetchPreview") then
		return
	end
	if landZoneColor(zone) == nil or fetchLandTargets(obj) == nil then
		return
	end
	-- wait for the fetchland to come to rest before showing previews, so they
	-- don't pop up mid-drop. Bails if it's been picked up / destroyed or has since
	-- left the zone (fetchlandLeave handles clearing in that case).
	whenSettledInZone(obj, zone, function()
		showFetchPreviews(zone, obj)
	end)
end

function fetchlandLeave(zone, obj)
	if obj == nil then
		return
	end
	clearFetchPreviews(obj.getGUID())
end

-- show/hide previews as a fetchland is tapped/untapped: a tapped fetchland is
-- "spent", so hide its previews; untapping a fetchland still in its land zone
-- brings them back. Called from onObjectRotate.
function fetchlandRotate(obj, spin, old_spin)
	if obj == nil or obj.type ~= "Card" or obj.hasTag("FetchPreview") then
		return
	end
	-- only act on a tap/untap transition, not flips or untouched rotations
	if spinIsTapped(spin) == spinIsTapped(old_spin) then
		return
	end
	for color, _ in pairs(data) do
		local zone = data[color]["landZone"]
		if zone ~= nil and zoneContains(zone, obj) and fetchLandTargets(obj) ~= nil then
			if spinIsTapped(spin) then
				clearFetchPreviews(obj.getGUID())
			else
				showFetchPreviews(zone, obj)
			end
			return
		end
	end
end

-- rebuild every fetchland preview for one player. Used when a setting that
-- affects previews is toggled (fetchPreviews on/off, or fetchFromClone switching
-- the source): clear first so turning previews off actually removes them, then
-- re-show (a no-op while fetchPreviews is off).
function refreshFetchPreviewsForColor(color)
	local zone = data[color] and data[color]["landZone"]
	if zone == nil then
		return
	end
	for _, obj in ipairs(zone.getObjects()) do
		if not obj.hasTag("FetchPreview") and fetchLandTargets(obj) ~= nil then
			clearFetchPreviews(obj.getGUID())
			showFetchPreviews(zone, obj)
		end
	end
end

-- same, for every player (used when the host enforces a preview-related setting)
function refreshAllFetchPreviews()
	for color, _ in pairs(data) do
		refreshFetchPreviewsForColor(color)
	end
end

-- on load, clear any orphaned preview copies left over from a previous script
-- reload, then show previews for fetchlands already sitting in land zones
function initFetchlands()
	for _, obj in ipairs(getAllObjects()) do
		if obj.hasTag("FetchPreview") then
			destroyObject(obj)
		end
	end
	fetchPreviews = {}
	for color, _ in pairs(data) do
		local zone = data[color]["landZone"]
		if zone ~= nil then
			for _, obj in ipairs(zone.getObjects()) do
				if not obj.hasTag("FetchPreview") and fetchLandTargets(obj) ~= nil then
					showFetchPreviews(zone, obj)
				end
			end
		end
	end
end
-------------------------------- DOUBLE-FACED CARDS ----------------------------
-- A double-faced card is a TTS object with two states (state 1 = front face,
-- state 2 = back face). When such a card is dropped into a player's land zone and
-- its back face is a land (per the type line, the 2nd line of that face's name),
-- flip it to the back face. Called from onObjectEnterZone (context_menus.lua).
function dfcLandEnter(zone, obj)
	if obj == nil or obj.type ~= "Card" then
		return
	end
	if landZoneColor(zone) == nil then
		return -- not a land zone
	end
	local states = obj.getStates()
	if states == nil or #states == 0 then
		return -- single-faced card
	end
	-- map each state's name by id; getStates() may omit the active state, so add it
	local names = {}
	for _, st in ipairs(states) do
		names[st.id] = st.name
	end
	names[obj.getStateId()] = obj.getName()
	local backName = names[2]
	if backName == nil or not nameTypeLineIsLand(backName) then
		return -- no back face, or it isn't a land
	end
	if names[1] ~= nil and nameTypeLineIsLand(names[1]) then
		return -- front face is already a land; leave it so that side can be played
	end
	if obj.getStateId() == 2 then
		return -- already showing the land face
	end
	-- wait until it settles, and only flip if it's still in the land zone
	whenSettledInZone(obj, zone, function(o)
		if o.getStateId() ~= 2 then
			o.setState(2)
		end
	end)
end
-------------------------------- FROZEN TOKENS ---------------------------------
-- Tokens drawn from the frozen bags, when dropped onto a card, apply the Frozen
-- keyword (mtg_frozen, the same flag the Untap button respects) to that card and
-- then consume the token. Mirrors the mod's "drop on card -> Encoder -> destroy"
-- pattern (see Sticker_Encoder), but driven from the Global script.
frozenBagGUIDs = { ["1a20bf"] = true, ["71d33b"] = true }

-- tag tokens as they come out of a frozen bag so we can recognise them on drop
function onObjectLeaveContainer(container, object)
	if frozenBagGUIDs[container.getGUID()] then
		object.addTag("frozenToken")
	end
end

function onObjectDropped(playerColor, object)
	if object == nil or not object.hasTag("frozenToken") then
		return
	end
	whenSettled(object, freezeCardUnder)
end

-- raycast straight down from the token; freeze the first card it's resting on
function freezeCardUnder(token)
	if token == nil then
		return
	end
	local hits = Physics.cast({
		origin = token.getPosition() + Vector(0, 0.5, 0),
		direction = Vector(0, -1, 0),
		type = 1,
		max_distance = 3,
	})
	local card = nil
	for _, h in ipairs(hits) do
		if h.hit_object ~= nil and h.hit_object ~= token and h.hit_object.type == "Card" then
			card = h.hit_object
			break
		end
	end
	if card == nil then
		return -- not dropped on a card; leave the token alone
	end

	local enc = Global.getVar("Encoder")
	if enc == nil then
		return
	end
	if enc.call("APIobjectExists", { obj = card }) == false then
		enc.call("APIencodeObject", { obj = card })
	end
	if enc.call("APIobjIsPropEnabled", { obj = card, propID = "πKeywords" }) == false then
		enc.call("APIobjEnableProp", { obj = card, propID = "πKeywords" })
	end
	local data = enc.call("APIobjGetPropData", { obj = card, propID = "πKeywords" })
	if data == nil then
		return
	end
	data["mtg_frozen"] = true
	enc.call("APIobjSetPropData", { obj = card, propID = "πKeywords", data = data })
	enc.call("APIrebuildButtons", { obj = card })
	token.destruct()
end
------------------------------------- UNTAP ------------------------------------
-- when each player last pressed their own untap-all button (os.time seconds).
-- A draw within skipDrawWindow seconds of this is treated as the turn's draw
-- step (see playerDraw's skip-your-draw-step handling in draw.lua).
lastUntapPress = {}

-- stolen from Untapper Tool by Tipsy Hobbit//STEAM_0:1:13465982
function playerUntap(button, playerColor, alt)
	if button == data[playerColor]["untapButton"] then
		buttonPress(button, drawDelay * 0.75)
		lastUntapPress[playerColor] = os.time()
		untapAll(playerColor, false)
		-- Seedborn Muse untaps its controller's permanents during each OTHER
		-- player's untap step. So when this player untaps, every other player who
		-- controls a Seedborn Muse untaps too -- and since it isn't their own
		-- untap step, "doesn't untap during your untap step" cards (Mana Vault,
		-- Basalt/Grim Monolith, ...) untap as well (foreign = true).
		for color, _ in pairs(data) do
			if color ~= playerColor and controlsSeedbornMuse(color) then
				untapAll(color, true)
				broadcastToColor("Seedborn Muse untaps your permanents.", color, { 0.4, 0.9, 0.4 })
			end
		end
	else
		warnNotYours(button, playerColor)
	end
end

-- does this player control a face-up Seedborn Muse on their playmat?
function controlsSeedbornMuse(playerColor)
	local mat = data[playerColor]["playmat"]
	if mat == nil then
		return false
	end
	for _, v in pairs(mat.getObjects()) do
		if v.type == "Card" and not v.is_face_down and v.getName():lower():find("seedborn muse", 1, true) then
			return true
		end
	end
	return false
end

-- untap every permanent on a player's playmat. When foreign is true this is
-- another player's untap step (e.g. driven by Seedborn Muse), so "doesn't untap
-- during your untap step" restrictions don't apply; stun counters, frozen,
-- exert and battles are still honoured either way.
function untapAll(playerColor, foreign)
	local playmat = data[playerColor]["playmat"]
	if playmat == nil then
		return
	end
	local enc = Global.getVar("Encoder")
	local ry = playmat.getRotation()
	for _, v in pairs(playmat.getObjects()) do
		local untaps = true
		local flash = false
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
				-- only on the controller's OWN untap step do these hold a card down
				if not foreign then
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
				local rr = v.getRotation()
				v.setRotationSmooth({ x = rr.x, y = ry.y, z = rr.z })
			end
		end
	end
end

------------------------------------- DRAW -------------------------------------
-- a draw within this many seconds of pressing untap-all counts as the turn's
-- draw step, so a "skip your draw step" card should stop it
skipDrawWindow = 5

-- the display name of a face-up card on this player's playmat that makes them
-- skip their draw step, or nil if they control none
function skipDrawStepCard(playerColor)
	local mat = data[playerColor]["playmat"]
	if mat == nil then
		return nil
	end
	for _, obj in ipairs(mat.getObjects()) do
		if obj.type == "Card" and not obj.is_face_down then
			local desc = (obj.getDescription() or ""):lower()
			if desc:find("skip your draw step", 1, true) or desc:find("skip your next draw step", 1, true) then
				return mainCardName(obj.getName())
			end
		end
	end
	return nil
end

function playerDraw(button, playerColor, alt)
	if button == data[playerColor]["drawButton"] then
		if not alt then
			buttonPress(button, drawDelay * 0.75)
			-- if this draw is the turn's draw step (pressed soon after untap) and a
			-- card forces this player to skip it, remind them instead of drawing.
			-- the draw step is a single draw, so consume the window either way.
			local drawStep = lastUntapPress[playerColor] ~= nil
				and (os.time() - lastUntapPress[playerColor]) <= skipDrawWindow
			lastUntapPress[playerColor] = nil
			if drawStep and getSetting(playerColor, "drawSkipReminder") then
				local skipper = skipDrawStepCard(playerColor)
				if skipper ~= nil then
					broadcastToColor(
						"Draw skipped: " .. skipper .. " makes you skip your draw step. (alt-click to draw anyway.)",
						playerColor,
						{ 0.9, 0.3, 0.3 }
					)
					return
				end
			end
			draw1(playerColor)
			announceDrawTriggers(playerColor, 1, drawStep)
		else
			buttonPress(button, drawDelay * nAlt)
			buttonCooldown(button, drawDelay * nAlt)
			Wait.time(function()
				draw1(playerColor)
			end, drawDelay, nAlt)
			-- an explicit multi-draw isn't the draw-for-turn
			announceDrawTriggers(playerColor, nAlt, false)
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

---------------------------- OPPONENT-DRAW TRIGGERS ----------------------------
-- Cards that trigger when someone draws -- Smothering Tithe, Consecrated Sphinx,
-- Sheoldred, the Apocalypse, ... -- all share the same shape: "Whenever an
-- opponent draws a card, <controller does something>." We handle them generically
-- by oracle text: when a player draws with their draw button, every player whose
-- board carries a matching trigger is reminded (along with the drawer) that it
-- fired, and how many times.
--
-- Only draws made with the draw button are seen (not card-effect draws, opening
-- hands, etc.), and it doesn't check the library actually had cards to draw.

-- trigger phrasings -> whether the controller's OWN draw also counts
--   "whenever an opponent draws a card" fires only on other players' draws
--   "whenever a player draws a card"    fires on any player's draw
drawTriggerPhrases = {
	{ text = "whenever an opponent draws a card", selfCounts = false },
	{ text = "whenever a player draws a card", selfCounts = true },
}

-- some triggers exempt the first draw of each draw step (Orcish Bowmasters:
-- "...except the first one they draw in each of their draw steps"). Recognised
-- generically so the draw-for-turn doesn't set them off.
function drawTriggerExemptsDrawStep(desc)
	return desc:find("except the first", 1, true) ~= nil and desc:find("draw step", 1, true) ~= nil
end

-- list of { color, name } for every face-up permanent that triggers off a draw
-- by drawerColor. isDrawStep marks the drawer's first draw of their draw step
-- (the draw-for-turn), which cards like Orcish Bowmasters explicitly ignore.
function opponentDrawTriggers(drawerColor, isDrawStep)
	local hits = {}
	for color, _ in pairs(data) do
		local mat = data[color]["playmat"]
		if mat ~= nil then
			for _, obj in ipairs(mat.getObjects()) do
				if obj.type == "Card" and not obj.is_face_down then
					local desc = (obj.getDescription() or ""):lower()
					for _, phrase in ipairs(drawTriggerPhrases) do
						if desc:find(phrase.text, 1, true) and (color ~= drawerColor or phrase.selfCounts) then
							-- skip Bowmasters-style triggers on the drawer's draw-step draw
							if not (isDrawStep and drawTriggerExemptsDrawStep(desc)) then
								table.insert(hits, { color = color, name = mainCardName(obj.getName()) })
							end
							break -- one entry per card, even if it matches twice
						end
					end
				end
			end
		end
	end
	return hits
end

-- after drawerColor draws `count` card(s) with the draw button, remind every
-- triggered controller and the drawer
function announceDrawTriggers(drawerColor, count, isDrawStep)
	local hits = opponentDrawTriggers(drawerColor, isDrawStep)
	if #hits == 0 then
		return
	end
	local drewStr = (count == 1) and "a card" or (count .. " cards")
	local timesStr = (count == 1) and "" or (" (x" .. count .. ")")
	local color = { 0.95, 0.8, 0.3 }
	local drawerList = {}
	for _, h in ipairs(hits) do
		-- tell the controller their trigger fired (skip if they are the drawer --
		-- the drawer's summary below already covers it), unless they've muted
		-- draw-trigger notifications in their settings
		if h.color ~= drawerColor and getSetting(h.color, "oppDrawTriggers") then
			broadcastToColor(
				drawerColor .. " drew " .. drewStr .. " -- your " .. h.name .. " triggers" .. timesStr .. ".",
				h.color,
				color
			)
		end
		table.insert(drawerList, h.color .. "'s " .. h.name)
	end
	-- tell the drawer what they set off
	if getSetting(drawerColor, "oppDrawTriggers") then
		broadcastToColor("Your draw triggers: " .. table.concat(drawerList, ", ") .. ".", drawerColor, color)
	end
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

-- the per-player buttons that live on a token belonging to one colour
buttonOwnerKeys = { "drawButton", "scryButton", "millButton", "untapButton", "mulliganButton", "revealButton" }

-- reverse-lookup the owner colour of a per-player button object, or nil
function buttonOwner(obj)
	for color, pdata in pairs(data) do
		for _, key in ipairs(buttonOwnerKeys) do
			if pdata[key] == obj then
				return color
			end
		end
	end
	return nil
end

-- if obj is another player's button, tell the clicker it isn't theirs
function warnNotYours(obj, clickerColor)
	local owner = buttonOwner(obj)
	if owner ~= nil and owner ~= clickerColor then
		Player[clickerColor].broadcast(
			"That's " .. owner .. "'s button -- you can only use your own.",
			{ 1, 0.6, 0.2 }
		)
	end
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
		-- skip display-only labels and the serum powder / reset buttons so their
		-- text isn't mirrored during a neighbouring button's cooldown
		if
			but.click_function ~= "noop"
			and but.click_function ~= "playerSerumPowder"
			and but.click_function ~= "playerReset"
		then
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

-- Single source of truth for "is this card a land?" (basic lands included).
-- Accepts either a card object or a name string. Card nicknames in this mod are
-- "<name>\n<type line> <cmc>CMC", so the type line is part of the name; matching
-- "land" there identifies lands without scanning the rules text. For objects we
-- also accept a "Land" tag.
function cardIsLand(card)
	if card == nil then
		return false
	end
	local name
	if type(card) == "string" then
		name = card
	else
		if card.getName == nil then
			return false
		end
		for _, tag in ipairs(card.getTags()) do
			if tag:lower() == "land" then
				return true
			end
		end
		name = card.getName()
	end
	return (name or ""):lower():find("land") ~= nil
end

-- the card nickname's second line is its type line (see mainCardName), so an
-- instant/sorcery is detected by "instant"/"sorcery" appearing there
function nameIsInstantOrSorcery(name)
	local typeLine = ((name or ""):match("\n([^\r\n]*)") or ""):lower()
	return typeLine:find("instant") ~= nil or typeLine:find("sorcery") ~= nil
end

-- as above, for a live card object (vs. a deck-contained card's name string)
function cardIsInstantOrSorcery(card)
	if card == nil or card.getName == nil then
		return false
	end
	return nameIsInstantOrSorcery(card.getName())
end

-- does the type line (2nd line of the nickname) name a land? used to spot a
-- double-faced card whose back face is a land
function nameTypeLineIsLand(name)
	local typeLine = ((name or ""):match("\n([^\r\n]*)") or ""):lower()
	return typeLine:find("land") ~= nil
end

-- write text into a card's "Notepad[sup]π[/sup]" Encoder prop (propID "πotepad",
-- value note = { text, editON }). Mirrors frozen.lua's πKeywords handling.
function setCardNotepad(card, text)
	local enc = Global.getVar("Encoder")
	if enc == nil or card == nil then
		return
	end
	if enc.call("APIobjectExists", { obj = card }) == false then
		enc.call("APIencodeObject", { obj = card })
	end
	if enc.call("APIobjIsPropEnabled", { obj = card, propID = "πotepad" }) == false then
		enc.call("APIobjEnableProp", { obj = card, propID = "πotepad" })
	end
	local data = enc.call("APIobjGetPropData", { obj = card, propID = "πotepad" })
	if data == nil then
		return
	end
	data.note = data.note or { editON = true }
	data.note.text = text
	enc.call("APIobjSetPropData", { obj = card, propID = "πotepad", data = data })
	enc.call("APIrebuildButtons", { obj = card })
end

-- For a sticker card's space-separated name (e.g. "space fungus snickerdoodle"),
-- return the word with the most unique vowels ("y" counts), lowercased with every
-- vowel capitalised, then a space and that count -- e.g. "snIckErdOOdlE 3".
function stickerNotepad(name)
	local best, bestCount = nil, -1
	for word in (name or ""):gmatch("%S+") do
		local lower = word:lower()
		local seen = {}
		for ch in lower:gmatch("[aeiouy]") do
			seen[ch] = true
		end
		local count = 0
		for _ in pairs(seen) do
			count = count + 1
		end
		if count > bestCount then
			bestCount = count
			best = lower
		end
	end
	if best == nil then
		return ""
	end
	return (best:gsub("[aeiouy]", string.upper)) .. " " .. bestCount
end

-- card nicknames in this mod are "<name>\n<type line> <cmc>CMC" (the importer
-- appends the type line and CMC on following lines). Return just the displayed
-- card name: the first line, trimmed.
function mainCardName(name)
	if name == nil then
		return ""
	end
	return (name:match("^[^\r\n]*") or ""):gsub("%s+$", "")
end

-- the lowercased type line of a card: the text after the first newline in its
-- "<name>\n<type line> <cmc>CMC" nickname. Accepts a nickname string or a card
-- object. Returns "" if there's no type line. Matching subtypes/supertypes here
-- (rather than the whole nickname) avoids a card name being mistaken for a type.
function cardTypeLine(nameOrObj)
	local name
	if type(nameOrObj) == "string" then
		name = nameOrObj
	elseif nameOrObj ~= nil and nameOrObj.getName ~= nil then
		name = nameOrObj.getName()
	end
	return ((name or ""):match("[\r\n]+(.*)$") or ""):lower()
end

-- is obj currently inside zone?
function zoneContains(zone, obj)
	if zone == nil or obj == nil then
		return false
	end
	for _, o in ipairs(zone.getObjects()) do
		if o == obj then
			return true
		end
	end
	return false
end

-- run fn(obj) once obj has come to rest. Does nothing if obj is destroyed first.
function whenSettled(obj, fn)
	Wait.condition(function()
		if obj ~= nil then
			fn(obj)
		end
	end, function()
		return obj == nil or obj.resting
	end)
end

-- run fn(obj) once obj has come to rest while still inside zone. Does nothing if
-- obj is destroyed or leaves zone before settling (e.g. a card just passing
-- through the zone while being drawn/moved).
function whenSettledInZone(obj, zone, fn)
	Wait.condition(function()
		if obj ~= nil and zoneContains(zone, obj) then
			fn(obj)
		end
	end, function()
		return obj == nil or obj.resting or not zoneContains(zone, obj)
	end)
end

-- double-click detection: returns true on the second call with the same key
-- within `window` seconds (default 0.5), else false. Key it however suits the
-- caller (object guid, player colour, ...).
doubleClickTimes = {}
function isDoubleClick(key, window)
	window = window or 0.5
	local now = os.clock()
	local last = doubleClickTimes[key]
	if last ~= nil and (now - last) <= window then
		doubleClickTimes[key] = nil
		return true
	end
	doubleClickTimes[key] = now
	return false
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
	-- land tracker: note lands entering a player's land zone (see landtracker.lua)
	trackLandEnter(zone, obj)
	-- fetchlands: show previews of fetchable lands above them (see fetchland.lua)
	fetchlandEnter(zone, obj)
	-- double-faced cards: flip to a land back face dropped in a land zone (dfc.lua)
	dfcLandEnter(zone, obj)
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
	-- fetchlands: remove previews when a fetchland leaves a land zone
	fetchlandLeave(zone, obj)
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
		local isLand = cmc == "-1"
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
	local isLand = cardIsLand(name)
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

-- rikrassen's importer is a deck builder: it POSTs a decklist to its backend
-- and spawns the card JSON streamed back. We hit that backend directly (rather
-- than the table object, which self-updates its own script) so "scryfall <name>"
-- loads a single card as a one-line "deck". Contract mirrors the importer's
-- api.deck request: lang rides in the Accept-Language header, everything else in
-- the JSON body, and the response is newline-delimited JSON.
rikrassenBuildURL = "https://importer.rikrassen.xyz/build"
rikrassenClientVersion = "v0.11.0"
rikrassenLang = "en"

-- load a single card named `query` for `color` through rikrassen's importer
function fetchCardViaRikrassen(color, query)
	local player = Player[color]
	if player == nil or not player.seated then
		return
	end
	-- the backend positions the spawned card relative to the player's hand
	local hand = player.getHandTransform(1)
	if hand == nil then
		broadcastToColor("Take a seat to load a card.", color, { 1, 0.3, 0.3 })
		return
	end
	local body = JSON.encode({
		url = "",
		data = "1 " .. query,
		useStates = true,
		preferOriginalPrinting = false,
		hand = hand,
	})
	local headers = {
		Accept = "application/x-ndjson",
		["Content-Type"] = "application/json",
		["X-Client-Version"] = rikrassenClientVersion,
		["Accept-Language"] = rikrassenLang,
	}
	broadcastToColor("Loading " .. query .. "...", color, { 1, 0.85, 0.2 })
	WebRequest.custom(rikrassenBuildURL, "POST", true, body, headers, function(resp)
		rikrassenBuildDone(resp, color, query)
	end)
end

-- handle the streamed ndjson response: spawn each card line, report any errors
function rikrassenBuildDone(resp, color, query)
	if resp.is_error then
		broadcastToColor("Importer request failed for '" .. query .. "'.", color, { 1, 0.3, 0.3 })
		return
	end
	if not resp.is_done then
		return
	end
	local issues = {}
	local spawned = 0
	for line in resp.text:gmatch("[^\r\n]+") do
		if line:match('^{"error":') then
			local ok, data = pcall(JSON.decode, line)
			table.insert(issues, (ok and data and data.error) or "unknown error")
		else
			spawnObjectJSON({ json = line })
			spawned = spawned + 1
		end
	end
	if #issues > 0 then
		broadcastToColor("Importer issue for '" .. query .. "': " .. table.concat(issues, ", "), color, { 1, 0.3, 0.3 })
	elseif spawned == 0 then
		broadcastToColor("No card found for '" .. query .. "'.", color, { 1, 0.3, 0.3 })
	end
end

-- manage turns through chat commands
function onChat(message, pl)
	-- "scryfall <query>" loads a single card via rikrassen's importer. Parse the
	-- raw message first so card names keep their case and punctuation.
	local query = message:match("^[Ss]cryfall%s+(.+)")
	if query ~= nil then
		query = query:gsub("^%s+", ""):gsub("%s+$", "")
		if query ~= "" then
			fetchCardViaRikrassen(pl.color, query)
		end
		return false
	end

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
VERSION = "v0.2.8"

local PATCH_NOTES_TAG = "patchNotesButton"
local RELEASES_API = "https://api.github.com/repos/klrmngr/mtg-edh-4player/releases"

-- split a "vX.Y.Z" tag into numeric parts, e.g. "v0.1.10" -> {0, 1, 10}
function parseVersion(s)
	local parts = {}
	for n in tostring(s or ""):gmatch("%d+") do
		table.insert(parts, tonumber(n))
	end
	return parts
end

-- is version tag `a` newer than `b`? (numeric, component-wise; missing = 0)
function versionNewer(a, b)
	local pa = parseVersion(a)
	local pb = parseVersion(b)
	for i = 1, math.max(#pa, #pb) do
		local x = pa[i] or 0
		local y = pb[i] or 0
		if x ~= y then
			return x > y
		end
	end
	return false
end

-- the spawned patch-notes tile, or nil if it isn't on the table yet
function patchNotesTile()
	for _, obj in ipairs(getAllObjects()) do
		if obj.getGMNotes() == PATCH_NOTES_TAG then
			return obj
		end
	end
	return nil
end

-- on load: ask GitHub for the newest release and, if it's newer than the loaded
-- VERSION, flag it on the patch-notes tile and tell everyone once
function checkForUpdate()
	WebRequest.get(RELEASES_API, function(req)
		if req.is_error then
			return
		end
		local releases = JSONdecode(req.text)
		if type(releases) ~= "table" or releases[1] == nil then
			return
		end
		local latest = releases[1].tag_name or releases[1].name
		if latest == nil or not versionNewer(latest, VERSION) then
			return
		end
		broadcastToAll(
			"A newer version (" .. latest .. ") is available -- this table is running " .. VERSION .. ".",
			{ 1, 0.85, 0.2 }
		)
		-- flag the tile once it has finished spawning
		Wait.condition(function()
			local tile = patchNotesTile()
			if tile ~= nil then
				tile.setColorTint({ 0.85, 0.6, 0.1 })
				tile.editButton({ index = 0, label = VERSION .. "\nupdate: " .. latest })
			end
		end, function()
			return patchNotesTile() ~= nil
		end, 10)
	end)
end

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
	-- escape XML specials so stray <, >, & in the notes (e.g. a PR title that
	-- mentions a tag) don't break the panel's XML when injected via setValue
	body = body:gsub("&", "&amp;")
	body = body:gsub("<", "&lt;")
	body = body:gsub(">", "&gt;")
	-- markdown -> TTS rich text (these tags are produced after escaping, so they
	-- stay real tags while the notes' own angle brackets are now literal text)
	body = body:gsub("%*%*(.-)%*%*", "<b>%1</b>")
	body = body:gsub("## (.-)\n", "<b>%1</b>\n")
	body = body:gsub("\n%s*%* ", "\n• ")
	body = body:gsub("^%* ", "• ")
	-- trim surrounding whitespace
	body = body:gsub("^%s+", ""):gsub("%s+$", "")
	return body
end
--------------------------------- SETTINGS -------------------------------------
-- Per-player settings. Each player opens a private settings panel from the gear
-- button in their UI; the panel is shown only to them via the same visibility
-- rules the Scryfall panels use (visibleOpenRules / visibleCloseRules). Values
-- are stored per colour in playerSettings and persisted across save/load.
--
-- NOTE: the panel is a single shared widget set. A toggle always writes to the
-- *acting* player's settings (player.color), so storage stays correctly
-- per-player; only the on-screen toggle states would be shared if two players
-- happened to have the panel open at the same instant.

-- default value for every setting, applied to each colour on load
settingsDefaults = {
	oppDrawTriggers = false, -- notify this player about draw triggers (theirs / others')
	                         -- default off: feature is unfinished / somewhat buggy
	drawSkipReminder = true, -- warn (and stop the draw) on a "skip your draw step" card
	abilityRestrictions = false, -- remind on tapping a permanent whose activated abilities are prohibited
	                             -- default off: feature is unfinished / somewhat buggy
	searchRestrictions = true, -- block fetchland resolution when a tutor/search-hate card is in play
	landTracker = true,      -- track / show lands entered this turn on this player's mat
	fetchPreviews = true,    -- float library-land previews above this player's fetchlands
	fetchFromClone = false,  -- read those previews from the game-start deck clone instead of
	                         -- the live library, so an opponent's hidden removal (Praetor's
	                         -- Grasp, etc.) can't leak which land left. Off = live library.
	commanderQOL = true,     -- spawn the per-commander QOL buttons (Etali trigger, Ral grid)
	revealResetSecs = 30,    -- seconds of inactivity before the reveal count resets
}

-- panel toggle id -> settings key it controls
settingsToggleIds = {
	setOppDrawTriggers = "oppDrawTriggers",
	setDrawSkipReminder = "drawSkipReminder",
	setAbilityRestrictions = "abilityRestrictions",
	setSearchRestrictions = "searchRestrictions",
	setLandTracker = "landTracker",
	setFetchPreviews = "fetchPreviews",
	setFetchFromClone = "fetchFromClone",
	setCommanderQOL = "commanderQOL",
}

-- colour -> { key = value }
playerSettings = playerSettings or {}

settingsColors = { "White", "Red", "Yellow", "Blue" }

-- settings the host can enforce on everyone (booleans only). When a key is
-- enforced, getSetting returns the enforced value for every colour and each
-- player's own toggle for it is greyed out. Defaults: nothing enforced, all
-- enforced values false.
enforceableKeys = {
	"oppDrawTriggers",
	"drawSkipReminder",
	"abilityRestrictions",
	"searchRestrictions",
	"landTracker",
	"fetchPreviews",
	"fetchFromClone",
	"commanderQOL",
}

-- key -> { enforced = bool, value = bool }
enforcedSettings = enforcedSettings or {}

function initEnforced()
	enforcedSettings = enforcedSettings or {}
	for _, key in ipairs(enforceableKeys) do
		local e = enforcedSettings[key] or {}
		if e.enforced == nil then
			e.enforced = false
		end
		if e.value == nil then
			e.value = false
		end
		enforcedSettings[key] = e
	end
end

-- pull the settings key out of a host-panel widget id ("hostEnf_<key>" /
-- "hostVal_<key>"), or nil if the prefix doesn't match
function hostKeyFromId(id, prefix)
	if id ~= nil and id:sub(1, #prefix) == prefix then
		return id:sub(#prefix + 1)
	end
	return nil
end

-- fill in any missing colours / keys with defaults; called from onload after any
-- saved state has been restored
function initSettings()
	playerSettings = playerSettings or {}
	for _, color in ipairs(settingsColors) do
		playerSettings[color] = playerSettings[color] or {}
		for key, def in pairs(settingsDefaults) do
			if playerSettings[color][key] == nil then
				playerSettings[color][key] = def
			end
		end
	end
end

-- read a setting for a colour. A host-enforced setting overrides every player's
-- own value; otherwise fall back to the player's value, then the default.
function getSetting(color, key)
	local e = enforcedSettings[key]
	if e ~= nil and e.enforced then
		return e.value
	end
	local s = playerSettings[color]
	if s ~= nil and s[key] ~= nil then
		return s[key]
	end
	return settingsDefaults[key]
end

---------------------------------- PERSISTENCE ---------------------------------
-- TTS serialises the Global script state via onSave; we stash playerSettings in
-- it and read it back in onload(saved). Tolerant of a nil / malformed blob.
-- Both casings are defined because this table's entry point is lower-case
-- onload(); whichever name TTS calls, the other is simply dead.
function saveSettings()
	return JSON.encode({ playerSettings = playerSettings, enforcedSettings = enforcedSettings })
end

function restoreSettings(saved)
	if saved ~= nil and saved ~= "" then
		local ok, decoded = pcall(JSON.decode, saved)
		if ok and type(decoded) == "table" then
			if type(decoded.playerSettings) == "table" then
				playerSettings = decoded.playerSettings
			end
			if type(decoded.enforcedSettings) == "table" then
				enforcedSettings = decoded.enforcedSettings
			end
		end
	end
	initSettings()
	initEnforced()
end

function onSave()
	return saveSettings()
end

function onsave()
	return saveSettings()
end

-------------------------------- PLAYER PANEL ----------------------------------
-- set each per-player toggle's enabled state to match host enforcement: an
-- enforced setting is locked (non-interactable) and shows the enforced value; an
-- unenforced setting is editable and, when a viewer colour is given, shows that
-- player's own value.
function applyEnforcementToPlayerPanel(color)
	for id, key in pairs(settingsToggleIds) do
		local e = enforcedSettings[key]
		if e ~= nil and e.enforced then
			UI.setAttribute(id, "isOn", e.value and "True" or "False")
			UI.setAttribute(id, "interactable", "false")
		else
			UI.setAttribute(id, "interactable", "true")
			if color ~= nil then
				UI.setAttribute(id, "isOn", getSetting(color, key) and "True" or "False")
			end
		end
	end
end

-- reflect the opening player's stored settings into the shared widgets, lock any
-- host-enforced ones, then show the panel only to them
function openSettings(player)
	if player == nil or player.color == "Grey" then
		return
	end
	local color = player.color
	applyEnforcementToPlayerPanel(color)
	UI.setAttribute("setRevealResetSecs", "text", tostring(getSetting(color, "revealResetSecs")))
	visibleOpenRules(color, "SettingsPanel")
end

function closeSettings(player)
	visibleCloseRules(player, "SettingsPanel")
end

-- a toggle changed: write the acting player's setting (ignored if the host has
-- enforced it)
function settingsToggle(player, value, id)
	local key = settingsToggleIds[id]
	if key == nil or player == nil then
		return
	end
	local e = enforcedSettings[key]
	if e ~= nil and e.enforced then
		-- locked by the host; snap the widget back to the enforced value
		UI.setAttribute(id, "isOn", e.value and "True" or "False")
		return
	end
	playerSettings[player.color] = playerSettings[player.color] or {}
	local on = (value == "True" or value == true)
	playerSettings[player.color][key] = on
	UI.setAttribute(id, "isOn", on and "True" or "False")
	-- the land tracker + fetch previews are passive, so refresh them the moment they
	-- are toggled (fetchFromClone changes the preview source, so refresh it too)
	if key == "landTracker" then
		refreshLandTrackerText(player.color)
	elseif key == "fetchPreviews" or key == "fetchFromClone" then
		refreshFetchPreviewsForColor(player.color)
	end
end

--------------------------------- HOST PANEL -----------------------------------
-- second, host-only menu: per setting an "enforced" toggle and a "value" toggle.
-- Enforcing a setting forces it on every player (via getSetting) and greys out
-- their own toggle; unenforcing hands control back to each player.

function refreshAllLandTrackers()
	for _, color in ipairs(settingsColors) do
		refreshLandTrackerText(color)
	end
end

function openHostSettings(player)
	if player == nil then
		return
	end
	if not player.host then
		broadcastToColor("Host settings are host-only.", player.color, { 0.9, 0.5, 0.2 })
		return
	end
	for _, key in ipairs(enforceableKeys) do
		local e = enforcedSettings[key]
		UI.setAttribute("hostEnf_" .. key, "isOn", e.enforced and "True" or "False")
		UI.setAttribute("hostVal_" .. key, "isOn", e.value and "True" or "False")
		-- the value only matters while enforced, so lock it otherwise
		UI.setAttribute("hostVal_" .. key, "interactable", e.enforced and "true" or "false")
	end
	visibleOpenRules(player.color, "HostSettingsPanel")
end

function closeHostSettings(player)
	visibleCloseRules(player, "HostSettingsPanel")
end

function hostToggleEnforced(player, value, id)
	if player == nil or not player.host then
		return
	end
	local key = hostKeyFromId(id, "hostEnf_")
	if key == nil or enforcedSettings[key] == nil then
		return
	end
	local on = (value == "True" or value == true)
	enforcedSettings[key].enforced = on
	UI.setAttribute(id, "isOn", on and "True" or "False")
	UI.setAttribute("hostVal_" .. key, "interactable", on and "true" or "false")
	applyEnforcementToPlayerPanel(nil)
	if key == "landTracker" then
		refreshAllLandTrackers()
	elseif key == "fetchPreviews" or key == "fetchFromClone" then
		refreshAllFetchPreviews()
	end
end

function hostToggleValue(player, value, id)
	if player == nil or not player.host then
		return
	end
	local key = hostKeyFromId(id, "hostVal_")
	if key == nil or enforcedSettings[key] == nil then
		return
	end
	local on = (value == "True" or value == true)
	enforcedSettings[key].value = on
	UI.setAttribute(id, "isOn", on and "True" or "False")
	applyEnforcementToPlayerPanel(nil)
	if key == "landTracker" then
		refreshAllLandTrackers()
	elseif key == "fetchPreviews" or key == "fetchFromClone" then
		refreshAllFetchPreviews()
	end
end

-- reveal-reset timeout committed
function settingsRevealReset(player, value, id)
	if player == nil then
		return
	end
	local n = tonumber(value)
	if n == nil or n < 1 then
		n = settingsDefaults.revealResetSecs
	end
	n = math.floor(n)
	playerSettings[player.color] = playerSettings[player.color] or {}
	playerSettings[player.color].revealResetSecs = n
	UI.setAttribute("setRevealResetSecs", "text", tostring(n))
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
