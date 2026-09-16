--------------------------------- CARD OWNERSHIP -------------------------------
-- Every card belongs to the player whose deck it came from. We record that owner
-- in the card's GMNotes (a JSON "owner" key; see getCardNote / setCardNote in
-- helpers.lua) the first time the card is seen in one of its owner's PRIVATE
-- areas -- their library zone or their hand. Those areas only ever hold that
-- player's own cards, so it's a safe ownership signal; a playmat is not (it
-- routinely holds cards lent to or stolen by other players). The stamp is written
-- once and never changed.
--
-- We stamp from the Global script rather than inside rikrassen's importer because
-- that importer replaces its own Lua on startup whenever a newer version exists
-- (setLuaScript + reload), which would wipe any hook we added there.
--
-- A card whose owner differs from the playmat it is resting on is glowed in its
-- owner's colour, so a card on someone else's board reads as "not theirs". Gated
-- by the mat owner's "ownerHighlight" setting (host-enforceable): turn it off and
-- foreign cards on YOUR mat aren't highlighted. Cards with no owner stamp (never
-- seen in a private area) are never highlighted.

-- stamp ownership the first time a card is seen in one of its owner's private
-- areas: their library zone (matched by the per-colour zone) or their hand
-- (checked by hand membership). Only unstamped Cards are touched, and ownership,
-- once set, is never overwritten.
function stampOwnershipOnEnter(zone, obj)
	if obj == nil or obj.type ~= "Card" then
		return
	end
	if getCardNote(obj, "owner") ~= nil then
		return
	end
	-- library zone: unambiguous per-colour scripting zone
	for _, color in ipairs(settingsColors) do
		if data[color] ~= nil and zone == data[color]["libraryZone"] then
			setCardNote(obj, "owner", color)
			return
		end
	end
	-- hand: only your own cards sit in your hand
	for _, color in ipairs(settingsColors) do
		for _, held in ipairs(Player[color].getHandObjects(1)) do
			if held == obj then
				setCardNote(obj, "owner", color)
				return
			end
		end
	end
end

-- guids we've glowed as foreign, so onObjectLeaveZone only ever clears highlights
-- we set here -- transient glows from other systems (cascade, reveal, ...) are
-- left untouched.
ownerHighlighted = ownerHighlighted or {}

-- the colour whose playmat scripting zone this is, or nil if it isn't a playmat
function playmatColorOfZone(zone)
	for _, color in ipairs(settingsColors) do
		local mat = data[color] and data[color]["playmat"]
		if mat ~= nil and zone == mat then
			return color
		end
	end
	return nil
end

-- a card entered a zone: if it's a playmat and the card belongs to someone else,
-- glow it in the owner's colour
function ownershipMatEnter(zone, obj)
	if obj == nil or obj.type ~= "Card" then
		return
	end
	local matColor = playmatColorOfZone(zone)
	if matColor == nil then
		return
	end
	if not getSetting(matColor, "ownerHighlight") then
		return
	end
	local owner = getCardNote(obj, "owner")
	if owner ~= nil and owner ~= matColor and data[owner] ~= nil then
		obj.highlightOn(stringColorToRGB(owner))
		ownerHighlighted[obj.getGUID()] = true
	end
end

-- a card left a zone: if we had glowed it as foreign, clear that glow
function ownershipMatLeave(zone, obj)
	if obj == nil or obj.type ~= "Card" then
		return
	end
	if playmatColorOfZone(zone) == nil then
		return
	end
	local guid = obj.getGUID()
	if ownerHighlighted[guid] then
		obj.highlightOff()
		ownerHighlighted[guid] = nil
	end
end
