pID = "πScry"
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
  tableGUIDs = Global.getTable('data')
  if enc ~= nil then
		properties = {
      propID = pID,
      name = "Scry Module",
      values = {},
      funcOwner = self,
      tags="tool,table_tool",
      activateFunc ='toggleProp',
      visible=false,
      visible_in_hand=2
		}
		enc.call("APIregisterProperty",properties)
  end
end

function toggleProp(obj,ply)
  enc.call("APItoggleProperty",{obj=obj,propID=pID})
  enc.call("APIrebuildButtons",{obj=obj})
end

-- -- disable scry buttons when leaving hand 2
-- function onObjectLeaveZone(zone,obj)
--   if obj==nil then return end --wtf? how can this happen? but it does
--   if obj.type~="Card" then return end
--   enc = Global.getVar('Encoder')
--   if enc then
--     Zones=enc.call("APIlistZones",{})
--     encZone=Zones[zone.getGUID()]
--     if encZone then
--       isHand2=encZone.name:find('Hand_2')
--       if isHand2 then
--         -- using GMnotes as a scry-zone flag (in case the object is just passing through the scry zone)
--         if obj.getGMNotes()=='scryEnter' then obj.setGMNotes('') end
--         -- check that the object is encoded
--         if not(enc.call("APIobjectExists",{obj=obj})) then return end
--         -- if encoded and scry is enabled, disable it
--         if enc.call("APIobjIsPropEnabled",{obj=obj,propID=pID}) then
--           enc.call("APIobjDisableProp",{obj=obj,propID=pID})
--         end
--       end
--     end
--   end
-- end

function onObjectEnterZone(zone,obj)
  if obj==nil then return end
  if obj.type~="Card" then return end
  enc = Global.getVar('Encoder')
  if enc then
    Zones=enc.call("APIlistZones",{})
    encZone=Zones[zone.getGUID()]
    if encZone then
      isHand1=encZone.name:find('_1')
      if isHand1 then
        -- check that the object is encoded
        if not(enc.call("APIobjectExists",{obj=obj})) then return end
        -- if encoded and scry is enabled, disable it
        if enc.call("APIobjIsPropEnabled",{obj=obj,propID=pID}) then
          enc.call("APIobjDisableProp",{obj=obj,propID=pID})
        end
      end
    end
  end
end

function onObjectDestroy(obj)
  pcall(function()
    if obj==nil then return end --wtf? how can this happen? but it does
    enc = Global.getVar('Encoder')
    if obj.type~="Card" or enc==nil then return end
    if enc.call("APIobjIsPropEnabled",{obj=obj,propID=pID}) then
      enc.call("APIobjDisableProp",{obj=obj,propID=pID})
    end
  end)
end

-- disable scry if the card lands on the table (height < 2)
function onObjectDrop(ply,obj)
  if obj==nil then return end --wtf? how can this happen? but it does
  if obj.type~="Card" then return end
  enc = Global.getVar('Encoder')
  if enc==nil then return end
  if not(enc.call("APIobjIsPropEnabled",{obj=obj,propID=pID})) then return end

  local inHand2=false
  if obj==nil then return end
  for _,col in pairs(Player.getAvailableColors()) do
    local handObjs=Player[col].getHandObjects(2)
    for _,handObj in pairs(handObjs) do
      if obj==handObj then
        inHand2=true
      end
    end
  end
  if not inHand2 then
    enc.call("APIobjDisableProp",{obj=obj,propID=pID})
    enc.call("APIrebuildButtons",{obj=obj})
  end
end

function createButtons(t)
  card=t.obj
  if card==nil then return end

  local backpars={    -- background frame
    label='', tooltip='', click_function = 'null', function_owner = self,
    position = {0, 0, 0}, width = 500, height = 400, font_size = 250,
    scale = {0.55,0.55,0.55}, rotation = {0,0,180},
    color = {0.7,0.7,0.7}, font_color = {1, 1, 1},
  }
  local forgpars={    -- foreground button with label
    label='', tooltip='', click_function = 'null', function_owner = self,
    position = {0, 0, 0}, width = 500, height = 400, font_size = 250,
    scale = {0.5,0.5,0.5}, rotation = {0,0,0},
    color = {0.16,0.16,0.16}, font_color = {1, 1, 1, 1}, hover_color = {0.4,0.4,0.4}
  }

  local lab='▲'
  local tip='move to top of library'
  local fun='move2TopLib'
  local pos={-0.8, 0.1, -2.2}
  forgpars.label=lab
  forgpars.tooltip=tip
  forgpars.click_function=fun
  forgpars.position=pos
  backpars.position=pos
  card.createButton(backpars)
  card.createButton(forgpars)

  local lab='▼'
  local tip='move to bottom of library'
  local fun='move2BotLib'
  local pos={-0.8, 0.1, -1.77}
  forgpars.label=lab
  forgpars.tooltip=tip
  forgpars.click_function=fun
  forgpars.position=pos
  backpars.position=pos
  card.createButton(backpars)
  card.createButton(forgpars)

  local lab='☠'
  local tip='move to graveyard'
  local fun='move2Grav'
  local pos={-0.8, 0.1, 1.77}
  forgpars.label=lab
  forgpars.tooltip=tip
  forgpars.click_function=fun
  forgpars.position=pos
  backpars.position=pos
  card.createButton(backpars)
  card.createButton(forgpars)
