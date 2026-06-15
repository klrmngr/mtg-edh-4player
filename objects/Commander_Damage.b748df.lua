MIN_VALUE = 0
MAX_VALUE = 21
function onload(saved_data)
  self.interactable = true
  val = 0
  if saved_data ~= "" then
    local loaded_data = JSON.decode(saved_data)
    val = loaded_data[1]
  end
  colStr=self.getDescription()
  self.setColorTint(Color.fromString(colStr))
  createAll()
end

function updateSave()
  local data_to_save = {val}
  saved_data = JSON.encode(data_to_save)
  self.script_state = saved_data
end

function createAll()
    s_color = {0.1, 0.1, 0.1, 95}
    f_color = {1,1,1,100}

    if tooltip_show then
        ttText = "     " .. val .. "\n" .. self.getName()
    else
        ttText = self.getName()
    end

    self.createButton({
      label='[R]',
      tooltip='Reset',
      click_function="reset_val",
      function_owner=self,
      position={0-0.04,0.05,1.3+0.04},
      rotation={0,0,0},
      height=0,
      width=0,
      scale={x=0.5, y=0.5, z=0.5},
      font_size=600,
      font_color=s_color,
      color={0,0,0,0}
    })

    for i=-1,1 do
      for j=-1,1 do
        self.createButton({
          label='[R]',
          tooltip='Reset',
          click_function="reset_val",
          function_owner=self,
          position={0+i*0.025,0.1,1.3+j*0.025},
          rotation={0,0,0},
          height=0,
          width=0,
          scale={x=0.5, y=0.5, z=0.5},
          font_size=600,
          font_color={0,0,0,100},
          color={0,0,0,0}
        })
      end
    end

    self.createButton({
      label='[R]',
      tooltip='Reset',
      click_function="reset_val",
      function_owner=self,
      position={0,0.1,1.3},
      rotation={0,0,0},
      height=400,
      width=600,
      scale={x=0.5, y=0.5, z=0.5},
      font_size=600,
      font_color=f_color,
      color={0,0,0,0}
    })

  	self.createButton({
      label=tostring(val),
      click_function="null",
      tooltip=ttText,
      function_owner=self,
      position={0-0.1,0.05,0+0.1},
      height=0,
      width=0,
      scale={1.65, 1.65, 1.65},
      font_size=800,
      font_color=s_color,
      color={0,0,0,0}
      })

    for i=-1,1 do
      for j=-1,1 do
        self.createButton({
          label=tostring(val),
          click_function="null",
          tooltip=ttText,
          function_owner=self,
          position={0+i*0.1,0.18,0+j*0.1},
          height=0,
          width= 0,
          scale={1.65, 1.65, 1.65},
          font_size=800,
          font_color={0,0,0,100},
          color={0,0,0,0}
          })
      end
    end

    self.createButton({
      label=tostring(val),
      click_function="add_subtract",
      tooltip=ttText,
      function_owner=self,
      position={0,0.18,0},
      height=500,
      width= 500,
      scale={1.65, 1.65, 1.65},
      font_size=800,
      font_color=f_color,
      color={0,0,0,0}
      })
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

  for ind=11,21 do
    self.editButton({
      index = ind,
      label = tostring(val),
      tooltip = ttText
    })
  end
end

function onChat(msg)
  if msg:lower()=='reset life 40' then
    val=0
    updateVal()
    updateSave()
  end
end

function reset_val()
  val = 0
  updateVal()
  updateSave()
  self.reload()
end

self.max_typed_number=99
function onNumberTyped(col,int)
  val = int
  updateVal()
  updateSave()
end

function null()
end