--MTG Keyword decal icons by pie
--Adapted and *heavily* modified from:
--[[Keyword Abilities Module
by Tipsy Hobbit//STEAM_0:1:13465982
This module adds keyword abilities.
]]

pID = "πKeywords"
version = 3.14159

KeywordList={
  mtg_stuncounter=         {name=" Stun",
                            des="If this permanent would untap, instead remove a stun counter.",
                            iconN=0, val='number',
                            url='https://steamusercontent-a.akamaihd.net/ugc/2308719713295420226/7C0D2178367957CDF12A74FF03EAFD60385021DC/',
                            def=0},
  mtg_deathtouchcounter=   {name="Deathtouch",
                            des="Any amount of damage this deals to a creature is enough to destroy it.",
                            iconN=0, val='number',
                            url='https://steamusercontent-a.akamaihd.net/ugc/1647720820459770551/8ED7C2CF930BB048D5D0F281CEE139681D9FC132/',
                            def=0},
  mtg_defendercounter=     {name="Defender",
                            des="This creature can't attack.",
                            iconN=0, val='number',
                            url='https://steamusercontent-a.akamaihd.net/ugc/1647720820459771131/766BD64F624C102D6B7824B3D2065DEF1F15BD65/',
                            def=0},
  mtg_doublestrikecounter= {name="Double Strike",
                            des="This creature deals both first-strike and regular combat damage.",
                            iconN=0, val='number',
                            url='https://steamusercontent-a.akamaihd.net/ugc/1647720820459771597/06334C3958CF7B3C50A76A4F2F22ACD6389D2169/',
                            def=0},
  mtg_exert=               {name="Exerted",
                            des="This creature does not untap during the next untap phase.",
                            iconN=0, val='boolean',
                            url='https://steamusercontent-a.akamaihd.net/ugc/1647720820459806827/780E1DD097101E18130DB4C83D6BC6952DDD389B/',
                            def=false},
  mtg_firststrikecounter=  {name="First Strike",
                            des="This creature deals combat damage before creatures without first strike.",
                            iconN=0, val='number',
                            url='https://steamusercontent-a.akamaihd.net/ugc/1647720820459774469/9FB16BFF1B02B2455C3D844127EC39A141534F33/',
                            def=0},
  mtg_flyingcounter=       {name="Flying",
                            des="This creature can't be blocked except by creatures with flying and/or reach.",
                            iconN=0, val='number',
                            url='https://steamusercontent-a.akamaihd.net/ugc/1647720820459775349/912974BD1EAE7E35274F2228F0275C08473F73C2/',
                            def=0},
  mtg_frozen=              {name="Frozen",
                            des="This permanent does not untap during your untap step.",
                            iconN=0, val='boolean',
                            url='https://steamusercontent-a.akamaihd.net/ugc/1647720820456149360/25E52B39EC8D17AB3DA424D6B3B8CAEA4FDF56AF/',
                            def=false},
  mtg_hastecounter=        {name="Haste",
                            des="This creature does not suffer from summoning sickness.",
                            iconN=0, val='number',
                            url='https://steamusercontent-a.akamaihd.net/ugc/1647720820459776460/2384D15814E736DCED6F3D755E9C7750DE844CF1/',
                            def=0},
  mtg_hexproofcounter=     {name="Hexproof",
                            des="This permanent can't be the target of spells or abilities your opponents control.",
                            iconN=0, val='number',
                            url='https://steamusercontent-a.akamaihd.net/ugc/1647720820459777186/41A7105B5FBBFE116EBFD950C5809724CCD508B1/',
                            def=0},
  mtg_indestructiblecounter={name="Indestructible",
                            des="Effects that say 'destroy' don’t destroy this.",
                            iconN=0, val='number',
                            url='https://steamusercontent-a.akamaihd.net/ugc/1647721275620396729/06E0D42899D763E8C179326CB8A904543C1F25DA/',
                            def=0},
  mtg_lifelinkcounter=     {name="Lifelink",
                            des="Damage dealt by this creature also causes you to gain that much life.",
                            iconN=0, val='number',
                            url='https://steamusercontent-a.akamaihd.net/ugc/1647720820459778541/EC0A9AE3F2A92ED0070E0050A3AB451046D79A35/',
                            def=0},
  mtg_menacecounter=       {name="Menace",
                            des="This creature can't be blocked except by two or more creatures.",
                            iconN=0, val='number',
                            url='https://steamusercontent-a.akamaihd.net/ugc/1647720820459779239/1C65FC6264E001EB3DCBC88A8473B0EABE33834A/',
                            def=0},
  mtg_monstrous=           {name="Monstrous",
                            des="",
                            iconN=0, val='boolean',
                            url='https://steamusercontent-a.akamaihd.net/ugc/1647720820459780510/BE90A9C8FB0237AB088B57E489958A11013D71E5/',
                            def=false},
  mtg_reachcounter=        {name="Reach",
                            des="This creature can block creatures with flying.",
                            iconN=0, val='number',
                            url='https://steamusercontent-a.akamaihd.net/ugc/1647720820459781368/2390550F830E8BF214F9FF9CD971976A35C95230/',
                            def=0},
  mtg_renowned=            {name="Renowned",
                            des="",
                            iconN=0, val='boolean',
                            url='https://steamusercontent-a.akamaihd.net/ugc/1647720820459782265/E8B8FA821ADA6B36A77984870E0B5BCF66352FB3/',
                            def=false},
  mtg_suspendcounter=      {name="Suspend",
                            des="At the beginning of your upkeep, remove a time counter. When the last is removed, cast this card without paying its mana cost, it has haste.",
                            iconN=0, val='number',
                            url='https://steamusercontent-a.akamaihd.net/ugc/1647720820459783190/43F1E357A6ABB926A6BB3A721F39CD827B2C2751/',
                            def=0},
  mtg_tramplecounter=      {name="Trample",
                            des="This creature can deal excess combat damage to player or planeswalker it's attacking.",
                            iconN=0, val='number',
                            url='https://steamusercontent-a.akamaihd.net/ugc/1647720820459785398/41B89DCAC842C5C2624AC5EFA9428492C2841515/',
                            def=0,},
  mtg_vigilancecounter=    {name="Vigilance",
                            des="Attacking doesn't cause this creature to tap.",
                            iconN=0, val='number',
                            url='https://steamusercontent-a.akamaihd.net/ugc/1647720820459786000/AF931371F2426EF81E336C0BD668EA983AE843D9/',
                            def=0},
}

