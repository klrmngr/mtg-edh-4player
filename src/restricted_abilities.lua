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