end

-- leftClick=top, rightClick=bottom of library function, currently unused
function move2Lib(card, playerColor, alt)
  if not(alt) then
    move2TopLib(card,playerColor)
  else
    move2BotLib(card,playerColor)
  end
end

function move2TopLib(card, playerColor)
  enc = Global.getVar('Encoder')
  enc.call("APIobjDisableProp",{obj=card,propID=pID})
  local deckPos = tableGUIDs[playerColor]["libraryZone"].getPosition()
  local target = {x=deckPos.x, y=3, z=deckPos.z}    -- above deck
  card.clearButtons()
  card.setHiddenFrom(allBut(playerColor))
  Wait.time(function() unhide(card) end, 0.2)
  local cardRot = card.getRotation()
  cardRot.z = 180
  card.setRotationSmooth(cardRot,false,true)
  Wait.time(function() handTrigger(card) card.setPositionSmooth(target,false,true) end, 0.2)
  Wait.time(function() checkMoveSuccess(card,target,playerColor) end, 0.5)

  selected = Player[playerColor].getSelectedObjects()
  for i,obj in ipairs(shuffleList(selected)) do
    if enc.call("APIobjIsPropEnabled",{obj=obj,propID=pID}) then
      Wait.frames(function() move2TopLib(obj, playerColor) end,i)
    end
  end
  Player[playerColor].clearSelectedObjects()

end

function move2BotLib(card, playerColor)
  enc = Global.getVar('Encoder')
  enc.call("APIobjDisableProp",{obj=card,propID=pID})
  local deckPos = tableGUIDs[playerColor]["libraryZone"].getPosition()
  local target  = {x=deckPos.x, y=0.95, z=deckPos.z}    -- below deck
  card.clearButtons()
  card.setHiddenFrom(allBut(playerColor))
  Wait.time(function() unhide(card) end, 0.2)
  local cardRot = card.getRotation()
  cardRot.z = 180
  card.setRotationSmooth(cardRot,false,true)
  Wait.time(function() handTrigger(card) card.setPositionSmooth(target,false,true) end, 0.2)
  Wait.time(function() checkMoveSuccess(card,target,playerColor) end, 0.5)

  selected = Player[playerColor].getSelectedObjects()
  for i,obj in ipairs(shuffleList(selected)) do
    if enc.call("APIobjIsPropEnabled",{obj=obj,propID=pID}) then
      Wait.frames(function() move2BotLib(obj, playerColor) end, i)
    end
  end
  Player[playerColor].clearSelectedObjects()
end

function move2Grav(card, playerColor)
  enc = Global.getVar('Encoder')
  enc.call("APIobjDisableProp",{obj=card,propID=pID})
  local gravPos = tableGUIDs[playerColor]["graveyard"].getPosition()
  local target  = {x=gravPos.x, y=3, z=gravPos.z}
  card.clearButtons()
  local cardRot = card.getRotation()
  cardRot.z = 0
  card.setRotationSmooth(cardRot,false,true)
  Wait.time(function() handTrigger(card) card.setPositionSmooth(target,false,true) end, 0.2)
  Wait.time(function() checkMoveSuccess(card,target,playerColor) end, 0.5)

  selected = Player[playerColor].getSelectedObjects()
  for i,obj in ipairs(shuffleList(selected)) do
    if enc.call("APIobjIsPropEnabled",{obj=obj,propID=pID}) then
      Wait.frames(function() move2Grav(obj, playerColor) end, i)
    end
  end
  Player[playerColor].clearSelectedObjects()
end

function shuffleList(list)
  math.randomseed(os.time())
	for i = #list, 2, -1 do
		local j = math.random(i)
		list[i], list[j] = list[j], list[i]
	end
  return list
end

-- for hiding cards
function allBut(playerColor)
  local players = {}
  for key, color in pairs(Color.list) do
    if color ~= playerColor then
      table.insert(players,color)
    end
  end
  return players
end
function unhide(card,nframes)
  if card~=nil then
    card.setHiddenFrom({})
  end
end

-- when returning cards from the scry-zone, turn off hand-zone's pull briefly
function handTrigger(obj)
  if obj~=nil then
    obj.use_hands=false
    Wait.time(function() handOn(obj) end, 0.1)
  end
end
function handOn(obj)
  if obj~=nil then
    obj.use_hands=true
  end
end

-- check that the card made it to it's target, if not, teleport it
function checkMoveSuccess(card,targetPos,playerColor)
  if card==nil then return end   -- the card is gone, probably stacked into a deck already
  -- use hands orientation to determine which coordinate to use to check position
  -- currently only set up to work with hands rotated 0,90,180,270 degrees
  local handForw=Player[playerColor].getHandTransform(2).forward
  local posDiff = 0
  if math.abs(handForw.z)>0.5 then
    posDiff = math.abs(card.getPosition().z - targetPos.z)
  elseif math.abs(handForw.x)>0.5 then
    posDiff = math.abs(card.getPosition().x - targetPos.x)
  end
  if posDiff>1 then
    card.setPosition(targetPos)
  end
end