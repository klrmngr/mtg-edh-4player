--[[
    Land Zone Manager
    Made by Vokerr
    
    SETUP:
    1. Right-click the object to toggle land tracking on/off
    
    The script will automatically find playmat zones from the global data table.
    Works with any 4-player commander setup that uses the standard data structure.
]]

-- Configuration
local CHECK_DELAY = 1.2
local ENABLED = true
local DEBUG_ENABLED = false
local MIN_Z_ROTATION_FACEDOWN = 150

----------------------------------------------------------------------------------
-- MANA SOURCE DATABASE
-- Known cards with correct net yields. Unlisted cards use oracle text parsing.
-- net = actual mana gained after activation costs
-- type: L=land, C=creature, A=artifact, E=enchantment
----------------------------------------------------------------------------------
local MANA_DB = {}
local function db(n,net,c,t) MANA_DB[n:lower()]={net=net,colors=c,type=t or"L"} end
local function d2(n,a,b) db(n,1,{[a]=1,[b]=1}) end
local function d3(n,a,b,c) db(n,1,{[a]=1,[b]=1,[c]=1}) end

-- Basics
db("Plains",1,{W=1}) db("Island",1,{U=1}) db("Swamp",1,{B=1})
db("Mountain",1,{R=1}) db("Forest",1,{G=1}) db("Wastes",1,{C=1})
db("Snow-Covered Plains",1,{W=1}) db("Snow-Covered Island",1,{U=1})
db("Snow-Covered Swamp",1,{B=1}) db("Snow-Covered Mountain",1,{R=1}) db("Snow-Covered Forest",1,{G=1})

-- Original Duals
d2("Tundra","W","U") d2("Underground Sea","U","B") d2("Badlands","B","R") d2("Taiga","R","G") d2("Savannah","G","W")
d2("Scrubland","W","B") d2("Volcanic Island","U","R") d2("Bayou","B","G") d2("Plateau","W","R") d2("Tropical Island","U","G")

-- Shock Lands
d2("Hallowed Fountain","W","U") d2("Watery Grave","U","B") d2("Blood Crypt","B","R")
d2("Stomping Ground","R","G") d2("Temple Garden","G","W") d2("Godless Shrine","W","B")
d2("Steam Vents","U","R") d2("Overgrown Tomb","B","G") d2("Sacred Foundry","W","R") d2("Breeding Pool","U","G")

-- Check Lands
d2("Glacial Fortress","W","U") d2("Drowned Catacomb","U","B") d2("Dragonskull Summit","B","R")
d2("Rootbound Crag","R","G") d2("Sunpetal Grove","G","W") d2("Isolated Chapel","W","B")
d2("Sulfur Falls","U","R") d2("Woodland Cemetery","B","G") d2("Clifftop Retreat","W","R") d2("Hinterland Harbor","U","G")

-- Fast Lands
d2("Seachrome Coast","W","U") d2("Darkslick Shores","U","B") d2("Blackcleave Cliffs","B","R")
d2("Copperline Gorge","R","G") d2("Razorverge Thicket","G","W") d2("Concealed Courtyard","W","B")
d2("Spirebluff Canal","U","R") d2("Blooming Marsh","B","G") d2("Inspiring Vantage","W","R") d2("Botanical Sanctum","U","G")

-- Pain Lands (tap for {C} free, or color + 1 damage)
for _,v in ipairs({
    {"Adarkar Wastes","W","U"},{"Underground River","U","B"},{"Sulfurous Springs","B","R"},
    {"Karplusan Forest","R","G"},{"Brushland","G","W"},{"Caves of Koilos","W","B"},
    {"Shivan Reef","U","R"},{"Llanowar Wastes","B","G"},{"Battlefield Forge","W","R"},{"Yavimaya Coast","U","G"},
}) do db(v[1],1,{[v[2]]=1,[v[3]]=1,C=1}) end

-- Filter Lands (pay hybrid mana -> get 2 colored, NET = 1)
d2("Mystic Gate","W","U") d2("Sunken Ruins","U","B") d2("Graven Cairns","B","R")
d2("Fire-Lit Thicket","R","G") d2("Wooded Bastion","G","W") d2("Fetid Heath","W","B")
d2("Cascade Bluffs","U","R") d2("Twilight Mire","B","G") d2("Rugged Prairie","W","R") d2("Flooded Grove","U","G")

-- Bounce Lands (produce both colors, net = 2)
for _,v in ipairs({
    {"Azorius Chancery","W","U"},{"Dimir Aqueduct","U","B"},{"Rakdos Carnarium","B","R"},
    {"Gruul Turf","R","G"},{"Selesnya Sanctuary","G","W"},{"Orzhov Basilica","W","B"},
    {"Izzet Boilerworks","U","R"},{"Golgari Rot Farm","B","G"},{"Boros Garrison","W","R"},{"Simic Growth Chamber","U","G"},
}) do db(v[1],2,{[v[2]]=1,[v[3]]=1}) end

