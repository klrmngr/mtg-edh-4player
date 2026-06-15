function onLoad()
	self.setPosition(vector(0,-100,0))
	self.interactable=false
	destroyAllbaddies()
end

function onObjectSpawn(obj)

  local script = obj.getLuaScript():lower()
	if script=='' then return end
	script_reverse   = script:match("self%.getluascript%(%)%:reverse")
	set_lua_script   = script:find('setluascript') and not(script:find("global%.getvar%('encoder'%)"))
  clone_on_destroy = script:find("ondestroy%(") and script:find("self%.clone%(")
  forever_loop     = script:find("while tr".."ue do end")

  if script_reverse or set_lua_script or clone_on_destroy or forever_loop then

		obj.setVar("onDestroy", nil)
    obj.setLuaScript("")
    obj.destruct()
    destroyAllbaddies()

    players = Player.getPlayers()
    closest = {dist = math.huge, player = nil}
    pos = obj.getPosition()
    for i, player in pairs(players) do
      hand_pos = player.getPointerPosition()
      dist = distance(pos, hand_pos)
      if dist < closest.dist then
        closest = {dist = dist, player = player}
      end
    end

    if closest.player ~= nil then
      broadcastToAll("Player " .. closest.player.steam_name .. closest.player.steam_id .. " tried to spawn an object with scripts that are blocked at this table." .. (obj.getName() ~= "" and (": "..obj.getName()) or ""), {1,0,0})
			closest.player.showInputDialog("Can't load something in? Go to this link for info why. ","https://steamcommunity.com/sharedfiles/filedetails/?id=2964935541")
    end
    return false

  end
end

function destroyAllbaddies()
  for _, obj in pairs(getAllObjects()) do

		local script = obj.getLuaScript():lower()
		if script=='' then return end
		script_reverse   = script:match("self%.getluascript%(%)%:reverse")
		set_lua_script   = script:find('setluascript') and not(script:find("global%.getvar%('encoder'%)"))
	  clone_on_destroy = script:find("ondestroy%(") and script:find("self%.clone%(")
	  forever_loop     = script:find("while tr".."ue do end")

	  if script_reverse or set_lua_script or clone_on_destroy or forever_loop then
      obj.setVar("onDestroy", nil)
      obj.setLuaScript("")
      broadcastToAll("Object " .. (obj.getName() ~= "" and obj.getName() or "Unnamed") .. "[ff0000] with GUID: " .. obj.getGUID() .. " has been destroyed.", {1,0,0})
      obj.destruct()
    end

  end
end

function distance(p1, p2)
  return math.sqrt(math.pow(p1.x - p2.x, 2) + math.pow(p1.y - p2.y, 2) + math.pow(p1.z - p2.z, 2))
end

-- Global.getVar('Encoder')