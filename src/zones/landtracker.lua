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