function onload()
  self.interactable=true
  self.createButton({
    click_function='registerModule', function_owner=self, label='[i]'..pID..'[/i]', tooltip='register '..pID,
    position={0,0.1,0}, rotation={0,0,0}, scale={0.5,1,0.5},
    height=250, width=900, font_size=150,  color={0.1,0.1,0.1,1}, font_color={1,1,1,1},
  })
  Wait.condition(registerModule,function() return Global.getVar('Encoder') ~= nil and true or false end)
end

function registerModule(obj,ply)
  enc = Global.getVar('Encoder')
  if enc ~= nil then

    value = {valueID='activeIcons',validType='nil',desc='',default={}}
    enc.call("APIregisterValue",value)
    value = {valueID='iconMenuOn',validType='boolean',desc='',default=false}
    enc.call("APIregisterValue",value)
    value = {valueID='iconLayout',validType='string',desc='',default='art'}
    enc.call("APIregisterValue",value)

    for k,v in pairs(KeywordList) do
      value = {
        valueID = k,
        validType = v.val,
        desc = '',
        default = v.def,
      }
      enc.call("APIregisterValue",value)
      _G['toggleStatus'..k] = function(obj,ply,alt) toggleStatus(obj,ply,alt,k) end
    end

    values={'activeIcons','iconMenuOn','iconLayout'}
    for k,v in pairs(KeywordList) do
      table.insert(values,k)
    end
    properties = {
      propID = pID,
      name = "Keywords[sup][i]π[/i][/sup]",
      values = values,
      funcOwner = self,
      tags="basic,counter",
      activateFunc = 'toggleKeywordsMenu',
      visible_in_hand=1
    }
    enc.call("APIregisterProperty",properties)
  end
end

