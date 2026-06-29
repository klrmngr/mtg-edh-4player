------------------------------------- UNTAP ------------------------------------
-- when each player last pressed their own untap-all button (os.time seconds).
-- A draw within skipDrawWindow seconds of this is treated as the turn's draw
-- step (see playerDraw's skip-your-draw-step handling in draw.lua).
lastUntapPress = {}

-- stolen from Untapper Tool by Tipsy Hobbit//STEAM_0:1:13465982
function playerUntap(button, playerColor, alt)
	if button == data[playerColor]["untapButton"] then
		buttonPress(button, drawDelay * 0.75)
		lastUntapPress[playerColor] = os.time()
		untapAll(playerColor, false)
		-- Seedborn Muse untaps its controller's permanents during each OTHER
		-- player's untap step. So when this player untaps, every other player who
		-- controls a Seedborn Muse untaps too -- and since it isn't their own
		-- untap step, "doesn't untap during your untap step" cards (Mana Vault,
		-- Basalt/Grim Monolith, ...) untap as well (foreign = true).
		for color, _ in pairs(data) do
			if color ~= playerColor and controlsSeedbornMuse(color) then
				untapAll(color, true)
				broadcastToColor("Seedborn Muse untaps your permanents.", color, { 0.4, 0.9, 0.4 })
			end
		end
	else
		warnNotYours(button, playerColor)
	end
end

-- does this player control a face-up Seedborn Muse on their playmat?
function controlsSeedbornMuse(playerColor)
	local mat = data[playerColor]["playmat"]
	if mat == nil then
		return false
	end
	for _, v in pairs(mat.getObjects()) do
		if v.type == "Card" and not v.is_face_down and v.getName():lower():find("seedborn muse", 1, true) then
			return true
		end
	end
	return false
end

-- untap every permanent on a player's playmat. When foreign is true this is
-- another player's untap step (e.g. driven by Seedborn Muse), so "doesn't untap
-- during your untap step" restrictions don't apply; stun counters, frozen,
-- exert and battles are still honoured either way.
function untapAll(playerColor, foreign)
	local playmat = data[playerColor]["playmat"]
	if playmat == nil then
		return
	end
	local enc = Global.getVar("Encoder")
	local ry = playmat.getRotation()
	for _, v in pairs(playmat.getObjects()) do
		local untaps = true
		local flash = false
		if v.type == "Card" or v.type == "Deck" then
			if enc ~= nil then
				if enc.call("APIobjectExists", { obj = v }) then
					local encdat = enc.call("APIobjGetAllData", { obj = v })
					if encdat["mtg_stuncounter"] ~= nil and untaps then
						if encdat["mtg_stuncounter"] > 0 then
							flash = true
							untaps = false
							encdat.mtg_stuncounter = encdat.mtg_stuncounter - 1
							enc.call("APIobjSetAllData", { obj = v, data = encdat })
							enc.call("APIrebuildButtons", { obj = v })
						end
					end
					if encdat["mtg_frozen"] ~= nil then
						if encdat["mtg_frozen"] == true then
							flash = true
							untaps = false
						end
					end
					if encdat["mtg_exert"] ~= nil then
						if encdat["mtg_exert"] == true then
							flash = true
							untaps = false
							encdat.mtg_exert = false
							enc.call("APIobjSetAllData", { obj = v, data = encdat })
							enc.call("APIrebuildButtons", { obj = v })
						end
					end
				end
			end
			if v.type == "Card" then
				local cname = v.getName():lower()
				local cdesc = v.getDescription():lower()
				local typeline = cname:match("\n(.*)")
				-- only on the controller's OWN untap step do these hold a card down
				if not foreign then
					if
						cname
						and (cname:find("mana vault") or cname:find("basalt monolith") or cname:find("grim monolith"))
					then
						untaps = false
						flash = true
					end
					if cdesc and cdesc:find("doesn't untap during your untap step") then
						untaps = false
						flash = true
					end
				end
				if typeline and typeline:find("battle") then
					untaps = false
				end
			end
			if untaps == false and flash == true then
				Wait.time(function()
					v.highlightOn(playerColor, 0.1)
				end, 0.2, 3)
			elseif untaps == true then
				local rr = v.getRotation()
				v.setRotationSmooth({ x = rr.x, y = ry.y, z = rr.z })
			end
		end
	end
end

