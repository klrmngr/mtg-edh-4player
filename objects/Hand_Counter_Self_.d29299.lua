function onload()

  colStr = self.getDescription()
  tableCols = Player.getAvailableColors()
  on = false
  plyList = {}
  for i,c in pairs(tableCols) do
    if colStr == c then
      on = true
    else
      table.insert(plyList,c)
    end
  end

  if on then
    player = Player[colStr]
    handPars = player.getHandTransform()

    Pos = handPars.position+handPars.forward:scale(4)
    Pos[2] = -0.04
    Rot = handPars.rotation+Vector(0,0,0)

    ----------------------------------------------------------------------------
    -- edit out the next "self" lines in order to fiddle with the counter
    self.setPosition(Pos)
    self.setRotation(Rot)
    self.setInvisibleTo({'White','Red','Grey'})
    self.setColorTint{1,1,1,0}
    self.setLock(true)
    self.setScale({1,1,1})
    self.interactable = false
    ----------------------------------------------------------------------------

    rgbColor = stringColorToRGB(colStr)
    pars = {
      rotation = {0, 180, 0},
      position = Vector(0,1,0),
      scale = {1,1,1},
      font_size = 1000,
      click_function = 'updateCardCount',
      width = 0,
      height = 0,
      font_color = {r=rgbColor.r, g=rgbColor.g, b=rgbColor.b, 1},
    }

    nButs=0
    -- spars = pars
    -- spars.font_color = {0,0,0,1}
    -- for i=-1,1 do
    --   for j=-1,1 do
    --     spars.position = pars.position+Vector(i*0.02,0,j*0.02)
    --     self.createButton(spars)
    --     nButs=nButs+1
    --   end
    -- end

    self.createButton(pars)

    Wait.time(updateCardCount,1,999999)   -- update every second

  end
end

function updateCardCount()
  if not(on) then return end
  local ncards = #player.getHandObjects()
  if ncards~=0 then
    if ncards==1 then cstr=" card" else cstr=' cards' end
    lab = ncards..cstr
  else
    lab = ''
  end
  for ind=0,nButs do
    self.editButton({index=ind, label=lab})
  end
end