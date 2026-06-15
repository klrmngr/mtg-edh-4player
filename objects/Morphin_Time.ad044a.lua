pID = 'MorphinTime'
version = '1.2'
--DXHHH101

function onload()
	Global.setVar('MorphinTime',self)
    
    self.createButton({
    label="+", click_function='registerModule', function_owner=self,
    position={0,0.2,-0.5}, height=120, width=120, font_size=100,
    rotation={0,0,0},tooltip="register "..pID,
    color={0.1,0.1,0.1},font_color={1,1,1}
    })
    Wait.condition(registerModule,function() return Global.getVar('Encoder') ~= nil and true or false end)
    
  
  -- scan all objects (necessary if the game is saved/loaded/ctrl-Zed)
  for _,obj in pairs(getObjects()) do
    addContextOptions(obj)
  end
  
end

function onObjectEnterZone(zone,obj)
    addContextOptions(obj)
end

function onObjectLeaveZone(zone,obj)
    addContextOptions(obj)
end


--backwards order because the buttons are created bottom-up and I can't be bothered to reverse the table iteration
faceDownTypes={
	
	mtg_faceDownCreature=   {
                            name="Creature",
                            cardName="[i]Creature[/i]\nCreature 0CMC",
                            cardDesc="[i](This face-down permanent is a 2/2 colorless, nameless creature.)[/i] \n[b]2/2[/b]",
                            contextMenuName="flip over",
                            url='https://steamusercontent-a.akamaihd.net/ugc/2350384442427730158/340D8C52766BA1ED3A5AE9CB33BD72FF146534CD/',
                            },
                            
    mtg_faceDownForest=     {
                            name="Forest",
                            cardName="[i]Forest[/i]\nLand — Forest 0CMC",
                            cardDesc="({T}: Add {G}.)\n[i](This face-down permanent is a colorless, nameless Forest Land.)[/i]",
                            url='https://steamusercontent-a.akamaihd.net/ugc/2350384442401704856/782526BF0D36E031799EB185C801F6FD026F665F/',
                            },
                            
    mtg_faceDownCyberman=   {
                            name="Cyberman",
                            cardName="[i]Cyberman[/i]\nArtifact Creature — Cyberman 0CMC",
                            cardDesc="[i](This face-down permanent is a 2/2 colorless, nameless Cyberman artifact creature.)[/i] \n[b]2/2[/b]",
                            url='https://cards.scryfall.io/png/front/9/b/9bc273b8-05bb-4c8f-92b1-c178d4bbadb0.png',
                            },
                            
    mtg_faceDownCloak=      {
                            name="Cloak",
                            cardName="[i]Cloak[/i]\nCreature 0CMC",
                            cardDesc="Ward 2\n[i](This face-down permanent is a 2/2 colorless, nameless creature with ward 2. A cloaked creature card can be turned face up any time for its mana cost. A face-down card can also be turned face up for its morph or disguise cost.)[/i] \n[b]2/2[/b]",
                            url='https://steamusercontent-a.akamaihd.net/ugc/2294088813204025955/DA6270187A882AC157345A39724728524DAE6AA7/',
                            },
                        
    mtg_faceDownDisguise=   {
                            name="Disguise",
                            cardName="[i]Disguise[/i]\nCreature 0CMC",
                            cardDesc="Ward 2\n[i](This face-down permanent is a 2/2 colorless, nameless creature with ward 2. A card with disguise can be turned face up any time for its disguise cost.)[/i] \n[b]2/2[/b]",
                            url='https://steamusercontent-a.akamaihd.net/ugc/2294088813204025955/DA6270187A882AC157345A39724728524DAE6AA7/',
                            },
                            
    mtg_faceDownManifest=   {
                            name="Manifest",
                            cardName="[i]Manifest[/i]\nCreature 0CMC",
                            cardDesc="[i](This face-down permanent is a 2/2 colorless, nameless creature. A manifested creature card can be turned face up any time for its mana cost. A face-down card can also be turned face up for its morph or disguise cost.)[/i] \n[b]2/2[/b]",
                            url='https://steamusercontent-a.akamaihd.net/ugc/1754682557224978180/6349076AC8C43E2DAE374272421A8D9E19F41641/',
                            },
                            
    mtg_faceDownMorph=      {
                            name="Morph",
                            cardName="[i]Morph[/i]\nCreature 0CMC",
                            cardDesc="[i](This face-down permanent is a 2/2 colorless, nameless creature. A card with morph can be turned face up any time for its morph cost.)[/i] \n[b]2/2[/b]",
                            contextMenuName="Unmorph",
                            url='https://steamusercontent-a.akamaihd.net/ugc/1754682557224979089/6342821AA427B7799F49AA51F9D60996BBC40977/',
                            }
}



