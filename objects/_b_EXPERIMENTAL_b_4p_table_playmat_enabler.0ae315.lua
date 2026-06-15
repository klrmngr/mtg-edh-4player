function onLoad(saved_data)

  -- Wait.time(function() broadcastToAll('now with playmats (type [i]playmat imageURL[/i] into chat)') end, 3)

  if saved_data and saved_data~='' then
    playmats=JSON.decode(saved_data)
  else
    playmats={}
  end

  deckDirs = Global.getTable('deckDirs')

end

function onChat(message, player)
  ply=player.color
  if message:match('^[Pp]laymat ') then
    local imageURL = message:match('^[Pp]laymat (.*)')
    if imageURL and imageURL:lower()=='none' then
      pcall(function()
        if playmats[ply] then
          getObjectFromGUID(playmats[ply]).destruct()
          playmats[ply]=nil
        end
      end)
    elseif imageURL and imageURL~='' then
      makePlaymat(ply,imageURL)
    end
    return false
  end
end

function makePlaymat(ply,imageURL)

  Player[ply].broadcast('attempting to set playmat image to [3366CC]'..imageURL..'\n[999999]type [i]playmat none[/i] to remove it')
  pcall(function()
    if playmats[ply] then
      getObjectFromGUID(playmats[ply]).destruct()
      playmats[ply]=nil
    end
  end)

  local json=playmatJSON:gsub('"DiffuseURL": "",' , '"DiffuseURL": "'..imageURL..'",')
  local hand=Player[ply].getHandTransform(1)
  local matPos = hand.position + hand.right*0.7*deckDirs[ply] + hand.forward*19.07
  matPos.y=0.96
  local matRot = hand.rotation + vector(0,180,0)
  obj=spawnObjectJSON({
    json=json,
    position=matPos,
    rotation=matRot,
    callback_function = function(obj)
      obj.interactable=false
      playmats[ply]=obj.getGUID()
      self.script_state = JSON.encode(playmats)
    end,
  })

end



playmatJSON=[[
{
  "Name": "Custom_Model",
  "Transform": {
    "scaleX": 2.3,
    "scaleY": 0.01,
    "scaleZ": 3.0
  },
  "Nickname": "Art Playmat",
  "ColorDiffuse": {
    "r": 1.0,
    "g": 1.0,
    "b": 1.0
  },
  "Locked": true,
  "CustomMesh": {
    "MeshURL": "https://steamusercontent-a.akamaihd.net/ugc/1661229755220411391/27AA7C44FB7D2F2E20F96618E6CD9671C5EE8341/",
    "DiffuseURL": "",
    "MaterialIndex": 3,
    "TypeIndex": 4,
    "CustomShader": {
      "SpecularColor": {
        "r": 1.0,
        "g": 1.0,
        "b": 1.0
      },
      "SpecularIntensity": 0.0,
      "SpecularSharpness": 2.0,
      "FresnelStrength": 0.0,
    },
  },
  "LuaScript": "function onload() self.interactable=false end",
}
]]