--By Amuzet /adapted by π
mod_name='Deck Lister'
version='π'

function onLoad()
  local txt = '[b]Instructions to re-import your deck:[/b]\n'..
               '1. Place your deck here\n'..
               '2. Press the button below\n'..
               '3. Type [b]scryfall deck[/b] into chat and the deck will spawn at your mouse cursor'

  self.setDescription(txt)
  self.setName(mod_name)

  sScale=self.getScale()

  bpars={ click_function='click',
          function_owner=self,
          label='Place Deck',
          position={0,0.5,0.65},
          scale={0.5/sScale[1],0.5/sScale[2],0.5/sScale[3]},
          color={0.1,0.1,0.1},
          font_color={1,1,1},
          width=3500,
          height=750,
          font_size=500,
          tooltip='' }
  self.createButton(bpars)

  bpars={ click_function='click',
          function_owner=self,
          label='Deck\nLister',
          position={0,0.5,0},
          scale={0.5/sScale[1],0.5/sScale[2],0.5/sScale[3]},
          color={0.1,0.1,0.1,1},
          font_color={1,1,1,1},
          width=0,
          height=0,
          font_size=600,
          tooltip='' }
  self.createButton(bpars)

end

function lister(obj,pColor)
  local pc = pColor

  if obj and obj.type=='Deck' then

    local list = ''
    for _,v in pairs(obj.getObjects())do
      local name = v.nickname:gsub('[\n].*','')
      list = list..'1 '..name..'\n'
    end

    -- remove any existing tabs corresponding to player color
    local proceed=false
    local tabs = getNotebookTabs()
    for i,tab in pairs(tabs) do
      if tab.color==pColor then
        removeNotebookTab(tab.index)
      end
      if i==#tabs then
        proceed=true
      end
    end

    -- once all existing player notebook tabs are removed, create a new one, containing the deck list
    -- (this way both Amuzet's and Omes importers direct to this notebook tab)
    Wait.condition(function()
      Wait.time(function()
        addNotebookTab({title=pColor , body=list , color=pColor})
        Player[pc].broadcast('Deck list in Notebook Tab: '..pColor..'\n'..
                             'Type [b][i]scryfall deck[/i][/b] into chat to re-import deck')
      end,0.2)
    end,function() return proceed end)

  end
end

function click(o,pc,a)
  if getObjectFromGUID(self.getGMNotes())~=nil then
    lister(getObjectFromGUID(self.getGMNotes()),pc)
  end
end

function onCollisionEnter(info)
  if info and info.collision_object.type=='Deck' then
    local g = info.collision_object.getGUID()
    self.setGMNotes(g)
    self.editButton({
      index=0,
      label='Get Card List'
    })
  end
end

function onCollisionExit(info)
  if info and info.collision_object.type=='Deck' then
    self.setGMNotes('')
    self.editButton({
      index=0,
      label='Place Deck'
    })
  end
end