-------------------------------- FROZEN TOKENS ---------------------------------
-- Tokens drawn from the frozen bags, when dropped onto a card, apply the Frozen
-- keyword (mtg_frozen, the same flag the Untap button respects) to that card and
-- then consume the token. Mirrors the mod's "drop on card -> Encoder -> destroy"
-- pattern (see Sticker_Encoder), but driven from the Global script.
frozenBagGUIDs = { ["1a20bf"] = true, ["71d33b"] = true }

-- tag tokens as they come out of a frozen bag so we can recognise them on drop
function onObjectLeaveContainer(container, object)
	if frozenBagGUIDs[container.getGUID()] then
		object.addTag("frozenToken")
	end
end

function onObjectDropped(playerColor, object)
	if object == nil or not object.hasTag("frozenToken") then
		return
	end
	Wait.condition(function()
		freezeCardUnder(object)
	end, function()
		return object == nil or object.resting
	end)
end

-- raycast straight down from the token; freeze the first card it's resting on
function freezeCardUnder(token)
	if token == nil then
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
	data["mtg_frozen"] = true
	enc.call("APIobjSetPropData", { obj = card, propID = "πKeywords", data = data })
	enc.call("APIrebuildButtons", { obj = card })
	token.destruct()
end