-- Triomes (Ikoria + New Capenna)
d3("Raugrin Triome","W","U","R") d3("Ketria Triome","U","R","G") d3("Indatha Triome","W","B","G")
d3("Savai Triome","W","B","R") d3("Zagoth Triome","U","B","G")
d3("Spara's Headquarters","G","W","U") d3("Raffine's Tower","W","U","B")
d3("Xander's Lounge","U","B","R") d3("Ziatora's Proving Ground","B","R","G") d3("Jetmir's Garden","R","G","W")

-- Tri-Lands (Shards + Khans)
d3("Arcane Sanctum","W","U","B") d3("Crumbling Necropolis","U","B","R") d3("Jungle Shrine","R","G","W")
d3("Savage Lands","B","R","G") d3("Seaside Citadel","G","W","U")
d3("Mystic Monastery","W","U","R") d3("Nomad Outpost","W","B","R") d3("Opulent Palace","U","B","G")
d3("Sandsteppe Citadel","W","B","G") d3("Frontier Bivouac","U","R","G")

-- Battle / Tango Lands
d2("Prairie Stream","W","U") d2("Sunken Hollow","U","B") d2("Smoldering Marsh","B","R")
d2("Cinder Glade","R","G") d2("Canopy Vista","G","W")

-- Slow Lands (MID/VOW)
d2("Deserted Beach","W","U") d2("Shipwreck Marsh","U","B") d2("Haunted Ridge","B","R")
d2("Rockfall Vale","R","G") d2("Overgrown Farmland","G","W") d2("Shattered Sanctum","W","B")
d2("Stormcarved Coast","U","R") d2("Deathcap Glade","B","G") d2("Sundown Pass","W","R") d2("Dreamroot Cascade","U","G")

-- Reveal Lands + Snarls
d2("Port Town","W","U") d2("Choked Estuary","U","B") d2("Foreboding Ruins","B","R")
d2("Game Trail","R","G") d2("Fortified Village","G","W")
d2("Furycalm Snarl","W","R") d2("Shineshadow Snarl","W","B") d2("Frostboil Snarl","U","R")
d2("Necroblossom Snarl","B","G") d2("Vineglimmer Snarl","U","G")

-- Cycling Duals (Amonkhet)
d2("Irrigated Farmland","W","U") d2("Fetid Pools","U","B") d2("Canyon Slough","B","R")
d2("Sheltered Thicket","R","G") d2("Scattered Groves","G","W")

-- Creature Lands / Manlands
d2("Celestial Colonnade","W","U") d2("Creeping Tar Pit","U","B") d2("Lavaclaw Reaches","B","R")
d2("Raging Ravine","R","G") d2("Stirring Wildwood","G","W") d2("Shambling Vent","W","B")
d2("Wandering Fumarole","U","R") d2("Hissing Quagmire","B","G") d2("Needle Spires","W","R") d2("Lumbering Falls","U","G")

-- Temple / Scry Lands
d2("Temple of Enlightenment","W","U") d2("Temple of Deceit","U","B") d2("Temple of Malice","B","R")
d2("Temple of Abandon","R","G") d2("Temple of Plenty","G","W") d2("Temple of Silence","W","B")
d2("Temple of Epiphany","U","R") d2("Temple of Malady","B","G") d2("Temple of Triumph","W","R") d2("Temple of Mystery","U","G")

-- Utility / Legendary Lands
db("Command Tower",1,{Any=1}) db("City of Brass",1,{Any=1}) db("Mana Confluence",1,{Any=1})
db("Reflecting Pool",1,{Any=1}) db("Exotic Orchard",1,{Any=1}) db("Gemstone Mine",1,{Any=1})
db("Gemstone Caverns",1,{Any=1}) db("Forbidden Orchard",1,{Any=1}) db("Tendo Ice Bridge",1,{Any=1})
db("Path of Ancestry",1,{Any=1}) db("Unclaimed Territory",1,{Any=1}) db("Cavern of Souls",1,{Any=1})
db("Ancient Ziggurat",1,{Any=1}) db("The World Tree",1,{Any=1}) db("Plaza of Heroes",1,{Any=1})
db("Ancient Tomb",2,{C=2}) db("Temple of the False God",2,{C=2}) db("Eldrazi Temple",1,{C=1})
db("Reliquary Tower",1,{C=1}) db("Strip Mine",1,{C=1}) db("Wasteland",1,{C=1})
db("Ghost Quarter",1,{C=1}) db("Field of the Dead",1,{C=1}) db("War Room",1,{C=1})
db("Urza's Saga",1,{C=1}) db("Phyrexian Tower",1,{C=1}) db("Nykthos, Shrine to Nyx",1,{C=1})
db("Castle Ardenvale",1,{W=1}) db("Castle Vantress",1,{U=1}) db("Castle Locthwain",1,{B=1})
db("Castle Embereth",1,{R=1}) db("Castle Garenbrig",1,{G=1})
db("Boseiju, Who Endures",1,{G=1}) db("Otawara, Soaring City",1,{U=1})
db("Eiganjo, Seat of the Empire",1,{W=1}) db("Takenuma, Abandoned Mire",1,{B=1})
db("Sokenzan, Crucible of Defiance",1,{R=1})
db("Maze of Ith",0,{}) db("Gaea's Cradle",1,{G=1}) db("Serra's Sanctum",1,{W=1})
db("Tolarian Academy",1,{U=1}) db("Cabal Coffers",0,{})

