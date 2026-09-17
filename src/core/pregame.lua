-------------------------------- KEEP / PREGAME --------------------------------
-- A big "Keep" button sits in the centre of each player's playmat. Left-clicking
-- it locks in that player's opening hand; right-clicking privately declares that
-- the player has a pregame action (Leyline, Chancellor, Gemstone Caverns, ...).
--
-- The button never changes its label -- doing so would leak whether a player has
-- a pregame action to the rest of the table. Instead each click just sends the
-- clicker a private message. Once every seated player has kept, the table
-- announces who declared a pregame action and every keep button hides itself
-- until the next round of mulligans re-arms the flow.

pregameAnnounceDelay = 2 -- grace period after the last Keep before announcing, so
                         -- the final player can still declare a pregame action
pregameAnnounced = false -- table-wide one-shot guard for the announcement

-- create the keep button in the centre of one player's playmat. The button lives
-- on the mat object and is found later by its click_function. Called once at load
-- (after the land tracker has claimed the mat's index-0 button) via spawnKeepButtons.
function createKeepButton(color)
	if not getSetting(color, "keepPregameFlow") then
		return
	end
	local mat = data[color] and data[color]["playmat"]
	if mat == nil then
		return
	end
	-- inverse-scale so the button renders at a consistent size no matter how big
	-- the mat is scaled (same trick the land tracker uses)
	local scale = mat.getScale()
	local textScale = { 1 / scale.x, 1 / scale.y, 1 / scale.z }
	mat.createButton({
		click_function = "playerKeep",
		function_owner = Global,
		label = "Keep",
		tooltip = "                    [b]Keep[/b]\n[i]left click[/i] to keep your hand\n[i]right click[/i] if you have a pregame action",
		position = { 0, 0.1, 0 },
		scale = textScale,
		width = 3500,
		height = 1400,
		font_size = 800,
		color = { 1, 1, 1, 0 },
		font_color = { 1, 1, 1, 100 },
		hover_color = { 1, 1, 1, 0.1 },
		press_color = { 1, 0, 0, 0.2 },
	})
end

-- create every player's keep button. Called from onload after spawnLandTrackerText.
function spawnKeepButtons()
	for color, _ in pairs(data) do
		createKeepButton(color)
	end
end

-- show or hide a player's keep button without disturbing the land tracker's own
-- button (index 0). Found by click_function so button indices never need tracking.
function setKeepButtonVisible(color, visible)
	local mat = data[color] and data[color]["playmat"]
	if mat == nil then
		return
	end
	for _, b in ipairs(mat.getButtons() or {}) do
		if b.click_function == "playerKeep" then
			mat.editButton({
				index = b.index,
				label = visible and "Keep" or "",
				width = visible and 3500 or 0,
				height = visible and 1400 or 0,
			})
			return
		end
	end
end

-- reconcile a player's keep button with their keepPregameFlow setting: create or
-- show it when enabled, hide it when disabled. Called when the setting is toggled
-- (per-player or host-enforced), since the button is otherwise spawned once at load.
function refreshKeepButton(color)
	local mat = data[color] and data[color]["playmat"]
	if mat == nil then
		return
	end
	local exists = false
	for _, b in ipairs(mat.getButtons() or {}) do
		if b.click_function == "playerKeep" then
			exists = true
			break
		end
	end
	if getSetting(color, "keepPregameFlow") then
		if exists then
			setKeepButtonVisible(color, true)
		else
			createKeepButton(color)
		end
	elseif exists then
		setKeepButtonVisible(color, false)
	end
end

-- the game colours seated at the table right now that are running the keep flow --
-- only these need to Keep before the pregame announcement fires. An empty seat would
-- otherwise block it forever, and a player who has the flow disabled never gets a
-- Keep button, so they must be excluded too.
function seatedGameColors()
	local seated = {}
	for color, _ in pairs(data) do
		if Player[color] ~= nil and Player[color].seated and getSetting(color, "keepPregameFlow") then
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

-- announce which seated players declared a pregame action, then hide every keep
-- button until the next round of mulligans re-arms them
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
	for color, _ in pairs(data) do
		setKeepButtonVisible(color, false)
	end
end

-- button handler. Left click = keep your hand; right click = privately declare a
-- pregame action (toggled). Neither changes the button, so nothing about a
-- player's hand or pregame action leaks to the rest of the table. Owner-only.
function playerKeep(obj, clickerColor, alt)
	local ownerColor = buttonOwner(obj)
	if ownerColor == nil then
		return
	end
	if clickerColor ~= ownerColor then
		warnNotYours(obj, clickerColor)
		return
	end
	if alt then
		-- right click: privately toggle this player's pregame-action declaration
		local on = not data[ownerColor]["pregameAction"]
		data[ownerColor]["pregameAction"] = on
		Player[ownerColor].broadcast(on and "Pregame action noted." or "Pregame action cleared.", ownerColor)
		return
	end
	if data[ownerColor]["kept"] then
		return -- already kept; nothing to do on another left click
	end
	-- first left click: lock in the keep (privately -- no visible change)
	data[ownerColor]["kept"] = true
	Player[ownerColor].broadcast("Hand kept -- right-click Keep if you have a pregame action.", ownerColor)
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
end

-- clear a player's keep/pregame state and re-show the button. Called from
-- resetMulliganCount so a fresh game (right-click count reset or a board reset)
-- re-arms the keep flow and lets the announcement fire again.
function resetKeepState(color)
	if data[color] == nil then
		return
	end
	data[color]["kept"] = false
	data[color]["pregameAction"] = false
	refreshKeepButton(color)
	pregameAnnounced = false
end
