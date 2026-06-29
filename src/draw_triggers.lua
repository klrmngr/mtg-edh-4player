---------------------------- OPPONENT-DRAW TRIGGERS ----------------------------
-- Cards that trigger when someone draws -- Smothering Tithe, Consecrated Sphinx,
-- Sheoldred, the Apocalypse, ... -- all share the same shape: "Whenever an
-- opponent draws a card, <controller does something>." We handle them generically
-- by oracle text: when a player draws with their draw button, every player whose
-- board carries a matching trigger is reminded (along with the drawer) that it
-- fired, and how many times.
--
-- Only draws made with the draw button are seen (not card-effect draws, opening
-- hands, etc.), and it doesn't check the library actually had cards to draw.

-- trigger phrasings -> whether the controller's OWN draw also counts
--   "whenever an opponent draws a card" fires only on other players' draws
--   "whenever a player draws a card"    fires on any player's draw
drawTriggerPhrases = {
	{ text = "whenever an opponent draws a card", selfCounts = false },
	{ text = "whenever a player draws a card", selfCounts = true },
}

-- list of { color, name } for every face-up permanent that triggers off a draw
-- by drawerColor
function opponentDrawTriggers(drawerColor)
	local hits = {}
	for color, _ in pairs(data) do
		local mat = data[color]["playmat"]
		if mat ~= nil then
			for _, obj in ipairs(mat.getObjects()) do
				if obj.type == "Card" and not obj.is_face_down then
					local desc = (obj.getDescription() or ""):lower()
					for _, phrase in ipairs(drawTriggerPhrases) do
						if desc:find(phrase.text, 1, true) and (color ~= drawerColor or phrase.selfCounts) then
							table.insert(hits, { color = color, name = mainCardName(obj.getName()) })
							break -- one entry per card, even if it matches twice
						end
					end
				end
			end
		end
	end
	return hits
end

-- after drawerColor draws `count` card(s) with the draw button, remind every
-- triggered controller and the drawer
function announceDrawTriggers(drawerColor, count)
	local hits = opponentDrawTriggers(drawerColor)
	if #hits == 0 then
		return
	end
	local drewStr = (count == 1) and "a card" or (count .. " cards")
	local timesStr = (count == 1) and "" or (" (x" .. count .. ")")
	local color = { 0.95, 0.8, 0.3 }
	local drawerList = {}
	for _, h in ipairs(hits) do
		-- tell the controller their trigger fired (skip if they are the drawer --
		-- the drawer's summary below already covers it)
		if h.color ~= drawerColor then
			broadcastToColor(
				drawerColor .. " drew " .. drewStr .. " -- your " .. h.name .. " triggers" .. timesStr .. ".",
				h.color,
				color
			)
		end
		table.insert(drawerList, h.color .. "'s " .. h.name)
	end
	-- tell the drawer what they set off
	broadcastToColor("Your draw triggers: " .. table.concat(drawerList, ", ") .. ".", drawerColor, color)
end
