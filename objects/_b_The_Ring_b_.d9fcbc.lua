function onLoad()
  enc = Global.getVar('Encoder')
  noencode=true

  pressedButton = tonumber(self.memo)



  colDown = {0,0,0,0.95}
  colUp   = {0,0,0,0.1}

  positions = {
    {0,0.28,0.055},
    {0,0.28,0.35},
    {0,0.28,0.7},
    {0,0.28,1.1}
  }

  width_height = {
    {1760,270},
    {1760,300},
    {1760,400},
    {1760,300},
  }

  labs = {
    "Your Ring-bearer is legendary and can't be blocked by creatures with greater power.",
    "Whenever your Ring-bearer attacks, draw a card, then discard a card.",
    "Whenever your Ring-bearer becomes blocked by a creature, that creature's controller sacrifices it at end of combat.",
    "Whenever your Ring-bearer deals combat damage to a player, each opponent loses 3 life.",
  }

  createButtons()

end

function createButtons()

  self.memo = pressedButton

  -- print(pressedButton)

  self.clearButtons()
  for i,pos in ipairs(positions) do
    local w = width_height[i][1]
    local h = width_height[i][2]

    local col=colUp;
    if pressedButton <= i-1 then
      col=colDown;
    end

    self.createButton({
      click_function='press'..i,
      function_owner=self,
      label=' ',
      font_size=300,
      font_color={col[1],col[2],col[3],2},
      tooltip=labs[i],
      position=pos,
      scale={0.5,0.5,0.5},
      width=w,
      height=h,
      color=col,
      hover_color=col,
    })
  end

  self.createButton({
    click_function='upDown',
    function_owner=self,
    label=tostring(pressedButton),
    font_size=500,
    font_color={1,1,1,100},
    tooltip='you have been tempted',
    position={0,0.28,-.9},
    scale={0.5,0.5,0.5},
    width=300,
    height=300,
    color={0,0,0,0},
    hover_color={0,0,0,0},
  })

end

function setCol(ply)
  col = Color.fromString(ply)
  -- colDown = {col.r,col.g,col.b,.5}
  -- colDown = {1,1,0,.5}
end

function upDown(obj,ply,alt)
  if alt then
    pressedButton=pressedButton-1
  else
    pressedButton=pressedButton+1
  end
  if pressedButton<0 then
    pressedButton=0
  end
  if pressedButton>4 then
    pressedButton=4
  end
  createButtons()
end

function press1(obj,ply)
  setCol(ply)
  if pressedButton == 1 then
    pressedButton = 0
  else
    pressedButton = 1
  end
  createButtons()
end

function press2(obj,ply)
  setCol(ply)
  if pressedButton == 2 then
    pressedButton = 0
  else
    pressedButton = 2
  end
  createButtons()
end

function press3(obj,ply)
  setCol(ply)
  if pressedButton == 3 then
    pressedButton = 0
  else
    pressedButton = 3
  end
  createButtons()
end

function press4(obj,ply)
  setCol(ply)
  if pressedButton == 4 then
    pressedButton = 0
  else
    pressedButton = 4
  end
  createButtons()
end

function doNothing()
end