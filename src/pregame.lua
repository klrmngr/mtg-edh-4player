-------------------------------- KEEP / PREGAME --------------------------------
-- A "Keep" button sits to the right of each player's Mulligan button, mirroring
-- the Serum Powder button on the left (see buttons.lua). Clicking Keep locks in
-- that player's opening hand and relabels the button to "Pregame"; clicking it
-- again toggles whether the player has a pregame action (Leyline, Chancellor,
-- Gemstone Caverns, ...). Once every seated player has clicked Keep, the table
-- announces who declared a pregame action.

pregameAnnounceDelay = 2 -- grace period after the last Keep before announcing, so
                         -- the final player can still declare a pregame action
pregameAnnounced = false -- table-wide one-shot guard for the announcement

-- set the Keep/Pregame button's label + colour for a player. The button lives on
-- the mulligan token and is found by its click_function.
function setKeepButtonLabel(color, label, active)
	local obj = data[color] and data[color]["mulliganButton"]
	if obj == nil then
		return
	end
	for _, b in ipairs(obj.getButtons() or {}) do
		if b.click_function == "playerKeep" then
			obj.editButton({
				index = b.index,
				label = label,
				font_color = active and { 0.4, 1, 0.4, 100 } or { 1, 1, 1, 100 },
			})
			return
		end
	end
end

-- the game colours seated at the table right now -- only these need to Keep before
-- the pregame announcement fires (an empty seat would otherwise block it forever)
function seatedGameColors()
	local seated = {}
	for color, _ in pairs(data) do
		if Player[color] ~= nil and Player[color].seated then
			table.insert(seated, color)
		end
	end
	return seated
end

-- have all seated players clicked Keep?
function allPlayersKept()
	local seated = seatedGameColors()
	if #seated == 0 then
		return false
	end
	for _, color in ipairs(seated) do
		if not (data[color] and data[color]["kept"]) then
			return false
		end
	end
	return true
end

-- join names into "A", "A and B", or "A, B and C"
function joinNames(names)
	local n = #names
	if n == 0 then
		return ""
	elseif n == 1 then
		return names[1]
	elseif n == 2 then
		return names[1] .. " and " .. names[2]
	end
	return table.concat(names, ", ", 1, n - 1) .. " and " .. names[n]
end

-- announce which seated players declared a pregame action
function announcePregame()
	local withAction = {}
	for _, color in ipairs(seatedGameColors()) do
		if data[color] and data[color]["pregameAction"] then
			table.insert(withAction, color)
		end
	end
	local gold = { 1, 0.85, 0.3 }
	if #withAction == 0 then
		broadcastToAll("Nobody has any pregame actions.", gold)
	elseif #withAction == 1 then
		broadcastToAll(joinNames(withAction) .. " has a pregame action!", gold)
	else
		broadcastToAll(joinNames(withAction) .. " have pregame actions!", gold)
	end
end

-- button handler. First click = keep (relabel to Pregame). Later clicks toggle the
-- player's pregame-action declaration. Owner-only.
function playerKeep(obj, clickerColor, alt)
	local ownerColor = buttonOwner(obj)
	if ownerColor == nil then
		return
	end
	if clickerColor ~= ownerColor then
		warnNotYours(obj, clickerColor)
		return
	end
	if not data[ownerColor]["kept"] then
		-- first click: lock in the keep and reveal the Pregame toggle
		data[ownerColor]["kept"] = true
		data[ownerColor]["pregameAction"] = false
		setKeepButtonLabel(ownerColor, "Pregame", false)
		Player[ownerColor].broadcast("Hand kept -- click Pregame if you have a pregame action.", ownerColor)
		-- once the last seated player keeps, announce after a short grace period so
		-- that final player still has a moment to declare their own pregame action
		if not pregameAnnounced and allPlayersKept() then
			pregameAnnounced = true
			Wait.time(function()
				if allPlayersKept() then
					announcePregame()
				end
			end, pregameAnnounceDelay)
		end
	else
		-- toggle this player's pregame-action declaration
		local on = not data[ownerColor]["pregameAction"]
		data[ownerColor]["pregameAction"] = on
		setKeepButtonLabel(ownerColor, on and "Pregame ✔" or "Pregame", on)
	end
end

-- clear a player's keep/pregame state and restore the button to "Keep". Called
-- from resetMulliganCount so a fresh game (right-click count reset or a board
-- reset) re-arms the keep flow and lets the announcement fire again.
function resetKeepState(color)
	if data[color] == nil then
		return
	end
	data[color]["kept"] = false
	data[color]["pregameAction"] = false
	setKeepButtonLabel(color, "Keep", false)
	pregameAnnounced = false
end
