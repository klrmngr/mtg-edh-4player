function onLoad()
  picounter=0
  createButtons()
end

function createButtons()
  self.clearButtons()

  self.createButton({
    label='Drop-On-Card Counter',
    click_function='null',
    position={0,0.05,1.15},
    width=0,
    height=0,
    font_size=230,
    scale={0.5,0.5,0.5},
    color={0,0,0,0},
    font_color={0,0,0,100}
  })

  pos = Vector(0,0.1,-0.65)
  bpars={
    click_function='null',
    function_owner=self,
    label=tostring(picounter),
    position=pos,
    rotation=Vector(0,0,0),
    width=0,
    height=0,
    font_size=1000,
    scale={1.15,1.15,1.15},
    color={0,0,0,0},
    hover_color={0,0,0,0},
    font_color={0,0,0,100},
  }
  for i=-1,1,1 do         -- outline
    for j=-1,1,1 do
      opars=bpars
      opars.position=pos+Vector(0.02*i,0,0.02*j)
      self.createButton(bpars)
    end
  end

  bpars.position=Vector(-0.05,0,-0.55)
  bpars.font_color={0.1,0.1,0.1,90}
  self.createButton(bpars)    -- shadow

  bpars.click_function='add_subtract'
  bpars.position=pos
  bpars.width=0
  bpars.height=0
  bpars.font_color={1,1,1,100}
  self.createButton(bpars)    -- the button
end

function add_subtract()
  new_value = math.min(math.max(picounter + (alt and -1 or 1), 0), 999)
  if picounter ~= new_value then
    picounter = new_value
    createButtons()
  end
end

function null()
end