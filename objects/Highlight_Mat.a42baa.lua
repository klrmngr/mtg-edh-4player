function onLoad()
  self.setColorTint({1, 1, 1, 0})
	self.interactable=false
  thisplayer = self.getDescription()
end

function onPlayerTurn(player)
  if player==nil then
    self.setColorTint({1, 1, 1, 0})
    return
  elseif player.color==thisplayer then
	  local rgb = stringColorToRGB(player.color)
	  local color = {rgb["r"], rgb["g"], rgb["b"], 0.05}
	  self.setColorTint(color)
    startTime = os.time()
	else
	  self.setColorTint({1, 1, 1, 0})
	end
end