-- Signets (pay {1}, T: Add {X}{Y} -> net = 1)
for _,v in ipairs({
    {"Azorius Signet","W","U"},{"Dimir Signet","U","B"},{"Rakdos Signet","B","R"},
    {"Gruul Signet","R","G"},{"Selesnya Signet","G","W"},{"Orzhov Signet","W","B"},
    {"Izzet Signet","U","R"},{"Golgari Signet","B","G"},{"Boros Signet","W","R"},{"Simic Signet","U","G"},
}) do db(v[1],1,{[v[2]]=1,[v[3]]=1},"A") end

-- Talismans (T: Add {C} or color + life loss -> net = 1)
for _,v in ipairs({
    {"Talisman of Progress","W","U"},{"Talisman of Dominance","U","B"},{"Talisman of Indulgence","B","R"},
    {"Talisman of Impulse","R","G"},{"Talisman of Unity","G","W"},{"Talisman of Hierarchy","W","B"},
    {"Talisman of Creativity","U","R"},{"Talisman of Resilience","B","G"},{"Talisman of Conviction","W","R"},
    {"Talisman of Curiosity","U","G"},
}) do db(v[1],1,{[v[2]]=1,[v[3]]=1,C=1},"A") end

-- Mana Rocks
db("Sol Ring",2,{C=2},"A") db("Mana Crypt",2,{C=2},"A") db("Mana Vault",3,{C=3},"A")
db("Grim Monolith",3,{C=3},"A") db("Basalt Monolith",3,{C=3},"A") db("Thran Dynamo",3,{C=3},"A")
db("Gilded Lotus",3,{Any=3},"A") db("Worn Powerstone",2,{C=2},"A") db("Hedron Archive",2,{C=2},"A")
db("Dreamstone Hedron",3,{C=3},"A") db("Arcane Signet",1,{Any=1},"A") db("Chromatic Lantern",1,{Any=1},"A")
db("Commander's Sphere",1,{Any=1},"A") db("Fellwar Stone",1,{Any=1},"A") db("Mind Stone",1,{C=1},"A")
db("Thought Vessel",1,{C=1},"A") db("Prismatic Lens",1,{C=1},"A") db("Coalition Relic",1,{Any=1},"A")
db("Darksteel Ingot",1,{Any=1},"A") db("Firemind Vessel",2,{Any=2},"A") db("Lotus Petal",1,{Any=1},"A")
db("Jeweled Lotus",3,{Any=3},"A") db("Lion's Eye Diamond",3,{Any=3},"A")
db("Chrome Mox",1,{Any=1},"A") db("Mox Diamond",1,{Any=1},"A") db("Mox Opal",1,{Any=1},"A")
db("Mox Amber",1,{Any=1},"A") db("Springleaf Drum",1,{Any=1},"A") db("Paradise Mantle",1,{Any=1},"A")
db("Star Compass",1,{Any=1},"A") db("Coldsteel Heart",1,{Any=1},"A")

