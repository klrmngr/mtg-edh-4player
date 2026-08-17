function onLoad()
  self.interactable=false
  self.setColorTint({1,1,1,0})
  ttip='off'
  createButton()
end

function createButton()
  self.clearButtons()
  self.createButton({
    click_function='mullSwitch',
    function_owner=self,
    position={0,0.1,0},
    width=1000,
    height=1000,
    color={0,0,0,0},
    hover_color={0,0,0,0},
    tooltip=ttip
  })
end
