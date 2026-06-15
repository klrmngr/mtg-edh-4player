--[[Description Module
Sticker Notepad Module
]]

-- By ZachStover

pID = "Stickers"
version = '0.1pi'
UPDATE_URL=''

function onload()
  self.addContextMenuItem('Register Module', function(p) registerModule() end)
  Wait.condition(registerModule,function() return Global.getVar('Encoder') ~= nil and true or false end)
end

function registerModule()
  enc = Global.getVar('Encoder')
  if enc ~= nil then
    properties = {
    propID = pID,
    name = "Sticker Menu",
    values = {},
    funcOwner = self,
    tags="basic",
    visible=false,
    activateFunc ='toggleProp'
    }
    enc.call("APIregisterProperty",properties)
  end
end

function toggleProp(obj, ply)
    printToAll("Stickers!")
end

function createButtons(t)
    enc = Global.getVar('Encoder')
    if enc ~= nil then
      getStickers(t.obj)
      data = enc.call("APIobjGetPropData",{obj=t.obj,propID=pID})
      flip = enc.call("APIgetFlip",{obj=t.obj})
    end
end


function getStickers(obj)
  local description = obj.getDescription()
  local buttons = {}
  local positions = {{-0.83,0.25,0.45}, {-0.83,0.25,.9}, {-0.12,0.25,1.25}, {0.48,0.25,1.25}}
  local i = 1
  for line in description:gmatch("[^\r\n]+") do
    local text = line:match('— (.*)')
    if text then
      local count = 0
      local num = i
      for _ in string.gmatch(line, "{TK}") do
         count = count + 1
      end
      local buttonLabel = count .. 'x'
      local buttonFunction = function()
        self.UI.setClipboard(text)
      end

      local buttonFunc = function() copyToClipboard(text) end
      self.setVar("copyText" .. i, buttonFunc)

      _G[i.."func"]= function(obj) copyToClipboard(obj,num) end

      obj.createButton({
        click_function=i.."func",
        function_owner=self,
        position=positions[i],
        rotation={0,20,0},
        scale={0.1,0.1,0.1},
        width=700,
        height=1000,
        color={.4,.4,.4},
        tooltip=text
      })
      obj.createButton({
        click_function=i.."func",
        function_owner=self,
        label=count,
        position=positions[i],
        rotation={0,20,0},
        scale={0.1,0.1,0.1},
        width=500,
        height=800,
        font_size=750,
        color={1,1,1,},
        font_color={.1,.1,.1},
        tooltip=text
      })
      i = i+1
    end
  end
  local position = obj.getPosition()
  position.y = position.y + 1
end

--Auto Functions
function onObjectDropped (playerColor, obj)
   local enc = Global.getVar('Encoder')
   if enc == nil then return end
   if obj.tag ~= "Card" then return end
   local nameField = obj.getName()
   if nameField:match("Stickers") then
      enc.call("APIobjEnableProp",{obj=obj,propID=pID})
      enc.call("APIrebuildButtons",{obj=obj})
   end
end

function copyToClipboard(obj, index)
    local description = obj.getDescription()
    local text = ""
    local lines = 1
    for line in description:gmatch("[^\r\n]+") do
      text = line:match('— (.*)')
      if index == lines then
        text = line:match('— (.*)')
        break
      end
      lines = lines + 1
    end
    -- add the local offset vector to the target object's position to get the spawn position
    object = spawnObjectJSON({
      json = NotepadDropper(),
      position = obj.positionToWorld(vector(0,1,-2.2)),
      rotation = obj.getRotation(),
      scale = {.5, .5, .5},
      sound = false,
    })
    object.setDescription(text)
end

function NotepadDropper()
    return [[
      {
        "GUID": "",
        "Name": "PiecePack_Suns",
        "Transform": {
          "posX": 0,
          "posY": 0,
          "posZ": 0,
          "rotX": 0,
          "rotY": 0,
          "rotZ": 0,
          "scaleX": 1,
          "scaleY": 1,
          "scaleZ": 1
        },
        "Nickname": "Sticker",
        "Description": "",
        "GMNotes": "",
        "AltLookAngle": {
          "x": 0.0,
          "y": 0.0,
          "z": 0.0
        },
        "ColorDiffuse": {
          "r": 1.0,
          "g": 1.0,
          "b": 1.0
        },
        "LayoutGroupSortIndex": 0,
        "Value": 0,
        "Locked": false,
        "Grid": false,
        "Snap": false,
        "IgnoreFoW": false,
        "MeasureMovement": false,
        "DragSelectable": true,
        "Autoraise": true,
        "Sticky": true,
        "Tooltip": true,
        "GridProjection": false,
        "HideWhenFaceDown": false,
        "Hands": false,
        "MeshIndex": 0,
        "LuaScript": "function onload()\r\n  self.createButton({\r\n    label=self.getName(), click_function='donothing', function_owner=self,\r\n    position={0,0.1,0}, height=0, width=0, font_size=200,\r\n    rotation={0,0,0}, font_color={0,0,0}\r\n    })\r\nend\r\nfunction onCollisionEnter(c)\r\n  obj = c.collision_object\r\n  if obj.type~='Card' then return end\r\n  enc = Global.getVar('Encoder')\r\n  if enc ~= nil and self.held_by_color == nil then\r\n    encoded = enc.call('APIobjectExists',{obj=obj})\r\n    if encoded == false then\r\n      enc.call('APIencodeObject',{obj=obj})\r\n      enc.call('APIobjEnableProp',{obj=obj,propID='_MTG_Simplified_UNIFIED'})\r\n      enc.call('APIrebuildButtons',{obj=obj})\r\n    end\r\n    desc = self.getDescription()\r\n    data = enc.call('APIobjGetAllData',{obj=obj})\r\n    local newPow,newTou = desc:match('(%d+)/(%d+)')\r\n    if newPow and newTou and #desc<6 then\r\n        k = \"tyrantUnified\"\r\n        dat = data[k]\r\n        local basePow=tonumber(dat.cardFaces[dat.activeFace].basePower)\r\n        local baseTou=tonumber(dat.cardFaces[dat.activeFace].baseToughness)\r\n        dat.displayPowTou = true\r\n        if basePow and baseTou then\r\n          dat.power = newPow - basePow\r\n          dat.toughness = newTou - baseTou\r\n        else\r\n          dat.power = newPow\r\n          dat.toughness = newTou\r\n        end\r\n        data[k]=dat\r\n    else\r\n        k = \"note\"\r\n        if enc.call('APIvalueExists',{valueID=k}) then\r\n          if data[k] == nil then\r\n            data[k] = enc.call('APIobjGetValueData',{obj=obj,valueID=k})[k]\r\n          end\r\n          data[k][\"text\"] = data[k][\"text\"]..desc..string.char(10)\r\n          data[k][\"editON\"] = false\r\n          enc.call(\"APIobjEnableProp\",{obj=obj,propID=\"πotepad\"})\r\n        end\r\n    end\r\n    enc.call('APIobjSetAllData',{obj=obj,data=data})\r\n    enc.call(\"APIrebuildButtons\",{obj=obj})\r\n    self.destruct()\r\n  end\r\nend\r\n",
        "LuaScriptState": "",
        "XmlUI": "",
        "AttachedDecals": [
        ]
      }]]
end