--------------------------------- FETCHLANDS ----------------------------------
-- When a fetch-style land ("Search your library for a <type> [or <type>] card
-- ... put it onto the battlefield") sits in a player's land zone, show small
-- previews of the matching lands still in that player's library, floating above
-- the fetchland. The previews are locked, non-interactable copies -- they do
-- nothing on click (yet). The real cards stay in the library untouched.

-- the land subtypes a fetch can name
fetchSubtypes = { "plains", "island", "swamp", "mountain", "forest", "wastes" }

-- preview layout (tunable, mirrors moon-mtg-equip's 0.475 scale)
fetchPreviewScale = 0.475
fetchPreviewUp = 2.6 -- distance "above" the fetchland (along its forward)
fetchPreviewSpacing = 1.2 -- horizontal gap between previews
fetchPreviewPerRow = 6 -- wrap to a new (higher) row after this many
fetchPreviewRowStep = 1.8 -- vertical gap between wrapped rows

-- fetchland guid -> array of spawned preview objects
fetchPreviews = {}

-- If the card is a fetch-style land, return a lowercased list of the land types
-- it can search for ("basic" means any basic land); otherwise return nil.
function fetchLandTargets(card)
	if not cardIsLand(card) then
		return nil
	end
	local desc = (card.getDescription() or ""):lower()
	if not desc:find("search your library") or not desc:find("onto the battlefield") then
		return nil
	end
	local phrase = desc:match("search your library for (.-) card") or desc
	local targets = {}
	if phrase:find("basic land") then
		table.insert(targets, "basic")
	end
	for _, t in ipairs(fetchSubtypes) do
		if phrase:find(t) then
			table.insert(targets, t)
		end
	end
	if #targets == 0 then
		return nil
	end
	return targets
end

-- does a library card (matched on its nickname / type line) satisfy the fetch?
function fetchCardMatches(nickname, targets)
	local typeLine = (nickname or ""):lower()
	if not typeLine:find("land") then
		return false
	end
	for _, t in ipairs(targets) do
		if t == "basic" then
			if typeLine:find("basic land") then
				return true
			end
		elseif typeLine:find(t) then
			return true
		end
	end
	return false
end

-- remove the previews belonging to a fetchland
function clearFetchPreviews(guid)
	local list = fetchPreviews[guid]
	if list == nil then
		return
	end
	for _, p in ipairs(list) do
		if p ~= nil then
			pcall(function()
				destroyObject(p)
			end)
		end
	end
	fetchPreviews[guid] = nil
end

-- spawn the preview row(s) above a fetchland from the matching library cards
function showFetchPreviews(zone, fetch)
	local color = landZoneColor(zone)
	if color == nil then
		return
	end
	local targets = fetchLandTargets(fetch)
	if targets == nil then
		return
	end
	clearFetchPreviews(fetch.getGUID())

	local deck = getDeckFromZone(data[color]["libraryZone"])
	if deck == nil then
		return
	end
	local contained = deck.getData().ContainedObjects or {}
	local matches = {}
	local seen = {} -- dedupe identical lands and skip blank / face-down (nameless) cards
	for _, cardData in ipairs(contained) do
		if fetchCardMatches(cardData.Nickname, targets) then
			local name = mainCardName(cardData.Nickname)
			if name ~= "" and not seen[name] then
				seen[name] = true
				table.insert(matches, cardData)
			end
		end
	end

	fetchPreviews[fetch.getGUID()] = {}
	-- orient previews to the land zone (consistent "above"), not the card, which
	-- the player may have rotated. Build unit direction vectors from the zone's
	-- yaw via trig so they're independent of how TTS scales transform vectors.
	-- "Above" on the mat is -forward.
	local rot = { 0, zone.getRotation().y, 0 }
	local yaw = math.rad(zone.getRotation().y)
	local fwd = { x = math.sin(yaw), z = math.cos(yaw) }
	local rgt = { x = math.cos(yaw), z = -math.sin(yaw) }
	local base = fetch.getPosition()
	for i, cardData in ipairs(matches) do
		local idx = i - 1
		local row = math.floor(idx / fetchPreviewPerRow)
		local col = idx % fetchPreviewPerRow
		local nInRow = math.min(fetchPreviewPerRow, #matches - row * fetchPreviewPerRow)
		local offRight = (col - (nInRow - 1) / 2) * fetchPreviewSpacing
		local offFwd = -(fetchPreviewUp + row * fetchPreviewRowStep)
		local pos = {
			x = base.x + fwd.x * offFwd + rgt.x * offRight,
			y = base.y + 0.5,
			z = base.z + fwd.z * offFwd + rgt.z * offRight,
		}

		-- tag the copy so the land tracker / fetch logic ignore it
		cardData.Tags = { "FetchPreview" }
		-- force the small scale in the data too (in case the spawn param is ignored)
		cardData.Transform = cardData.Transform or {}
		cardData.Transform.scaleX = fetchPreviewScale
		cardData.Transform.scaleY = fetchPreviewScale
		cardData.Transform.scaleZ = fetchPreviewScale
		local preview = spawnObjectData({
			data = cardData,
			position = pos,
			rotation = rot,
			scale = { fetchPreviewScale, fetchPreviewScale, fetchPreviewScale },
			callback_function = function(obj)
				obj.setVar("noencode", true)
				obj.interactable = false
				obj.setLock(true)
				-- only the land zone's owner sees their own fetch previews
				obj.setInvisibleTo(allBut(color))
			end,
		})
		table.insert(fetchPreviews[fetch.getGUID()], preview)
	end
end

-- event hooks (called from onObjectEnterZone / onObjectLeaveZone)
function fetchlandEnter(zone, obj)
	if obj == nil or obj.hasTag("FetchPreview") then
		return
	end
	if landZoneColor(zone) == nil or fetchLandTargets(obj) == nil then
		return
	end
	-- let the card settle and the library become readable
	Wait.frames(function()
		showFetchPreviews(zone, obj)
	end, 5)
end

function fetchlandLeave(zone, obj)
	if obj == nil then
		return
	end
	clearFetchPreviews(obj.getGUID())
end

-- on load, clear any orphaned preview copies left over from a previous script
-- reload, then show previews for fetchlands already sitting in land zones
function initFetchlands()
	for _, obj in ipairs(getAllObjects()) do
		if obj.hasTag("FetchPreview") then
			destroyObject(obj)
		end
	end
	fetchPreviews = {}
	for color, _ in pairs(data) do
		local zone = data[color]["landZone"]
		if zone ~= nil then
			for _, obj in ipairs(zone.getObjects()) do
				if not obj.hasTag("FetchPreview") and fetchLandTargets(obj) ~= nil then
					showFetchPreviews(zone, obj)
				end
			end
		end
	end
end