function registerModule(obj,ply)
	enc = Global.getVar('Encoder')
	if enc ~= nil then

		value = {
            valueID='subMenuOpen',
            validType='boolean',
            desc='is the sub menu open',
            default=false
        }
		enc.call("APIregisterValue",value)
        value = {
            valueID = 'cardName',
            validType = 'string',
            desc = 'save a cards name here',
            default = "Morphin' Time Error"
        }
        enc.call("APIregisterValue",value)
        
        value = {
            valueID = 'cardDesc',
            validType = 'string',
            desc = 'save a cards description here',
            default = "Morphin' Time Error"
        }
        enc.call("APIregisterValue",value)
        
        value = {
            valueID = 'activeMode',
            validType = 'string',
            desc = '',
            default = "mtg_faceDownCreature"
        }
        enc.call("APIregisterValue",value)

		values={'subMenuOpen', 'cardName', 'cardDesc', 'activeMode'}

		properties = {
			propID = pID,
			name = "Morphin' Time",
			values = values,
			funcOwner = self,
			tags="basic,counter", --FIX
			activateFunc = 'toggleFaceDown',
			visible_in_hand=1
		}
		enc.call("APIregisterProperty",properties)
        
        
        for k,_ in pairs(faceDownTypes) do

            _G['changeMode'..k] = function(obj,ply,alt) changeMode(obj,ply,alt,k) end
        end
	end
end



function toggleFaceDown(obj)
	enc = Global.getVar('Encoder')
	if enc ~= nil then
    
        data = enc.call("APIobjGetPropData",{obj=obj,propID=pID})
	
		--flip=enc.call("APIgetFlip",{obj=obj})
        flip=obj.is_face_down
        encoderFlip = enc.call("APIgetFlip",{obj=obj})
    
		enc.call("APItoggleProperty",{obj=obj,propID=pID})
		if enc.call("APIobjIsPropEnabled",{obj=obj,propID=pID}) then
        
            data.subMenuOpen = true
            checkConflictingMenus(obj)
        
            if not flip then --flip the card over
                obj.flip()
            end
            
            if encoderFlip>0 then
                enc.call("APIFlip",{obj=obj})
            end
            
            
            data.cardName = obj.getName()
            data.cardDesc = obj.getDescription()

            
            setCardDetails(obj, data, true)
        
		else
        
            if flip then
                obj.flip()
            end
            
            if encoderFlip<0 then
                enc.call("APIFlip",{obj=obj})
            end
        

            data['activeMode'] = "mtg_faceDownCreature"
            setCardDetails(obj, data, false)
            
		end
        
        enc.call("APIobjSetPropData",{obj=obj,propID=pID,data=data})
		enc.call("APIrebuildButtons",{obj=obj})
	end
end


function openSubMenu(obj,ply)
    checkConflictingMenus(obj)
    
	enc.call("APIobjSetValueData",{obj=obj,valueID='subMenuOpen',data={subMenuOpen=true}})
	enc.call("APIrebuildButtons",{obj=obj})
end

function closeSubMenu(obj)
	enc.call("APIobjSetValueData",{obj=obj,valueID='subMenuOpen',data={subMenuOpen=false}})
	enc.call("APIrebuildButtons",{obj=obj})
end


