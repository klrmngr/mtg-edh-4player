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
