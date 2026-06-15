--By Amuzet
--polished/updated by π

mod_name,version='LifeTracker',1
author='76561198045776458'

function updateSave()
  self.script_state=JSON.encode({['c']=count})
end

function wait(t)
  local s=os.time()
  repeat coroutine.yield(0) until os.time()>s+t
end

function sL(l,n)
  plus=''
  if n~=nil then
    if n>0 then plus='+' end
    if n==0 then
      n=nil
    end
  end
  self.editButton({index=0,label=l})
  self.editButton({index=1,label=plus..(n or'')})
  if slID~=nil then
    Wait.stop(slID)
  end
  slID=Wait.time(function() self.editButton({index=1,label=''}) end, 3)
end

function onPlayerChangeColor()
  onload(self.script_state)
end

function onPlayerConnect()
  onload(self.script_state)
end

function option(o,c,a)
  local n=1
  if a then
    n=-n
  end
  click_changeValue(o,c,n)
end

function click_changeValue(obj, color, val)
  -- if not(color==owner or Player[color].admin) then return end
  local C3=count
  count=count+val
  local C1=count
  function clickCoroutine()
    if not C2 then
      C2=C3
    end
    sL(count,(count-C2))
    wait(3)
    if C2 and C1==count then
      local gl='lost'
      if C1>C2 then
        gl='gained'
      end
      if C1~=C2 then
        sL(count)
        local t=txt:format(gl,math.abs(count-C2),count)
        printToAll(t,ownerRGB)
        log(t)
      end
      C2=nil
    end
  return 1
  end
  startLuaCoroutine(self,'clickCoroutine')
  updateSave()
end

function getActivePlayers()
  activePlayerList={}                       -- list of active colors
  for _,p in pairs(Player.getPlayers()) do
    if p.seated then
      activePlayerList[p.color]=true
    end
  end
  for _,obj in pairs(Global.getObjects()) do
    if obj.getName()=='Turn Skipper' then
      if obj.is_face_down then
        local skipColor = obj.getColorTint():toString()
        activePlayerList[skipColor]=false
      elseif not(obj.is_face_down) then
        local skipColor = obj.getColorTint():toString()
        activePlayerList[skipColor]=true
      end
    end
  end
end

function onObjectDrop(ply,obj)
  if obj.getName()=='Turn Skipper' then
    getActivePlayers()
    onload(self.script_state)
  end
end

function onObjectRotate(obj)
  if obj.getName()=='Turn Skipper' then
    Wait.condition(function()
      getActivePlayers()
      onload(self.script_state)
    end,function() return obj==nil or obj.resting end)
  end
end

function onObjectDestroy(obj)
  if obj.getName()=='Turn Skipper' then
    getActivePlayers()
    onload(self.script_state)
  end
end


local lCheck={
  ['extort_']=function(n,c)
    if c==owner then
      nseated=0
      for _,p in pairs(Player.getPlayers()) do
        if p.seated and p.color~=owner and activePlayerList[p.color] then
          nseated=nseated+1
          count=count+n
        end
      end
      return count,'extorted everyone for',n*nseated
    elseif Player[owner].seated and activePlayerList[owner] then
      return count-n,false,-1*n
    end
  end,
  ['drain_']=function(n,c)
    if c==owner and activePlayerList[owner] then
      return count+n,'drained everyone for',n
    elseif Player[owner].seated and activePlayerList[owner] then
      return count-n,false,-1*n
    end
  end,
  ['opponents_lose_']=function(n,c)
    if c==owner and activePlayerList[owner] then
      return count,'opponents lost',nil
    elseif Player[owner].seated and activePlayerList[owner] then
      return count-n,false,-1*n
    end
  end,
  ['everyone_loses_']=function(n,c)
    if Player[owner].seated and activePlayerList[owner] then
      return count-n,'made everyone lose',-1*n
    end
  end,
  ['double_my_life_']=function(n,c)
    if c==owner and activePlayerList[owner] then
      return count*2^n,'doubled their life this many times:',nil
    end
  end,
  ['reset_life_']=function(n,c)
    if c==owner then
      return n,'reset life totals to',nil
    else
      return n,false,nil
    end
  end,
  ['set_life_']=function(n,c)
    if c==owner then
      return n,'life total changed by '..math.abs(n-count)..'. Setting it to',nil
    end
  end,
  -- ['test_']=function(n,c)return count end,
}

