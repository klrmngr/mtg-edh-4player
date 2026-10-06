------------------------------ CARD TRIGGER BUTTONS -----------------------------
-- Cards whose triggers we can resolve for the player (Mindmoil, Etali, the ping
-- commanders, Ral, ...) carry their buttons on the card itself, and only while it
-- sits on a player's playmat: they are added once the card settles on a mat and
-- removed when it leaves (cardTriggersEnter / cardTriggersLeave, hooked from
-- onObjectEnterZone / onObjectLeaveZone in context_menus.lua). The mat's owner is
-- the card's controller -- they're the one who may click its trigger.
--
-- Each card module registers itself with registerCardTrigger at load time:
--
--   registerCardTrigger({
--     names = { "Etali, Primal Conqueror" },  -- card names (front/back faces)
--     setting = "commanderQOL",                -- mat owner's setting gating it
--     buttons = {                              -- laid out in rows under the card
--       { click_function = "playerEtali", label = "Etali Trigger", tooltip = "..." },
--     },
--   })
--
-- A button may give row (0 = just under the card), col and cols (its slot in a
-- row of that many equal-width buttons), and a label function(color) for labels
-- that carry state (e.g. Ral's counters).

-- layout. A button spans width * scale / cardButtonUnits local units, so a row
-- of cardTriggerRowWidth roughly matches the card's width. Nudge
-- cardButtonUnits if the rows come out wider or narrower than the card.
cardButtonUnits = 420 -- button width units per local unit, at scale 1
cardTriggerScale = 0.6
cardTriggerRowWidth = 1400 -- total width of one row, in button units
cardTriggerSlotGap = 40 -- gap between buttons sharing a row, in button units
cardTriggerTop = 1.9 -- local z of the first row (just below the card face)
cardTriggerRowGap = 0.65 -- local z between rows
cardTriggerHeight = 400

-- registered triggers, by lowercased card name, and every click_function any of
-- them uses (so stale buttons can be told apart from the Encoder's own)
cardTriggersByName = cardTriggersByName or {}
cardTriggerClickFns = cardTriggerClickFns or {}

function registerCardTrigger(def)
	for _, name in ipairs(def.names) do
		cardTriggersByName[name:lower()] = def
	end
	for _, b in ipairs(def.buttons) do
		cardTriggerClickFns[b.click_function] = true
	end
end

-- the trigger registered for this card, or nil (nicknames in this mod are
-- "<name>\n<type line> <cmc>CMC", so compare only the displayed name)
function cardTriggerFor(obj)
	if obj == nil or obj.type ~= "Card" then
		return nil
	end
	return cardTriggersByName[mainCardName(obj.getName()):lower()]
end

-- the colour of the playmat this card is currently sitting on, or nil
function cardMatColor(card)
	if card == nil then
		return nil
	end
	for _, zone in ipairs(card.getZones()) do
		local color = playmatColorOfZone(zone)
		if color ~= nil then
			return color
		end
	end
	return nil
end

--------------------------------- THE BUTTONS -----------------------------------

-- drop every trigger button on the card (high-to-low so indices hold), leaving
-- the Encoder's own buttons alone
function removeCardTriggerButtons(card)
	if card == nil then
		return
	end
	local indices = {}
	for _, b in ipairs(card.getButtons() or {}) do
		if cardTriggerClickFns[b.click_function] then
			table.insert(indices, b.index)
		end
	end
	table.sort(indices, function(a, b)
		return a > b
	end)
	for _, idx in ipairs(indices) do
		card.removeButton(idx)
	end
end

-- local position and width of a button in its row
function cardTriggerSlot(b)
	local cols = b.cols or 1
	local col = b.col or 1
	local slot = cardTriggerRowWidth / cols
	local x = (col - (cols + 1) / 2) * slot * cardTriggerScale / cardButtonUnits
	local z = cardTriggerTop + (b.row or 0) * cardTriggerRowGap
	local width = cols == 1 and cardTriggerRowWidth or math.floor(slot - cardTriggerSlotGap)
	return { x, 0.2, z }, width
end

function cardTriggerLabel(b, color)
	if type(b.label) == "function" then
		return b.label(color)
	end
	return b.label
end

-- hang the card's trigger buttons under it. Clear first so a card that re-enters
-- a mat (or a reload that kept the old buttons) can't end up with two sets.
function addCardTriggerButtons(card, def, color)
	removeCardTriggerButtons(card)
	for _, b in ipairs(def.buttons) do
		local pos, width = cardTriggerSlot(b)
		card.createButton({
			click_function = b.click_function,
			function_owner = self,
			label = cardTriggerLabel(b, color),
			tooltip = b.tooltip,
			position = pos,
			rotation = { 0, 0, 0 },
			width = width,
			height = cardTriggerHeight,
			font_size = b.font_size or 220,
			scale = { cardTriggerScale, cardTriggerScale, cardTriggerScale },
			color = { 0.16, 0.16, 0.16 },
			font_color = { 1, 1, 1 },
			hover_color = { 0.4, 0.4, 0.4 },
			press_color = { 1, 0, 0, 0.2 },
		})
	end
end

-- make the card's buttons match where it is now: a full set while it's on a mat
-- whose owner has the setting on, none otherwise
function syncCardTriggerButtons(card)
	local def = cardTriggerFor(card)
	local color = def and cardMatColor(card)
	if color ~= nil and getSetting(color, def.setting) then
		addCardTriggerButtons(card, def, color)
	elseif card ~= nil and card.type == "Card" then
		removeCardTriggerButtons(card)
	end
end

-- zone hooks (called from onObjectEnterZone / onObjectLeaveZone)
function cardTriggersEnter(zone, obj)
	local def = cardTriggerFor(obj)
	local matColor = playmatColorOfZone(zone)
	if def == nil or matColor == nil or not getSetting(matColor, def.setting) then
		return
	end
	-- only button it once it has come to rest on the mat, and only if it's still
	-- there (a card merely passing through the zone shouldn't get buttons)
	whenSettledInZone(obj, zone, function(o)
		addCardTriggerButtons(o, def, matColor)
	end)
end

function cardTriggersLeave(zone, obj)
	if cardTriggerFor(obj) == nil or playmatColorOfZone(zone) == nil then
		return
	end
	removeCardTriggerButtons(obj)
end

-- flipping a double-faced card swaps in the other face's object: give it the
-- buttons for whichever face is now showing (Ral's back face keeps the grid)
function onObjectStateChange(obj, _oldGuid)
	Wait.frames(function()
		if obj ~= nil then
			syncCardTriggerButtons(obj)
		end
	end, 1)
end

-- The Encoder rebuilds a card's entire button set from its own prop data, which
-- drops any button we put there. It calls us back at the end of each rebuild (see
-- card_buttons.lua), so put ours straight back. No-ops for anything that isn't a
-- trigger card, since this runs for every rebuild of every encoded object.
function cardTriggersReassert(card)
	if cardTriggerFor(card) ~= nil then
		syncCardTriggerButtons(card)
	end
end

-- rescan a player's mat (or every mat, when color is nil) and make the buttons
-- match the settings. Used by onload and by the settings panels, which toggle
-- them live.
function refreshCardTriggerButtons(color)
	for c, _ in pairs(data) do
		local mat = data[c] and data[c]["playmat"]
		if mat ~= nil and (color == nil or c == color) then
			for _, obj in ipairs(mat.getObjects()) do
				if cardTriggerFor(obj) ~= nil then
					syncCardTriggerButtons(obj)
				end
			end
		end
	end
end

-- relabel every button with this click_function on cards on color's mat
function setCardTriggerLabel(color, clickFn, label)
	local mat = data[color] and data[color]["playmat"]
	if mat == nil then
		return
	end
	for _, obj in ipairs(mat.getObjects()) do
		if cardTriggerFor(obj) ~= nil then
			for _, b in ipairs(obj.getButtons() or {}) do
				if b.click_function == clickFn then
					obj.editButton({ index = b.index, label = label })
				end
			end
		end
	end
end

--------------------------------- THE HANDLERS ----------------------------------

-- the mat owner of a clicked trigger card, if the clicker is that owner. Anyone
-- else gets told whose it is; a card whose setting was switched off with the
-- buttons still on it just loses them. Returns nil when the click should no-op.
function cardTriggerController(card, clickerColor, what)
	local def = cardTriggerFor(card)
	local owner = cardMatColor(card)
	if def == nil or owner == nil then
		return nil
	end
	if not getSetting(owner, def.setting) then
		removeCardTriggerButtons(card)
		return nil
	end
	if clickerColor ~= owner then
		Player[clickerColor].broadcast(
			"That's " .. owner .. "'s " .. what .. " -- only they can use it.",
			{ 1, 0.6, 0.2 }
		)
		return nil
	end
	return owner
end
