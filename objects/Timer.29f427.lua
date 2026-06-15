function onLoad(saved_data)

  owner=self.getDescription()

  self.setLock(true)
  self.interactable=false

  pos=self.getPosition()
  pos[2]=0
  self.setPosition(pos)

  timerOn=true
  viewTot=false

  ownerCol=Color.fromString(owner)

  turnN=0
  totT=0
  pcall(function()
    if saved_data ~= "" then
      local loaded_data = JSON.decode(saved_data)
      turnN = loaded_data[1]
      totT = loaded_data[2]
    end
  end)
  updateSave()

  bpars={
    click_function='null',
    function_owner=self,
    label='',
    width=0,
    height=0,
    font_size=500,
    color={0,0,0,0},
    font_color={ownerCol.r,ownerCol.g,ownerCol.b,100},
    tooltip=''
  }

  bpars_s1=bpars
  bpars_s2=bpars
  bpars_co=bpars
  bpars_m1=bpars
  bpars_m2=bpars

  bpars_s1.position=vector(1,1,0)
  self.createButton(bpars_s1)
  bpars_s2.position=vector(0.4,1,0)
  self.createButton(bpars_s2)
  bpars_co.position=vector(0,1,-0.05)
  bpars_co.font_size=400
  self.createButton(bpars_co)
  bpars_m1.position=vector(-0.4,1,0)
  bpars_m1.font_size=500
  self.createButton(bpars_m1)
  bpars_m2.position=vector(-1,1,0)
  self.createButton(bpars_m2)

  bpars_t=bpars
  bpars_t.font_size=400
  bpars_t.label=''
  bpars_t.position=vector(-0.2,1,-1.2)
  self.createButton(bpars_t)

  bpars_tc=bpars
  bpars_tc.click_function='modTurn'
  bpars_tc.font_size=500
  bpars_tc.width=0
  bpars_tc.height=0
  bpars_tc.label=''
  bpars_tc.position=vector(1.2,1,-1.2)
  self.createButton(bpars_tc)

  bpars_tot=bpars
  bpars_t.position=vector(-2,1,0)
  bpars_t.label=''
  bpars_t.font_size=300
  self.createButton(bpars_tc)

  bpars_swap=bpars
  bpars_swap.position=vector(0.2,1,0)
  bpars_swap.width=900
  bpars_swap.height=350
  bpars_swap.click_function='swapTot'
  self.createButton(bpars_swap)

end

function updateSave()
  local data_to_save = {turnN, totT}
  saved_data = JSON.encode(data_to_save)
  self.script_state = saved_data
end

function modTurn(obj,ply,alt)
  turnN=turnN + (alt and -1 or 1)
  self.editButton({index=6,label=turnN})
  updateSave()
end

function swapTot(obj,ply,alt)
  if alt then

    viewTot=true

    self.editButton({index=5,label='turn'})
    self.editButton({index=6,width=400,height=400,label=turnN})

    self.editButton({index=7,label='total'})
    self.editButton({index=8,width=900,height=350,label=''})
    tdiff=totT

    mins=math.floor(tdiff/60)
    secs=tdiff-mins*60
    secStr=tostring(secs)
    minStr=tostring(mins)
    if string.len(secStr)<2 then
      secStr='0'..secStr
    end
    if string.len(minStr)<2 then
      minStr=' '..minStr
    end
    timeStr=minStr..':'..secStr

    updateButtons(timeStr)
    updateSave()

    if totTimer~=nil then
      pcall(function() Wait.stop(totTimer) end)
    end
    totTimer = Wait.time(function() viewTot=false end,5)

  end
end

function onPlayerTurn(ply)
  -- print(ply)
  if timerOn then
    if ply~=nil and ply.color==owner then
      turnT=0
      turnN=turnN+1
      showTimer(ply)
    else
      hideTimer(ply)
    end
  else
    hideTimer(ply)
  end
end

function showTimer()

    if timerID~=nil then
      pcall(function() Wait.stop(timerID) end)
    end

    timerID=Wait.time(function()

      turnT=turnT+1
      totT=totT+1

      -- print(turnT,' ',totT)

      self.editButton({index=5,label='turn'})
      self.editButton({index=6,width=400,height=400,label=turnN})

      if viewTot then
        self.editButton({index=7,label='total'})
        self.editButton({index=8,width=900,height=350,label=''})
        tdiff=totT
      else
        self.editButton({index=7,label=''})
        self.editButton({index=8,width=900,height=350,label=''})
        tdiff=turnT
      end

      mins=math.floor(tdiff/60)
      secs=tdiff-mins*60
      secStr=tostring(secs)
      minStr=tostring(mins)
      if string.len(secStr)<2 then
        secStr='0'..secStr
      end
      if string.len(minStr)<2 then
        minStr=' '..minStr
      end
      timeStr=minStr..':'..secStr

      updateButtons(timeStr)
      updateSave()

    end,1,5999)

end

function hideTimer(ply)

  if timerID~=nil then
    pcall(function() Wait.stop(timerID) end)
  end
  updateButtons('     ')
  self.editButton({index=5,label=''})
  self.editButton({index=6,width=0,height=0,label=''})
  self.editButton({index=7,label=''})
  self.editButton({index=8,width=0,height=0,label=''})

end


function updateButtons(str)

  if timerOn then
    self.editButton({index=0,label=str:sub(5,5)})
    self.editButton({index=1,label=str:sub(4,4)})
    self.editButton({index=2,label=str:sub(3,3)})
    self.editButton({index=3,label=str:sub(2,2)})
    self.editButton({index=4,label=str:sub(1,1)})
  else
    self.editButton({index=0,label=''})
    self.editButton({index=1,label=''})
    self.editButton({index=2,label=''})
    self.editButton({index=3,label=''})
    self.editButton({index=4,label=''})
  end

end


function onChat(msg,ply)

  if msg:lower()=='timers on' then
    timerOn=true
  end
  if msg:lower()=='timers off' then
    timerOn=false
    updateButtons('     ')
    self.editButton({index=5,label=''})
    self.editButton({index=6,width=0,height=0,label=''})
  end

  if msg:lower():find('reset life') then
    turnN=0
    turnT=0
    totT=0
    updateSave()
    if Turns.turn_color==owner then
      self.editButton({index=6,width=400,height=400,label=turnN})
    end
  end

end