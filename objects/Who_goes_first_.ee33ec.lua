whoGoesFirstVersion = 3.14

function onLoad()
    whoGoesFirstNameSides()
end

function onPlayerChangeColor(col)
  pcall(function()
    whoGoesFirst()
  end)
end

function onPickedUp()
    pcall(function() whoGoesFirst() end)
end

function onObjectRandomize(obj)
    if obj == self then
        whoGoesFirst()
    end
end

function whoGoesFirst()
    pcall(function()
      local seated = ""
      local dietype = 1
      local colors = {"Red","Orange","Yellow","Green","Teal","Blue","Purple","Pink","Brown","White"}
      local shortc = {"r","o","y","g","t","b","p","i","n","w"}
      for k,color in pairs(colors) do
          if Player[color].seated then
              seated = seated .. shortc[k]
          end
      end

      if string.len(seated) > 0 then
          if string.len(seated) == 7 or string.len(seated) == 9 then
              seated = seated .. 'x'
          end

          if string.len(seated) == 1 or string.len(seated) == 2 or string.len(seated) == 3 or string.len(seated) == 6 then
              rep = math.floor(6/string.len(seated))
              dietype = 1
          elseif string.len(seated) == 4 or string.len(seated) == 7 or string.len(seated) == 8 then
              rep = math.floor(8/string.len(seated))
              dietype = 2
          elseif string.len(seated) == 5 or string.len(seated) == 9 or string.len(seated) == 10 then
              rep = math.floor(10/string.len(seated))
              dietype = 3
          end
          seated = string.rep(seated,rep)
      end

      local url = "0rganics.org/tts/wgf/2.php?v=" .. whoGoesFirstVersion .. "&c=" .. seated
      local arr = {image=url,type=dietype}
      local cur = self.getCustomObject()
      if cur.image != url then
          self.setCustomObject(arr)
          self.reload()
      else
          whoGoesFirstNameSides()
      end
    end)
end

function whoGoesFirstNameSides()
    local url = "0rganics.org/tts/wgf/2.php?v=" .. whoGoesFirstVersion .. "&c="
    local cur = self.getCustomObject()
    local rotvals = {}

    if cur.image != url then
        local colors = {"Red","Orange","Yellow","Green","Teal","Blue","Purple","Pink","Brown","White"}
        local shortc = {"r","o","y","g","t","b","p","i","n","w"}
        local c = string.sub(cur.image,string.len(url))
        local playersides = {}
        local k = 1

        if string.len(c) > 0 then
            while k <= string.len(c) do
                if string.sub(c,k,k) == "x" then
                    table.insert(playersides,"Roll again to see who")
                else
                    for i=1,10 do
            			if string.sub(c,k,k) == shortc[i] then
                            if Player[colors[i]].seated then
                                table.insert(playersides,Player[colors[i]].steam_name)
                            else
                                table.insert(playersides,colors[i])
                            end
            				break
            			end
            		end
                end
                k = k + 1
            end

            if cur.type == 1 then
                rotvals[1] = {value=playersides[1],rotation={-90,0,0}}
                rotvals[2] = {value=playersides[2],rotation={0,0,0}}
                rotvals[3] = {value=playersides[3],rotation={0,0,-90}}
                rotvals[4] = {value=playersides[4],rotation={0,0,90}}
                rotvals[5] = {value=playersides[5],rotation={0,0,-180}}
                rotvals[6] = {value=playersides[6],rotation={90,0,0}}
            elseif cur.type == 2 then
                rotvals[1] = {value=playersides[1],rotation={-33,0,90}}
                rotvals[2] = {value=playersides[2],rotation={-33,0,180}}
                rotvals[3] = {value=playersides[3],rotation={33,180,-180}}
                rotvals[4] = {value=playersides[4],rotation={33,180,90}}
                rotvals[5] = {value=playersides[5],rotation={33,180,-90}}
                rotvals[6] = {value=playersides[6],rotation={33,180,0}}
                rotvals[7] = {value=playersides[7],rotation={-33,0,0}}
                rotvals[8] = {value=playersides[8],rotation={-33,0,-90}}
            elseif cur.type == 3 then
                rotvals[1] = {value=playersides[1],rotation={-38,180,234}}
                rotvals[2] = {value=playersides[2],rotation={38,180,-233}}
                rotvals[3] = {value=playersides[3],rotation={-38,0,20}}
                rotvals[4] = {value=playersides[4],rotation={38,180,-17}}
                rotvals[5] = {value=playersides[5],rotation={-38,0,90}}
                rotvals[6] = {value=playersides[6],rotation={38,180,-161}}
                rotvals[7] = {value=playersides[7],rotation={-38,0,307}}
                rotvals[8] = {value=playersides[8],rotation={38,180,-304}}
                rotvals[9] = {value=playersides[9],rotation={-38,0,163}}
                rotvals[10] = {value=playersides[10],rotation={38,180,-90}}
            end
            self.setName("goes first!")
        else
            self.setName("Who goes first?")
        end
    else
        self.setName("Who goes first?")
    end
    self.setRotationValues(rotvals);
end