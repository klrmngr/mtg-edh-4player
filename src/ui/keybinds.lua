-- Scripting hotkeys
function onScriptingButtonDown(index, playerColor)
	if index == 10 then
		if Turns.enable then
			if playerColor == Turns.turn_color then
				Player[playerColor].broadcast("keybind 0: end turn", { 0.7, 0.7, 0.7 })
				Turns.turn_color = Turns.getNextTurnColor()
			end
		else
			Player[playerColor].broadcast("keybind 0: enable turns", { 0.7, 0.7, 0.7 })
			Turns.enable = true
			Turns.turn_color = playerColor
		end
	elseif index == 1 then
		Player[playerColor].broadcast("keybind 1: untap", { 0.7, 0.7, 0.7 })
		playerUntap(data[playerColor]["untapButton"], playerColor, false)
	elseif index == 2 then
		Player[playerColor].broadcast("keybind 2: draw", { 0.7, 0.7, 0.7 })
		playerDraw(data[playerColor]["drawButton"], playerColor, false)
	elseif index == 3 then
		Player[playerColor].broadcast("keybind 3: scry", { 0.7, 0.7, 0.7 })
		playerScry(data[playerColor]["scryButton"], playerColor, false)
	elseif index == 4 then
		Player[playerColor].broadcast("keybind 4: mill", { 0.7, 0.7, 0.7 })
		playerMill(data[playerColor]["millButton"], playerColor, false)
	elseif index == 5 then
		Player[playerColor].broadcast("keybind 5: revealFan", { 0.7, 0.7, 0.7 })
		local obj = data[playerColor]["revealButton"]
		revealFan(obj, playerColor)
	elseif index == 6 then
		Player[playerColor].broadcast("keybind 6: revealStack", { 0.7, 0.7, 0.7 })
		local obj = data[playerColor]["revealButton"]
		revealStack(obj, playerColor)
	elseif index == 7 then
		Player[playerColor].broadcast("keybind 7: move to graveyard", { 0.7, 0.7, 0.7 })
		move2grav(playerColor)
	elseif index == 8 then
		Player[playerColor].broadcast("keybind 8: move to exile", { 0.7, 0.7, 0.7 })
		move2exile(playerColor)
	elseif index == 9 then
		Player[playerColor].broadcast("keybind 9: move to bottom of library", { 0.7, 0.7, 0.7 })
		move2botLib(playerColor)
	end
end

