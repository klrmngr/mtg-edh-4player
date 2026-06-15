--[[
"MTG Importer DX" by DXHHH101
Originally written by Omes (https://steamcommunity.com/sharedfiles/filedetails/?id=2163084841)
Credit to Amuzet as well for ideas taken from their importer.

This is my approach to a rewrite/recycling of Omes' code to comply with Scryfall's API rules.
This does nothing on its own, an actual deck loader like "MTG Deck Loader DX" is required
to actually load the decks for you. This is to keep all Scryfall calls in one place
so they can be kept under control in terms of quantity.

Feel free to contribute if you spot a bug or something to improve!
https://github.com/DXHHH101/TabletopSimulatorScripts/tree/main/MTGImporter
]]

-- ============================================================================
-- Variables GITHUB AUTO-UPDATE
-- ============================================================================
local ScriptVersion = "1.1.0"
local ScriptClass = 'MTGImporter.Main'
local checkUpdateTimeout = 1

--========================================
-- Config / Constants
--========================================
local globalVar = "MTGImporterDX"

local DEFAULT_BACK_URL = "https://cards.scryfall.io/back.png"

-- Scryfall batching
local BATCH_SIZE  = 75
local BATCH_DELAY = 0.1

local ERROR_MESSAGE_IMPORTER = "MTG Importer DX Error: "

--========================================
-- Runtime State
--========================================
local isLocked = false
local rateLimitUnlockTime = 0

--========================================
-- Error / Status Helpers
--========================================

local function printError(string, pc) --if no color is given, prints to all
    if pc then
        printToColor(ERROR_MESSAGE_IMPORTER .. string, pc, {r=1, g=0, b=0})
    else
        printToAll(ERROR_MESSAGE_IMPORTER .. string, {r=1, g=0, b=0})
    end
    lockImporter(false)
end

local function printInfo(string, pc)
    if pc then
        printToColor(ERROR_MESSAGE_IMPORTER .. string, pc)
    else
        printToAll(ERROR_MESSAGE_IMPORTER .. string)
    end
end

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
	print('[33ff33]Installing Upgrade to MTG Importer DX ['..tostring(newVersion)..']')
	WebRequest.get('https://raw.githubusercontent.com/DXHHH101/TabletopSimulatorScripts/refs/heads/main/MTGImporter/Main.lua' .. "?t=" .. tostring(os.time()), function(res)
        if (not(res.is_error)) then
            local state = {}

            if self.script_state ~= "" then
                state = JSON.decode(self.script_state)
            end

            state.updatedTo = newVersion

            self.script_state = JSON.encode(state)

            self.script_code = res.text
            self.reload()
            print('[33ff33]Installation Successful[-]')
        else
            error(res)
        end
    end)
end

local function checkForUpdates()
    if Global.getVar("DXMTGScriptVersions_fetchFailed") then
        error("Remote version check previously failed.")
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
                end
            end)
        else
            local remoteVersion = allRemoteVersions[ScriptClass]
            if not remoteVersion then
                error("Remote version not found for " .. ScriptClass)
            elseif isNewerVersion(remoteVersion, ScriptVersion) then
                installUpdate(remoteVersion)
            end
        end
    end
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
    end
end

--========================================
-- Import Lock / Rate Limit Helpers
--========================================

local function rateLimitLockFor(seconds)
    rateLimitUnlockTime = os.time() + seconds
end

local function isRateLimited()
    return os.time() < rateLimitUnlockTime
end

local function getRateLimitTimeLeft()
    return math.max(0, math.ceil(rateLimitUnlockTime - os.time()))
end

function isImporterLocked()
    if isLocked then
        return "Importer is currently working, please wait a moment."
    elseif isRateLimited() then
        return "Too many requests to Scryfall, please wait " .. getRateLimitTimeLeft() .. " seconds."
    end

    return false
end

function lockImporter(state)
    isLocked = state
end


--========================================
-- Data / Identifier Helpers
--========================================
local function buildIdentifiersFromMap(cards, identifierType)
    --the string identifier type names are straight form scryfall https://scryfall.com/docs/api/cards/collection

    if identifierType == "id" then
        local identifiers = {}
        for _, card in pairs(cards) do
            table.insert(identifiers, {
                id = card.id,
            })
        end
        return identifiers
    elseif identifierType == "collector_number,set" then
        local identifiers = {}
        for _, card in pairs(cards) do
            table.insert(identifiers, {
                set = card.set,
                collector_number = card.collector_number
            })
        end
        return identifiers
    elseif identifierType == "name" then
        local identifiers = {}
        for _, card in pairs(cards) do
            table.insert(identifiers, {
                name = card.name
            })
        end
        return identifiers
    elseif identifierType == "name,set" then
        local identifiers = {}
        for _, card in pairs(cards) do
            table.insert(identifiers, {
                set = card.set,
                name = card.name
            })
        end
        return identifiers
    elseif identifierType == "mixed" then
        local identifiers = {}
        for _, card in pairs(cards) do
            if card.dataType == "id" then
                table.insert(identifiers, {
                    id = card.id,
                })
            elseif card.dataType == "collector_number,set" then
                table.insert(identifiers, {
                    set = card.set,
                    collector_number = card.collector_number
                })
            elseif card.dataType == "name" then
                table.insert(identifiers, {
                    name = card.name
                })
            elseif card.dataType == "name,set" then
                table.insert(identifiers, {
                    set = card.set,
                    name = card.name
                })
            end
        end
        return identifiers
    end

    return nil
end