function createButtons(t)
	enc = Global.getVar('Encoder')

	if enc ~= nil then

		local data = enc.call("APIobjGetPropData",{obj=t.obj,propID=pID})
		local flip = enc.call("APIgetFlip",{obj=t.obj})
        local subMenuOpen = data['subMenuOpen']
        activeMode = data['activeMode']
        
        
		if not subMenuOpen then
            
			t.obj.createButton({
			label="[b]>>>[/b]", click_function='openSubMenu', function_owner=self,
			position={0.875*flip,0.28*flip,1.485}, scale={0.5,1,0.3}, height=0, width=0, font_size=200,
			rotation={0,0,90-90*flip},color={0,0,0,0},font_color={0,0,0,50},
			})
			t.obj.createButton({
			label=">>>", click_function='openSubMenu', function_owner=self,
			position={0.875*flip,0.28*flip,1.485}, scale={0.5,1,0.3}, height=350, width=450, font_size=200,
			rotation={0,0,90-90*flip},color={0,0,0,0},font_color={1,1,1,50},hover_color={0.1,0.1,0.1,1/50},tooltip="Morphin' Menu",
			})

		else
        

			t.obj.createButton({
			label="<<<", click_function='closeSubMenu', function_owner=self,
			position={0.875*flip,0.28*flip,1.485}, scale={0.5,1,0.3}, height=350, width=450, font_size=200,
			rotation={0,0,90-90*flip},color={0.1,0.1,0.1,1},font_color={1,1,1,1},tooltip="Morphin' Menu",
			})
			
			local j = 1
            
            
            
            for key,dat in pairs(faceDownTypes) do --make the named buttons, colored white or yellow based on selection
    
                if activeMode == key then
                    t.obj.createButton({
                    label= dat.name, click_function='changeMode'..key, function_owner=self, scale={0.5,1,0.5}, height=200, width=1100, font_size=160,
                    position={1.7*flip,0.28*flip,(1.6-j*0.2)},
                    rotation={0,0,90-90*flip}, color={0.1,0.1,0.1,1}, font_color={1,1,0},tooltip=""
                    })
                else
                    t.obj.createButton({
                    label= dat.name, click_function='changeMode'..key, function_owner=self, scale={0.5,1,0.5}, height=200, width=1100, font_size=160,
                    position={1.7*flip,0.28*flip,(1.6-j*0.2)},
                    rotation={0,0,90-90*flip}, color={0.1,0.1,0.1,1}, font_color={1,1,1,0.75},tooltip=""
                    })
                end
                j=j+1
            end

		end   --end menu
        
        local activeModeName = faceDownTypes[activeMode].name

        
        buttonLabel = '< '..activeModeName..' >'
        buttonColor = {0.5, 0.5, 0.5, 1}
        
        if activeMode == "mtg_faceDownForest" then
            buttonColor = {0, 0.45, 0.25, 1} --custom color for the Forest token
        end
            
        
        t.obj.createButton({
            label='',tooltip="[b]"..activeModeName.."[/b]\nTurn the card face up",
            click_function='toggleFaceDown', function_owner=self,
            position={0,-0.28,-1.29},rotation={0,0,180},
            scale={0.4,0.4,0.4}, height=251, width=2320, font_size=190,
            color=buttonColor, font_color={1,1,1,1},
        })
        t.obj.createButton({
            label=buttonLabel,tooltip="[b]"..activeModeName.."[/b]\nTurn the card face up",
            click_function='toggleFaceDown', function_owner=self,
            position={0,-0.28,-1.29},rotation={0,0,180},
            scale={0.4,0.4,0.4}, height=0, width=0, font_size=190,
            color=buttonColor, font_color={1,1,1,1},
        })
        
	end   --end if enc
end   --end 


function changeMode(obj,_ply,_alt,key)
    

    enc = Global.getVar('Encoder')
    if enc ~= nil then
        local data = enc.call("APIobjGetPropData",{obj=obj,propID=pID})
        
        if data['activeMode'] ~= key then
            data['activeMode'] = key
        
            enc.call("APIobjSetPropData",{obj=obj,propID=pID,data=data})
            enc.call("APIrebuildButtons",{obj=obj})
        end
        
        setCardDetails(obj, data, true)
        closeSubMenu(obj)
        
    end
    
