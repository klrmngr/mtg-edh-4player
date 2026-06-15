--[[Color Module
by Tipsy Hobbit//STEAM_0:1:13465982
This module adds color Designators.
]]
pID = "MTG_Colors"
UPDATE_URL='https://raw.githubusercontent.com/Jophire/Tabletop-Simulator-Workshop-Items/master/Encoder/Modules/Encoder_Color_Addon.lua'
version = '1.12'
Style = {}
colors={
w={c=Color(0.988,0.988,0.757),n="White"},
u={c=Color(0.404,0.757,0.961),n="Blue"},
b={c=Color(0.518,0.518,0.518),n="Black"},
r={c=Color(0.973,0.333,0.333),n="Red"},
g={c=Color(0.149,0.710,0.412),n="Green"}
}

function onload()
  Color.Add("mtg_white",colors.w.c)
  Color.Add("mtg_blue",colors.u.c)
  Color.Add("mtg_black",colors.b.c)
  Color.Add("mtg_red",colors.r.c)
  Color.Add("mtg_green",colors.g.c)
  Color.Add("mtg_colorless",Color(0.7,0.7,0.7))
  
  self.addContextMenuItem('Register Module', function(p) 
    registerModule()
  end)
  Wait.condition(registerModule,function() return Global.getVar('Encoder') ~= nil and true or false end)
end
function registerModule(obj,ply)
  enc = Global.getVar('Encoder')
  if enc ~= nil then

    properties = {
    propID = pID,
    name = "MTG Colors",
    values = {'mtg_colors'},
    funcOwner = self,
    tags='basic,face_prop',
    activateFunc ='callEditor'
    }
    enc.call("APIregisterProperty",properties)

    value = {
    valueID = 'mtg_colors',
    validType = 'pattern(^[wubrg]*$)',
    desc = "MTG:Color Identity of the card.",
    default = ''
    }
    enc.call("APIregisterValue",value)
    
    for c,t in pairs(colors) do 
      _G['toggle'..c]=function(obj,ply,alt) toggleStatus(obj,ply,alt,c) end
    end
    
    Style.proto = enc.call("APIgetStyleTable",nil)
    Style.mt = {}
    Style.mt.__index = Style.proto
    function Style.new(o)
      for k,v in pairs(Style.proto) do
        if o[k] == nil then
          o[k] = v
        end
      end
      return o
    end
  end
end
function refreshStyle()
  Style.proto = enc.call("APIgetStyleTable",nil)
end

function toggleStatus(obj,ply,alt,val)
  enc = Global.getVar('Encoder')
  if enc ~= nil then
    data = enc.call("APIobjGetPropData",{obj=obj,propID=pID})
    if string.find(data['mtg_colors'],val) then
      data['mtg_colors']=string.gsub(data['mtg_colors'],val,'')
    else
      data['mtg_colors']=data['mtg_colors']..val
    end
    
    enc.call("APIobjSetPropData",{obj=obj,propID=pID,data=data})
    enc.call("APIrebuildButtons",{obj=obj})
  end
end

function toggleEditor(obj,ply)
  enc = Global.getVar('Encoder')
  if enc ~= nil then
    enc.call("APIsetEditing",{obj=obj,propID=pID})
    enc.call("APIrebuildButtons",{obj=obj})
  end
end
function callEditor(obj,ply,alt)
  if type(obj) == 'Table' then obj=obj[1] ply=obj[2] alt=obj[3] end
  if alt then
    enc.call("APIobjResetProp",{obj=obj,propID=pID})
  else
    enc.call("APItoggleProperty",{obj=obj,propID=pID})
    if enc.call("APIobjIsPropEnabled",{obj=obj,propID=pID}) then
      toggleEditor(obj,nil)
    else
      enc.call("APIrebuildButtons",{obj=obj})
    end
  end
end
function toggleEditClose(obj,ply)
  enc = Global.getVar('Encoder')
  if enc ~= nil then
    enc.call("APIclearEditing",{obj=obj})
    enc.call("APIrebuildButtons",{obj=obj})
  end
end

function createButtons(t)
  enc = Global.getVar('Encoder')
  if enc ~= nil then
    data = enc.call("APIobjGetPropData",{obj=t.obj,propID=pID})
    flip = enc.call("APIgetFlip",{obj=t.obj})
    scaler = {x=1,y=1,z=1}--t.obj.getScale()
    editing = enc.call("APIgetEditing",{obj=t.obj})
    
    i = 0
    for c,a in pairs(colors) do
      if editing == nil then
        if string.find(data['mtg_colors'],c) then
          t.obj.createButton({
          label=temp, click_function='toggleEditor', function_owner=self,
          position={1.0*flip*scaler.x,0.28*flip*scaler.z,(-1.4+i*0.1)*scaler.y}, height=50, width=75, font_size=0,
          rotation={0,0,90-90*flip}, color=a.c, tooltip='Color Identity: '..a.n
          })
          i = i+1
        end
      elseif editing == pID then
        t.obj.createButton({
        label='', click_function='toggle'..c, function_owner=self,
        position={-0*flip,0.28*flip*scaler.z,(-1.2+i*0.4)*scaler.y}, height=100, width=300, font_size=0,
        rotation={0,0,90-90*flip}, color=a.c, tooltip='Color Identity: '..a.n
        })
        i = i+1
      end
    end
    if editing == nil and i == 0 then
      t.obj.createButton(Style.new{
      label=temp, click_function='toggleEditor', function_owner=self,
      position={1.0*flip*scaler.x,0.25*flip*scaler.z,(-1.4+3*0.1)*scaler.y}, height=150, width=77, font_size=0,
      rotation={0,0,90-90*flip}, color=Color.mtg_colorless, tooltip='Color Identity: Colorless'
      })
    end
  end
end
function updateModule(wr)
  enc = Global.getVar('Encoder')
  if enc ~= nil then
    wr = wr.text
    wrv = string.match(wr,"version = '(.-)'")
    if wrv == 'DEPRECIATED' then
      enc.call("APIremoveProperty",{propID=pID})
      self.destruct()
    end
    local ver = enc.call("APIversionComp",{wv=wrv,cv=version})
    if ''..ver ~= ''..version then
      broadcastToAll("An update has been found for "..pID..". Reloading Module.")
      self.script_code = wr
      self.reload()
    else
      broadcastToAll("No update found for "..pID..". Carry on.")
    end
  end
end