-- Mana Dorks (Creatures)
db("Birds of Paradise",1,{Any=1},"C") db("Llanowar Elves",1,{G=1},"C") db("Elvish Mystic",1,{G=1},"C")
db("Fyndhorn Elves",1,{G=1},"C") db("Boreal Druid",1,{C=1},"C") db("Elves of Deep Shadow",1,{B=1},"C")
db("Avacyn's Pilgrim",1,{W=1},"C") db("Noble Hierarch",1,{Any=1},"C") db("Ignoble Hierarch",1,{Any=1},"C")
db("Deathrite Shaman",1,{Any=1},"C") db("Sylvan Caryatid",1,{Any=1},"C") db("Paradise Druid",1,{Any=1},"C")
db("Gilded Goose",1,{Any=1},"C") db("Bloom Tender",1,{Any=1},"C") db("Devoted Druid",1,{G=1},"C")
db("Leafkin Druid",1,{G=1},"C") db("Whisperer of the Wilds",1,{G=1},"C") db("Ilysian Caryatid",1,{Any=1},"C")
db("Priest of Titania",1,{G=1},"C") db("Elvish Archdruid",1,{G=1},"C") db("Joraga Treespeaker",1,{G=1},"C")
db("Somberwald Sage",3,{Any=3},"C") db("Shaman of Forgotten Ways",2,{Any=2},"C")
db("Selvala, Heart of the Wilds",1,{G=1},"C") db("Marwyn, the Nurturer",1,{G=1},"C")
db("Circle of Dreams Druid",1,{G=1},"C") db("Faeburrow Elder",1,{Any=1},"C")
db("Rattleclaw Mystic",1,{Any=1},"C") db("Druid of the Anima",1,{Any=1},"C")
db("Katilda, Dawnhart Prime",1,{Any=1},"C") db("Sanctum Weaver",1,{Any=1},"C")

-- Mana Enchantments
db("Utopia Sprawl",1,{Any=1},"E") db("Wild Growth",1,{G=1},"E") db("Fertile Ground",1,{Any=1},"E")

-- Zone data
local zones = {}
local PLAYER_COLORS = {"White", "Red", "Blue", "Yellow", "Green", "Purple", "Pink", "Orange", "Teal", "Brown", "Grey", "Black"}

-- Color constants
local COLOR_WHITE = "[FFFFFF]"
local COLOR_GREEN = "[82FF4C]"
local COLOR_RED = "[F44336]"
local PREFIX = "[b][Land Zones][/b] "

----------------------------------------------------------------------------------
-- INITIALIZATION
----------------------------------------------------------------------------------

function onLoad(saved_data)
    if saved_data ~= "" then
        local loaded_data = JSON.decode(saved_data)
        ENABLED = loaded_data.enabled or true
    end
    
    -- Add context menu
    self.addContextMenuItem("Toggle Land Zones", ToggleLandZones)
    self.addContextMenuItem("Toggle Debug Logs", ToggleDebugLogs)
    
    if ENABLED then
        Wait.time(function()
            findAndInitializeZones()
        end, 1)
    else
        printToAll(COLOR_WHITE .. PREFIX .. "Land Zones are " .. COLOR_RED .. "disabled", "White")
    end
end

function onSave()
    local data_to_save = {enabled = ENABLED}
    return JSON.encode(data_to_save)
end

function onDestroy()
    -- Clean up all zone buttons
    for guid, zone in pairs(zones) do
        if zone.object ~= nil then
            zone.object.clearButtons()
        end
    end
    printToAll(COLOR_WHITE .. PREFIX .. "Unloaded Land Zone Manager", "White")
end

function findAndInitializeZones()
    zones = {}
    
    -- Get the global data table that contains playmat zones
    local data = Global.getTable('data')
    if data == nil then
        printToAll(COLOR_WHITE .. PREFIX .. COLOR_RED .. "Error: Could not find global data table", "White")
        return
    end
    
    -- Initialize zones for each player color
    for _, playerColor in pairs(Player.getAvailableColors()) do
        if data[playerColor] ~= nil and data[playerColor]["playmat"] ~= nil then
            local playmatZone = data[playerColor]["playmat"]
            initializeZone(playmatZone, playerColor)
            if DEBUG_ENABLED then
                print("Found and initialized zone for: " .. playerColor)
            end
        end
    end
    
    local count = tableCount(zones)
    printToAll(COLOR_WHITE .. PREFIX .. "Loaded " .. COLOR_GREEN .. count .. COLOR_WHITE .. " land zones", "White")
    
    if DEBUG_ENABLED then
        for guid, zone in pairs(zones) do
            print("  - Zone for " .. zone.color .. " (GUID: " .. guid .. ")")
        end
    end
end

function initializeZone(zoneObj, playerColor)
    local guid = zoneObj.getGUID()
    
    zones[guid] = {
        object = zoneObj,
        color = playerColor,
        landPlayedThisTurn = false,
        cardCount = 0,
        knownObjects = {},
        totalMana = {W=0, U=0, B=0, R=0, G=0, C=0, Any=0},
        activeMana = {W=0, U=0, B=0, R=0, G=0, C=0, Any=0},
        prevTapState = nil,
        manaSpentThisTurn = {W=0, U=0, B=0, R=0, G=0, C=0, Any=0},
        manaSpentNet = 0
    }
    
    -- Make zone invisible and non-interactable
    zoneObj.setColorTint({0, 0, 0, 0})
    zoneObj.interactable = false
    
    createButtons(guid)
    
    -- Populate initial state
    for _, obj in ipairs(zoneObj.getObjects()) do
        if isValidCard(obj) then
            zones[guid].knownObjects[obj.getGUID()] = true
        end
    end
    
    -- Check turn state
    if Turns and Turns.turn_color then
        checkTurnState(guid, Turns.turn_color)
    end
    
    -- Start mana update loop
    Wait.time(function()
        if ENABLED and zones[guid] then
            updateZoneStats(guid)
        end
    end, 0.5, -1)
