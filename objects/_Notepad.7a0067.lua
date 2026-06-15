-- this thingy has been modified by �� for his table
-- if you take it and try to use it AS-IS it might not work and break other stuff on your table
-- get the vanilla version from the original un-modified mod here, by Tipsy Hobbit:
-- https://steamcommunity.com/sharedfiles/filedetails/?id=828894732
-- if you do take my modified version, please let me know
-- just in case, I might have it set to non-interactable to filter out folks who can't script at all

--Notepad
--by Tipsy Hobbit//STEAM_0:1:13465982
--redesigned by pie

pID = "πotepad"
version = 3.14159

function onload()
  self.createButton({
    click_function='registerModule', function_owner=self, label='[i]'..pID..'[/i]', tooltip='register '..pID,
    position={0,0.1,0}, rotation={0,0,0}, scale={0.5,1,0.5},
    height=250, width=700, font_size=150,  color={0.1,0.1,0.1,1}, font_color={1,1,1,1},
  })

  Wait.condition(registerModule,function() return Global.getVar('Encoder') ~= nil and true or false end)
end

function registerModule()
  enc = Global.getVar('Encoder')
  if enc ~= nil then
		properties = {
		propID = pID,
		name = "Notepad[sup][i]π[/i][/sup]",
		values = {'note'},
    funcOwner = self,
		tags='tool',
		activateFunc ='toggleProp',
    visible_in_hand=1
		}
		enc.call("APIregisterProperty",properties)
    value = {
    valueID = 'note',
    validType = nil,
    desc = "Write whatever you want onto the card",
    default = {text='',editON=true}
    }
    enc.call("APIregisterValue",value)
  end
end

function toggleProp(obj,ply)
  enc.call("APItoggleProperty",{obj=obj,propID=pID})
  enc.call("APIrebuildButtons",{obj=obj})
end

function createButtons(t)
  enc = Global.getVar('Encoder')
  if enc ~= nil then
    flip = enc.call("APIgetFlip",{obj=t.obj})
		data = enc.call("APIobjGetPropData",{obj=t.obj,propID=pID})

    if data.note.editON then
      ttip = 'Lock Text'
    else
      ttip = 'Unlock Text'
    end
    t.obj.createButton({
      click_function='toggleEdit',
      function_owner=self,
      label='',
      position={0.835*flip,0.28*flip,0.275},
      scale={0.4,1,0.4},
      width=1250/4,
      height=950/4,
      font_size=850/4,
      color={0.1,0.1,0.1},
      font_color={1,1,1},
      tooltip=ttip
    })

    if data.note.editON then

      t.obj.createButton({      -- toggleEdit button
        click_function='toggleEdit',
        function_owner=self,
        label='✏',
        position={0.840*flip,0.28*flip,0.27},
        scale={0.4,1,0.3},
        rotation={0,225,0},
        width=0,
        height=0,
        font_size=850/4,
        color={0.1,0.1,0.1},
        font_color={1,1,1},
      })

      t.obj.createInput({      -- text input field
        label="\n\n\n\nenter text here",
        input_function='editText',
        function_owner=self,
        alignment=3,
        value=data.note.text,
        validation=1,
        tab=3,
        position={0,0.28*flip,-0.51},
        rotation={0,0,90-90*flip},
        scale={0.5,0,0.5},
        height=1320,
        width=1770,
        font_size=140,
        color={0.1,0.1,0.1,0.9},
        font_color={1,1,1,1/0.9},
      })

    else

      bLabel = insertBreaks(data.note.text)

      t.obj.createButton({      -- unclickable background
        click_function='null',
        function_owner=self,
        label='',
        position={0,0.28*flip,-0.51},
        rotation={0,0,270-90*flip},
        scale={0.1,0,0.1},
        height=1330*5,
        width=1780*5,
        font_size=140*5,
        color={0.1,0.1,0.1,0.9},
        font_color={1,1,1,1/0.9},
      })

      t.obj.createButton({      -- the text
        click_function='null',
        function_owner=self,
        label=bLabel,
        position={0,0.28*flip,-0.538},  -- button needs a small shift relative to input field
        rotation={0,0,90-90*flip},
        scale={0.5,0,0.5},
        height=0,
        width=0,
        font_size=140,
        color={0.1,0.1,0.1,0.9},
        font_color={1,1,1,1/0.9},
      })

      t.obj.createButton({      -- toggleEdit button
        click_function='toggleEdit',
        function_owner=self,
        label='✉',
        position={0.835*flip,0.28*flip,0.295},
        scale={0.4,1,0.4},
        width=0,
        height=0,
        font_size=850/4,
        color={0.1,0.1,0.1},
        font_color={1,1,1}
      })

    end

  end
