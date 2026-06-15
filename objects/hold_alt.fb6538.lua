function onLoad()
  self.setColorTint({0,0,0,0})
  self.interactable=false
  self.createButton({
      click_function='nothing',
      function_owner=self,
      label='hold [Alt] to view these panels easier',
      position={0,2,0},
      scale={2,2,2},
      width=0,
      height=0,
      font_size=1000,
      font_color={1,1,1,0.5}
  })
end
function nothing() end