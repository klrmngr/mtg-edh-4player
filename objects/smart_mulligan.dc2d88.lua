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

function mullSwitch(obj,ply)
  if Player[ply].steam_id=='76561197968157267' then
    smartMulligan=Global.getVar('smartMulligan')
    if smartMulligan==nil then
      smartMulligan=false
    end
    smartMulligan=not(smartMulligan)
    Global.setVar('smartMulligan',smartMulligan)
    if smartMulligan then
      ttip='on'
      createButton()
    else
      ttip='off'
      createButton()
    end
    Player[ply].broadcast('smart mulligan is '..ttip)
  end
end