MIN_VALUE = 0
MAX_VALUE = 100

function onload()
  val = 0

  self.setColorTint({0,0,0,0})
  self.interactable = false
  pTime=os.time()

  colStr=self.getDescription():gsub('[ ].*','')
  col=Color.fromString(colStr)
  bcolor = col
  bcolor[4] = 100

  zcoord = -1.8
  bpars={
    label=tostring(val),
    click_function="add_subtract",
    function_owner=self,
    position={0,0.03,zcoord},
    scale={0.5,0.5,0.5},
    height=0,
    width=0,
    font_size=1000,
    font_color={0,0,0,100},
    color={0,0,0,0}
  }

  for i=-1,1 do
    for j=-1,1 do
      bpars.position={0+0.015*i,0.03,zcoord+0.015*j}
      self.createButton(bpars)
    end
  end

  bpars.position={0,0.03,zcoord}
  bpars.height=1000
  bpars.width=1000
  bpars.font_color=bcolor
  self.createButton(bpars)

end

-- -- reload commander cards such that deck reset does not shuffle them back in
-- function onCollisionEnter(co)
--   nTime=os.time()
--   if pTime==nil then pTime=0 end
--   if nTime-pTime<0.5 then return end    -- activate at most once per second
--   pTime=nTime
--
-- 	obj = co.collision_object
--   if obj.type ~= 'Card' then return end
--
--   objGUID = obj.getGUID()
--   savedGUIDs = Global.getTable('savedGUIDs')
--   if savedGUIDs == nil then
--     savedGUIDs={}
--     Global.setTable('savedGUIDs',savedGUIDs)
--   end
--   saved = false
--   for i,savedGUID in pairs(savedGUIDs) do
--     if objGUID == savedGUID then
--       saved = true
--     end
--   end
--
--   if not(saved) then
--     table.insert(savedGUIDs,objGUID)
--     Global.setTable('savedGUIDs',savedGUIDs)
--     obj=obj.reload()
--   end
-- end

function add_subtract(_obj, _color, alt_click)
  mod = alt_click and -2 or 2
  new_value = math.min(math.max(val + mod, MIN_VALUE), MAX_VALUE)
  if val ~= new_value then
    val = new_value
    for ind=0,9 do
      self.editButton({index = ind, label = tostring(val)})
    end
  end
end

function onChat(msg)
  if msg:lower()=='reset life 40' then
    val=0
    for ind=0,9 do
      self.editButton({index = ind, label = tostring(val)})
    end
  end
end