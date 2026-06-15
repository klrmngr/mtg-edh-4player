function onload(saved_data)
  f_color = {0.9,0.9,0.9,95}
  self.createButton({
    label='0',
    click_function='null',
    tooltip=ttText,
    function_owner=self,
    position={0,0.05,-0.5},
    height=0,
    width=0,
    alignment = 3,
    scale={x=1.5, y=1.5, z=1.5},
    font_size=900,
    font_color=f_color,
    color={0,0,0,0}
  })
  self.createButton({
    label = "Text",
    click_function='null',
    function_owner = self,
    position = {0,0.05,1},
    width = 0,
    height = 0,
    font_size = 350,
    scale={x=1, y=1, z=1},
    font_color= f_color,
    color = {0,0,0,0}
  })
end

function null()
end