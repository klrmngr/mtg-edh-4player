function onLoad()
  data=Global.getTable('data')
  plys=Player.getAvailableColors()
  enc = Global.getVar('Encoder')
  noencode=true
  self.createButton({
    click_function='switchState',
    function_owner=self,
    label='switch to [b]night[/b]',
    position={0,0.28,-0.5},
    scale={0.5,0.5,0.5},
    width=1600,
    height=400,
    font_size=200,
    color={0,0,0,0.7},
    font_color={1,1,1,1/0.7}
  })
end

function switchState()
  self.setState(2)
end

function onStateChange()
  for _,ply in pairs(plys) do
    for _,card in pairs(data[ply].playmat.getObjects()) do
      if card~=self and card.getName()~='[b]Day[/b]' and card.type=='Card' and card.getDescription():lower():match('nightbound') then
        states=card.getStates()
        for _,state in pairs(states) do
          if state.description:lower():match('daybound') then
            card=card.setState(state.id)
            enc.call("APIencodeObject",{obj=card})
            enc.call("APIrebuildButtons",{obj=card})
            Wait.time(function() card.highlightOn({1,1,0.5},0.1) end,0.2,5)
          end
        end
      end
    end
  end
end