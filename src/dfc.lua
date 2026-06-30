-------------------------------- DOUBLE-FACED CARDS ----------------------------
-- A double-faced card is a TTS object with two states (state 1 = front face,
-- state 2 = back face). When such a card is dropped into a player's land zone and
-- its back face is a land (per the type line, the 2nd line of that face's name),
-- flip it to the back face. Called from onObjectEnterZone (context_menus.lua).
function dfcLandEnter(zone, obj)
	if obj == nil or obj.type ~= "Card" then
		return
	end
	if landZoneColor(zone) == nil then
		return -- not a land zone
	end
	local states = obj.getStates()
	if states == nil or #states == 0 then
		return -- single-faced card
	end
	-- map each state's name by id; getStates() may omit the active state, so add it
	local names = {}
	for _, st in ipairs(states) do
		names[st.id] = st.name
	end
	names[obj.getStateId()] = obj.getName()
	local backName = names[2]
	if backName == nil or not nameTypeLineIsLand(backName) then
		return -- no back face, or it isn't a land
	end
	if names[1] ~= nil and nameTypeLineIsLand(names[1]) then
		return -- front face is already a land; leave it so that side can be played
	end
	if obj.getStateId() == 2 then
		return -- already showing the land face
	end
	-- wait until it settles, and only flip if it's still in the land zone
	whenSettledInZone(obj, zone, function(o)
		if o.getStateId() ~= 2 then
			o.setState(2)
		end
	end)
end