end

function toggleEdit(obj,ply)
  data = enc.call("APIobjGetPropData",{obj=obj,propID=pID})
  data.note.editON = not data.note.editON
  enc.call("APIobjSetPropData",{obj=obj,propID=pID,data=data})
  enc.call("APIrebuildButtons",{obj=obj})
end

function editText(obj,ply,val,sel)
	if sel == false then
		enc = Global.getVar('Encoder')
		if enc ~= nil then
			data = enc.call("APIobjGetPropData",{obj=obj,propID=pID})
			data.note.text = val
			enc.call("APIobjSetPropData",{obj=obj,propID=pID,data=data})
		end
	else
		log(val,"input_text", "Notepad"..obj.getGUID())
	end
end

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
function findStringLength(str)
    local len = 0
    local k=0
    for i = 1, #str do
        local c = str:sub(i,i)
        len = len + (charWidth[c] or charWidth.avg)
    end
    return len
end

--------------------------------------------------------------------------------
-- Over-engineered method to convert input string to button string
-- inserting line-breaks whenever the width of a line exceeds the box
maxWidth=59837    -- found by trial and error
maxNlines=9
function insertBreaks(str)

  -- first, split the str by any existing line-breaks
  local strTable={}
  local brInd=nil
  while str:find('\n') do
    brInd=str:find('\n')
    table.insert(strTable,str:sub(1,brInd))
    str=str:sub(brInd+1,-1)
  end
  table.insert(strTable,str)

  -- split each string further by maxWidth
  local strTable2={}
  local nLines = 0
  for _,str in ipairs(strTable) do

    str=str:gsub('[\n]','')    -- remove \n, it'll get reinserted with table.concat

    local len = 0
    local stInd = 1
    local enInd = nil
    local parsing = true
    local i=0

    while parsing do

      i=i+1
      local c = str:sub(i,i)
      if c==' ' then enInd=i end  -- save last encoutered space ind
      prevLen = len
      len = len + (charWidth[c] or charWidth.avg)

      if i>=#str and len<=maxWidth then   -- reached the end of string
        local snip=str:sub(stInd,i)
        table.insert(strTable2,snip)
        nLines=nLines+1
        parsing = false
        break
      end

      if len>maxWidth then   -- maxWidth reached
        if enInd then        -- a space was found
          local snip = str:sub(stInd,enInd-1)
          table.insert(strTable2,snip)
          nLines=nLines+1
          len=0
          stInd=enInd+1
          i=enInd
          enInd=nil
        else                 -- a long sequence of characters without space
          local snip = str:sub(stInd,i-1)
          table.insert(strTable2,snip)
          nLines=nLines+1
          len=0
          stInd=i
          i=i-1
          enInd=nil
        end

        if i>=#str then
          parsing = false
        end

      end

      if nLines>maxNlines then    -- max number of lines reached
        parsing=false
      end

    end
  end

  while nLines<maxNlines do       -- fill up the rest of the lines
    nLines=nLines+1
    table.insert(strTable2,' ')
  end

  return table.concat(strTable2,'\n')

end
--------------------------------------------------------------------------------


function null()
end