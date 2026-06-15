--[[πMenu
all props on one side
<<< open menu button along the top edge of card
]]

--[[Basic Menu
by Tipsy Hobbit//STEAM_0:1:13465982
The basic menu style, default for the encoder.
If no menu has been registered, then the encoder will spawn this from the github.
]]
pID="πMenu"
version = '3.14159'

-- Amaranth charWidth table ripped from https://gist.github.com/tjakubo2/7b6248e765163ffcf9963ab1f59f3e18
charWidth = {
        ['`'] = 2381, ['~'] = 2381, ['1'] = 1724, ['!'] = 1493, ['2'] = 2381,
        ['@'] = 4348, ['3'] = 2381, ['#'] = 3030, ['4'] = 2564, ['$'] = 2381,
        ['5'] = 2381, ['%'] = 3846, ['6'] = 2564, ['^'] = 2564, ['7'] = 2174,
        ['&'] = 2777, ['8'] = 2564, ['*'] = 2174, ['9'] = 2564, ['('] = 1724,
        ['0'] = 2564, [')'] = 1724, ['-'] = 1724, ['_'] = 2381, ['='] = 2381,
        ['+'] = 2381, ['q'] = 2564, ['Q'] = 3226, ['w'] = 3704, ['W'] = 4167,
        ['e'] = 2174, ['E'] = 2381, ['r'] = 1724, ['R'] = 2777, ['t'] = 1724,
        ['T'] = 2381, ['y'] = 2564, ['Y'] = 2564, ['u'] = 2564, ['U'] = 3030,
        ['i'] = 1282, ['I'] = 1282, ['o'] = 2381, ['O'] = 3226, ['p'] = 2564,
        ['P'] = 2564, ['['] = 1724, ['{'] = 1724, [']'] = 1724, ['}'] = 1724,
        ['|'] = 1493, ['\\']= 1923, ['a'] = 2564, ['A'] = 2777, ['s'] = 1923,
        ['S'] = 2381, ['d'] = 2564, ['D'] = 3030, ['f'] = 1724, ['F'] = 2381,
        ['g'] = 2564, ['G'] = 2777, ['h'] = 2564, ['H'] = 3030, ['j'] = 1075,
        ['J'] = 1282, ['k'] = 2381, ['K'] = 2777, ['l'] = 1282, ['L'] = 2174,
        [';'] = 1282, [':'] = 1282, ['\''] = 855, ['"'] = 1724, ['z'] = 1923,
        ['Z'] = 2564, ['x'] = 2381, ['X'] = 2777, ['c'] = 1923, ['C'] = 2564,
        ['v'] = 2564, ['V'] = 2777, ['b'] = 2564, ['B'] = 2564, ['n'] = 2564,
        ['N'] = 3226, ['m'] = 3846, ['M'] = 3846, [','] = 1282, ['<'] = 2174,
        ['.'] = 1282, ['>'] = 2174, ['/'] = 1923, ['?'] = 2174, [' '] = 1282,
        ['avg'] = 2500
    }
-- Get real string width as per char table
function GetStringWidth(str)
    local len = 0
    for i = 1, #str do
        local c = str:sub(i,i)
        len = len + (charWidth[c] or charWidth.avg)
    end
    return len
end

-- spent an hour trying to find the pattern to go from len to correct button width
-- it changes with scale...
scales = { 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1}
scaleR = {6143,4730,4730,4725,4760,4740,4784,4856,4685,4623}
-- ^^^ WHAT THE HELL IS THE PATTERN HERE?! no pattern, kinda messed up? ^^^
scaleI = 5
xScale=scales[scaleI]
getWidthOffset = function(str,align,fSize,xScale)
  local width  = GetStringWidth(str)/scaleR[scaleI]*fSize+100/scales[scaleI]
  local offset = width*xScale*align/2/480.8
  return width,offset
end

function onload()
  Wait.condition(registerModule,function() return Global.getVar('Encoder') ~= nil and true or false end)
  self.createButton({
    click_function='registerModule', function_owner=self, label='[i]'..pID..'[/i]', tooltip='register '..pID,
    position={0,0.1,0}, rotation={0,0,0}, scale={0.5,1,0.5},
    height=250, width=600, font_size=150,  color={0.1,0.1,0.1,1}, font_color={1,1,1,1},
  })
end

function registerModule()
  enc = Global.getVar('Encoder')
  if enc ~= nil then
    menu={
      menuID=pID,
      funcOwner=self,
      activateFunc='createMenu',
      visible_in_hand=1
    }
    enc.call("APIregisterMenu",menu)

    Style = {}
    Style.proto = {
      scale={xScale,1,xScale},
      height=1200*0.1/xScale,
      font_size=1000*0.1/xScale,
      color={0.1,0.1,0.1,1},
      font_color={1,1,1,1}
    }

    Style.mt = {}
    Style.mt.__index = Style.proto
    function Style.new(o)
      for k,v in pairs(Style.proto) do
        if o[k] == nil then
          o[k] = v
        end
      end
      return o
    end
  end
