function onLoad()
  enc = Global.getVar('Encoder')
  noencode=true

  pressedButton = tonumber(self.memo)

  colDown = {1,1,1,.5}
  colUp   = {0,0,0,0}

  positions = {
    {0,0.28,-0.985},
	
    {-.62,0.28,-.74},
    {0,0.28,-.74},
    {.62,0.28,-.74},
	
    {-.455,0.28,-.49},
    {.4555,0.28,-.49},
	
	  {-.62,0.28,-.178},
    {0,0.28,-.178},
    {.62,0.28,-.178},
	
	  {-.455,0.28,.12},
    {.455,0.28,.12},
	
    {-.62,0.28,.37},
    {-.05,0.28,.37},
    {.55,0.28,.37},
	
	{-.455,0.28,.63},
    {.455,0.28,.63},

	{-.62,0.28,.99},
    {0,0.28,.99},
    {.62,0.28,.99},
  }

  width_height = {
    {1750,230},
	
    {540,230},
    {620,230},
    {540,230},
	
    {850,250},
    {850,250},
	
    {535,340},
    {630,340},
	  {535,340},
	
    {850,250},
    {850,250},
	
    {540,250},
    {540,250},
    {630,250},
	
    {850,250},
    {850,250},
	
    {540,460},
    {630,460},
    {540,460},
  }

  labs = {
	"[b]Crash Landing[/b] [i]Search your library for a basic land card, reveal it, put it into your hand, then shuffle.[/i]",
	"[b]Goblin Camp[/b] [i]Create a Treasure token.[/i]",
	"[b]Emerald Grove[/b] [i]Create a 2/2 white Knight creature token.[/i]",
	"[b]Auntie's Teahouse[/b] [i]Scry 3.[/i]",
	"[b]Defiled Temple[/b] [i]You may sacrifice a permanent. If you do, draw a card.[/i]",
	"[b]Mountain Pass[/b] [i]You may put a land card from your hand onto the battlefield.[/i]",
	"[b]Ebonlake Grotto[/b] [i]Create two 1/1 blue Faerie Dragon creature tokens with flying.[/i]",
	"[b]Grymforge[/b] [i]For each opponent, goad up to one target creature that player controls.[/i]",
	"[b]Githyanki Crèche[/b] [i]Distribute three +1/+1 counters among up to three target creatures you control.[/i]",
	"[b]Last Light Inn[/b] [i]Draw two cards.[/i]",
	"[b]Reithwin Tollhouse[/b] [i]Roll 2d4 and create that many Treasure tokens.[/i]",
	"[b]Moonrise Towers[/b] [i]Instant and sorcery spells you cast this turn cost 3 less to cast.[/i]",
	"[b]Gauntlet of Shar[/b] [i]Each opponent loses 5 life.[/i]",
	"[b]Balthazar's Lab[/b] [i]Return up to two target creature cards from your graveyard to your hand.[/i]",
	"[b]Circus of the Last Days[/b] [i]Create a token that's a copy of one of your commanders, except it's not legendary.[/i]",
	"[b]Undercity Ruins[/b] [i]Create three 4/1 black Skeleton creature tokens with menace.[/i]",
	"[b]Steel Watch Foundry[/b] [i]You get an emblem with 'Creatures you control get +2/+2 and have trample.'[/i]",
	"[b]Ansur's Sanctum[/b] [i]Reveal the top four cards of your library and put them into your hand. Each opponent loses life equal to those cards' total mana value.[/i]",
	"[b]Temple of Bhaal[/b] [i]Creatures your opponents control get -5/-5 until end of turn.[/i]"
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
	  spawnTokens({3})
  end
  createButtons()
end

function press3(obj,ply)
  setCol(ply)
  if pressedButton == 3 then
    pressedButton = 0
  else
    pressedButton = 3
	  spawnTokens({1})
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
  end
  createButtons()
end

function press6(obj,ply)
  setCol(ply)
  if pressedButton == 6 then
    pressedButton = 0
  else
    pressedButton = 6
  end
  createButtons()
end

function press7(obj,ply)
  setCol(ply)
  if pressedButton == 7 then
    pressedButton = 0
  else
    pressedButton = 7
	  spawnTokens({2})
    spawnTokens({2})
  end
  createButtons()
end

function press8(obj,ply)
  setCol(ply)
  if pressedButton == 8 then
    pressedButton = 0
  else
    pressedButton = 8
  end
  createButtons()
end

function press9(obj,ply)
  setCol(ply)
  if pressedButton == 9 then
    pressedButton = 0
  else
    pressedButton = 9
  end
  createButtons()
end

function press10(obj,ply)
  setCol(ply)
  if pressedButton == 10 then
    pressedButton = 0
  else
    pressedButton = 10
  end
  createButtons()
end

function press11(obj,ply)
  setCol(ply)
  if pressedButton == 11 then
    pressedButton = 0
  else
    pressedButton = 11
	  spawnTokens({4})
  end
  createButtons()
end

function press12(obj,ply)
  setCol(ply)
  if pressedButton == 12 then
    pressedButton = 0
  else
    pressedButton = 12
  end
  createButtons()
end

function press13(obj,ply)
  setCol(ply)
  if pressedButton == 13 then
    pressedButton = 0
  else
    pressedButton = 13
  end
  createButtons()
end

function press14(obj,ply)
  setCol(ply)
  if pressedButton == 14 then
    pressedButton = 0
  else
    pressedButton = 14
  end
  createButtons()
end

function press15(obj,ply)
  setCol(ply)
  if pressedButton == 15 then
    pressedButton = 0
  else
    pressedButton = 15
  end
  createButtons()
end

function press16(obj,ply)
  setCol(ply)
  if pressedButton == 16 then
    pressedButton = 0
  else
    pressedButton = 16
	  spawnTokens({5})
  end
  createButtons()
end

function press17(obj,ply)
  setCol(ply)
  if pressedButton == 17 then
    pressedButton = 0
  else
    pressedButton = 17
  end
  createButtons()
end

function press18(obj,ply)
  setCol(ply)
  if pressedButton == 18 then
    pressedButton = 0
  else
    pressedButton = 18
  end
  createButtons()
end

function press19(obj,ply)
  setCol(ply)
  if pressedButton == 19 then
    pressedButton = 0
  else
    pressedButton = 19
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

      print(cardName)

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