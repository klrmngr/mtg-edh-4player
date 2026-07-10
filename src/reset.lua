----------------------------------- BOARD RESET ----------------------------------
-- A per-player "Reset" button (under the mulligan count) restores that player's
-- board to its game-start state. At the opening hand (the first mulligan bump,
-- detected the same way mulligans are) we snapshot the full library deck and the
-- command zone. Double-clicking Reset destroys that player's Card/Deck objects
-- across their library, hand, battlefield (playmat), graveyard, command zone, and
-- exile, then respawns the snapshot deck + commander(s) and re-shuffles the
-- library. It also restores the player's life to 40 and zeroes the commander
-- damage they've taken from each colour.
--
-- Limitations: cards sitting outside every tracked zone (loose on the table, or
-- taken by another player) and token creatures (Custom_Token) are not destroyed.

resetDoubleClickSecs = 0.5
-- take the game-start snapshot for a player. Called from bumpMulliganCount on
-- each fresh opening hand (count at 0), while the library is still complete. This
-- clone is the single source of truth for both the board reset and the
-- clone-sourced fetch previews (see fetchland.lua).
--
-- Without force, an existing snapshot is kept. Even with force we refuse to
-- overwrite a fuller clone with a smaller (mid-game / degraded) library: a fresh
-- opening hand drawn after cards have been deleted must NOT replace the complete
-- game-start deck, or a later reset would restore an incomplete deck. A genuinely
-- new game restores every card to the library first, so its count matches (or
-- exceeds) the old clone and overwrites as expected.
function captureResetSnapshot(color, force)
	if data[color] == nil then
		return
	end
	local existing = data[color]["resetSnapshot"]
	if existing ~= nil and not force then
		return
	end
	-- the full library deck, before the opening hand is drawn
	local deck = getDeckFromZone(data[color]["libraryZone"])
	if deck == nil then
		return -- no deck to clone right now; keep any existing snapshot
	end
	local deckData = deck.getData()
	local deckCount = deckData.ContainedObjects and #deckData.ContainedObjects or 0
	-- don't degrade a good clone with a smaller library (deleted cards mid-game)
	if existing ~= nil and existing.deckCount ~= nil and deckCount < existing.deckCount then
		return
	end
	local snap = { commanders = {}, deckData = deckData, deckCount = deckCount }
	-- whatever is sitting in the command zone (commander, partner, ...)
	local cz = data[color]["commandZone"]
	if cz ~= nil then
		for _, obj in ipairs(cz.getObjects()) do
			if obj.type == "Card" or obj.type == "Deck" then
				table.insert(snap.commanders, obj.getData())
			end
		end
	end
	data[color]["resetSnapshot"] = snap
end

-- button handler: owner-only, double-click to confirm
function playerReset(button, color, alt)
	local ownerColor = nil
	for c, pdata in pairs(data) do
		if button == pdata["mulliganButton"] then
			ownerColor = c
			break
		end
	end
	if ownerColor == nil or color ~= ownerColor then
		warnNotYours(button, color)
		return
	end
	if isDoubleClick("reset_" .. ownerColor, resetDoubleClickSecs) then
		doBoardReset(ownerColor)
	else
		Player[color].broadcast("Double-click Reset to restore your board to its game-start state.")
	end
end

-- destroy the player's cards across their tracked areas, then respawn the snapshot
function doBoardReset(color)
	local snap = data[color] and data[color]["resetSnapshot"]
	if snap == nil then
		Player[color].broadcast("Reset: no game-start snapshot yet -- draw your opening hand first.")
		return
	end

	-- clear fetch previews + land-tracker state for this player up front, while
	-- the soon-to-be-destroyed lands are still in their zone
	local lz = data[color]["landZone"]
	if lz ~= nil then
		for _, obj in ipairs(lz.getObjects()) do
			clearFetchPreviews(obj.getGUID())
		end
	end
	landsEnteredThisTurn[color] = {}
	refreshLandTrackerText(color)

	-- 1. destroy this player's Card/Deck objects across their areas
	local seen = {}
	local function wipe(objs)
		for _, obj in ipairs(objs) do
			if obj ~= nil and (obj.type == "Card" or obj.type == "Deck") and not seen[obj.getGUID()] then
				seen[obj.getGUID()] = true
				pcall(function()
					destroyObject(obj)
				end)
			end
		end
	end
	for _, zone in ipairs({
		data[color]["libraryZone"],
		data[color]["graveyard"],
		data[color]["playmat"],
		data[color]["commandZone"],
		data[color]["exileZone"],
	}) do
		if zone ~= nil then
			wipe(zone.getObjects())
		end
	end
	wipe(Player[color].getHandObjects(1))

	-- 2. respawn the snapshot deck + commanders at their captured transforms
	if snap.deckData ~= nil then
		spawnObjectData({ data = snap.deckData })
	end
	for _, cdata in ipairs(snap.commanders or {}) do
		spawnObjectData({ data = cdata })
	end

	-- 3. re-shuffle the freshly spawned library once it settles
	Wait.time(function()
		local deck = getDeckFromZone(data[color]["libraryZone"])
		if deck ~= nil then
			pcall(function()
				deck.shuffle()
			end)
		end
	end, 1)

	-- 4. restore life to 40 and zero the commander damage taken from each colour
	resetLifeAndCommanderDamage(color)

	-- 5. reset the mulligan counter back to 0
	resetMulliganCount(color)

	Player[color].broadcast("Board reset to game-start state.")
end

-- restore a player's life to 40 and reset every Commander Damage tracker that
-- records damage dealt *to* them (one per opposing colour) back to 0
function resetLifeAndCommanderDamage(color)
	local tracker = data[color] and data[color]["lifeTracker"]
	if tracker ~= nil then
		pcall(function()
			tracker.call("resetLife")
		end)
	end

	local trackers = data[color] and data[color]["commanderDamage"]
	if trackers ~= nil then
		for _, guid in ipairs(trackers) do
			local obj = getObjectFromGUID(guid)
			if obj ~= nil then
				pcall(function()
					obj.call("reset_val")
				end)
			end
		end
	end
end

-- Called by a Commander Damage tracker when its value changes (clicks or typed
-- input). Find the player whose board that tracker belongs to and apply the
-- change to their life: a positive delta is damage taken (lose that much life),
-- a negative delta is a correction (gain it back). Tracker resets don't call
-- this, so a board reset's separate life-to-40 step isn't double-counted.
function commanderDamageDealt(params)
	if params == nil or params.guid == nil or params.delta == nil then
		return
	end
	for color, pdata in pairs(data) do
		local trackers = pdata["commanderDamage"]
		if trackers ~= nil then
			for _, guid in ipairs(trackers) do
				if guid == params.guid then
					loseLife(color, params.delta, "commander damage")
					return
				end
			end
		end
	end
end