local function chunkArray(arr, size)
    local chunks = {}

    for i = 1, #arr, size do
        local chunk = {}
        for j = i, math.min(i + size - 1, #arr) do
            chunk[#chunk+1] = arr[j]
        end
        chunks[#chunks+1] = chunk
    end

    return chunks
end


--========================================
-- Image / Card Utility Helpers
--========================================
local function stripScryfallImageURI(url)
    if not url then return "" end
    return string.match(url, "^[^?]+")
end

local function calcCMCofDFC(cardObj, side)
    if  cardObj.layout == "transform" then
        return cardObj.cmc
    elseif cardObj.layout == "modal_dfc" then
        local cost = cardObj.card_faces[side].mana_cost
        local cmc = 0


        for token in cost:gmatch("{(.-)}") do
            token = token:match("^%s*(.-)%s*$") or token -- trim surrounding whitespace
            local lower = token:lower()

            -- Treat X, Y, Z (any case) as 0
            if lower:match("^[xyz]$") then
                cmc = cmc + 0
            -- Treat HR, HW, HB, HU, HG (any case) as 0.5
            elseif lower:match("^h[rbwug]$") then
                cmc = cmc + 0.5
            else
            -- If it starts with a number, use that number (e.g. "2", "10/W")
                local n = token:match("^(%d+)")
                if n then
                    cmc = cmc + tonumber(n)
                else
                    cmc = cmc + 1
                end
            end
        end
        return tostring(cmc)
    end
    return "ERROR" .. cardObj.name --find bugs with this later if they happen
end

local function getSingleFacedImage(cardInfo, isPNGImage)
    if isPNGImage then
        if cardInfo.image_uris and cardInfo.image_uris.png then
            return cardInfo.image_uris.png
        end
    else
        if cardInfo.image_uris and cardInfo.image_uris.large then
            return cardInfo.image_uris.large
        end
    end
    --backup image if something goes wrong
    return DEFAULT_BACK_URL
end

local function getDoubleFacedImages(cardInfo, isPNGImage)
    if isPNGImage then
        if cardInfo.card_faces[1] and cardInfo.card_faces[1].image_uris and cardInfo.card_faces[1].image_uris.png and cardInfo.card_faces[2] and cardInfo.card_faces[2].image_uris and cardInfo.card_faces[2].image_uris.png then
            return cardInfo.card_faces[1].image_uris.png, cardInfo.card_faces[2].image_uris.png
        end
    else
        if cardInfo.card_faces[1] and cardInfo.card_faces[1].image_uris and cardInfo.card_faces[1].image_uris.large and cardInfo.card_faces[2] and cardInfo.card_faces[2].image_uris and cardInfo.card_faces[2].image_uris.large then
            return cardInfo.card_faces[1].image_uris.large, cardInfo.card_faces[2].image_uris.large
        end
    end
    --backup image if something goes wrong
    return DEFAULT_BACK_URL
end

local function isSidewaysCard(cardInfo)
    local sidewaysLayouts = {
        planar = true
    }

    if sidewaysLayouts[cardInfo.layout] or cardInfo.type_line and cardInfo.type_line:find("Battle", 1, true) then
        return true
    end
    return false
end

--========================================
-- Card Layout Handling
--========================================
--If the layout doesn't match anything (new releases), just default to the card name and description if it can be gotten
--Also for card layouts that can be super generic
local function cardLayoutHandlingNormal(cardInfo, options)
    cardName = cardInfo.name or "Card Name Not Found"
    typeLine = cardInfo.type_line or "Type Line Not Found"
    cmc = cardInfo.cmc or "CMC Not Found"

    local nickname = cardName .. "\n" .. typeLine .. " " .. cmc .. "CMC"

    local description = cardInfo.oracle_text or "Description Not Found"
    if cardInfo.power then
        if description ~= "" then
            description = description .. "\n"
        end
        description = description .. "[b]" .. cardInfo.power .. "/" .. cardInfo.toughness .. "[/b]"
    end

    local image = getSingleFacedImage(cardInfo, options.isPNGImage)

    return nickname, description, image
end

--handles all of the different layouts on scryfall
local cardLayoutHandling = {
    normal = function(cardInfo, options)
        return cardLayoutHandlingNormal(cardInfo, options)
    end,

    split = function(cardInfo, options)
        local nickname = cardInfo.name .. "\n" .. cardInfo.type_line .. " " .. cardInfo.cmc .. "CMC"

        local description = ""
        for i, face in ipairs(cardInfo.card_faces) do
            --Don't add the spacing for the first one
            if i > 1 then
                description = description .. "\n\n"
            end
            description = description .. "[u]" .. face.name .. "[/u]\n" .. face.oracle_text

            if face.power then
                if description ~= "" then
                    description = description .. "\n"
                end
                description = description .. "[b]" .. face.power .. "/" .. face.toughness .. "[/b]"
            end
        end

        local image = getSingleFacedImage(cardInfo, options.isPNGImage)

        return nickname, description, image
    end,

    modal_dfc = function(cardInfo, options)
        --first name
        local nickname = cardInfo.card_faces[1].name .. "\n" .. cardInfo.card_faces[1].type_line .. " " .. cardInfo.cmc .. "CMC"

        --first description
        local description = cardInfo.card_faces[1].oracle_text
        if cardInfo.card_faces[1].power then
            if description ~= "" then
                description = description .. "\n"
            end
            description = description .. "[b]" .. cardInfo.card_faces[1].power .. "/" .. cardInfo.card_faces[1].toughness .. "[/b]"
        end

        --second name, including handling CMC of modal_dfcs
        local dfcCMC = calcCMCofDFC(cardInfo, 2)
        local nicknameSide2 = cardInfo.card_faces[2].name .. "\n" .. cardInfo.card_faces[2].type_line .. " " .. dfcCMC .. "CMC"

        local descriptionSide2 = cardInfo.card_faces[2].oracle_text
        if cardInfo.card_faces[2].power then
            if descriptionSide2 ~= "" then
                descriptionSide2 = descriptionSide2 .. "\n"
            end
            descriptionSide2 = descriptionSide2 .. "[b]" .. cardInfo.card_faces[2].power .. "/" .. cardInfo.card_faces[2].toughness .. "[/b]"
        end

        local image, imageSide2 = getDoubleFacedImages(cardInfo, options.isPNGImage)

        return nickname, description, image, nicknameSide2, descriptionSide2, imageSide2
    end,

    --Flip card: https://scryfall.com/search?q=layout%3Aflip
    flip = function(cardInfo, options)
        local nickname = cardInfo.name .. "\n" .. cardInfo.type_line .. " " .. cardInfo.cmc .. "CMC"

        local description = ""
        for i, face in ipairs(cardInfo.card_faces) do
            --Don't add the spacing for the first one
            if i > 1 then
                description = description .. "\n\n"
            end
            description = description .. "[u]" .. face.name .. "[/u]\n" .. face.oracle_text

            if face.power then
                if description ~= "" then
                    description = description .. "\n"
                end
                description = description .. "[b]" .. face.power .. "/" .. face.toughness .. "[/b]"
            end
        end

        local image = getSingleFacedImage(cardInfo, options.isPNGImage)

        return nickname, description, image
    end,

    transform = function(cardInfo, options)
        --first name
        local nickname = cardInfo.card_faces[1].name .. "\n" .. cardInfo.card_faces[1].type_line .. " " .. cardInfo.cmc .. "CMC"

        --first description
        local description = cardInfo.card_faces[1].oracle_text
        if cardInfo.card_faces[1].power then
            if description ~= "" then
                description = description .. "\n"
            end
            description = description .. "[b]" .. cardInfo.card_faces[1].power .. "/" .. cardInfo.card_faces[1].toughness .. "[/b]"
        end

        local nicknameSide2 = cardInfo.card_faces[2].name .. "\n" .. cardInfo.card_faces[2].type_line .. " " .. cardInfo.cmc .. "CMC"

        local descriptionSide2 = cardInfo.card_faces[2].oracle_text
        if cardInfo.card_faces[2].power then
            if descriptionSide2 ~= "" then
                descriptionSide2 = descriptionSide2 .. "\n"
            end
            descriptionSide2 = descriptionSide2 .. "[b]" .. cardInfo.card_faces[2].power .. "/" .. cardInfo.card_faces[2].toughness .. "[/b]"
        end

        local image, imageSide2 = getDoubleFacedImages(cardInfo, options.isPNGImage)

        return nickname, description, image, nicknameSide2, descriptionSide2, imageSide2
    end,

    --https://scryfall.com/search?q=layout%3Aleveler
    leveler = function(cardInfo, options)
        --first name
        local nickname = cardInfo.name .. "\n" .. cardInfo.type_line .. " " .. cardInfo.cmc .. "CMC"

        local description = cardInfo.oracle_text

        -- Underline LEVEL lines
        description = description:gsub("^(LEVEL [^\n]+)", "[u]%1[/u]")
        description = description:gsub("\n(LEVEL [^\n]+)", "\n[u]%1[/u]")

        -- Bold Power/Toughness lines (X/Y format)
        description = description:gsub("\n(%d+/%d+)", "\n[b]%1[/b]")

        if cardInfo.power then
            description = "[b]" .. cardInfo.power .. "/" .. cardInfo.toughness .. "[/b]\n" .. description
        end

        local image = getSingleFacedImage(cardInfo, options.isPNGImage)

        return nickname, description, image
    end,

    --https://scryfall.com/search?q=layout%3Aadventure
    adventure = function(cardInfo, options)
        local nickname = cardInfo.name .. "\n" .. cardInfo.type_line .. " " .. cardInfo.cmc .. "CMC"

        local description = ""
        for i, face in ipairs(cardInfo.card_faces) do
            --Don't add the spacing for the first one
            if i > 1 then
                description = description .. "\n\n"
            end
            description = description .. "[u]" .. face.name .. "[/u]\n" .. face.oracle_text

            if face.power then
                if description ~= "" then
                    description = description .. "\n"
                end
                description = description .. "[b]" .. face.power .. "/" .. face.toughness .. "[/b]"
            end
        end

        local image = getSingleFacedImage(cardInfo, options.isPNGImage)

        return nickname, description, image
    end,

    --https://scryfall.com/search?q=layout%3Aprepare
    prepare = function(cardInfo, options)
        local nickname = cardInfo.name .. "\n" .. cardInfo.type_line .. " " .. cardInfo.cmc .. "CMC"

        local description = ""
        for i, face in ipairs(cardInfo.card_faces) do
            --Don't add the spacing for the first one
            if i > 1 then
                description = description .. "\n\n"
            end
            description = description .. "[u]" .. face.name .. "[/u]\n" .. face.oracle_text

            if face.power then
                if description ~= "" then
                    description = description .. "\n"
                end
                description = description .. "[b]" .. face.power .. "/" .. face.toughness .. "[/b]"
            end
        end

        local image = getSingleFacedImage(cardInfo, options.isPNGImage)

        return nickname, description, image
    end,

    prototype = function(cardInfo, options)
        local nickname, description, image = cardLayoutHandlingNormal(cardInfo, options)

        description = description:gsub("([—%-]%s*)(%d+/%d+)", "%1[b]%2[/b]")

        return nickname, description, image
    end,

    --https://scryfall.com/search?q=layout%3Aplanar
    planar = function(cardInfo, options)
        local nickname = cardInfo.name .. "\n" .. cardInfo.type_line

        local description = cardInfo.oracle_text

        local image = getSingleFacedImage(cardInfo, options.isPNGImage)

        return nickname, description, image
    end,

    --https://scryfall.com/search?q=layout%3Ascheme
    scheme = function(cardInfo, options)
        local nickname = cardInfo.name .. "\n" .. cardInfo.type_line

        local description = cardInfo.oracle_text

        local image = getSingleFacedImage(cardInfo, options.isPNGImage)

        return nickname, description, image
    end,

    --https://scryfall.com/search?q=layout%3Avanguard
    vanguard = function(cardInfo, options)
        local nickname = cardInfo.name .. "\n" .. cardInfo.type_line

        local description = cardInfo.oracle_text
        if cardInfo.hand_modifier then
            if description ~= "" then
                description = description .. "\n"
            end
            description = description .. "[b]Hand Size: " .. cardInfo.hand_modifier .. "[/b]"
        end
        if cardInfo.life_modifier then
            if description ~= "" then
                description = description .. "\n"
            end
            description = description .. "[b]Starting Life: " .. cardInfo.life_modifier .. "[/b]"
        end

        local image = getSingleFacedImage(cardInfo, options.isPNGImage)

        return nickname, description, image
    end,

    --https://scryfall.com/search?q=layout%3Atoken
    token = function(cardInfo, options)
        local nickname, description, image = cardLayoutHandlingNormal(cardInfo, options)
        if cardInfo.cmc == 0 then
            nickname = cardInfo.name .. "\n" .. cardInfo.type_line
        else
            nickname = cardInfo.name .. "\n" .. cardInfo.type_line .. " " .. cardInfo.cmc .. "CMC"
        end

        return nickname, description, image
    end,

    --https://scryfall.com/search?q=layout%3Adouble_faced_token
    double_faced_token = function(cardInfo, options)
        --first name
        local nickname = cardInfo.card_faces[1].name .. "\n" .. cardInfo.card_faces[1].type_line
        if cardInfo.cmc ~= 0 then
            nickname = nickname .. " " .. cardInfo.cmc .. "CMC"
        end

        --first description
        local description = cardInfo.card_faces[1].oracle_text
        if cardInfo.card_faces[1].power then
            if description ~= "" then
                description = description .. "\n"
            end
            description = description .. "[b]" .. cardInfo.card_faces[1].power .. "/" .. cardInfo.card_faces[1].toughness .. "[/b]"
        end

        --second name, including handling CMC of dfcs
        local nicknameSide2 = cardInfo.card_faces[2].name .. "\n" .. cardInfo.card_faces[2].type_line
        if cardInfo.card_faces[2].mana_cost ~= "" then
            local dfcCMC = calcCMCofDFC(cardInfo, 2)
            nicknameSide2 = nicknameSide2 .. " " .. dfcCMC .. "CMC"
        end

        local descriptionSide2 = cardInfo.card_faces[2].oracle_text
        if cardInfo.card_faces[2].power then
            if descriptionSide2 ~= "" then
                descriptionSide2 = descriptionSide2 .. "\n"
            end
            descriptionSide2 = descriptionSide2 .. "[b]" .. cardInfo.card_faces[2].power .. "/" .. cardInfo.card_faces[2].toughness .. "[/b]"
        end

        local image, imageSide2 = getDoubleFacedImages(cardInfo, options.isPNGImage)

        return nickname, description, image, nicknameSide2, descriptionSide2, imageSide2
    end,

    --https://scryfall.com/search?q=layout%3Aemblem
    emblem = function(cardInfo, options)
        local nickname, description, image = cardLayoutHandlingNormal(cardInfo, options)

        nickname = cardInfo.name .. "\n" .. cardInfo.type_line

        return nickname, description, image
    end,

    --https://scryfall.com/search?q=layout%3Aart_series
    art_series = function(cardInfo, options)
        local nickname = cardInfo.card_faces[1].name
        local nicknameSide2 = nickname

        local description = cardInfo.card_faces[2].artist or ""
        local descriptionSide2 = description

        local image, imageSide2 = getDoubleFacedImages(cardInfo, options.isPNGImage)

        return nickname, description, image, nicknameSide2, descriptionSide2, imageSide2
    end,

    --https://scryfall.com/search?q=layout%3Areversible_card
    reversible_card = function(cardInfo, options)
        local nickname = cardInfo.card_faces[1].name .. "\n" .. cardInfo.card_faces[1].type_line .. " " .. cardInfo.card_faces[1].cmc .. "CMC"

        local description = cardInfo.card_faces[1].oracle_text
        if cardInfo.card_faces[1].power then
            if description ~= "" then
                description = description .. "\n"
            end
            description = description .. "[b]" .. cardInfo.card_faces[1].power .. "/" .. cardInfo.card_faces[1].toughness .. "[/b]"
        end

        local nicknameSide2 = nickname
        local descriptionSide2 = description

        local image, imageSide2 = getDoubleFacedImages(cardInfo, options.isPNGImage)

        return nickname, description, image, nicknameSide2, descriptionSide2, imageSide2
    end
}

--========================================
-- Deck Object Construction
--========================================
function createDeckObject(bundledData)
    --[[bundledData must have decklistArray (see below)
        Optional:
        cacheBuster (bool) add the time onto the image uri to force a cache break
        isPNGImage (bool) whether to use the large or png image (large by default)
        cardBack (string) if there's a card back given to importer (nil by default, uses default back)
    ]]


    --[[
        decklistArray entries look like this:
        {
            card (the scryfall-returned data for that specific card printing)
            qty (how many of it to make)
        }
    ]]
    if #bundledData.decklistArray == 0 then
        return
    end

    local customDeck = {}
    local deckIDs = {}
    local cardContainer = {}
    local nextDeckKey = 1
    local cacheBuster = ""

    if bundledData.cacheBuster then --If needed, make the cachebusting string
        cacheBuster = string.gsub(tostring(Time.time), "%.", "-")
    end

    for _, entry in ipairs(bundledData.decklistArray) do
        local cardInfo = entry.card
        local quantity = entry.qty or 1

        local doubleSidedLayouts = {
            modal_dfc = true,
            transform = true,
            double_faced_token = true,
            art_series = true,
            reversible_card = true
        }

        local isDoubleSided = doubleSidedLayouts[cardInfo.layout] or false

        local nickname, description, image, nicknameSide2, descriptionSide2, imageSide2

        --misc options to pass
        local cardOptions = {}
        cardOptions.isPNGImage = bundledData.isPNGImage
        if isDoubleSided then
            nickname, description, image, nicknameSide2, descriptionSide2, imageSide2 = cardLayoutHandling[cardInfo.layout](cardInfo, cardOptions)
        else
            --singled faced
            if cardLayoutHandling[cardInfo.layout] then
                nickname, description, image = cardLayoutHandling[cardInfo.layout](cardInfo, cardOptions)
            else
                --let it fallback to the "normal" card method for layouts that don't matter (like meld)
                nickname, description, image = cardLayoutHandling["normal"](cardInfo, cardOptions)
            end
        end

        --check if cachebusting is needed (almost never, toggled by user)
        if bundledData.cacheBuster then

            image = stripScryfallImageURI(image)
            image = image .. "?" .. cacheBuster

            if imageSide2 then
                imageSide2 = stripScryfallImageURI(imageSide2)
                imageSide2 = imageSide2 .. "?" .. cacheBuster
            end
        end

        for _ = 1, quantity do
            -- Always create key A for base face (Do this before side Bs is created)
            local keyAStr = tostring(nextDeckKey)
            local cardIdA = nextDeckKey * 100
            nextDeckKey = nextDeckKey + 1

            customDeck[keyAStr] = {
                    FaceURL = image,
                    BackURL = bundledData.cardBack or DEFAULT_BACK_URL,
                    NumWidth = 1,
                    NumHeight = 1,
                    BackIsHidden = true
                }

            table.insert(deckIDs, cardIdA)

            local card = {
                Name = "Card",
                Nickname = nickname,
                Description = description,
                Transform = {posX=0,posY=0,posZ=0, rotX=0,rotY=0,rotZ=0, scaleX=1,scaleY=1,scaleZ=1},
                CardID = cardIdA
            }

            if isSidewaysCard(cardInfo) then
                card.AltLookAngle = { x = 0, y = 180, z = 270 }
            end


            -- Add State 2 if double-faced
            if isDoubleSided then

                --if double sided, need another ID
                local keyBStr = tostring(nextDeckKey)
                local cardIdB = nextDeckKey * 100
                nextDeckKey = nextDeckKey + 1

                customDeck[keyBStr] = {
                    FaceURL = imageSide2 or DEFAULT_BACK_URL,
                    BackURL = bundledData.cardBack or DEFAULT_BACK_URL,
                    NumWidth = 1,
                    NumHeight = 1,
                    BackIsHidden = true
                }

                card.States = {
                    ["2"] = {
                        Name = "Card",
                        Nickname = nicknameSide2,
                        Description = descriptionSide2,
                        Transform = {posX=0,posY=0,posZ=0, rotX=0,rotY=0,rotZ=0, scaleX=1,scaleY=1,scaleZ=1},
                        CardID = cardIdB,
                        CustomDeck = customDeck
                    }
                }
            end

            table.insert(cardContainer, card)
        end
    end

    local deckData = {
        Name = "DeckCustom",
        Nickname = "",
        Transform = {
            posX = 0, posY = 1.05, posZ = 0,
            rotX = 0, rotY = 180, rotZ = 0,
            scaleX = 1, scaleY = 1, scaleZ = 1
        },
        DeckIDs = deckIDs,
        ContainedObjects = cardContainer,
        CustomDeck = customDeck
    }

    if #deckData.ContainedObjects == 1 then
        local cardData = deckData.ContainedObjects[1]

        -- TTS often needs CustomDeck on the card itself.
        if not cardData.CustomDeck then
            cardData.CustomDeck = deckData.CustomDeck
        end
        return cardData
    else


        return deckData
    end
end

--========================================
-- Scryfall Import / Fetch Pipeline
--========================================
function loadDeckFromScryfall(bundledData)

    --[[
        bundledData = {
            cardMap = cardMap,
            dataType = dataType ("id", "name")
            deckName = options.deckName or "",
            needToFetchTokens = true,
            callerGUID = self.getGUID(),
            onSuccess = postLoadFunction
        }
    ]]

    local bundledDataToSendBack = {}

    local identifiers
    identifiers = buildIdentifiersFromMap(bundledData.cardMap, bundledData.dataType)

    local batches = chunkArray(identifiers, BATCH_SIZE)

    local url = "https://api.scryfall.com/cards/collection"
    local headers = {
        ["Content-Type"] = "application/json",
        ["Accept"] = "*/*",
        ["User-Agent"] = "TTS-MTGImporterDX/1.0" --NOTE ADD VERSION NUMBER HERE
    }

    local allFound = {}
    local batchIndex = 1


    local function requestNextBatch()


        if batchIndex > #batches then

            --check if we need to fetch tokens before returning
            if bundledData.needToFetchTokens then

                local tokenIDs = {}
                local tokenIDDupeCheck = {}
                for _, cardData in ipairs(allFound or {}) do
                    local isTokenLayout = (cardData.layout == "token")
                    local isCardType = cardData.type_line and cardData.type_line:find("Card", 1, true)

                    if not isTokenLayout and not isCardType then
                        for _, part in ipairs(cardData.all_parts or {}) do
                            if part.id ~= cardData.id then
                                local partID = part.id
                                local component = part.component
                                local typeLine = part.type_line
                                local name = part.name


                                local isWantedPart =
                                    not name:find("Checklist", 1, true) and
                                    (component == "token"
                                    or component == "meld_result"
                                    or (typeLine and typeLine:find("Emblem", 1, true))
                                    or (typeLine and typeLine:find("Card", 1, true)))

                                if not tokenIDDupeCheck[partID] and isWantedPart then
                                    tokenIDDupeCheck[partID] = true
                                    tokenIDs[#tokenIDs + 1] = { id = partID }
                                end
                            end
                        end
                    end
                end


                --if there are tokens in the list, restart the requestNewBatch loop, but replace the identifiers with the tokenIDs
                if #tokenIDs > 0 then

                    bundledDataToSendBack = {
                        cardMap = bundledData.cardMap,
                        dataType = bundledData.dataType,
                        deckName = bundledData.deckName,
                        importedDeck = allFound,
                        isFetchingTokens = true
                    }
                    bundledData.needToFetchTokens = false



                    batchIndex = 1
                    allFound = {}

                    identifiers = buildIdentifiersFromMap(tokenIDs, "id")
                    batches = chunkArray(identifiers, BATCH_SIZE)
                    Wait.time(requestNextBatch, BATCH_DELAY)
                    return
                end
            end


            local caller = getObjectFromGUID(bundledData.callerGUID)
            if not caller then
                --missing reference to the object that called the importer
                printError("Missing caller. Was the deckloader deleted?", bundledData.playerColor)
                lockImporter(false)
            end
            local onSuccess = bundledData.onSuccess

            --if this was a token run, handle the output differently
            if bundledDataToSendBack.isFetchingTokens then
                bundledDataToSendBack.importedTokens = allFound

                -- tokens by id (for putting tokens into cards with all_parts)
                local importedTokensByID = {}
                for _, token in ipairs(bundledDataToSendBack.importedTokens or {}) do
                    importedTokensByID[token.id] = token
                end

                --check each card's all_parts and find imported tokens to attach to their data
                if next(importedTokensByID) then
                    for _, card in ipairs(bundledDataToSendBack.importedDeck or {}) do
                        local importerAddedTokenData = {}
                        if card.all_parts then
                            for _, part in ipairs(card.all_parts) do
                                local token = importedTokensByID[part.id]
                                if token then
                                    importerAddedTokenData[#importerAddedTokenData +1] = token
                                end
                            end
                        end
                        if #importerAddedTokenData > 0 then
                            card.importerAddedTokenData = importerAddedTokenData
                        end
                    end
                end

            else
                bundledDataToSendBack = {
                    importedDeck = allFound,
                    cardMap = bundledData.cardMap,
                    deckName = bundledData.deckName,
                    dataType = bundledData.dataType
                }
            end
            lockImporter(false)
            caller.call(onSuccess, bundledDataToSendBack)
            return
        end



        -- Encode JSON
        local payloadJson = JSON.encode({ identifiers = batches[batchIndex] })

        payloadJson = payloadJson:gsub("\226\152\133", "\\u2605") --handles ★ characters from manually typed/pasted decklists. --NOTE Maybe new update doesn't need this. Test with "1 Fish // Kraken (ta25) 5★"

        WebRequest.custom(url, "POST", true, payloadJson, headers, function(res)
            if res.response_code == 200 then
                local raw = res.text
                if bundledDataToSendBack.isFetchingTokens then --if it's a token run. Remove all of the all_parts from the raw json. Too much data, takes forever to decode
                    raw = raw:gsub('"all_parts"%s*:%s*%b[]%s*,?', "")
                end

                local decoded = json.decode(raw)
                if decoded and decoded.object ~= "error" then
                    local found = decoded.data or {}
                    -- append into allFound
                    for i = 1, #found do
                        table.insert(allFound, found[i])
                    end
                else
                    lockImporter(false)
                    return
                end
            elseif res.response_code == 429 then --Too Many Requests
                printError("Rate limited by Scryfall. Try again in 30 seconds.", bundledData.playerColor)
                rateLimitLockFor(30)
                lockImporter(false)

                local caller = getObjectFromGUID(bundledData.callerGUID)
                if caller then
                    caller.call("lockSelf", false) --if the deckloader has/needs an unlock function, call it if the importer errors out
                end
                return
            elseif res.response_code >= 500 then
                printError("Scryfall server error (" .. res.response_code .. "). Try again later.", bundledData.playerColor)
                lockImporter(false)

                local caller = getObjectFromGUID(bundledData.callerGUID)
                if caller then
                    caller.call("lockSelf", false) --if the deckloader has/needs an unlock function, call it if the importer errors out
                end
                return
            elseif res.response_code == 0 then
                printError("Could not reach Scryfall. (" .. (res.text or "Unknown Error") .. ")", bundledData.playerColor)
                lockImporter(false)
                local caller = getObjectFromGUID(bundledData.callerGUID)
                if caller then
                    caller.call("lockSelf", false) --if the deckloader has/needs an unlock function, call it if the importer errors out
                end
                return
            else
                printError("Unexpected API error (" .. (res.response_code or "???") .. "): " .. (res.text or "Unknown Error"))
                lockImporter(false)
                local caller = getObjectFromGUID(bundledData.callerGUID)
                if caller then
                    caller.call("lockSelf", false) --if the deckloader has/needs an unlock function, call it if the importer errors out
                end
                return
            end

            batchIndex = batchIndex + 1
            Wait.time(requestNextBatch, BATCH_DELAY)
        end)
    end

    requestNextBatch()
end

--========================================
-- TTS Lifecycle / Commands
--========================================
local function setVersionInDescription(optionalExtraText)
    local desc = self.getDescription() or ""
    local versionLine = "[i]Version " .. tostring(ScriptVersion) .. (optionalExtraText and ("\n" .. optionalExtraText) or "") .. "[/i]"

    local pattern = "%[i%]Version%s+%d+%.%d+%.%d+.-%[/i%]"

    if desc:match(pattern) then
        -- Replace existing version line
        desc = desc:gsub(pattern, versionLine, 1)
    else
        -- No version present, add it to the top
        if desc == "" then
            desc = versionLine
        else
            desc = versionLine .. "\n" .. desc
        end
    end

    self.setDescription(desc)
end

function onLoad(script_state)
    self.setName("[00B4FF]MTG Importer[-] [EF8B06]DX[-]")

    setVersionInDescription("Type !reloadimporter if this is stuck")


    checkCurrentVersion(script_state)

    Global.setVar(globalVar, self)

end

function onChat(message, player)
    if message:sub(1,1) ~= "!" then return end

    local msg = string.lower(message)
    local command = msg:match("^!(%S+)")

    if command == "reloadimporter" then
        printToAll("Reloading MTG Importer DX...", {1,1,0})
        self.reload()
    end
end


-- ============================================================================
-- json.lua
-- ============================================================================

json = (function()
--
-- json.lua
--
-- Copyright (c) 2020 rxi
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy of
-- this software and associated documentation files (the "Software"), to deal in
-- the Software without restriction, including without limitation the rights to
-- use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
-- of the Software, and to permit persons to whom the Software is furnished to do
-- so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
--

local json = { _version = "0.1.2" }

-------------------------------------------------------------------------------
-- Encode
-------------------------------------------------------------------------------

local encode

local escape_char_map = {
  [ "\\" ] = "\\",
  [ "\"" ] = "\"",
  [ "\b" ] = "b",
  [ "\f" ] = "f",
  [ "\n" ] = "n",
  [ "\r" ] = "r",
  [ "\t" ] = "t",
}

local escape_char_map_inv = { [ "/" ] = "/" }
for k, v in pairs(escape_char_map) do
  escape_char_map_inv[v] = k
end


local function escape_char(c)
  return "\\" .. (escape_char_map[c] or string.format("u%04x", c:byte()))
end


local function encode_nil(val)
  return "null"
end


local function encode_table(val, stack)
  local res = {}
  stack = stack or {}

  -- Circular reference?
  if stack[val] then error("circular reference") end

  stack[val] = true

  if rawget(val, 1) ~= nil or next(val) == nil then
    -- Treat as array -- check keys are valid and it is not sparse
    local n = 0
    for k in pairs(val) do
      if type(k) ~= "number" then
        error("invalid table: mixed or invalid key types")
      end
      n = n + 1
    end
    if n ~= #val then
      error("invalid table: sparse array")
    end
    -- Encode
    for i, v in ipairs(val) do
      table.insert(res, encode(v, stack))
    end
    stack[val] = nil
    return "[" .. table.concat(res, ",") .. "]"

  else
    -- Treat as an object
    for k, v in pairs(val) do
      if type(k) ~= "string" then
        error("invalid table: mixed or invalid key types")
      end
      table.insert(res, encode(k, stack) .. ":" .. encode(v, stack))
    end
    stack[val] = nil
    return "{" .. table.concat(res, ",") .. "}"
  end
end


local function encode_string(val)
  return '"' .. val:gsub('[%z\1-\31\\"]', escape_char) .. '"'
end


local function encode_number(val)
  -- Check for NaN, -inf and inf
  if val ~= val or val <= -math.huge or val >= math.huge then
    error("unexpected number value '" .. tostring(val) .. "'")
  end
  return string.format("%.14g", val)
end


local type_func_map = {
  [ "nil"     ] = encode_nil,
  [ "table"   ] = encode_table,
  [ "string"  ] = encode_string,
  [ "number"  ] = encode_number,
  [ "boolean" ] = tostring,
}


encode = function(val, stack)
  local t = type(val)
  local f = type_func_map[t]
  if f then
    return f(val, stack)
  end
  error("unexpected type '" .. t .. "'")
end


function json.encode(val)
  return ( encode(val) )
end


-------------------------------------------------------------------------------
-- Decode
-------------------------------------------------------------------------------

local parse

local function create_set(...)
  local res = {}
  for i = 1, select("#", ...) do
    res[ select(i, ...) ] = true
  end
  return res
end

local space_chars   = create_set(" ", "\t", "\r", "\n")
local delim_chars   = create_set(" ", "\t", "\r", "\n", "]", "}", ",")
local escape_chars  = create_set("\\", "/", '"', "b", "f", "n", "r", "t", "u")
local literals      = create_set("true", "false", "null")

local literal_map = {
  [ "true"  ] = true,
  [ "false" ] = false,
  [ "null"  ] = nil,
}


local function next_char(str, idx, set, negate)
  for i = idx, #str do
    if set[str:sub(i, i)] ~= negate then
      return i
    end
  end
  return #str + 1
end


local function decode_error(str, idx, msg)
  local line_count = 1
  local col_count = 1
  for i = 1, idx - 1 do
    col_count = col_count + 1
    if str:sub(i, i) == "\n" then
      line_count = line_count + 1
      col_count = 1
    end
  end
  error( string.format("%s at line %d col %d", msg, line_count, col_count) )
end


local function codepoint_to_utf8(n)
  -- http://scripts.sil.org/cms/scripts/page.php?site_id=nrsi&id=iws-appendixa
  local f = math.floor
  if n <= 0x7f then
    return string.char(n)
  elseif n <= 0x7ff then
    return string.char(f(n / 64) + 192, n % 64 + 128)
  elseif n <= 0xffff then
    return string.char(f(n / 4096) + 224, f(n % 4096 / 64) + 128, n % 64 + 128)
  elseif n <= 0x10ffff then
    return string.char(f(n / 262144) + 240, f(n % 262144 / 4096) + 128,
                       f(n % 4096 / 64) + 128, n % 64 + 128)
  end
  error( string.format("invalid unicode codepoint '%x'", n) )
end


local function parse_unicode_escape(s)
  local n1 = tonumber( s:sub(1, 4),  16 )
  local n2 = tonumber( s:sub(7, 10), 16 )
   -- Surrogate pair?
  if n2 then
    return codepoint_to_utf8((n1 - 0xd800) * 0x400 + (n2 - 0xdc00) + 0x10000)
  else
    return codepoint_to_utf8(n1)
  end
end


local function parse_string(str, i)
  local res = ""
  local j = i + 1
  local k = j

  while j <= #str do
    local x = str:byte(j)

    if x < 32 then
      decode_error(str, j, "control character in string")

    elseif x == 92 then -- `\`: Escape
      res = res .. str:sub(k, j - 1)
      j = j + 1
      local c = str:sub(j, j)
      if c == "u" then
        local hex = str:match("^[dD][89aAbB]%x%x\\u%x%x%x%x", j + 1)
                 or str:match("^%x%x%x%x", j + 1)
                 or decode_error(str, j - 1, "invalid unicode escape in string")
        res = res .. parse_unicode_escape(hex)
        j = j + #hex
      else
        if not escape_chars[c] then
          decode_error(str, j - 1, "invalid escape char '" .. c .. "' in string")
        end
        res = res .. escape_char_map_inv[c]
      end
      k = j + 1

    elseif x == 34 then -- `"`: End of string
      res = res .. str:sub(k, j - 1)
      return res, j + 1
    end

    j = j + 1
  end

  decode_error(str, i, "expected closing quote for string")
end


local function parse_number(str, i)
  local x = next_char(str, i, delim_chars)
  local s = str:sub(i, x - 1)
  local n = tonumber(s)
  if not n then
    decode_error(str, i, "invalid number '" .. s .. "'")
  end
  return n, x
end


local function parse_literal(str, i)
  local x = next_char(str, i, delim_chars)
  local word = str:sub(i, x - 1)
  if not literals[word] then
    decode_error(str, i, "invalid literal '" .. word .. "'")
  end
  return literal_map[word], x
end


local function parse_array(str, i)
  local res = {}
  local n = 1
  i = i + 1
  while 1 do
    local x
    i = next_char(str, i, space_chars, true)
    -- Empty / end of array?
    if str:sub(i, i) == "]" then
      i = i + 1
      break
    end
    -- Read token
    x, i = parse(str, i)
    res[n] = x
    n = n + 1
    -- Next token
    i = next_char(str, i, space_chars, true)
    local chr = str:sub(i, i)
    i = i + 1
    if chr == "]" then break end
    if chr ~= "," then decode_error(str, i, "expected ']' or ','") end
  end
  return res, i
end


local function parse_object(str, i)
  local res = {}
  i = i + 1
  while 1 do
    local key, val
    i = next_char(str, i, space_chars, true)
    -- Empty / end of object?
    if str:sub(i, i) == "}" then
      i = i + 1
      break
    end
    -- Read key
    if str:sub(i, i) ~= '"' then
      decode_error(str, i, "expected string for key")
    end
    key, i = parse(str, i)
    -- Read ':' delimiter
    i = next_char(str, i, space_chars, true)
    if str:sub(i, i) ~= ":" then
      decode_error(str, i, "expected ':' after key")
    end
    i = next_char(str, i + 1, space_chars, true)
    -- Read value
    val, i = parse(str, i)
    -- Set
    res[key] = val
    -- Next token
    i = next_char(str, i, space_chars, true)
    local chr = str:sub(i, i)
    i = i + 1
    if chr == "}" then break end
    if chr ~= "," then decode_error(str, i, "expected '}' or ','") end
  end
  return res, i
end


local char_func_map = {
  [ '"' ] = parse_string,
  [ "0" ] = parse_number,
  [ "1" ] = parse_number,
  [ "2" ] = parse_number,
  [ "3" ] = parse_number,
  [ "4" ] = parse_number,
  [ "5" ] = parse_number,
  [ "6" ] = parse_number,
  [ "7" ] = parse_number,
  [ "8" ] = parse_number,
  [ "9" ] = parse_number,
  [ "-" ] = parse_number,
  [ "t" ] = parse_literal,
  [ "f" ] = parse_literal,
  [ "n" ] = parse_literal,
  [ "[" ] = parse_array,
  [ "{" ] = parse_object,
}


parse = function(str, idx)
  local chr = str:sub(idx, idx)
  local f = char_func_map[chr]
  if f then
    return f(str, idx)
  end
  decode_error(str, idx, "unexpected character '" .. chr .. "'")
end


function json.decode(str)
  if type(str) ~= "string" then
    error("expected argument of type string, got " .. type(str))
  end
  local res, idx = parse(str, next_char(str, 1, space_chars, true))
  idx = next_char(str, idx, space_chars, true)
  if idx <= #str then
    decode_error(str, idx, "trailing garbage")
  end
  return res
end

    return {
        decode = json.decode,
        encode = json.encode
    }
end)()