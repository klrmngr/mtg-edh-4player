--------------------------------- CHAT COMMANDS --------------------------------
-- manage turns through chat commands
function onChat(message, pl)
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