function toggleKeywordsMenu(obj,ply)
  enc = Global.getVar('Encoder')
  if enc ~= nil then
    enc.call("APItoggleProperty",{obj=obj,propID=pID})
    if enc.call("APIobjIsPropEnabled",{obj=obj,propID=pID}) then
      iconMenuOn = true
      enc.call("APIobjSetValueData",{obj=obj,valueID='iconMenuOn',data={iconMenuOn=iconMenuOn}})
      checkConflictingMenus(obj)
    else
      resetDecals(obj)    -- delete keyword decals on object
      -- set all keyword values to 0 and false
      local data   = enc.call("APIobjGetPropData",{obj=obj,propID=pID})
      for key,dat in pairs(KeywordList) do
        if KeywordList[key].val=='number' then
          data[key]=0
        elseif KeywordList[key].val=='boolean' then
          data[key]=false
        end
      end
      data['iconMenuOn'] = false
      enc.call("APIobjSetPropData",{obj=obj,propID=pID,data=data})
    end
    enc.call("APIrebuildButtons",{obj=obj})
  end
end

function checkConflictingMenus(obj)
    enc = Global.getVar('Encoder')
    if enc ~= nil then
        keywordsData = enc.call("APIobjGetPropData",{obj=obj,propID="MorphinTime"})
        if keywordsData ~= nil then
            if keywordsData['subMenuOpen'] then
                keywordsData['subMenuOpen'] = false
                enc.call("APIobjSetPropData",{obj=obj,propID="MorphinTime",data=keywordsData})
            end
        end
    end
end

function toggleIconMenu(obj,ply)
  local ico = enc.call("APIobjGetValueData",{obj=obj,valueID='iconMenuOn'})
  local iconMenuOn = ico['iconMenuOn']
  iconMenuOn = not iconMenuOn
  
  if iconMenuOn then
    checkConflictingMenus(obj)
  end
  
  enc.call("APIobjSetValueData",{obj=obj,valueID='iconMenuOn',data={iconMenuOn=iconMenuOn}})
  enc.call("APIrebuildButtons",{obj=obj})
end

function toggleStatus(obj,ply,alt,key)
  enc = Global.getVar('Encoder')
  if enc ~= nil then
    local data   = enc.call("APIobjGetPropData",{obj=obj,propID=pID})
    local activeIcons = data['activeIcons']

    -- booleans
    if KeywordList[key].val == 'boolean' then
      if alt ~= true then
        if data[key] ~= true then
          data[key] = true
          table.insert(activeIcons,key)
          updateDecals=true
        end
      else
        if data[key] ~= false then
          data[key] = false
          activeIcons = rmFromTable(activeIcons,key)
          updateDecals=true
      end
    end

    -- colors? unused
    elseif KeywordList[key].val == 'color' then
      if data[key] ~= '' then
        data[key] = ''
      else
        data[key] = KeywordList[key].func ~= nil and KeywordList[key].func() or ply
      end

    -- numbers
    elseif KeywordList[key].val == 'number' then
      if alt ~= true then
        if data[key]==0 then
          table.insert(activeIcons,key)
          updateDecals=true
        end
        data[key] = data[key]+1
      else
        if data[key]==1 then
          activeIcons = rmFromTable(activeIcons,key)
          updateDecals=true
        end
        data[key] = data[key]-1
        if data[key]<0 then data[key]=0 end
      end
    end

    data['activeIcons'] = activeIcons
    enc.call("APIobjSetPropData",{obj=obj,propID=pID,data=data})
    enc.call("APIrebuildButtons",{obj=obj})
  end
end

function rmFromTable(oldList,key)
  local newList={}
  for i,k in pairs(oldList) do
    if k~=key then
      table.insert(newList,k)
    end
  end
  return newList
end

function toggleLayout(obj,ply)
  local lay = enc.call("APIobjGetValueData",{obj=obj,valueID='iconLayout'})
  iconLayout = lay['iconLayout']
  if iconLayout=='above' then
    iconLayout='art'
  else
    iconLayout='above'
  end
  updateDecals=true
  enc.call("APIobjSetValueData",{obj=obj,valueID='iconLayout',data={iconLayout=iconLayout}})
  enc.call("APIrebuildButtons",{obj=obj})
end

function resetDecals(obj)
  -- reset decals, keeping any that are not from keywords
  local decals = obj.getDecals()
  local ndecals = {}
  if decals~=nil then
    for i,d in pairs(decals) do
      if not isKeyword(d.name) then
        table.insert(ndecals,d)
      end
    end
    obj.setDecals(ndecals)
  end
