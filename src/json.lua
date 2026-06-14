--------------------------------------------------------------------------------
-- pie's manual "JSONdecode" for scryfall's api output
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- which fields to extract?
-- these need to be in the order the appear in the json text
normal_card_keys = {
	"object",
	"id",
	"oracle_id",
	"name",
	"printed_name", --for non-EN cards
	"lang",
	"layout",
	"image_uris",
	"mana_cost",
	"cmc",
	"type_line",
	"printed_type_line", --for non-EN cards
	"oracle_text",
	"printed_text", --for non-EN cards
	"loyalty",
	"power",
	"toughness",
	"loyalty",
	"set",
	"collector_number",
}

image_uris_keys = { -- "image_uris":{
	"small",
	"normal",
	"large",
}

related_card_keys = { -- "all_parts":[{"object":"related_card",
	"id",
	"component",
	"name",
	"uri",
}

card_face_keys = { -- "card_faces":[{"object":"card_face",
	"name",
	"printed_name", --for non-EN cards
	"mana_cost",
	"type_line",
	"printed_type_line", --for non-EN cards
	"oracle_text",
	"printed_text", --for non-EN cards
	"power",
	"toughness",
	"loyalty",
	"image_uris",
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function JSONdecode(txt)
	local txtBeginning = txt:sub(1, 16)
	local jsonType = txtBeginning:match('{"object":"(%w+)"')

	-- not scryfall? use normal JSONdecode
	if not (jsonType == "card" or jsonType == "list") then
		return JSON.decode(txt)
	end

	------------------------------------------------------------------------------
	-- parse list: extract each card, and parse it separately
	-- used when one wants to decode a whole list
	if jsonType == "list" then
		local txtBeginning = txt:sub(1, 80)
		local nCards = txtBeginning:match('"total_cards":(%d+)')
		local cardEnd = 0
		local cardDats = {}
		for i = 1, nCards do -- could insert max number cards to parse here
			local cardStart = string.find(txt, '{"object":"card"', cardEnd + 1)
			local cardEnd = findClosingBracket(txt, cardStart)
			local cardDat = JSONdecode(txt:sub(cardStart, cardEnd))
			table.insert(cardDats, cardDat)
		end
		local dat = { object = "list", total_cards = nCards, data = cardDats } --ignoring hast_more...
		return dat
	end

	------------------------------------------------------------------------------
	-- parse card

	txt = txt:gsub("}", ",}") -- comma helps parsing last element in an array

	local cardDat = {}
	local all_parts_i = string.find(txt, '"all_parts":')
	local card_faces_i = string.find(txt, '"card_faces":')

	-- if all_parts exist
	if all_parts_i ~= nil then
		local st = string.find(txt, "%[", all_parts_i)
		local en = findClosingBracket(txt, st)
		local all_parts_txt = txt:sub(all_parts_i, en)
		local all_parts = {}
		-- remove all_parts snip from the main text
		txt = txt:sub(1, all_parts_i - 1) .. txt:sub(en + 2, -1)
		-- parse all_parts_txt for each related_card
		st = 1
		local cardN = 0
		while st ~= nil do
			st = string.find(all_parts_txt, '{"object":"related_card"', st)
			if st ~= nil then
				cardN = cardN + 1
				en = findClosingBracket(all_parts_txt, st)
				local related_card_txt = all_parts_txt:sub(st, en)
				st = en
				local s, e = 1, 1
				local related_card = {}
				for i, key in ipairs(related_card_keys) do
					val, s = getKeyValue(related_card_txt, key, s)
					related_card[key] = val
				end
				table.insert(all_parts, related_card)
				if cardN > 30 then
					break
				end -- avoid inf loop if something goes strange
			end
			cardDat.all_parts = all_parts
		end
	end

	-- if card_faces exist
	if card_faces_i ~= nil then
		local st = string.find(txt, "%[", card_faces_i)
		local en = findClosingBracket(txt, st)
		local card_faces_txt = txt:sub(card_faces_i, en)
		local card_faces = {}
		-- remove card_faces snip from the main text
		txt = txt:sub(1, card_faces_i - 1) .. txt:sub(en + 2, -1)

		-- parse card_faces_txt for each card_face
		st = 1
		local cardN = 0
		while st ~= nil do
			st = string.find(card_faces_txt, '{"object":"card_face"', st)
			if st ~= nil then
				cardN = cardN + 1
				en = findClosingBracket(card_faces_txt, st)
				local card_face_txt = card_faces_txt:sub(st, en)
				st = en
				local s, e = 1, 1
				local card_face = {}
				for i, key in ipairs(card_face_keys) do
					val, s = getKeyValue(card_face_txt, key, s)
					card_face[key] = val
				end
				table.insert(card_faces, card_face)
				if cardN > 4 then
					break
				end -- avoid inf loop if something goes strange
			end
			cardDat.card_faces = card_faces
		end
	end

	-- normal card (or what's left of it after removing card_faces and all_parts)
	st = 1
	for i, key in ipairs(normal_card_keys) do
		val, st = getKeyValue(txt, key, st)
		cardDat[key] = val
	end

	return cardDat
end

--------------------------------------------------------------------------------
-- returns data for one card at a time from a scryfall's "object":"list"
function getNextCardDatFromList(txt, startHere)
	if startHere == nil then
		startHere = 1
	end

	local cardStart = string.find(txt, '{"object":"card"', startHere)
	if cardStart == nil then
		print("error: no more cards in list")
		startHere = nil
		return nil, nil, nil
	end

	local cardEnd = findClosingBracket(txt, cardStart)
	if cardEnd == nil then
		print("error: no more cards in list")
		startHere = nil
		return nil, nil, nil
	end

	-- startHere is not a local variable, so it's possible to just do:
	-- getNextCardFromList(txt) and it will keep giving the next card or nil if there's no more
	startHere = cardEnd + 1

	local cardDat = JSONdecode(txt:sub(cardStart, cardEnd))

	return cardDat, cardStart, cardEnd
end

--------------------------------------------------------------------------------
function findClosingBracket(txt, st) -- find paired {} or []
	local ob, cb = "{", "}"
	local pattern = "[{}]"
	if txt:sub(st, st) == "[" then
		ob, cb = "[", "]"
		pattern = "[%[%]]"
	end
	local txti = st
	local nopen = 1
	while nopen > 0 do
		if txti == nil then
			return nil
		end
		txti = string.find(txt, pattern, txti + 1)
		if txt:sub(txti, txti) == ob then
			nopen = nopen + 1
		elseif txt:sub(txti, txti) == cb then
			nopen = nopen - 1
		end
	end
	return txti
end

--------------------------------------------------------------------------------
function getKeyValue(txt, key, st)
	local str = '"' .. key .. '":'
	local st = string.find(txt, str, st)
	local en = nil
	local value = nil
	if st ~= nil then
		if key == "image_uris" then -- special case for scryfall's image_uris table
			value = {}
			local s = st
			for i, k in ipairs(image_uris_keys) do
				local val, s = getKeyValue(txt, k, s)
				value[k] = val
			end
			en = s
		elseif txt:sub(st + #str, st + #str) ~= '"' then -- not a string
			en = string.find(txt, ',"', st + #str + 1)
			value = tonumber(txt:sub(st + #str, en - 1))
		else -- a string
			en = string.find(txt, '",', st + #str + 1)
			value = txt:sub(st + #str + 1, en - 1):gsub('\\"', '"'):gsub("\\n", "\n"):gsub("(\\u....)", "")
		end
	end
	if type(value) == "string" then
		value = value:gsub(",}", "}") -- get rid of the previously inserted comma
	end
	return value, en
end
