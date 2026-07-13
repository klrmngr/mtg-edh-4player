-- Main functionality
function onload(saved)
	restoreSettings(saved)
	buildDataStructure()
	registerObjectGUIDs()
	buildTableButtons()
	addZoneContextMenus()
	for _, guid in pairs({ "cb1610", "a7a029", "4c02f8", "a3e6a8", "9c553c", "eb479b", "3d4319", "540e21" }) do
		pcall(function()
			getObjectFromGUID(guid).interactable = false
		end)
	end
	Wait.frames(function()
		for _, guid in pairs({ "02e062", "de4346", "d936a8", "b93b40" }) do
			pcall(function()
				getObjectFromGUID(guid).interactable = false
			end)
		end
	end, 5)

	-- flip hands on load
	Hands.disable_unused = false
	Wait.condition(function()
		local Zones = Encoder.call("APIlistZones", {})
		for guid, zone in pairs(Zones) do
			local objs = getObjectFromGUID(guid).getObjects()
			for _, obj in pairs(objs) do
				if obj.type == "Card" then
					local rot = obj.getRotation()
					rot[3] = 180
					obj.setRotation(rot)
				end
			end
		end
	end, function()
		return Encoder ~= nil
	end)

	-- 4pl specific vars
	revealNrow = 12
	revealUp = 15.5
	revealUpS = 3.1
	revealRi = 1.5
	exileRot = -180
	gravFor = -4.14

	spawnPatchNotesButton()
	checkForUpdate()
	spawnLandTrackerText()
	spawnKeepButtons()
	initFetchlands()
end

-- Ensure data structure exists
function buildDataStructure()
	data = {
		White = { deck = nil },
		Red = { deck = nil },
		Yellow = { deck = nil },
		Blue = { deck = nil },
	}
end

