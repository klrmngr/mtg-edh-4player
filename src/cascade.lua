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

