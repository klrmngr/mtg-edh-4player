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
-- fetchland guid -> spawn generation; bumped on every clear so an in-flight
-- staggered spawn (see showFetchPreviews) knows to stop
fetchPreviewGen = {}
-- preview guid -> { color, fetchGuid, cardGuid, name } for resolving double-clicks
fetchPreviewData = {}
-- preview guid -> last click time (for double-click detection)
fetchPreviewLastClick = {}
fetchDoubleClickSecs = 0.5

-- If the card is a fetch-style land, describe what it can search for; otherwise
-- return nil. Result: { subtypes = {...}, requireBasic = bool, anyBasic = bool }.
--   subtypes    - named land subtypes the fetch lists (e.g. island, mountain)
--   requireBasic - the fetch says "basic", so only basic lands qualify
--   anyBasic    - "basic land" with no named subtype: any basic land qualifies
function fetchLandTargets(card)
	if not cardIsLand(card) then
		return nil
	end
	local desc = (card.getDescription() or ""):lower()
	if not desc:find("search your library") or not desc:find("onto the battlefield") then
		return nil
	end
	local phrase = desc:match("search your library for (.-) card") or desc
	-- "basic Island, ..." / "basic land" restrict to basics; "nonbasic" does not
	local requireBasic = phrase:find("basic") ~= nil and phrase:find("nonbasic") == nil
	local subtypes = {}
	for _, t in ipairs(fetchSubtypes) do
		if phrase:find(t) then
			table.insert(subtypes, t)
		end
	end
	local anyBasic = requireBasic and #subtypes == 0
	if #subtypes == 0 and not anyBasic then
		return nil
	end
	return { subtypes = subtypes, requireBasic = requireBasic, anyBasic = anyBasic }
end

-- does a library card (matched on its nickname / type line) satisfy the fetch?
function fetchCardMatches(nickname, targets)
	-- match only against the type line, not the card name: nicknames are
	-- "<name>\n<type line> <cmc>CMC", and a name can contain a subtype substring
	-- (e.g. Misty Rainforest -> "forest") that must not count as a match
	local typeLine = ((nickname or ""):match("[\r\n]+(.*)$") or ""):lower()
	if not typeLine:find("land") then
		return false
	end
	local isBasic = typeLine:find("basic land") ~= nil
	-- "basic land card" with no named subtype: any basic land
	if targets.anyBasic then
		return isBasic
	end
	-- a fetch that names "basic <subtype>" only takes basic lands of that subtype
	if targets.requireBasic and not isBasic then
		return false
	end
	for _, t in ipairs(targets.subtypes) do
		if typeLine:find(t) then
			return true
		end
	end
	return false
end

-- remove the previews belonging to a fetchland
function clearFetchPreviews(guid)
	-- invalidate any in-flight staggered spawn for this fetchland
	fetchPreviewGen[guid] = (fetchPreviewGen[guid] or 0) + 1
	local list = fetchPreviews[guid]
	if list == nil then
		return
	end
	for _, p in ipairs(list) do
		if p ~= nil then
			fetchPreviewData[p.getGUID()] = nil
			fetchPreviewLastClick[p.getGUID()] = nil
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
	local fetchGuid = fetch.getGUID()
	-- generation was just bumped by clearFetchPreviews above; capture it so the
	-- staggered spawn below stops if a newer call supersedes this one
	local gen = fetchPreviewGen[fetchGuid]

	-- spawn the previews one per frame rather than all at once -- spawning every
	-- matching land in a single frame causes a visible stutter
	local function spawnPreview(i)
		if i > #matches then
			return
		end
		-- abort if this run was superseded (cleared/re-shown) or the fetch moved
		if fetchPreviewGen[fetchGuid] ~= gen or not zoneContains(zone, fetch) then
			return
		end
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
		local cardData = matches[i]
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
				obj.setLock(true)
				-- only the land zone's owner sees their own fetch previews
				obj.setInvisibleTo(allBut(color))
				-- record what this preview resolves to, and add a click target
				fetchPreviewData[obj.getGUID()] = {
					color = color,
					fetchGuid = fetchGuid,
					cardGuid = cardData.GUID,
					name = mainCardName(cardData.Nickname),
				}
				obj.createButton({
					click_function = "fetchPreviewClick",
					function_owner = Global,
					label = "",
					position = { 0, 0.3, 0 },
					rotation = { 0, 0, 0 },
					width = 1500,
					height = 2100,
					scale = { 1, 1, 1 },
					color = { 0, 0, 0, 0 },
				})
			end,
		})
		-- the list may have been cleared between scheduling and now
		if fetchPreviews[fetchGuid] ~= nil then
			table.insert(fetchPreviews[fetchGuid], preview)
		end
		Wait.frames(function()
			spawnPreview(i + 1)
		end, 1)
	end
	spawnPreview(1)
