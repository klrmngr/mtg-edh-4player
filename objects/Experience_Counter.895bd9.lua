function onload(saved_data)

    f_color = {0.9,0.9,0.9,100}

  	self.createButton({
      label='0',
      click_function="null",
      function_owner=self,
      position={0-0.1,0.1,0.2+0.1},
      height=0,
      width=0,
      alignment = 3,
      scale={x=1.5, y=1.5, z=1.5},
      font_size=800,
      font_color={1-f_color[1],1-f_color[2],1-f_color[3],95},
      color={0,0,0,0}
      })

    self.createButton({
      label='0',
      click_function="null",
      function_owner=self,
      position={0,0.15,0.2},
      height=0,
      width= 0,
      alignment = 3,
      scale={x=1.5, y=1.5, z=1.5},
      font_size=800,
      font_color=f_color,
      color={0,0,0,0}
      })

end

function null()
end