end

function setCardDetails(obj, data, isFlipped)

    enc = Global.getVar('Encoder')
    
    if enc ~= nil then
        
        local decals = obj.getDecals() --reset the decals
        if decals ~= nil then
            for k,v in pairs(decals) do
                for ke,va in pairs(faceDownTypes) do
                    if v.name == ke then
                        table.remove(decals, k)
                    end
                end
            end
            
            obj.setDecals(decals)
        end
        
        if (isFlipped) then --what side is it on
        
            activeMode = data['activeMode']
            modeData = faceDownTypes[activeMode]
            
            obj.setName(modeData.cardName)
            obj.setDescription(modeData.cardDesc)
            
            obj.addDecal({name=activeMode,url=modeData.url,position={0,-0.28,0},rotation={-90,0,0},scale={2.15,3.05,1}})
            
        
        else
            obj.setName(data.cardName)
            obj.setDescription(data.cardDesc)
        end 
        
        local tData=enc.call("APIobjGetValueData",{obj=obj,valueID='tyrantUnified'})
        if tData ~= nil and tData.tyrantUnified~=nil then
            tData.tyrantUnified.hasParsed=false
            enc.call("APIobjSetValueData",{obj=obj,valueID='tyrantUnified',data=tData})
        end
        
        
    end
end

function addContextOptions(obj)

    if obj.type=='Card' then

        Wait.frames(function()        -- wait 1 frame to allow Global's context menu reset to take place first

            enc = Global.getVar('Encoder')
            if enc ~= nil then
                
                local cardDesc=obj.getDescription():lower()

                if enc.call("APIobjIsPropEnabled",{obj=obj,propID=pID}) then --if morphin time is activated, check card names instead
                    
                    obj.addContextMenuItem("Flip Over", contextGenericFlipUp)
                    
                    return --don't add any other flip context options once this one is added, skips unneeded string searching
                end
                
                if cardDesc:find('morph') and cardDesc:find('morph {') or cardDesc:find('morph—') then
                    obj.addContextMenuItem('Morph',contextMorph)
                end
          
                if cardDesc:find('disguise') and cardDesc:find('disguise {') or cardDesc:find('disguise—') then
                    obj.addContextMenuItem('Disguise',contextDisguise)
                end
                
            end
      
            
      

        end,1)
    
    end
  
end

function contextMorph(ply, objPos, obj)
    genericFlip({obj, "mtg_faceDownMorph"})
end

function contextDisguise(ply, objPos, obj)
    genericFlip({obj, "mtg_faceDownDisguise"})
end

function genericFlip(params) -- params is a table (obj, mode)
    obj = params[1]
    mode = params[2]
    if enc ~= nil then
        enc.call("APIencodeObject",{obj=obj})
        local data = enc.call("APIobjGetPropData",{obj=obj,propID=pID})
        data['activeMode'] = mode
        enc.call("APIobjSetPropData",{obj=obj,propID=pID,data=data})
        toggleFaceDown(obj)
        closeSubMenu(obj)
    end
end

function contextGenericFlipUp(ply, objPos, obj)
    genericFlipUp(obj)
end

function genericFlipUp(obj)
    toggleFaceDown(obj)
end

function genericChangeMode(params) --params is a table (obj, mode)
    changeMode(params[1], nil, nil, params[2])
end



function checkConflictingMenus(obj)
    enc = Global.getVar('Encoder')
    if enc ~= nil then
        keywordsData = enc.call("APIobjGetPropData",{obj=obj,propID="πKeywords"})
        if keywordsData ~= nil then
            if keywordsData['iconMenuOn'] then
                keywordsData['iconMenuOn'] = false
                enc.call("APIobjSetPropData",{obj=obj,propID="πKeywords",data=keywordsData})
            end
        end
    end
end