--Token Desginator
--By Tipsy Hobbit
pID = "MTG_Token"
version = '1.7.1'
Style={}

function onload()
  self.addContextMenuItem('Register Module', function(p)
    registerModule()
  end)
  Wait.condition(registerModule,function() return Global.getVar('Encoder') ~= nil and true or false end)
end
function registerModule()
  enc = Global.getVar('Encoder')
  if enc ~= nil then
    properties = {
    propID = pID,
    name = "Is Token",
    values = {'mtg_token'},
    funcOwner = self,
    tags='tool',
    activateFunc ='tToken'
    }
    enc.call("APIregisterProperty",properties)
    value = {
    valueID = 'mtg_token',
    validType = 'boolean',
    desc = 'MTG:is this a token? Tokens are non-card permanents.',
    default = false
    }
    enc.call("APIregisterValue",value)
  end
end

function createButtons(t)
  enc = Global.getVar('Encoder')
  if enc ~= nil then
    Style.proto = enc.call("APIgetStyleTable",nil)
    flip = enc.call("APIgetFlip",{obj=t.obj})
    t.obj.createButton({
    label='Token', click_function='toggleToken', function_owner=self,
    scale={0.5,0.5,0.5}, position={0,0.28*flip,-1.7}, height=300, width=800, font_size=250,
    rotation={0,0,90-90*flip}, font_color={1,1,1}, color={0.1,0.1,0.1}
    })
  end
end

function tToken(obj,ply)
  enc = Global.getVar('Encoder')
  if enc ~= nil then
    enc.call("APItoggleProperty",{obj=obj,propID=pID})
    data = enc.call("APIobjGetPropData",{obj=obj,propID=pID})
    if data.mtg_token ~= true then
      data.mtg_token = true
    else
      data.mtg_token = false
    end
    enc.call("APIrebuildButtons",{obj=obj})
  end
end

function toggleToken(obj,ply)
  enc = Global.getVar('Encoder')
  if enc ~= nil then
    data = enc.call("APIobjGetPropData",{obj=obj,propID=pID})
    data.mtg_token = false
    enc.call("APIobjDisableProp",{obj=obj,propID=pID})
    enc.call("APIobjSetPropData",{obj=obj,propID=pID,data=data})

    if type(ply) == "string" then
      local selection =Player[ply].getSelectedObjects()
      if selection ~= nil then
        for k,v in pairs(selection) do
          if v ~= tar and enc.call("APIobjExists",{obj=v}) == true then
            toggleToken(v,0)
          end
        end
      end
    end

    enc.call("APIrebuildButtons",{obj=obj})
  end
end