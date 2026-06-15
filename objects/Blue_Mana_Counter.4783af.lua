MIN_VALUE = 0
MAX_VALUE = 99

function onload(saved_data)
  light_mode = true
  tooltip_show = false
  val = 0

  if saved_data ~= "" then
    local loaded_data = JSON.decode(saved_data)
    light_mode = loaded_data[1]
    val = loaded_data[2]
    tooltip_show = loaded_data[3]
  end

  createAll()
end

function updateSave()
  local data_to_save = {light_mode, val, tooltip_show}
  saved_data = JSON.encode(data_to_save)
  self.script_state = saved_data
end

function createAll()
    s_color = {0.5, 0.5, 0.5, 95}

    if light_mode then
        f_color = {0.9,0.9,0.9,100}
    else
        f_color = {0.1,0.1,0.1,100}
    end

    if tooltip_show then
        ttText = "     " .. val .. "\n" .. self.getName()
    else
        ttText = self.getName()
    end

	self.createButton({
    label=tostring(val),
    click_function="null",
    tooltip=ttText,
    function_owner=self,
    position={0-0.05,0.1,0.065+0.05},
    height=0,
    width=0,
    alignment = 3,
    scale={x=0.75, y=0.75, z=0.75},
    font_size=800,
    font_color={1-f_color[1],1-f_color[2],1-f_color[3],95},
    color={0,0,0,0}
    })

  self.createButton({
    label=tostring(val),
    click_function="add_subtract",
    tooltip=ttText,
    function_owner=self,
    position={0,0.15,0.065},
    height=10,
    width= 10,
    alignment = 3,
    scale={x=0.75, y=0.75, z=0.75},
    font_size=800,
    font_color=f_color,
    color={0,0,0,0}
    })

  lightButtonText = "swap text color"
  self.createButton({
    label=lightButtonText,
    tooltip='',
    click_function="swap_fcolor",
    function_owner=self,
    position={0,-0.075,-0.25},
    rotation={180,180,0},
    height=150,
    width=1200,
    scale={x=0.5, y=0.5, z=0.5},
    font_size=150,
    font_color=s_color,
    color={0,0,0,0}
  })


  self.createButton({
    label='reset',
    tooltip='',
    click_function="reset_val",
    function_owner=self,
    position={0,-0.075,0.25},
    rotation={180,180,0},
    height=250,
    width=1200,
    scale={x=0.5, y=0.5, z=0.5},
    font_size=250,
    font_color=s_color,
    color={0,0,0,0}
  })

  setTooltips()
end

function removeAll()
  self.removeButton(0)
  self.removeButton(1)
  self.removeButton(2)
  self.removeButton(3)
end

function reloadAll()
  removeAll()
  createAll()
  setTooltips()
  updateSave()
end

function swap_fcolor(_obj, _color, alt_click)
  light_mode = not light_mode
  reloadAll()
end

function swap_align(_obj, _color, alt_click)
  center_mode = not center_mode
  reloadAll()
end

function editName(_obj, _string, value)
  self.setName(value)
  setTooltips()
end

function add_subtract(_obj, _color, alt_click)
  mod = alt_click and -1 or 1
  new_value = math.min(math.max(val + mod, MIN_VALUE), MAX_VALUE)
  if val ~= new_value then
    val = new_value
    updateVal()
    updateSave()
  end
end

function updateVal()
  if tooltip_show then
    ttText = "     " .. val .. "\n" .. self.getName()
  else
    ttText = self.getName()
  end

  self.editButton({
    index = 0,
    label = tostring(val),
    tooltip = ttText
  })

  self.editButton({
  	index = 1,
  	label = tostring(val),
  	tooltip = ttText
	})

end

function reset_val()
  val = 0
  updateVal()
  updateSave()
end

function setTooltips()
  if tooltip_show then
    ttText = "     " .. val .. "\n" .. self.getName()
  else
    ttText = self.getName()
  end

  self.editButton({
    index = 0,
    value = tostring(val),
    tooltip = ttText
    })
end

function null()
end