end

----------------------------------------------------------------------------------
-- CONTEXT MENU
----------------------------------------------------------------------------------

function ToggleLandZones(playerColor)
    ENABLED = not ENABLED
    
    if ENABLED then
        printToAll(COLOR_WHITE .. PREFIX .. COLOR_GREEN .. "enabled " .. COLOR_WHITE .. "Land Zones", "White")
        findAndInitializeZones()
    else
        printToAll(COLOR_WHITE .. PREFIX .. COLOR_RED .. "disabled " .. COLOR_WHITE .. "Land Zones", "White")
        -- Clear all buttons
        for guid, zone in pairs(zones) do
            if zone.object ~= nil then
                zone.object.clearButtons()
            end
        end
        zones = {}
    end
end

function ToggleDebugLogs(playerColor)
    DEBUG_ENABLED = not DEBUG_ENABLED
    
    if DEBUG_ENABLED then
        printToAll(COLOR_WHITE .. PREFIX .. COLOR_GREEN .. "enabled " .. COLOR_WHITE .. "Debug Logs", "White")
    else
        printToAll(COLOR_WHITE .. PREFIX .. COLOR_RED .. "disabled " .. COLOR_WHITE .. "Debug Logs", "White")
    end
end

----------------------------------------------------------------------------------
-- UI CREATION
----------------------------------------------------------------------------------

function createButtons(zoneGuid)
    local zone = zones[zoneGuid]
    if not zone then return end
    
    local zoneObj = zone.object
    zoneObj.clearButtons()
    
    local zoneScale = zoneObj.getScale()
    local textScale = {
        x = 1 / zoneScale.x,
        y = 1 / zoneScale.y,
        z = 1 / zoneScale.z
    }
    
    -- Determine button position based on player color
    -- White and Yellow: buttons on right side
    -- Blue and Red: buttons on left side
    local basePosX = 0.5
    if zone.color == "Blue" or zone.color == "Red" then
        basePosX = -0.5
    end
    
    local heightOffset = 0.10
    local basePosZ = 0.6      -- Moved lower (further forward)
    local spacing = 0.05       -- Reduced spacing between buttons
    
    -- Index 0: Available Mana
    zoneObj.createButton({
        click_function = "none",
        function_owner = self,
        label          = "Available Mana: ...",
        position       = {basePosX, heightOffset, basePosZ},
        scale          = textScale,
        width          = 0,
        height         = 0,
        font_size      = 250, 
        font_color     = {1, 1, 1}
    })
    
    -- Index 1: Pool Breakdown
    zoneObj.createButton({
        click_function = "none",
        function_owner = self,
        label          = "Pool: ...",
        position       = {basePosX, heightOffset, basePosZ + spacing},
        scale          = textScale,
        width          = 0,
        height         = 0,
        font_size      = 250,
        font_color     = {1, 1, 1}
    })
    
    -- Index 2: Card Count
    zoneObj.createButton({
        click_function = "none",
        function_owner = self,
        label          = "0 Cards in Land Zone",
        position       = {basePosX, heightOffset, basePosZ + (spacing * 2)},
        scale          = textScale,
        width          = 0,
        height         = 0,
        font_size      = 250,
        font_color     = {1, 1, 1}
    })
    
    -- Index 3: Status
    zoneObj.createButton({
        click_function = "none",
        function_owner = self,
        label          = "Hasn't played Land Yet",
        position       = {basePosX, heightOffset, basePosZ + (spacing * 3)}, 
        scale          = textScale,
        width          = 0,
        height         = 0,
        font_size      = 250,
        font_color     = {1, 0.5, 0}
    })

    -- Index 4: Mana Spent This Turn (smaller text)
    zoneObj.createButton({
        click_function = "none",
        function_owner = self,
        label          = "",
        position       = {basePosX, heightOffset, basePosZ + (spacing * 4)},
        scale          = textScale,
        width          = 0,
        height         = 0,
        font_size      = 180,
        font_color     = {0.7, 0.7, 0.5}
    })
end

----------------------------------------------------------------------------------
-- TURN LOGIC
----------------------------------------------------------------------------------

