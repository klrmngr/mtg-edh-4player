--bigCounter
--by π

pID = "πCounter"
version = 3.14159

function onload()
  self.createButton({
    click_function='registerModule', function_owner=self, label='[i]'..pID..'[/i]', tooltip='register '..pID,
    position={0,0.1,0}, rotation={0,0,0}, scale={0.5,1,0.5},
    height=250, width=700, font_size=150,  color={0.1,0.1,0.1,1}, font_color={1,1,1,1},
  })

  Wait.condition(registerModule,function() return Global.getVar('Encoder') ~= nil and true or false end)
end

function registerModule()
  enc = Global.getVar('Encoder')
  if enc ~= nil then
		properties = {
		propID = pID,
		name = "Counter[sup][i]π[/i][/sup]",
		values = {'picounter'},
    funcOwner = self,
		tags='basic',
		activateFunc ='toggleProp'
		}
		enc.call("APIregisterProperty",properties)
    value = {
    valueID = 'picounter',
    validType = 'number',
    desc = "it's a big counter",
    default = 0
    }
    enc.call("APIregisterValue",value)
  end
end

script="self.max_typed_number=999 function onNumberTyped(ply, int) enc = Global.getVar('Encoder') if enc ~= nil then enc.call('APIobjSetValueData',{obj=self,valueID='picounter',data={picounter=int}}) enc.call('APIrebuildButtons',{obj=self}) return true end end"

function toggleProp(obj,ply)
  enc = Global.getVar('Encoder')
  if enc then
    enc.call("APItoggleProperty",{obj=obj,propID=pID})

    if enc.call("APIobjIsPropEnabled",{obj=obj,propID=pID}) then
      obj.setLuaScript(script)
    else
      obj.setLuaScript('')
      enc.call("APIobjSetValueData",{obj=obj,valueID='picounter',data={picounter=0}})
    end

    obj=obj.reload()
    Wait.condition(function()
      enc.call("APIobjUpdateThis",{obj=obj})
      enc.call("APIrebuildButtons",{obj=obj})
    end, function() return not(obj.spawning) end)

  end
end

function createButtons(t)
  enc = Global.getVar('Encoder')
  if enc ~= nil then
    flip = enc.call("APIgetFlip",{obj=t.obj})
    dat  = enc.call("APIobjGetValueData",{obj=t.obj,valueID='picounter'})
    picounter = dat.picounter
    pos = Vector(0,2*flip,-0.45)

    t.obj.createButton({
      click_function='toggleProp',
      function_owner=self,
      tooltip='close counter',
      label='×',
      position=Vector(0.65*flip,0.25*flip,-1.09),
      rotation=Vector(0,0,90-flip*90),
      width=400,
      height=400,
      font_size=600,
      scale={0.25,0.25,0.25},
      color={0.1,0.1,0.1,0.6},
      font_color={1,1,1},
    })

    bpars={
      click_function='null',
      function_owner=self,
      label=tostring(picounter),
      position=pos,
      rotation=Vector(0,0,90-flip*90),
      width=0,
      height=0,
      font_size=1000,
      scale={0.8,0.8,0.8},
      color={0,0,0,0},
      hover_color={0,0,0,0},
      font_color={0,0,0,100},
    }

    for i=-1,1,1 do         -- outline
      for j=-1,1,1 do
        opars=bpars
        opars.position=pos+Vector(0.015*i,0,0.015*j)
        t.obj.createButton(bpars)
      end
    end

    bpars.position=Vector(-0.05,0.28*flip,-0.4)
    bpars.font_color={0.1,0.1,0.1,90}
    t.obj.createButton(bpars)

    bpars.click_function='add_subtract'
    bpars.position=pos
    bpars.width=600
    bpars.height=600
    bpars.font_color={1,1,1,100}
    t.obj.createButton(bpars)

  end
end

min_val=0
max_val=999
function add_subtract(obj,color,alt)
  dat = enc.call("APIobjGetValueData",{obj=obj,valueID='picounter'})
  picounter = dat.picounter
  new_value = math.min(math.max(picounter + (alt and -1 or 1), min_val), max_val)
  if picounter ~= new_value then
    picounter = new_value
    enc.call("APIobjSetValueData",{obj=obj,valueID='picounter',data={picounter=picounter}})
    enc.call("APIrebuildButtons",{obj=obj})
  end
end

function null()
end