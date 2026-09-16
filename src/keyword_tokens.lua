------------------------------- KEYWORD TOKENS ---------------------------------
-- Keyword-status tokens (Frozen, Flying, Deathtouch, Trample, ...) live in
-- infinite bags on the table. Each bag's nickname matches a keyword in the
-- Keywords module (objects/_Keywords). When a token is pulled from one of these
-- bags and dropped onto a card, we apply that keyword to the card (the same
-- data the Untap button and keyword icons read) and consume the token.
--
-- We drive the change through the Keywords module's own toggleStatus<key>
-- function rather than writing the value directly: that path also registers the
-- icon in the module's activeIcons list and flips its internal updateDecals
-- flag, which is the only way the keyword's decal actually gets drawn above the
-- card. Writing the value by hand applies the effect but leaves no visible
-- indicator. Mirrors the mod's "drop on card -> Encoder -> destroy" pattern
-- (see Sticker_Encoder), but driven from the Global script.
--
-- Boolean keywords (Frozen, Monstrous) toggle on; numeric keywords (Flying,
-- Deathtouch, ...) add one counter per token dropped -- exactly what clicking
-- the keyword button once does.

-- token-bag nickname -> keyword id in the Keywords module. Every bag whose
-- nickname appears here is a keyword token; two physical copies of each bag
-- share a nickname, so keying on the name covers both. Keywords without a token
-- bag in the save (Stun, Exerted, Renowned, Suspend) are intentionally absent.
tokenBagKeywords = {
	["Frozen"] = "mtg_frozen",
	["Deathtouch"] = "mtg_deathtouchcounter",
	["Defender"] = "mtg_defendercounter",
	["Double Strike"] = "mtg_doublestrikecounter",
	["First Strike"] = "mtg_firststrikecounter",
	["Flying"] = "mtg_flyingcounter",
	["Haste"] = "mtg_hastecounter",
	["Hexproof"] = "mtg_hexproofcounter",
	["Indestructible"] = "mtg_indestructiblecounter",
	["Lifelink"] = "mtg_lifelinkcounter",
	["Menace"] = "mtg_menacecounter",
	["Monstrous"] = "mtg_monstrous",
	["Reach"] = "mtg_reachcounter",
	["Trample"] = "mtg_tramplecounter",
	["Vigilance"] = "mtg_vigilancecounter",
}

-- tag tokens as they come out of a keyword bag so we can recognise them on drop
-- and remember which keyword they carry. The "kw:" tag rides along with the
-- object (surviving the drop) so we don't need any external bookkeeping.
function onObjectLeaveContainer(container, object)
	local keyword = tokenBagKeywords[container.getName()]
	if keyword ~= nil then
		object.addTag("keywordToken")
		object.addTag("kw:" .. keyword)
	end
end

function onObjectDropped(playerColor, object)
	if object == nil or not object.hasTag("keywordToken") then
		return
	end
	whenSettled(object, applyKeywordUnder)
end

-- read the "kw:<id>" tag a keyword token was stamped with on leaving its bag
function tokenKeyword(token)
	for _, t in ipairs(token.getTags()) do
		local kw = t:match("^kw:(.+)$")
		if kw ~= nil then
			return kw
		end
	end
	return nil
end

-- raycast straight down from the token; apply its keyword to the first card it's
-- resting on, then consume the token
function applyKeywordUnder(token)
	if token == nil then
		return
	end
	local keyword = tokenKeyword(token)
	if keyword == nil then
		return
	end

	local hits = Physics.cast({
		origin = token.getPosition() + Vector(0, 0.5, 0),
		direction = Vector(0, -1, 0),
		type = 1,
		max_distance = 3,
	})
	local card = nil
	for _, h in ipairs(hits) do
		if h.hit_object ~= nil and h.hit_object ~= token and h.hit_object.type == "Card" then
			card = h.hit_object
			break
		end
	end
	if card == nil then
		return -- not dropped on a card; leave the token alone
	end

	local enc = Global.getVar("Encoder")
	if enc == nil then
		return
	end
	if enc.call("APIobjectExists", { obj = card }) == false then
		enc.call("APIencodeObject", { obj = card })
	end
	if enc.call("APIobjIsPropEnabled", { obj = card, propID = "πKeywords" }) == false then
		enc.call("APIobjEnableProp", { obj = card, propID = "πKeywords" })
	end
	local data = enc.call("APIobjGetPropData", { obj = card, propID = "πKeywords" })
	if data == nil then
		return
	end

	-- Drive the change through the Keywords module's own toggle so the icon
	-- renders (see file header). toggleStatus handles both value kinds: it turns
	-- a boolean on (a no-op if already set) and adds one counter to a number --
	-- so one token dropped == +1 counter, which is the behaviour we want.
	local prop = enc.call("APIgetProp", { propID = "πKeywords" })
	if prop ~= nil and prop.funcOwner ~= nil then
		prop.funcOwner.call("toggleStatus" .. keyword, card)
	else
		-- fallback: apply the value directly so the effect still lands even if
		-- the Keywords module can't be reached (icon just won't render).
		if type(data[keyword]) == "number" then
			data[keyword] = data[keyword] + 1
		else
			data[keyword] = true
		end
		enc.call("APIobjSetPropData", { obj = card, propID = "πKeywords", data = data })
		enc.call("APIrebuildButtons", { obj = card })
	end
	token.destruct()
end