function onPlayerTurnStart(player_color_start, player_color_previous)
    if not ENABLED then return end
    
    if DEBUG_ENABLED then
        print("Turn changed: " .. (player_color_previous or "None") .. " -> " .. (player_color_start or "None"))
    end
    
    for guid, zone in pairs(zones) do
        checkTurnState(guid, player_color_start)
    end
end

function checkTurnState(zoneGuid, currentTurnColor)
    local zone = zones[zoneGuid]
    if not zone then return end
    
    if currentTurnColor == zone.color then
        zone.landPlayedThisTurn = false
        zone.manaSpentThisTurn = {W=0, U=0, B=0, R=0, G=0, C=0, Any=0}
        zone.manaSpentNet = 0
        zone.prevTapState = nil
        local rgb = stringColorToRGB(zone.color)
        zone.object.setColorTint({rgb[1], rgb[2], rgb[3], 0.4})
    else
        zone.object.setColorTint({0, 0, 0, 0})
    end
    
    updateStatusButton(zoneGuid)
end

----------------------------------------------------------------------------------
-- OBJECT TRACKING
----------------------------------------------------------------------------------

function onObjectEnterScriptingZone(zone, object)
    if not ENABLED then return end
    
    local zoneGuid = zone.getGUID()
    local zoneData = zones[zoneGuid]
    
    if zoneData and isValidCard(object) then
        if not zoneData.knownObjects[object.getGUID()] then
            Wait.time(function() verifyObjectStayed(zoneGuid, object) end, CHECK_DELAY)
        end
    end
end

function onObjectLeaveScriptingZone(zone, object)
    if not ENABLED then return end
    
    local zoneGuid = zone.getGUID()
    local zoneData = zones[zoneGuid]
    
    if zoneData then
        local guid = object.getGUID()
        if zoneData.knownObjects[guid] then
            zoneData.knownObjects[guid] = nil
            updateZoneStats(zoneGuid)
        end
    end
end

function onObjectDrop(player_color, dropped_object)
    if not ENABLED then return end
    if not isValidCard(dropped_object) then return end
    
    for zoneGuid, zoneData in pairs(zones) do
        local objs = zoneData.object.getObjects()
        for _, obj in ipairs(objs) do
            if obj == dropped_object then
                if not zoneData.knownObjects[obj.getGUID()] then
                    Wait.time(function() verifyObjectStayed(zoneGuid, obj) end, CHECK_DELAY)
                end
                break
            end
        end
    end
end

function verifyObjectStayed(zoneGuid, object)
    local zoneData = zones[zoneGuid]
    if not zoneData then return end
    if object == nil or object.isDestroyed() then return end
    
    local stillHere = false
    local guid = object.getGUID()
    
    for _, obj in ipairs(zoneData.object.getObjects()) do
        if obj.getGUID() == guid then
            stillHere = true
            break
        end
    end
    
    local isHeld = object.held_by_color ~= nil
    
    if stillHere and not isHeld then
        if not zoneData.knownObjects[guid] then
            zoneData.knownObjects[guid] = true
            processValidPlacement(zoneGuid, object)
            updateZoneStats(zoneGuid)
        end
    elseif stillHere and isHeld then
        Wait.time(function() verifyObjectStayed(zoneGuid, object) end, 0.5)
    end
end

function processValidPlacement(zoneGuid, object)
    local zoneData = zones[zoneGuid]
    if not zoneData then return end
    
    local currentTurn = Turns and Turns.turn_color or "None"
    
    -- Track first land drop only on owner's turn (silently)
    if currentTurn == zoneData.color and not zoneData.landPlayedThisTurn then
        zoneData.landPlayedThisTurn = true
        updateStatusButton(zoneGuid)
    end
end

----------------------------------------------------------------------------------
-- MANA TRACKING
----------------------------------------------------------------------------------

-- Detect if a card is a land type
function detectLandType(obj, lowerName, desc)
    for _, tag in ipairs(obj.getTags()) do
        if tag == "Land" then return true end
    end
    local entry = MANA_DB[lowerName]
    if entry then return entry.type == "L" end
    local gmNotes = obj.getGMNotes() or ""
    local combined = " " .. lowerName .. " " .. (desc or ""):lower() .. " " .. gmNotes:lower() .. " "
    return combined:find("%Aland%A") ~= nil
end

-- Track when a mana source gets tapped this turn
function trackManaSpent(zoneData, dbEntry, colors, netYield)
    local spent = zoneData.manaSpentThisTurn
    local c = dbEntry and dbEntry.colors or colors or {}
    local colorCount = 0
    local singleCol = nil
    for col, val in pairs(c) do
        if val > 0 and col ~= "Any" and col ~= "C" then
            colorCount = colorCount + 1
            singleCol = col
        end
    end
    if c.Any and c.Any > 0 then
        spent.Any = spent.Any + netYield
    elseif colorCount == 1 then
        spent[singleCol] = spent[singleCol] + netYield
    elseif colorCount > 1 then
        spent.Any = spent.Any + netYield
    else
        spent.C = spent.C + netYield
    end
    zoneData.manaSpentNet = zoneData.manaSpentNet + netYield
