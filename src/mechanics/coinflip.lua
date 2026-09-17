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

-- button handler: only the owning player may flip. A tails costs the flipper
-- 1 life. Announce the result to the table. (Counters are not auto-bumped.)
function playerCoinFlip(obj, clickerColor, alt)
	local ownerColor = commandZoneOwnerOf(obj)
	if ownerColor == nil then
		return
	end
	if clickerColor ~= ownerColor then
		Player[clickerColor].broadcast("Only " .. ownerColor .. " may flip this coin.")
		return
	end
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
