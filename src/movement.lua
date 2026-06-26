function move2botLib(ply)
	local objs = Player[ply].getSelectedObjects()
	local cards = {}
	for _, obj in pairs(objs) do
		if obj.type == "Card" or obj.type == "Deck" then
			local rot = obj.getRotation()
			rot[3] = 180
			obj.setRotationSmooth(rot, false, true)
			table.insert(cards, obj)
		end
	end
	Wait.time(function()
		if #cards > 1 then
			targpos = vector(0, 0, 0)
			for _, c in pairs(cards) do
				targpos = targpos + c.getPosition()
			end
			targpos = targpos:scale(1 / #cards)
			for _, c in pairs(cards) do
				c.setPositionSmooth(targpos, false, true)
			end
		end
		local gr = group(cards)
		gr = gr[1]
		if gr == nil then
			pcall(function()
				gr = hoveredObjs[ply]
			end)
		end
		if gr == nil or not (gr.type == "Card" or gr.type == "Deck") then
			return
		end
		local rot = gr.getRotation()
		rot[3] = 180
		gr.interactable = false
		gr.use_gravity = false
		gr.shuffle()
		local deck = getDeckFromZone(data[ply]["libraryZone"])
		if deck == nil then
			deck = getCardFromZone(data[ply]["libraryZone"])
		end
		Wait.time(function()
			gr.use_gravity = true
			gr.interactable = true
			gr.shuffle()
			if gr.type == "Card" then
				handTrigger(gr)
			end
			gr.shuffle()
			if deck ~= nil then
				local pos = deck.getPosition()
				pos[2] = 1
				gr.setPositionSmooth(pos, false, true)
				gr.setRotationSmooth(deck.getRotation(), false, true)
				deck.setPositionSmooth(deck.getPosition() + Vector(0, 2, 0), false, true)
			else
				local rot = gr.getRotation()
				rot.z = 180
				local pos = data[ply]["libraryZone"].getPosition()
				pos[2] = 1
				gr.setRotationSmooth(rot, false, true)
				gr.setPositionSmooth(pos, false, true)
			end
		end, 1)
	end, 0.25)
end

hoveredObjs = {}
function onObjectHover(ply, obj)
	hoveredObjs[ply] = obj
end

function move2grav(ply)
	local objs = Player[ply].getSelectedObjects()
	local cards = {}
	for _, obj in pairs(objs) do
		if obj.type == "Card" or obj.type == "Deck" then
			table.insert(cards, obj)
		end
	end
	local gr = group(cards)
	gr = gr[1]
	if gr == nil then
		pcall(function()
			gr = hoveredObjs[ply]
		end)
	end
	if gr == nil or not (gr.type == "Card" or gr.type == "Deck") then
		return
	end
	gr.interactable = false
	gr.use_gravity = false
	Wait.time(function()
		gr.interactable = true
		gr.use_gravity = true
		if gr.type == "Card" then
			handTrigger(gr)
		end
		local rot = gr.getRotation()
		rot.z = 0
		rot.y = data[ply]["libraryZone"].getRotation().y + exileRot
		local pos = data[ply]["libraryZone"].getPosition()
			+ data[ply]["libraryZone"].getTransformForward():scale(gravFor)
		pos[2] = 3
		gr.setRotationSmooth(rot, false, true)
		gr.setPositionSmooth(pos, false, true)
	end, 1)
end

function move2exile(ply)
	local objs = Player[ply].getSelectedObjects()
	local cards = {}
	for _, obj in pairs(objs) do
		if obj.type == "Card" or obj.type == "Deck" then
			table.insert(cards, obj)
		end
	end
	local gr = group(cards)
	gr = gr[1]
	if gr == nil then
		pcall(function()
			gr = hoveredObjs[ply]
		end)
	end
	if gr == nil or not (gr.type == "Card" or gr.type == "Deck") then
		return
	end
	gr.interactable = false
	gr.use_gravity = false
	Wait.time(function()
		gr.interactable = true
		gr.use_gravity = true
		if gr.type == "Card" then
			handTrigger(gr)
		end
		-- anchor on the dedicated exile zone so placement survives zone rotation
		local zone = data[ply]["exileZone"]
		local rot = gr.getRotation()
		rot.z = 0
		rot.y = zone.getRotation().y
		local pos = zone.getPosition()
		pos[2] = 3
		gr.setRotationSmooth(rot, false, true)
		gr.setPositionSmooth(pos, false, true)
	end, 1)
end

