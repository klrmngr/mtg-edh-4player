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
		local playmat = data[playerColor]["playmat"]
		local enc = Global.getVar("Encoder")
		local ry = playmat.getRotation()
		local rr = nil
		local untaps = true
		for k, v in pairs(playmat.getObjects()) do
			untaps = true
			flash = false
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
					if typeline and typeline:find("battle") then
						untaps = false
					end
				end
				if untaps == false and flash == true then
					Wait.time(function()
						v.highlightOn(playerColor, 0.1)
					end, 0.2, 3)
				elseif untaps == true then
					rr = v.getRotation()
					v.setRotationSmooth({ x = rr.x, y = ry.y, z = rr.z })
				end
			end
		end
	else
		warnNotYours(button, playerColor)
	end
end