end

function createMenu(t)

  if Style==nil then
    registerModule()
  end

  local o = t.obj
  enc = Global.getVar('Encoder')
  if enc ~= nil then
    local flip = enc.call("APIgetFlip",{obj=o})
    local scaler = {x=1,y=1,z=1}--o.getScale()
    local zpos =  0.3*flip
    local xpos = -1.1*flip
    local props = enc.call("APIgetPropsList")   -- get ALL props
    md = enc.call("APIobjGetMenuData",{obj=o,menuID=pID})
    if md.open == false then

      o.createButton(Style.new{     -- black text background for cards with white borders
      label="[b]<<<[/b]", click_function='toggleMenu', function_owner=self,
      position={-0.875*flip,zpos,-1.485}, scale={0.5,1,0.3}, height=0, width=0, font_size=200,
      rotation={0,0,90-90*flip},color={0,0,0,0},font_color={0,0,0,50}
      })
      o.createButton(Style.new{     -- white text menu button
      label="<<<", click_function='toggleMenu', function_owner=self,
      position={-0.875*flip,zpos,-1.485}, scale={0.5,1,0.3}, height=350, width=450, font_size=200,
      rotation={0,0,90-90*flip},color={0.1,0.1,0.1,0},font_color={1,1,1,50},hover_color={0.1,0.1,0.1,1/50},tooltip="Open Menu"
      })

    else

      o.createButton(Style.new{
      label=">>>", click_function='toggleMenu', function_owner=self,
      position={-0.875*flip,zpos,-1.485}, scale={0.5,1,0.3}, height=350, width=450, font_size=200,
      rotation={0,0,90-90*flip},color={0.1,0.1,0.1,1},font_color={1,1,1,1},tooltip="Close Menu"
      })

      local propOrder = {}
      local propOrder = {   -- force a specific menu order by using the first 2 letters of the props name
        ['co']=0,     -- notepad
        ['no']=1,
        ['ke']=2,     -- keywords
        ['ca']=3,     -- card importer
        ['mt']=4.5,   -- mtg colors
        ['ph']=5.5,   -- phasing
        ['is']=6.5,   -- is token
        ['ma']=7.5,     -- manifest
        ['mo']=8.5,     -- morph
      }

      onProps=enc.call("APIobjGetProps",{obj=o})

      local nOrder = 0
      for i,v in pairs(propOrder) do
        if v+1>nOrder then nOrder=v+1 end
      end
      local count = 0
      local pos = 0
      for h,j in pairs(props) do
        v = enc.call("APIgetProp",{propID=h})
        if v.funcOwner ~= nil and v.visible ~= false then

          if onProps[h]==true then
            fColor={1,1,0}
          else
            fColor={1,1,1,0.75}
          end

          propName = v.name
          propName_repPi = propName:gsub('%[sup%]%[i%]π%[/i%]%[/sup%]','p') -- replace my π with p
          width,xOffset = getWidthOffset(propName_repPi,-1,Style.proto.font_size,Style.proto.scale[1])

          t2 = propName:sub(1,2):lower()  -- force a specific menu order by using the first 2 letters of the props name
          pos = propOrder[t2]
          if pos==nil then pos=nOrder+count; count=count+1 end

          o.createButton(Style.new{
          label=propName, click_function=v.activateFunc, function_owner=v.funcOwner,
          position={xpos+xOffset*flip,zpos,-1.4+pos*0.25}, rotation={0,0,90-90*flip}, width=width,
          font_color=fColor
          })

        end
      end

      if nOrder+count<10 then count=10-nOrder end -- if small amount of props, keep flip menu and disable encoding at the bottom of card

      propName = "Flip Menu"
      width,xOffset = getWidthOffset(propName,-1,Style.proto.font_size,Style.proto.scale[1])
      pos=nOrder+count; count=count+1
      o.createButton(Style.new{
      label=propName, click_function='piFlipMenu', function_owner=self, font_color={1,1,1,0.75},
      position={xpos+xOffset*flip,zpos,-1.35+pos*0.25}, rotation={0,0,90-90*flip}, width=width
      })

      propName = "Disable Encoding"
      width,xOffset = getWidthOffset(propName,-1,Style.proto.font_size,Style.proto.scale[1])
      pos=nOrder+count; count=count+1
      o.createButton(Style.new{
      label=propName, click_function='disableEncoding', function_owner=enc, font_color={1,0,0,1},
      position={xpos+xOffset*flip,zpos,-1.35+pos*0.25}, rotation={0,0,90-90*flip}, width=width
      })

    end
  end
end

function piFlipMenu(o)    -- also flips the object
  enc = Global.getVar('Encoder')
  if enc then
    enc.call('APIFlip',{obj=o})
    o.flip()
  end
end

function toggleMenu(o)
  enc = Global.getVar('Encoder')
  if enc ~= nil then
    enc.call("APIobjToggleMenu",{obj=o,menuID=pID})
    enc.call("APIrebuildButtons",{obj=o})
  end
end