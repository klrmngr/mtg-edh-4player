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
	-- etali button, directly under the serum powder button
	object.createButton({
		click_function = "playerEtali",
		label = "Etali",
		tooltip = "                  [b]Etali[/b]\nreveal each library until a nonland:\n  lands go to that player's exile,\n  the nonland comes to you",
		width = 4000,
		height = 1000,
		position = { lp.x, 0.1, lp.z + 1.8 },
		font_size = 500,
		color = { 1, 1, 1, 0 },
		font_color = { 1, 1, 1, 100 },
		hover_color = { 1, 1, 1, 0.1 },
		press_color = { 1, 0, 0, 0.2 },
	})
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

