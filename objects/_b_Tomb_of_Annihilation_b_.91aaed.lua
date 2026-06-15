function onLoad()
  enc = Global.getVar('Encoder')
  noencode=true

  pressedButton = tonumber(self.memo)

  colDown = {1,1,1,.5}
  colUp   = {0,0,0,0}

  positions = {
    {0,0.28,-.865},
    {-.455,0.28,-.333},
    {.455,0.28,-.035},
    {-.455,0.28,0.26},
    {0,0.28,.85},
  }

  width_height = {
    {1750,445},
    {870,560},
    {870,1135},
    {870,570},
    {1750,550},
  }

  labs = {
    "[b]Trapped Entry[/b] \nEach player loses 1 life.",
    "[b]Veils of Fear[/b] \nEach player loses 2 life unless they discard a card.",
    "[b]Oubliette[/b] \nDiscard a card and sacrifice a creature, an artifact, and a land.",
    "[b]Sandfall Cell[/b] \nEach player loses 2 life unless they sacrifice a creature, artifact, or land.",
    "[b]Cradle of the Death God[/b] \nCreate The Atropal, a legendary 4/4 black God Horror creature token with deathtouch.",
  }

  createButtons()

end

function createButtons()

  self.memo = pressedButton

  self.clearButtons()
  for i,pos in ipairs(positions) do
    local w = width_height[i][1]
    local h = width_height[i][2]

    local col=colUp;
    if pressedButton == i then
      col=colDown;
    end

    self.createButton({
      click_function='press'..i,
      function_owner=self,
      label='✘',
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
end

function setCol(ply)
  col = Color.fromString(ply)
  colDown = {col.r,col.g,col.b,.5}
  -- colDown = {1,1,0,.5}
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

function press5(obj,ply)
  setCol(ply)
  if pressedButton == 5 then
    pressedButton = 0
  else
    pressedButton = 5
    spawnTokens({1})
  end
  createButtons()
end

function doNothing()
end




function spawnTokens(inds)
  local jsonTxt=self.script_state
  if not(jsonTxt:find('"object":"list"')) then return end
  local json=JSON.decode(jsonTxt)
  local cardBackURL=self.getCustomObject().back
  local cPos=self.getPosition()+self.getTransformForward():scale(-3.2)
  local cRot=self.getRotation()
  for n,cardDat in ipairs(json.data) do
    local continue=false
    for j,i in pairs(inds) do
      if i==n then
        continue=true
      end
    end
    if continue then
      local imagesuffix=''
      if cardDat.image_status~='highres_scan' then      -- cache buster for low quality images
        imagesuffix='?'..tostring(os.date("%x")):gsub('/', '')
      end
      local faceAddress,backAddress,cardName,cardDesc,backName,backDesc
      local backDat=nil
      if cardDat.image_uris then
        faceAddress=cardDat.image_uris.large:gsub('%?.*','')..imagesuffix
        cardName=cardDat.name:gsub('"','')..'\n'..cardDat.type_line..' '..cardDat.cmc..'CMC'
        cardDesc=setOracle(cardDat)
      elseif cardDat.card_faces then
        cardName=cardDat.card_faces[1].name:gsub('"','')..'\n'..cardDat.card_faces[1].type_line..' '..cardDat.cmc..'CMC DFC'
        cardDesc=setOracle(cardDat.card_faces[1])
        faceAddress=cardDat.card_faces[1].image_uris.large:gsub('%?.*','')..imagesuffix
        backAddress=cardDat.card_faces[2].image_uris.large:gsub('%?.*','')..imagesuffix
        if faceAddress:find('/back/') and backAddress:find('/front/') then
          local temp=faceAddress;faceAddress=backAddress;backAddress=temp
        end
        backName=cardDat.card_faces[2].name:gsub('"','')..'\n'..cardDat.card_faces[2].type_line..' '..cardDat.cmc..'CMC DFC'
        backDesc=setOracle(cardDat.card_faces[2])
        backDat={
          Transform={posX=0,posY=0,posZ=0,rotX=0,rotY=0,rotZ=0,scaleX=1,scaleY=1,scaleZ=1},
          Name="Card",
          Nickname=backName,
          Description=backDesc,
          Memo=cardDat.oracle_id,
          CardID=(n+10)*100,
          CustomDeck={[n+10]={FaceURL=backAddress,BackURL=cardBackURL,NumWidth=1,NumHeight=1,Type=0,BackIsHidden=true,UniqueBack=false}},
        }
      end
      local cardDat={
        Transform={posX=0,posY=0,posZ=0,rotX=0,rotY=0,rotZ=0,scaleX=1,scaleY=1,scaleZ=1},
        Name="Card",
        Nickname=cardName,
        Description=cardDesc,
        Memo=cardDat.oracle_id,
        CardID=n*100,
        CustomDeck={[n]={FaceURL=faceAddress,BackURL=cardBackURL,NumWidth=1,NumHeight=1,Type=0,BackIsHidden=true,UniqueBack=false}},
      }
      if backDat then
        cardDat.States={[2]=backDat}
      end
      spawnObjectData({data=cardDat,position=cPos,rotation=cRot})
    end
  end
end
function setOracle(cardDat)
  local n='\n[b]'
  if cardDat.power then
    n=n..cardDat.power..'/'..cardDat.toughness
  elseif cardDat.loyalty then
    n=n..tostring(cardDat.loyalty)
  else
    n=false
  end
  return cardDat.oracle_text..(n and n..'[/b]'or'')
end