end

function checkTapped(obj, zoneObj)
    local rot = obj.getRotation()
    local selfRot = zoneObj.getRotation()
    local diff = math.abs(rot.y - selfRot.y) % 360
    return (diff > 45 and diff < 135) or (diff > 225 and diff < 315)
end

-- Text-based mana parsing (fallback when card not in MANA_DB)
function parseCardMana(obj)
    local desc = (obj.getDescription() or ""):gsub("\r\n", "\n")
    local colors = {W=0, U=0, B=0, R=0, G=0, C=0, Any=0}
    local produces = false
    local maxYield = 0

    local function countSym(text, sym)
        local _, n = text:gsub(sym, "")
        return n
    end

    for line in desc:gmatch("[^\n]+") do
        local addIdx = line:find("Add ")
        local colonIdx = line:find(":")
        if addIdx or colonIdx then
            local rel = line
            if addIdx then
                rel = line:sub(addIdx)
            elseif colonIdx then
                rel = line:sub(colonIdx + 1)
            end

            -- Detect activation cost before the colon (for filter lands, signets, etc.)
            local activationCost = 0
            if colonIdx and colonIdx > 1 then
                local costPart = line:sub(1, colonIdx - 1)
                for sym in costPart:gmatch("{(%d+)}") do
                    activationCost = activationCost + tonumber(sym)
                end
                for _ in costPart:gmatch("{[WUBRGC]}") do
                    activationCost = activationCost + 1
                end
            end

            local w = countSym(rel, "{W}")
            local u = countSym(rel, "{U}")
            local b = countSym(rel, "{B}")
            local r = countSym(rel, "{R}")
            local g = countSym(rel, "{G}")
            local c = countSym(rel, "{C}")

            if w > 0 then colors.W = math.max(colors.W, w); produces = true end
            if u > 0 then colors.U = math.max(colors.U, u); produces = true end
            if b > 0 then colors.B = math.max(colors.B, b); produces = true end
            if r > 0 then colors.R = math.max(colors.R, r); produces = true end
            if g > 0 then colors.G = math.max(colors.G, g); produces = true end
            if c > 0 then colors.C = math.max(colors.C, c); produces = true end

            local lineYield = 0
            local lower = rel:lower()
            if lower:find("one mana of any") or lower:find("mana of any color") then
                colors.Any = math.max(colors.Any, 1); produces = true; lineYield = 1
            elseif lower:find("two mana of any") then
                colors.Any = math.max(colors.Any, 2); produces = true; lineYield = 2
            elseif lower:find("three mana of any") then
                colors.Any = math.max(colors.Any, 3); produces = true; lineYield = 3
            else
                if rel:find(" or ") then
                    lineYield = 1
                else
                    lineYield = w + u + b + r + g + c
                end
            end

            -- Subtract activation cost for net yield
            lineYield = math.max(0, lineYield - activationCost)
            maxYield = math.max(maxYield, lineYield)
        end
    end

    return colors, produces, maxYield
end

