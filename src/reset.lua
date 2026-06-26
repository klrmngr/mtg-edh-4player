----------------------------------- BOARD RESET ----------------------------------
-- A per-player "Reset" button (under the mulligan count) restores that player's
-- board to its game-start state. At the opening hand (the first mulligan bump,
-- detected the same way mulligans are) we snapshot the full library deck and the
-- command zone. Double-clicking Reset destroys that player's Card/Deck objects
-- across their library, hand, battlefield (playmat), graveyard, command zone, and
-- exile, then respawns the snapshot deck + commander(s) and re-shuffles the
-- library.
--
-- Limitations: cards sitting outside every tracked zone (loose on the table, or
-- taken by another player) and token creatures (Custom_Token) are not destroyed.

resetDoubleClickSecs = 0.5
-- take the game-start snapshot for a player. Called from bumpMulliganCount on
-- each fresh opening hand (count at 0), while the library is still complete.
-- Without force, an existing snapshot is kept; force overwrites it so a new game
-- after a mulligan-count reset re-snapshots the (possibly different) library.
function captureResetSnapshot(color, force)
	if data[color] == nil then
		return
	end
	if data[color]["resetSnapshot"] ~= nil and not force then
		return
	end
	local snap = { commanders = {} }
	-- the full library deck, before the opening hand is drawn
	local deck = getDeckFromZone(data[color]["libraryZone"])
	if deck ~= nil then
		snap.deckData = deck.getData()
	end
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

	Player[color].broadcast("Board reset to game-start state.")
end
