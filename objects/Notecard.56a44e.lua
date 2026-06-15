function onload()
  self.createButton({
      value = self.getName(),
      click_function = "null",
      label = "Notecard",
      function_owner = self,
      position = {0,0.05,0},
      width = 0,
      height = 0,
      font_size = 400,
      scale={x=1, y=1, z=1},
      font_color= {0.9,0.9,0.9,100},
      color = {0,0,0,0},
      })
end

function null()
end