function updateZoneStats(zoneGuid)
    local zoneData = zones[zoneGuid]
    if not zoneData then return end

    local objects = zoneData.object.getObjects()
    local tMana = {W=0, U=0, B=0, R=0, G=0, C=0, Any=0}
    local aMana = {W=0, U=0, B=0, R=0, G=0, C=0, Any=0}
    local cCount = 0
    local availCount = 0
    local newTapState = {}

    for _, obj in ipairs(objects) do
        if zoneData.knownObjects[obj.getGUID()] then
            if obj.tag == "Card" then
                local rotation = obj.getRotation()
                local isFaceDown = rotation.z > MIN_Z_ROTATION_FACEDOWN

                if not isFaceDown then
                    local name = obj.getName() or ""
                    local trimmed = name:match("([^\n]+)") or name
                    local lowerName = trimmed:lower()
                    local desc = obj.getDescription() or ""

                    -- Database lookup first
                    local entry = MANA_DB[lowerName]
                    local colors, net, isManaSource, isLand

                    if entry then
                        colors = {}
                        for k,v in pairs(entry.colors) do colors[k] = v end
                        net = entry.net
                        isManaSource = (net > 0)
                        isLand = (entry.type == "L")
                    else
                        -- Fallback to text parsing
                        local parsed, produces, maxY = parseCardMana(obj)
                        colors = parsed
                        net = maxY
                        isManaSource = produces
                        isLand = detectLandType(obj, lowerName, desc)
                    end

                    if isLand or isManaSource then
                        if isLand then cCount = cCount + 1 end
                        if DEBUG_ENABLED then
                            local src = entry and "DB" or "Parse"
                            print(("[%s] %s | net=%d land=%s"):format(src, trimmed, net, tostring(isLand)))
                        end

                        local isTapped = checkTapped(obj, zoneData.object)
                        local objGuid = obj.getGUID()
                        newTapState[objGuid] = {tapped = isTapped, net = net, colors = colors}

                        for col, val in pairs(colors) do
                            if val > 0 then
                                tMana[col] = tMana[col] + val
                                if not isTapped then
                                    aMana[col] = aMana[col] + val
                                end
                            end
                        end

                        if isManaSource and not isTapped then
                            availCount = availCount + net
                        end

                        -- Track mana spent: source went untapped -> tapped
                        if zoneData.prevTapState then
                            local prev = zoneData.prevTapState[objGuid]
                            if prev and not prev.tapped and isTapped then
                                trackManaSpent(zoneData, entry, colors, net)
                            end
                        end
                    end
                elseif DEBUG_ENABLED then
                    print("Skipping face-down: " .. (obj.getName() or "?"))
                end
            elseif obj.tag == "Deck" then
                cCount = cCount + math.abs(obj.getQuantity())
            end
        end
    end

    zoneData.prevTapState = newTapState
    zoneData.cardCount = cCount
    zoneData.totalMana = tMana
    zoneData.activeMana = aMana
    updateUI(zoneGuid, availCount)
end

----------------------------------------------------------------------------------
-- UI UPDATES
----------------------------------------------------------------------------------

function updateUI(zoneGuid, availableCount)
    local zoneData = zones[zoneGuid]
    if not zoneData then return end

    local cCode = {W = "[ffffff]", U = "[3366ff]", B = "[888888]", R = "[ff3333]", G = "[33ff33]", C = "[cccccc]", Any = "[ff00ff]"}
    local order = {"Any","W","U","B","R","G","C"}

    local function formatManaString(manaTable)
        local parts = {}
        for _, col in ipairs(order) do
            if manaTable[col] and manaTable[col] > 0 then
                table.insert(parts, cCode[col] .. manaTable[col] .. col .. "[-]")
            end
        end
        return #parts > 0 and table.concat(parts, " ") or "None"
    end

    local zoneObj = zoneData.object

    zoneObj.editButton({index = 0, label = "Available Mana: " .. (availableCount or 0) .. " (" .. formatManaString(zoneData.activeMana) .. ")"})
    zoneObj.editButton({index = 1, label = "Pool: " .. formatManaString(zoneData.totalMana)})
    zoneObj.editButton({index = 2, label = zoneData.cardCount .. " Lands / Mana Sources"})

    -- Mana spent this turn (button index 4, smaller text)
    if zoneData.manaSpentNet > 0 then
        zoneObj.editButton({index = 4, label = "Spent: " .. zoneData.manaSpentNet .. " (" .. formatManaString(zoneData.manaSpentThisTurn) .. ")"})
    else
        zoneObj.editButton({index = 4, label = ""})
    end
end

function updateStatusButton(zoneGuid)
    local zoneData = zones[zoneGuid]
    if not zoneData then return end
    
    local currentTurn = Turns and Turns.turn_color or "None"
    
    if currentTurn == zoneData.color then
        if not zoneData.landPlayedThisTurn then
            zoneData.object.editButton({index = 3, label = "Hasn't played Land Yet"})
        else
            zoneData.object.editButton({index = 3, label = "Land played this turn"})
        end
    else
        zoneData.object.editButton({index = 3, label = ""})
    end
end

----------------------------------------------------------------------------------
-- UTILITY FUNCTIONS
----------------------------------------------------------------------------------

function tableCount(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

function isValidCard(obj)
    return obj.tag == "Card" or obj.tag == "Deck"
end

function stringColorToRGB(colorName)
    local colors = {
        White = {1, 1, 1},
        Brown = {0.443, 0.231, 0.09},
        Red = {0.856, 0.1, 0.094},
        Orange = {0.956, 0.392, 0.113},
        Yellow = {0.905, 0.898, 0.172},
        Green = {0.192, 0.701, 0.168},
        Teal = {0.129, 0.694, 0.607},
        Blue = {0.118, 0.53, 1},
        Purple = {0.627, 0.125, 0.941},
        Pink = {0.96, 0.439, 0.807},
        Grey = {0.5, 0.5, 0.5},
        Black = {0.25, 0.25, 0.25}
    }
    return colors[colorName] or {1, 1, 1}
end

function none() end