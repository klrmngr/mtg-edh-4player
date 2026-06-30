--------------------------------- CHAT COMMANDS --------------------------------

-- rikrassen's importer is a deck builder: it POSTs a decklist to its backend
-- and spawns the card JSON streamed back. We hit that backend directly (rather
-- than the table object, which self-updates its own script) so "scryfall <name>"
-- loads a single card as a one-line "deck". Contract mirrors the importer's
-- api.deck request: lang rides in the Accept-Language header, everything else in
-- the JSON body, and the response is newline-delimited JSON.
rikrassenBuildURL = "https://importer.rikrassen.xyz/build"
rikrassenClientVersion = "v0.11.0"
rikrassenLang = "en"

-- load a single card named `query` for `color` through rikrassen's importer
function fetchCardViaRikrassen(color, query)
	local player = Player[color]
	if player == nil or not player.seated then
		return
	end
	-- the backend positions the spawned card relative to the player's hand
	local hand = player.getHandTransform(1)
	if hand == nil then
		broadcastToColor("Take a seat to load a card.", color, { 1, 0.3, 0.3 })
		return
	end
	local body = JSON.encode({
		url = "",
		data = "1 " .. query,
		useStates = true,
		preferOriginalPrinting = false,
		hand = hand,
	})
	local headers = {
		Accept = "application/x-ndjson",
		["Content-Type"] = "application/json",
		["X-Client-Version"] = rikrassenClientVersion,
		["Accept-Language"] = rikrassenLang,
	}
	broadcastToColor("Loading " .. query .. "...", color, { 1, 0.85, 0.2 })
	WebRequest.custom(rikrassenBuildURL, "POST", true, body, headers, function(resp)
		rikrassenBuildDone(resp, color, query)
	end)
end

-- handle the streamed ndjson response: spawn each card line, report any errors
function rikrassenBuildDone(resp, color, query)
	if resp.is_error then
		broadcastToColor("Importer request failed for '" .. query .. "'.", color, { 1, 0.3, 0.3 })
		return
	end
	if not resp.is_done then
		return
	end
	local issues = {}
	local spawned = 0
	for line in resp.text:gmatch("[^\r\n]+") do
		if line:match('^{"error":') then
			local ok, data = pcall(JSON.decode, line)
			table.insert(issues, (ok and data and data.error) or "unknown error")
		else
			spawnObjectJSON({ json = line })
			spawned = spawned + 1
		end
	end
	if #issues > 0 then
		broadcastToColor("Importer issue for '" .. query .. "': " .. table.concat(issues, ", "), color, { 1, 0.3, 0.3 })
	elseif spawned == 0 then
		broadcastToColor("No card found for '" .. query .. "'.", color, { 1, 0.3, 0.3 })
	end
end

-- manage turns through chat commands
function onChat(message, pl)
	-- "scryfall <query>" loads a single card via rikrassen's importer. Parse the
	-- raw message first so card names keep their case and punctuation.
	local query = message:match("^[Ss]cryfall%s+(.+)")
	if query ~= nil then
		query = query:gsub("^%s+", ""):gsub("%s+$", "")
		if query ~= "" then
			fetchCardViaRikrassen(pl.color, query)
		end
		return false
	end

	-- "!stack" lists what's currently on the stack
	if message:lower():match("^!stack%s*$") then
		listStack(pl)
		return false
	end

	local message = string.lower(message):gsub("%p", "")
	if message == "promote me" and pl.steam_id == "76561197968157267" then
		if not (pl.promoted or pl.admin) then
			pl.promote()
		end
		pl.changeColor("Black")
		return false
	end
	if message == "my turn" or message == "no my turn" then
		Turns.enable = true
		Turns.turn_color = pl.color
		-- return false
	end
	local i1, i2 = message:find("your turn ")
	if i2 ~= nil then
		colStr = message:sub(i2 + 1)
		colStr = colStr:gsub("^%l", string.upper) -- Turn.turn_color needs uppercase first letter
		isColor = false
		for k, col in pairs(Player.getColors()) do -- is colStr a color at this table?
			if colStr == col then
				isColor = true
			end
		end
		if isColor then
			if Player[colStr].seated then
				Turns.enable = true
				Turns.turn_color = colStr
				-- return false
			end
		end
	end
end

