--Phasing
--By Tipsy Hobbit
pID = "MTG_Phase"
UPDATE_URL='https://raw.githubusercontent.com/Jophire/Tabletop-Simulator-Workshop-Items/master/Encoder/Modules/Encoder_Phasing_Addon.lua'
version = '1.12'

function onload()
  self.createButton({
  label="+", click_function='registerModule', function_owner=self,
  position={0,0.2,-0.5}, height=100, width=100, font_size=100,
  rotation={0,0,0},tooltip="Version: "..version
  })
  Wait.condition(registerModule,function() return Global.getVar('Encoder') ~= nil and true or false end)
end
function registerModule()
  enc = Global.getVar('Encoder')
  if enc ~= nil then
		properties = {
		propID = pID,
		name = "Phase Out",
		values = {'mtg_phased'},
		funcOwner = self,
		tags='tool,face_prop',
		activateFunc ='phaseOut'
		}
		enc.call("APIregisterProperty",properties)
    value = {
    valueID = 'mtg_phased',
    validType = 'boolean',
    desc = 'MTG: Is the card phased out?.',
    default = false
    }
    enc.call("APIregisterValue",value)
  end
end
function createButtons(t)
  enc = Global.getVar('Encoder')
  if enc ~= nil then
    flip = enc.call("APIgetFlip",{obj=t.obj})
    scaler = {x=1,y=1,z=1}--t.obj.getScale()
    temp = " PHASED OUT "
    barSize,fsize,offset_x,offset_y = enc.call('APIformatButton',{str=temp,font_size=400,max_len=90,xJust=0,yJust=0})
    t.obj.createButton({
    label=temp, click_function='unPhased', function_owner=self,
    position={(0+offset_x)*flip*scaler.x,0.63*flip*scaler.z,(0+offset_y)*scaler.y}, height=1000, width=1500, font_size=200,color={0,0,0,1},font_color={0.6,0.6,1,1},
    rotation={0,90,90-90*flip,tooltip="This is Phased Out."}
    })
  end
end
function phaseOut(obj,ply)
  enc = Global.getVar('Encoder')
  if enc ~= nil then
    enc.call("APItoggleProperty",{obj=obj,propID=pID})
    data = enc.call("APIobjGetPropData",{obj=obj,propID=pID})
		if data.mtg_phased ~= true then
			data.mtg_phased = true
    else
      data.mtg_phased = false
    end
    enc.call("APIobjSetPropData",{obj=obj,propID=pID,data=data})
    enc.call("APIrebuildButtons",{obj=obj})
  end
end
function unPhased(obj,ply)
  enc = Global.getVar('Encoder')
  if enc ~= nil and enc.call("APIobjectExists",{obj=obj}) then
    flip = enc.call("APIgetFlip",{obj=obj})
		
		data = enc.call("APIobjGetPropData",{obj=obj,propID=pID})
		if data.mtg_phased == true then
			data.mtg_phased = false
			enc.call("APIobjSetPropData",{obj=obj,propID=pID,data=data})
      enc.call("APIobjDisableProp",{obj=obj,propID=pID})
		end
		if type(ply) == "string" then
			local selection =Player[ply].getSelectedObjects()
			if selection ~= nil then
				for k,v in pairs(selection) do
					if v ~= tar and enc.call("APIobjectExists",{obj=v}) == true then 
						unPhased(v,0)
					end
				end
			end
		end
    enc.call("APIrebuildButtons",{obj=obj})
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