function onChat(msg,player)
  if msg:find('[ _]%-?%d+') then
    local m=msg:lower():gsub(' ','_')
    local a,sl,t,n=false,false,'',tonumber(m:match('%-?%d+'))
    for k,f in pairs(lCheck) do
      if m:find(k..'%-?%d+') then

        getActivePlayers()
        if not(activePlayerList[owner]) then
          if owner==player.color then
            Player[owner].broadcast('You have a Turn Skipper active!',{0.25,0.25,0.25})
          end
          if not(msg:lower():match('set life')) then
            return
          end
        end

        a,t,nn=f(n,player.color)
        if a then
          count=a
          sL(count,nn)
        break
        else
          return msg
        end
      end
    end
    updateSave()
    if t and t~='' then
      broadcastToAll(player.color..'[999999] '..t..' [-]'..n,ownerRGB)
      -- sL(count,count-JSON.decode(self.script_state).c)
      return false
    end
  end
end

function onload(s)
  --Loads the tracking for if the game has started yet
  owner = self.getDescription()
  ownerRGB = Color.fromString(owner)
  ref_type = 'life'--self.getName():gsub('%s.+','')
  txt = owner..' [999999]%s %s '..ref_type..'[-] |%s|'

  self.setColorTint(ownerRGB)
  self.interactable=true

  if s~='' then
    local ld=JSON.decode(s); count=ld.c
  else
    count=40
  end

  self.clearButtons()

  local rgb = stringColorToRGB(owner)
  getActivePlayers()

  -- for a,b in pairs(activePlayerList) do
  --   print(a,'=',b)
  -- end
  -- print(activePlayerList[owner])

  -- font = Color.fromString(self.getDescription())
  if Player[owner].seated and activePlayerList[owner] then
    font1={1,1,1,100}
    font2={1,1,1,50}
    font3={1,1,1,20}
  else
    font1={1,1,1,20}
    font2={1,1,1,15}
    font3={1,1,1,15}
  end

  self.createButton({             -- the main button
    tooltip='Click to increase\nRight click to decrease',
    click_function='option',
    function_owner=self,
    height=750,
    width=950,
    font_size=1000,
    label='\n'..count..'\n',
    position={0,y,z},
    hover_color={1,1,1,0.1},
    scale=scale,
    color=back,
    font_color=font1
  })

  self.createButton({             -- moved the change value to a separate button for more control
    click_function='null',
    function_owner=self,
    height=0,
    width=0,
    font_size=400,
    label='',
    position={0-0.05,y,z+1},
    hover_color={1,1,1,0.1},
    scale=scale,
    color=back,
    font_color=font1
  })

  for i,v in ipairs({             -- the side buttons
      {n=1,l='▲',p={x*0.95,y,z+0.2}},
      {n=-1,l='▼',p={-x,y,z+0.2}},
      {n=20,l='+20',p={x*1.05,y,z-0.4}},
      {n=-20,l='-20',p={-x*1.1,y,z-0.4}}}) do

    local fn='valueChange'..i
    self.setVar(fn, function(o,c,a) local b=1 if a then b=5 end click_changeValue(o,c,v.n*b) end)
    self.createButton({
      tooltip='Right-click for '..v.n*5,
      label=v.l,
      position=v.p,
      click_function=fn,
      function_owner=self,
      height=800,
      width=800,
      font_size=700,
      hover_color={1,1,1,0.1},
      scale=scale2,
      color=back,
      font_color=font2,
    })
  end

	self.createButton({            -- reset life to 40 button
		label='[R]',
		click_function='resetLife',
		tooltip='Reset Life',
		function_owner=self,
		position={x*0.72,y,z-1.05},
		height=800,
		width=800,
		alignment = 3,
		font_size=700,
    hover_color={1,1,1,0.1},
		scale=scale2,
		font_color=font3,
		color=back,
	})
end

function resetLife(obj,color)
	sL(40,0)
	count=40
	printToAll(owner..'[999999] reset their life to [-]|'..count..'|',ownerRGB)
	updateSave()
end

self.max_typed_number=999
function onNumberTyped(col,int)
  local n=int-count
  sL(int,n)
  if tID~=nil then Wait.stop(tID) end
  tID=Wait.time(function()
    if int~=count then
      count=int
      local tx=' lost '
      if n>0 then tx=' gained ' end
      printToAll(owner..'[999999]'..tx..math.abs(n)..' life [-]|'..count..'|',ownerRGB)
    end
  end, 3)
end

function null()
end

x=1.2
y=0.05
z=-0.3
objsca = self.getScale()
scale  = {1,1,1}
scale2 = {0.3,1,0.3}
back = {0,0,0,0}
mode=''
ref_type=''
owner=''
C2=nil