end

function isKeyword(str)
  local isKeyword = false
  for i,key in pairs(KeywordList) do
    if key.name==str then
      isKeyword=true
    end
  end
  return isKeyword
end

function updateActiveIcons(data,obj)
  local activeIcons = data['activeIcons']
  local prevActiveIcons = activeIcons
  for i,key in pairs(activeIcons) do
    if data[key]==0 or data[key]==false then
      activeIcons = rmFromTable(activeIcons,key)
    end
  end
  data['activeIcons'] = activeIcons
  enc.call("APIobjSetValueData",{obj=obj,valueID='activeIcons',data={activeIcons=activeIcons}})

  if table.concat(activeIcons)~=table.concat(prevActiveIcons) then
    updateDecals=true
  end

  return activeIcons
end

function createButtons(t)
  enc = Global.getVar('Encoder')
  if enc ~= nil then

    local data = enc.call("APIobjGetPropData",{obj=t.obj,propID=pID})
    local flip = enc.call("APIgetFlip",{obj=t.obj})
    local scaler = {x=1,y=1,z=1}        --t.obj.getScale()
    local iconMenuOn  = data['iconMenuOn']
    local layout      = data['iconLayout']
    activeIcons = updateActiveIcons(data,t.obj)

    if updateDecals then
      resetDecals(t.obj)
    end

    -- keyword decals and buttons
    nIcons = #activeIcons
    for i,key in pairs(activeIcons) do
      iconN=i
      val = data[key]
      if (KeywordList[key].val=='number' and val~=0) or (KeywordList[key].val=='boolean' and val~=false) then
        if layout=='above' then
          nPerRow = 5     -- number icons per row
          gridY = math.floor((iconN-1)/nPerRow)
          gridX = iconN-nPerRow*gridY-1
          posD = {(-1)*(1-1/nPerRow-gridX*(2/nPerRow))*flip*scaler.x,0.3*flip*scaler.z,(-1.55-1/nPerRow-gridY*2/nPerRow)}
          posB = {     (1-1/nPerRow-gridX*(2/nPerRow))*flip*scaler.x,0.8*flip*scaler.z,(-1.55-1/nPerRow-gridY*2/nPerRow)}
          sm = 4/nPerRow  --scale multiplier
        else
          if nIcons==1 then
            posD = {(-1)*(0)*flip*scaler.x,0.3*flip*scaler.z,(-0.5)}
            posB = {     (0)*flip*scaler.x,0.8*flip*scaler.z,(-0.5)}
            sm = 1.5
          elseif nIcons==2 then
            gridY = math.floor((iconN-1)/2)
            gridX = iconN-2*gridY-1
            posD = {(-1)*(0.3-gridX*0.6)*flip*scaler.x,0.3*flip*scaler.z,(-0.5+gridY*0.6)}
            posB = {     (0.3-gridX*0.6)*flip*scaler.x,0.8*flip*scaler.z,(-0.5+gridY*0.6)}
            sm = 1.25
          elseif nIcons==3 then
            gridY = math.floor((iconN-1)/3)
            gridX = iconN-3*gridY-1
            posD = {(-1)*(0.6-gridX*0.6)*flip*scaler.x,0.3*flip*scaler.z,(-0.5+gridY*0.6)}
            posB = {     (0.6-gridX*0.6)*flip*scaler.x,0.8*flip*scaler.z,(-0.5+gridY*0.6)}
            sm = 1.25
          elseif nIcons==4 then
            gridY = math.floor((iconN-1)/2)
            gridX = iconN-2*gridY-1
            posD = {(-1)*(0.3-gridX*0.6)*flip*scaler.x,0.3*flip*scaler.z,(-0.8+gridY*0.6)}
            posB = {     (0.3-gridX*0.6)*flip*scaler.x,0.8*flip*scaler.z,(-0.8+gridY*0.6)}
            sm = 1.25
          else
            gridY = math.floor((iconN-1)/3)
            gridX = iconN-3*gridY-1
            posD = {(-1)*(0.6-gridX*0.6)*flip*scaler.x,0.3*flip*scaler.z,(-0.8+gridY*0.6)}
            posB = {     (0.6-gridX*0.6)*flip*scaler.x,0.8*flip*scaler.z,(-0.8+gridY*0.6)}
            sm = 1.25
          end
        end

        rotD = {180-flip*90,90+flip*90,0}
        rotB = {0,0,90-90*flip}

        --decal parameters
        dpars = {
          name=KeywordList[key].name,
          url=KeywordList[key].url,
          position=posD,
          rotation=rotD,
          scale={0.45*sm,0.45*sm,0.45*sm}
        }

        --buttons parameters
        ttip='[b]'..KeywordList[key].name..'[/b]'
        if KeywordList[key].val=='number' and val~=0 then
          ttip=val..' '..ttip
        end
        if KeywordList[key].des~='' then
          ttip=ttip..': '..KeywordList[key].des
        end
        lab=''
        if KeywordList[key].val == 'number' and val>1 then
          lab=tostring(val)
        end

        bpars = {   -- main button with counter
          click_function='toggleStatus'..key, function_owner=self, label=lab, tooltip=ttip,
          position=posB, rotation=rotB,
          scale={0.45*sm,0.45*sm,0.45*sm}, width=512, height=512, font_size=350,
          color={0,0,0,0}, font_color={1,1,1,100}, hover_color={0,0,0,0}
        }
        bparsO = {   -- main button with counter
          click_function='toggleStatus'..key, function_owner=self, label='[b]'..lab..'[/b]', tooltip=ttip,
          position=posB, rotation=rotB,
          scale={0.45*sm,0.45*sm,0.45*sm}, width=512, height=512, font_size=350,
          color={0,0,0,0}, font_color={0,0,0,100}, hover_color={0,0,0,0}
        }
        bparsS = {    -- shadow below the counter
          click_function='null', function_owner=self, label=lab,
          position={posB[1]-0.02*sm,posD[2],posB[3]+0.02*sm}, rotation=rotB,
          scale={0.45*sm,0.45*sm,0.45*sm}, width=0, height=0, font_size=350,
          color={0,0,0,0}, font_color={0,0,0,90}, hover_color={0,0,0,0},
        }
        bparsNs = {    -- name of ability on button
          click_function='null', function_owner=self, label=KeywordList[key].name,
          position={posB[1]-0.005*sm,posB[2],posB[3]+0.18*sm+0.005*sm}, rotation=rotB,
          scale={0.45*sm,0.45*sm,0.45*sm},  width=0,  height=0, font_size=80,
          color={0,0,0,0},  font_color={0,0,0,90},  hover_color={0,0,0,0},
        }
        bparsN = {    -- name of ability on button
          click_function='null', function_owner=self, label=KeywordList[key].name,
          position={posB[1],posB[2],posB[3]+0.18*sm}, rotation=rotB,
          scale={0.45*sm,0.45*sm,0.45*sm},  width=0,  height=0, font_size=80,
          color={0,0,0,0},  font_color={1,1,1,100},  hover_color={0,0,0,0},
        }

        if updateDecals then
          t.obj.addDecal(dpars)
        end
        t.obj.createButton(bparsNs)
        t.obj.createButton(bparsN)
        t.obj.createButton(bparsS)
        t.obj.createButton(bparsO)
        t.obj.createButton(bpars)
      end
    end

    updateDecals=false

    -- menu
    if not iconMenuOn then

      t.obj.createButton({
      label="[b]>>>[/b]", click_function='toggleIconMenu', function_owner=self,
      position={0.875*flip*scaler.x,0.28*flip*scaler.z,-1.485*scaler.y}, scale={0.5,1,0.3}, height=0, width=0, font_size=200,
      rotation={0,0,90-90*flip},color={0,0,0,0},font_color={0,0,0,50},
      })
      t.obj.createButton({
      label=">>>", click_function='toggleIconMenu', function_owner=self,
      position={0.875*flip*scaler.x,0.28*flip*scaler.z,-1.485*scaler.y}, scale={0.5,1,0.3}, height=350, width=450, font_size=200,
      rotation={0,0,90-90*flip},color={0,0,0,0},font_color={1,1,1,50},hover_color={0.1,0.1,0.1,1/50},tooltip="Keywords Menu",
      })

    else

      t.obj.createButton({
      label="<<<", click_function='toggleIconMenu', function_owner=self,
      position={0.875*flip*scaler.x,0.28*flip*scaler.z,-1.485*scaler.y}, scale={0.5,1,0.3}, height=350, width=450, font_size=200,
      rotation={0,0,90-90*flip},color={0.1,0.1,0.1,1},font_color={1,1,1,1},tooltip="Keywords Menu",
      })
      t.obj.createButton({
      label='layout:\n'..layout, click_function='toggleLayout', function_owner=self,
      position={2.9*flip*scaler.x,0.28*flip*scaler.z,0*scaler.y}, scale={0.5,0.5,0.5}, height=300, width=600, font_size=100,
      rotation={0,0,90-90*flip},color={0.1,0.1,0.1,0.8},font_color={1,1,1,0.5},tooltip="Change location of icons relative to the card",
      })

      t.obj.createButton({
      label="Counters", click_function='null', function_owner=self, scale={0.5,1,0.5}, height=0, width=0, font_size=180,
      position={1.7*flip,0.28*flip*scaler.z,(-1.6)*scaler.y},
      rotation={0,0,90-90*flip}, tooltip='', color={0,0,0,0}, font_color={1,1,1,100},
      })
      t.obj.createButton({
      label="Status Effects", click_function='null', function_owner=self, scale={0.5,1,0.5}, height=0, width=0, font_size=180,
      position={2.9*flip,0.28*flip*scaler.z,(-1.6)*scaler.y},
      rotation={0,0,90-90*flip}, tooltip='', color={0,0,0,0}, font_color={1,1,1,100},
      })

      local i = 1
      local j = 1
      for key,dat in pairs(KeywordList) do
        if key:sub(1,3)=='mtg' then
          val = data[key]
          --numbers
          if type(val) == 'number' then
            if val~=0 then
              t.obj.createButton({
              label= KeywordList[key].name, click_function='toggleStatus'..key, function_owner=self, scale={0.5,1,0.5}, height=200, width=1100, font_size=160,
              position={1.7*flip,0.28*flip*scaler.z,(-1.6+i*0.2)*scaler.y},
              rotation={0,0,90-90*flip}, color={0.1,0.1,0.1,1}, font_color={1,1,0},tooltip='[b]'..tostring(val).."[/b]\nleft click to increase\nright click to decrease"
              })
            else
              t.obj.createButton({
              label= KeywordList[key].name, click_function='toggleStatus'..key, function_owner=self, scale={0.5,1,0.5}, height=200, width=1100, font_size=160,
              position={1.7*flip,0.28*flip*scaler.z,(-1.6+i*0.2)*scaler.y},
              rotation={0,0,90-90*flip}, color={0.1,0.1,0.1,1}, font_color={1,1,1,0.75},tooltip="left click to increase\nright click to decrease"
              })
            end
            i=i+1
          end
          --booleans
          if type(val) == 'boolean' then
            if val==true then
              t.obj.createButton({
              label= KeywordList[key].name, click_function='toggleStatus'..key, function_owner=self, scale={0.5,1,0.5}, height=200, width=1100, font_size=160,
              position={2.9*flip,0.28*flip*scaler.z,(-1.6+j*0.2)*scaler.y},
              rotation={0,0,90-90*flip}, color={0.1,0.1,0.1,1}, font_color={1,1,0},tooltip="left click to turn on\nright click to turn off"
              })
            else
              t.obj.createButton({
              label= KeywordList[key].name, click_function='toggleStatus'..key, function_owner=self, scale={0.5,1,0.5}, height=200, width=1100, font_size=160,
              position={2.9*flip,0.28*flip*scaler.z,(-1.6+j*0.2)*scaler.y},
              rotation={0,0,90-90*flip}, color={0.1,0.1,0.1,1}, font_color={1,1,1,0.75},tooltip="left click to turn on\nright click to turn off"
              })
            end
            j=j+1
          end
        end
      end
    end   --end menu
  end   --end if enc
end   --end createButtons

function null() end

-- prevent copy pasting emblems
function onObjectSpawn(obj)
  enc = Global.getVar('Encoder')
  if enc ~= nil then
    if enc.call("APIobjIsPropEnabled",{obj=obj,propID=pID}) then
      local t = {obj=obj}
      createButtons(t)
    else
      resetDecals(obj)
    end
  end
end