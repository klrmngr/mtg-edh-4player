--[[
"Infinite 'Bag' MTG Deck Loader DX" by DXHHH101

This is an infinite "bag" that will attempt to update its own code.
After it does so (if it needs to), it will attempt to let the
deck loader inside of it.

Feel free to contribute if you spot a bug or something to improve!
https://github.com/DXHHH101/TabletopSimulatorScripts/tree/main/MTGImporter
]]

-- ============================================================================
-- Variables GITHUB AUTO-UPDATE
-- ============================================================================
local ScriptVersion = "1.0.0"
local ScriptClass = 'MTGImporter.InfiniteDeckloaderMat'
local checkUpdateTimeout = 1

-- ============================================================================
-- GITHUB AUTO-UPDATE
-- ============================================================================
--(originally written by ThatRobHuman, heavily modified by DXHHH101)
local function isNewerVersion(r,l)
    local a,b,c = r:match("(%d+)%.(%d+)%.(%d+)")
    local x,y,z = l:match("(%d+)%.(%d+)%.(%d+)")
    a,b,c,x,y,z = tonumber(a),tonumber(b),tonumber(c),tonumber(x),tonumber(y),tonumber(z)
    return a>x or (a==x and (b>y or (b==y and c>z)))
end

local function installUpdate(newVersion)
	--print('[33ff33]Installing Upgrade to MTG Deck Loader DX ['..tostring(newVersion)..']')
	WebRequest.get('https://raw.githubusercontent.com/DXHHH101/TabletopSimulatorScripts/refs/heads/main/MTGImporter/InfiniteDeckloaderMat.lua' .. "?t=" .. tostring(os.time()), function(res)
        if (not(res.is_error)) then
            local state = {}

            if self.script_state ~= "" then
                state = JSON.decode(self.script_state)
            end

            state.updatedTo = newVersion

            self.script_state = JSON.encode(state)

            self.script_code = res.text
            self.reload()
            --print('[33ff33]Installation Successful[-]')
        else
            error(res)
        end
        self.setVar("updateFinished", "reload")
    end)
end

local function checkForUpdates()
    if Global.getVar("DXMTGScriptVersions_fetchFailed") then
        error("Remote version check previously failed.")
        self.setVar("updateFinished", true) --used for the infinite bag object
        return
    end


    if Global.getVar("DXMTGScriptVersions_isFetching") then
        if checkUpdateTimeout <= 5 then
            Wait.time(checkForUpdates, 1)
            checkUpdateTimeout = checkUpdateTimeout + 1
            return
        else 
            error("Failed to check for DX MTG Script updates.")
        end
    else
        local allRemoteVersions = Global.getTable("DXMTGScriptVersions")
        if not allRemoteVersions then
            Global.setVar("DXMTGScriptVersions_isFetching", true)
            WebRequest.get('https://raw.githubusercontent.com/DXHHH101/TabletopSimulatorScripts/refs/heads/main/ScriptVersions.json' .. "?t=" .. tostring(os.time()), function(res)
                if (not(res.is_error)) then
                    local response = JSON.decode(res.text)
                    Global.setTable("DXMTGScriptVersions", response)
                    Global.setVar("DXMTGScriptVersions_isFetching", false)

                    local remoteVersion = response[ScriptClass]
                    if not remoteVersion then
                        error("Remote version not found for " .. ScriptClass)
                    elseif isNewerVersion(remoteVersion, ScriptVersion) then
                        installUpdate(remoteVersion)
                    end
                else
                    Global.setVar("DXMTGScriptVersions_fetchFailed", true)
                    Global.setVar("DXMTGScriptVersions_isFetching", false)
                    error(res)
                    self.setVar("updateFinished", true) --used for the infinite bag object
                end
            end)
            return
        else
            local remoteVersion = allRemoteVersions[ScriptClass]
            if not remoteVersion then
                error("Remote version not found for " .. ScriptClass)
            elseif isNewerVersion(remoteVersion, ScriptVersion) then
                installUpdate(remoteVersion)
                return
            end
        end
    end
    self.setVar("updateFinished", true) --used for the infinite bag object
end

local function checkCurrentVersion(script_state)
    local state = {}
    if script_state ~= "" then
        state = JSON.decode(script_state) or {}
    end
    --Will skip an update check once when the object is reloaded after updating
    if state.updatedTo ~= ScriptVersion then
        checkForUpdates()
    else
        state.updatedTo = nil
        self.script_state = JSON.encode(state)
        self.setVar("updateFinished", true) --used for the infinite bag object
    end
end

-- ============================================================================
-- LIFECYCLE
-- ============================================================================
local function patchFirstPulledObject()
    self.takeObject({
        position = self.getPosition() + Vector(0, -1000, 0),
        smooth = false,
        callback_function = function(obj)
            local objGUID = obj.getGUID()
            local cancelWait = false
            obj.setLock(true)

            self.setName("[00B4FF]MTG Deck Loader[-] [EF8B06]DX[-]")

            Wait.frames(function()
                self.setDescription(obj.getDescription())
            end, 1)

            Wait.condition(
                function()
                    if cancelWait then
                        return
                    end

                    local newObjectRef = getObjectFromGUID(objGUID)
                    if not newObjectRef or newObjectRef.isDestroyed() then
                        return
                    end

                    self.reset()
                    newObjectRef.setLock(false)

                    Wait.frames(function()
                        self.setDescription(newObjectRef.getDescription())
                        self.putObject(newObjectRef)
                    end, 1)
                    
                end,
                function()
                    local newObjectRef = getObjectFromGUID(objGUID)

                    if not newObjectRef or newObjectRef.isDestroyed() then
                        return false
                    end

                    local updateFinished = newObjectRef.getVar("updateFinished")

                    if updateFinished == true then
                        return true
                    elseif updateFinished == "kill" then
                        newObjectRef.destruct()
                        cancelWait = true
                        return true
                    end

                    return false
                end,
                20,
                function()
                    local newObjectRef = getObjectFromGUID(objGUID)
                    if newObjectRef and not newObjectRef.isDestroyed() then
                        self.setName("[00B4FF]MTG Deck Loader[-] [EF8B06]DX[-]")
                        newObjectRef.destruct()
                    end
                end
            )
        end
    })
end

function onLoad(script_state)
    checkCurrentVersion(script_state)

    local isReloading = false
    Wait.condition(
        function()
            if not isReloading then
                patchFirstPulledObject()
            end
        end,
        function()
            local updateFinished = self.getVar("updateFinished")
            if updateFinished then
                return true
            elseif updateFinished == "reload" then
                isReloading = true
            else
                return false
            end
        end,
        20,
        function()
            patchFirstPulledObject()
        end

    )
    
end