end

-- double-click handler on a preview: only the land zone's owner can resolve it
function fetchPreviewClick(obj, color, alt)
	local info = fetchPreviewData[obj.getGUID()]
	if info == nil or color ~= info.color then
		return
	end
	local guid = obj.getGUID()
	local now = os.clock()
	local last = fetchPreviewLastClick[guid]
	if last ~= nil and (now - last) <= fetchDoubleClickSecs then
		fetchPreviewLastClick[guid] = nil
		resolveFetch(info)
	else
		fetchPreviewLastClick[guid] = now
	end
end

-- carry out a fetch: lose 1 life (only if the land says so), pull the chosen
-- land next to the fetchland, and send the fetchland to the graveyard
function resolveFetch(info)
	local color = info.color
	local fetch = getObjectFromGUID(info.fetchGuid)

	-- 1. lose 1 life, but only if the fetchland actually says "pay 1 life"
	-- (some lands -- Evolving Wilds, panoramas, etc. -- fetch for free)
	if fetch ~= nil and (fetch.getDescription() or ""):lower():find("pay 1 life") then
		loseLife(color, 1)
	end

	-- 2. pull the chosen land from the library, place it next to the fetchland
	local rotY = fetch ~= nil and fetch.getRotation().y or 0
	local landPos
	if fetch ~= nil then
		local zone = data[color]["landZone"]
		local yaw = math.rad(zone.getRotation().y)
		local rgt = { x = math.cos(yaw), z = -math.sin(yaw) }
		local b = fetch.getPosition()
		landPos = { x = b.x + rgt.x * 2.6, y = b.y + 1, z = b.z + rgt.z * 2.6 }
	else
		landPos = data[color]["landZone"].getPosition()
	end
	-- find the chosen land in the library by name (deck.getObjects() gives live
	-- guids/indexes; the GUID captured at preview time isn't reliable) and take
	-- exactly that card by index
	local deck = getDeckFromZone(data[color]["libraryZone"])
	local taken = false
	if deck ~= nil then
		for _, entry in ipairs(deck.getObjects()) do
			if mainCardName(entry.name) == info.name then
				pcall(function()
					deck.takeObject({
						index = entry.index,
						position = landPos,
						rotation = { 0, rotY, 0 },
						smooth = true,
					})
				end)
				taken = true
				break
			end
		end
	end
	if not taken then
		-- fallback: the land is a loose card in the library, not inside a deck
		local loose = getObjectFromGUID(info.cardGuid)
		if loose ~= nil then
			loose.setRotationSmooth({ 0, rotY, 0 }, false, true)
			loose.setPositionSmooth(landPos, false, true)
		end
	end

	-- shuffle the library after fetching (let the take settle, then re-fetch the
	-- deck in case it changed)
	if taken then
		Wait.time(function()
			local d = getDeckFromZone(data[color]["libraryZone"])
			if d ~= nil then
				pcall(function()
					d.shuffle()
				end)
			end
		end, 0.5)
	end

	-- 3. send the fetchland to the graveyard (reuse the discard placement)
	if fetch ~= nil then
		discardCard(fetch, color)
	end

	-- previews are no longer valid
	clearFetchPreviews(info.fetchGuid)
end

-- subtract n life from a player's Life_Tracker and update its display
function loseLife(color, n)
	local tracker = data[color] and data[color]["lifeTracker"]
	if tracker == nil then
		return
	end
	local count = tonumber(tracker.getVar("count")) or 0
	count = count - n
	tracker.setVar("count", count)
	tracker.editButton({ index = 0, label = tostring(count) })
	tracker.call("updateSave")
end

-- event hooks (called from onObjectEnterZone / onObjectLeaveZone)
function fetchlandEnter(zone, obj)
	if obj == nil or obj.hasTag("FetchPreview") then
		return
	end
	if landZoneColor(zone) == nil or fetchLandTargets(obj) == nil then
		return
	end
	-- wait for the fetchland to come to rest before showing previews, so they
	-- don't pop up mid-drop. Bail if it's been picked up / destroyed or has
	-- since left the zone (fetchlandLeave handles clearing in that case).
	Wait.condition(function()
		if obj ~= nil and zoneContains(zone, obj) then
			showFetchPreviews(zone, obj)
		end
	end, function()
		return obj == nil or obj.resting or not zoneContains(zone, obj)
	end)
end

-- is obj currently inside zone?
function zoneContains(zone, obj)
	if zone == nil or obj == nil then
		return false
	end
	for _, o in ipairs(zone.getObjects()) do
		if o == obj then
			return true
		end
	end
	return false
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
