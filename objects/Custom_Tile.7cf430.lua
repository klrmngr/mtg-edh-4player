function onLoad()
  link='https://steamcommunity.com/sharedfiles/filedetails/?id=2296042369',

  self.setName(link)
  self.setDescription(link)

  self.createButton({
    click_function='showLink',
    function_owner=self,
    position={0,0.1,0},
    width=10,
    height=10,
    scale={100,100,100},
    color={1,1,1,0},
    hover_color={1,1,1,0.25},
    tooltip='show link to this table\nin the steam workshop'
  })
end

function showLink()
  self.createInput({
    input_function='null',
    function_owner=self,
    label=link,
    position={0,1,-1.5},
    width=4200,
    height=170,
    font_size=140,
    scale={2,2,2},
    color={0.1,0.1,0.1},
    font_color={1,1,1},
    alignment=3,
    value=link,
    tooltip='ctrl-C'
  })

  self.clearButtons()

  self.createButton({
    click_function='hideLink',
    function_owner=self,
    position={0,0.1,0},
    width=10,
    height=10,
    scale={100,100,100},
    color={1,1,1,0},
    hover_color={1,1,1,0.25},
    tooltip='hide link'
  })

  wid=Wait.time(hideLink,10)
end

function hideLink()
  if wid then
    Wait.stop(wid)
  end

  self.clearInputs()
  self.clearButtons()
  self.createButton({
    click_function='showLink',
    function_owner=self,
    position={0,0.1,0},
    width=10,
    height=10,
    scale={100,100,100},
    color={1,1,1,0},
    hover_color={1,1,1,0.25},
    tooltip='show link to this table\nin the steam workshop'
  })
end

function null()
end