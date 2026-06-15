function onload()

  chatInstr = getObjectFromGUID('7b59f7')
  altButton = getObjectFromGUID('fb6538')
  self.interactable = true
  chatInstr.interactable = true

  self.createButton({
    label='×',
    click_function="closeSelf",
    tooltip='[i]remove clutter[/i]:\ndelete room background and a lot of the clutter on the table',
    function_owner=self,
    position={0.97,0.1,-0.8},
    height=500,
    width=500,
    scale={0.3,0.3,0.3},
    font_size=1000,
    font_color={1,1,1,2},
    color={1,1,1,0.05}
  })

end

function closeSelf(obj,ply)

  unnecessaryStuff={"fc40c8","b7ccfb","633ed3","de6cde","9cf532","32f398","e7428d",
  "1a20bf","9360fc","0a79c7","792837","163a5f","63bc71","e0d9cc","917dc3","f62d00",
  "82e64d","0cebc6","59d2ee","080e23","d658b5","cbcbea","fcd8d9","c3ca32","b8b9ed",
  "c36338","721b69","8764e9","28297f","b41ace","220d2f","1c4a59","aeeb11","2e1ed6",
  "e2c813","d9bd81","7eeb77","195243","d82eb8","64d53e","005d07","c1840d","e3ecb3",
  "023349","cdbccc","69ab89","4783af","721688","444725","f209f9","895bd9","ae70ca",
  "f378f1","6c1ede","cd8bb6","bfceec","e6f47f","c99d05","5ca969","6d46cd","6ed442",
  "1d701a","5c471e","544ef3","d471e5","3ef9ac","7746f9","d0cca5","14da25","979e78",
  "eab63d","e86d81","2d87b2","b35666","feadfa","243420","1e573a","71d33b","bc8aef",
  "f082df","9f82de","372113","47f1ce","b9f545","7edac2","673bac","098c38","c5addf",
  "123asd","05b07c","8dad82","4bf968","6d07c3","5006a4","7cf430"}

  moveThese={"b3961f","3cba4d","576ccd","94b67a","5035f1","da1b48","29d31b","beb998",
  "56a44e","855d09","7ae211","daebb2","b991d5","887dd2","52e44b","389c4d","e76686",
  "b02684","f07e80","0beb07","4256ba","1f2263","8c31d2","7071ce","3c7ad3"}

  -- if ply=='Black' then

    for _,guid in pairs({'cb1610', 'a7a029', '4c02f8', 'a3e6a8', '9c553c', 'eb479b'}) do
      pcall(function() getObjectFromGUID(guid).destruct() end)
    end

    for _,guid in pairs(unnecessaryStuff) do
      pcall(function() getObjectFromGUID(guid).destruct() end)
    end

    for _,guid in pairs(moveThese) do
      pos=getObjectFromGUID(guid).getPosition()
      pos[1]=pos[1]-3
      getObjectFromGUID(guid).setPosition(pos)
    end

  -- end

  altButton.destruct()
  chatInstr.destruct()
  Wait.frames(function() self.destruct() end, 1)
end