-- Get pointers to in-game objects so we can script them
function registerObjectGUIDs()
	data["White"]["libraryZone"] = getObjectFromGUID("166036")
	data["Red"]["libraryZone"] = getObjectFromGUID("2365d0")
	data["Yellow"]["libraryZone"] = getObjectFromGUID("033b34")
	data["Blue"]["libraryZone"] = getObjectFromGUID("c04462")

	data["White"]["graveyard"] = getObjectFromGUID("68549d")
	data["Red"]["graveyard"] = getObjectFromGUID("07dd80")
	data["Yellow"]["graveyard"] = getObjectFromGUID("8b439a")
	data["Blue"]["graveyard"] = getObjectFromGUID("debc40")

	data["White"]["playmat"] = getObjectFromGUID("8b3401")
	data["Red"]["playmat"] = getObjectFromGUID("c20e3f")
	data["Yellow"]["playmat"] = getObjectFromGUID("129eaa")
	data["Blue"]["playmat"] = getObjectFromGUID("56cd9d")

	-- dedicated land scripting zone on each playmat (where lands are played)
	data["White"]["landZone"] = getObjectFromGUID("c24ef0")
	data["Red"]["landZone"] = getObjectFromGUID("772714")
	data["Yellow"]["landZone"] = getObjectFromGUID("00f87d")
	data["Blue"]["landZone"] = getObjectFromGUID("e63cad")

	-- command-zone scripting zones (one per player), used by the reset button to
	-- snapshot/restore commanders
	data["White"]["commandZone"] = getObjectFromGUID("8fc485")
	data["Red"]["commandZone"] = getObjectFromGUID("750cd5")
	data["Yellow"]["commandZone"] = getObjectFromGUID("c451cd")
	data["Blue"]["commandZone"] = getObjectFromGUID("879cc5")

	-- exile scripting zones (one per player); the reset button clears these too
	data["White"]["exileZone"] = getObjectFromGUID("d614cb")
	data["Red"]["exileZone"] = getObjectFromGUID("878032")
	data["Yellow"]["exileZone"] = getObjectFromGUID("ee5024")
	data["Blue"]["exileZone"] = getObjectFromGUID("bc8e3c")

	data["White"]["mulliganButton"] = getObjectFromGUID("3b07ae")
	data["Red"]["mulliganButton"] = getObjectFromGUID("c53ac6")
	data["Yellow"]["mulliganButton"] = getObjectFromGUID("47645d")
	data["Blue"]["mulliganButton"] = getObjectFromGUID("e0a3bc")

	data["White"]["untapButton"] = getObjectFromGUID("18fb5d")
	data["Red"]["untapButton"] = getObjectFromGUID("86e447")
	data["Yellow"]["untapButton"] = getObjectFromGUID("1f3e4a")
	data["Blue"]["untapButton"] = getObjectFromGUID("e2f7ae")

	data["White"]["drawButton"] = getObjectFromGUID("26775a")
	data["Red"]["drawButton"] = getObjectFromGUID("885f49")
	data["Yellow"]["drawButton"] = getObjectFromGUID("305c12")
	data["Blue"]["drawButton"] = getObjectFromGUID("b49d50")

	data["White"]["scryButton"] = getObjectFromGUID("614515")
	data["Red"]["scryButton"] = getObjectFromGUID("ffa67c")
	data["Yellow"]["scryButton"] = getObjectFromGUID("8a4c8b")
	data["Blue"]["scryButton"] = getObjectFromGUID("4e19c8")

	data["White"]["millButton"] = getObjectFromGUID("57914a")
	data["Red"]["millButton"] = getObjectFromGUID("da5d0d")
	data["Yellow"]["millButton"] = getObjectFromGUID("67b4a5")
	data["Blue"]["millButton"] = getObjectFromGUID("d06889")

	data["White"]["revealButton"] = getObjectFromGUID("d67eb4")
	data["Red"]["revealButton"] = getObjectFromGUID("0ad181")
	data["Yellow"]["revealButton"] = getObjectFromGUID("59ab68")
	data["Blue"]["revealButton"] = getObjectFromGUID("c489e1")

	-- life trackers identify their owner via their Description (a colour name)
	for _, guid in ipairs({ "23e485", "37e533", "395037", "448880" }) do
		local tracker = getObjectFromGUID(guid)
		if tracker ~= nil then
			local owner = tracker.getDescription()
			if data[owner] ~= nil then
				data[owner]["lifeTracker"] = tracker
			end
		end
	end

	-- Commander-damage trackers grouped by the player who *receives* the damage.
	-- A tracker's Description is its *source* colour (the dealer), not the
	-- recipient -- a player's own board holds one tracker per opponent, so the
	-- recipient is the colour missing from that cluster. The GUID lists below
	-- capture that recipient -> trackers mapping.
	data["White"]["commanderDamage"] = { "0f6598", "6b6e1f", "b748df" }
	data["Red"]["commanderDamage"] = { "4bfa09", "95eb63", "d5907a" }
	data["Yellow"]["commanderDamage"] = { "45331a", "484c38", "906d4b" }
	data["Blue"]["commanderDamage"] = { "8d172a", "bfcf4a", "f43e61" }
end

props = {
	White = {
		spawns = {
			main = { posX = "25.5", posZ = "-5", rotY = "180" },
			part = { posX = "22.5", posZ = "-5", rotY = "180" },
		},
	},

	Red = {
		spawns = {
			main = { posX = "-25.5", posZ = "-5", rotY = "180" },
			part = { posX = "-22.5", posZ = "-5", rotY = "180" },
		},
	},

	Yellow = {
		spawns = {
			main = { posX = "-25.5", posZ = "5", rotY = "0" },
			part = { posX = "-22.5", posZ = "5", rotY = "0" },
		},
	},

	Blue = {
		spawns = {
			main = { posX = "25.5", posZ = "5", rotY = "0" },
			part = { posX = "22.5", posZ = "5", rotY = "0" },
		},
	},
}

deckDirs = { White = -1, Red = 1, Yellow = -1, Blue = 1 }

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function onPlayerDisconnect(player) -- flip cards in hand if disconnected
	for handInd = 1, player.getHandCount() do
		objs = player.getHandObjects(handInd)
		for _, obj in pairs(objs) do
			local rot = obj.getRotation()
			rot[3] = 180
			obj.setRotation(rot)
		end
	end
end

