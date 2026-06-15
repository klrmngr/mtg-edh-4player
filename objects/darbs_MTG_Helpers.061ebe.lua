-- https://steamcommunity.com/sharedfiles/filedetails/?id=3529879914
-- created 7/19/2025
-- updated 7/28/2025
--
-- todo: 
-- remove lands from KVP_LANDS_PLAYED_GUIDS when entering graveyard zone, not leaving play zone
-- draws per turn?
-- propaganda/similar?
--
-- no touch below
--
-- variables
do
TRACK_LAND_PLAYS = true
DEBUG_ENABLED = false
MIN_Z_ROTATION_FACEDOWN = 150
--
PLAY_ZONE_GUIDS_COLORS = { 
	-- ["guid"] = "[color]" hex color wrapped in brackets for bbcode
}
PLAYER_COLORS_GUIDS = { 
	-- ["color"] = "guid"
}
--
PAT_LAND1 = "%s(Land)%s"
PAT_LAND2 = "%s(Basic Land)%s"
PAT_LAND_FETCH = {
	["PAT_BASIC_FETCH"] = "(search your library for a basic)",
	["PAT_SWAMP_FETCH"] = "(search your library for a swamp)",
	["PAT_MNTAN_FETCH"] = "(search your library for a mountain)",
	["PAT_FORST_FETCH"] = "(search your library for a forest)",
	["PAT_ISLND_FETCH"] = "(search your library for a island)",
	["PAT_PLAIN_FETCH"] = "(search your library for a plains)",
}
KVP_LANDS_PLAYED_TURN = { 
	-- ["guid"] = (int)landsPlayed (resets on turn start)
}
KVP_LANDS_PLAYED_GUIDS = {
	-- ["guid"] = { "land guid1", "land guid2" }
}
--
PAT_CHECK_UPKP = "%s(upkeep)[%p%s]"
PAT_CHECK_DRAW = "%s(draw)[%p%s]"
PAT_CHECK_PRECMB = "%s(precombat)[%p%s]"
PAT_CHECK_CMB = "%s(combat)[%p%s]"
PAT_CHECK_END = "%s(end)[%p%s]"
--
PAT_UPKP = {
	["PAT_MY_UPKP"] = "(beginning of your upkeep)",
	["PAT_PLY_UPKP"] = "(each player's upkeep)",
	["PAT_OPP_UPKP"] = "(each opponent's upkeep)",
}
KVP_UPKP = {
-- ["card guid"] = "color coded card name"
}
--
PAT_DRAW = {
	["PAT_MY_DRAW"] = "(beginning of your draw)",
	["PAT_PLY_DRAW"] = "(each player's draw)",
	["PAT_OPP_DRAW"] = "(each opponent's draw)",
}
KVP_DRAW = {}
--
PAT_PRECMB = {
	["PAT_MY_PRECMB"] = "(beginning of your precombat)",
	["PAT_PLY_PRECMB"] = "(each player's precombat)",
}
KVP_PRECMB = {}
--
PAT_CMB = "(beginning of combat)"
KVP_CMB = {}
--
PAT_END = { 
	["PAT_MY_END"] = "(beginning of your end)",
	["PAT_PLY_END1"] = "(each player's end step)",
	["PAT_PLY_END2"] = "(end of each player's turn)",
	["PAT_OPP_END"] = "(each opponent's end step)",
}
KVP_END = {}
--
ERROR_DESC = "[NO ERROR SET]"
--
HELP_MESSAGE_LANDS = "use 'land-1' and 'land+1' to fix errors"
--
PREFIX_PLS_DONT = "[b][darbs][/b] "
PREFIX_DEBUG = "[b][debug][/b] "
PREFIX_LAND = "[b][Land][/b] "
--
COLOR_WHITE = "[FFFFFF]"
COLOR_GREY = "[C0C0C0]"
COLOR_GREEN = "[82FF4C]"
COLOR_RED = "[F44336]"
COLOR_HIGHLIGHT = "Pink"
--
HIGHLIGHT_DURATION = 10
--
end
--
-- STARTUP EVENTS
function onLoad(_state)
	if(DEBUG_ENABLED == true) then
		printToAll(PREFIX_DEBUG .. "logs are enabled", "White")
		if(TRACK_LAND_PLAYS == true) then
			printToAll(PREFIX_DEBUG .. "track land plays is enabled", "White")
		else
			printToAll(PREFIX_DEBUG .. "track land plays is disabled", "White")
		end
	end
	
	if(SetupPlayerTables() == false) then
		printToAll(PREFIX_PLS_DONT .. "Couldn't load [b]MTG Helper[/b] due to " .. ERROR_DESC, "White")
		return
	end
	if(ValidateZoneGUIDs() == false) then
		printToAll(PREFIX_PLS_DONT .. "Couldn't load [b]MTG Helper[/b] due to " .. ERROR_DESC, "White")
		return
	end
	
	PREFIX_PLS_DONT = COLOR_WHITE .. PREFIX_PLS_DONT
	HELP_MESSAGE_LANDS = COLOR_GREY .. HELP_MESSAGE_LANDS
	HELP_MESSAGE_LANDS = PREFIX_PLS_DONT .. HELP_MESSAGE_LANDS
	
	if(TRACK_LAND_PLAYS == true) then
		SetupLandTables()
	end
	SetNotes()
	
    self.addContextMenuItem("Toggle Land Tracking", ToggleLandTracking)
    self.addContextMenuItem("Toggle Debug Logs", ToggleDebugLogging)
	
	printToAll(PREFIX_PLS_DONT .. "Loaded [b]MTG Helper[/b]", "White")
	if(TRACK_LAND_PLAYS == true) then
		printToAll(PREFIX_PLS_DONT .. "Land Tracking " .. COLOR_WHITE .. "is " .. COLOR_GREEN .. "enabled\n" .. HELP_MESSAGE_LANDS, "White")
	else
		printToAll(PREFIX_PLS_DONT .. "Land Tracking " .. COLOR_WHITE .. "is " .. COLOR_RED .. "disabled", "White")
	end
end
function onDestroy()
	if(ERROR_FLAGGED == true) then
		return
	end
	Notes.setNotes("")
	printToAll(PREFIX_PLS_DONT .. "Unloaded MTG Helper", "White")
end
--
-- RUNTIME EVENTS
function onChat(message, sender)
	if(ERROR_FLAGGED == true) then
		return
	end
	local _PlayerColor = sender.color
	if(ValidatePlayerColor(_PlayerColor) == false) then
		if(DEBUG_ENABLED) then
			printToAll(PREFIX_DEBUG .. "message was not from a tracked color", "White")
		end
		return
	end
	
	local _zoneGUID = PLAYER_COLORS_GUIDS[_PlayerColor]
	local _LandCommand = false
	
	local _SubtractLand = string.match(message, "land[-]%d+")
	local _AddLand = string.match(message, "land[+]%d+")
	if(_SubtractLand ~= nil) then
		local _Count = string.match(message, "%d+")
		if(_Count == nil or _Count == "") then
			if(DEBUG_ENABLED == true) then	
				printToAll(PREFIX_DEBUG .. "matched land in chat but invalid command", "White")
			end
			return
		end
		_Count = tonumber(_Count)
		ChatSubtractLandTableEntry(_zoneGUID, _Count)
		_LandCommand = true
	elseif(_AddLand ~= nil) then
		local _Count = string.match(message, "%d+")
		if(_Count == nil or _Count == "") then
			if(DEBUG_ENABLED == true) then	
				printToAll(PREFIX_DEBUG .. "matched land in chat but invalid command", "White")
			end
			return
		end
		_Count = tonumber(_Count)
		ChatAddLandTableEntry(_zoneGUID, _Count)
		_LandCommand = true
	end
	local _Message = PLAY_ZONE_GUIDS_COLORS[_zoneGUID] .. PREFIX_LAND .. "command change " .. "| " .. KVP_LANDS_PLAYED_TURN[_zoneGUID]
	local function DelayChatPrintToAll()
		printToAll(_Message, "White")
	end
	if(_LandCommand == true) then
		Wait.frames(DelayChatPrintToAll, 2)
	end
	
	return true
end
function onPlayerTurn(player, previous_player)
	if(ERROR_FLAGGED == true) then
		return
	end
	if(player == nil) then
		if(DEBUG_ENABLED) then
			printToAll(PREFIX_DEBUG .. "only colorless players remaining", "White")
		end
		return
	end
	if(ValidatePlayerColor(player.color) == false) then
		if(DEBUG_ENABLED) then
			printToAll(PREFIX_DEBUG .. "turn change was not to a tracked color", "White")
		end
		return
	end
	local _zoneGUID = PLAYER_COLORS_GUIDS[player.color]
	local _Highlighted = false
	for cardguid,name in pairs(KVP_UPKP) do
		for zoneguid,color in pairs(PLAY_ZONE_GUIDS_COLORS) do
			local _Color = string.sub(name, 1, 8)
			if(_Color == color and _zoneGUID == zoneguid) then
				local _Card = getObjectFromGUID(cardguid)
				_Card.highlightOn(COLOR_HIGHLIGHT, HIGHLIGHT_DURATION)
				_Highlighted = true
				break		
			end
		end
	end
	for cardguid,name in pairs(KVP_DRAW) do
		for zoneguid,color in pairs(PLAY_ZONE_GUIDS_COLORS) do
			local _Color = string.sub(name, 1, 8)
			if(_Color == color and _zoneGUID == zoneguid) then
				local _Card = getObjectFromGUID(cardguid)
				_Card.highlightOn(COLOR_HIGHLIGHT, HIGHLIGHT_DURATION)
				_Highlighted = true
				break		
			end
		end
	end
	if(_Highlighted == true) then
		--printToAll(PREFIX_PLS_DONT .. "highlighted an upkeep or draw step card", "White")
	else
		if(DEBUG_ENABLED) then
			printToAll(PREFIX_DEBUG .. "player has no upkeep or draw step cards in play", "White")
		end
	end
	if(TRACK_LAND_PLAYS == false) then
		return
	end
	ResetLandTableEntry(_zoneGUID)
end
function onObjectEnterZone(_zone, _object)
	if(ERROR_FLAGGED == true) then
		return
	end
	-- zone check and get zone color
	local _Color = ColorFromZone(_zone.guid)
	if(_Color == nil or _Color == "") then
		return
	end
	if(_object.isSmoothMoving() == true) then
		if(DEBUG_ENABLED == true) then	
			printToAll(PREFIX_DEBUG .. "card isn't being moved by player", "White")
		end
		return
	end
	
	local _Rotation = _object.getRotation()
	
	if(_Rotation.z > MIN_Z_ROTATION_FACEDOWN) then
		if(DEBUG_ENABLED == true) then	
			printToAll(PREFIX_DEBUG .. "card is face down, ignoring it", "White")
		end
		return
	end

    local _Description = _object.getDescription()
	local _cardGUID = _object.guid
	local _zoneGUID = _zone.guid
	local _Name = _Color .. _object.getName()
	
	local _IsLand = string.match(_Name, PAT_LAND1)
	if(_IsLand == nil or _IsLand == "") then
		_IsLand = string.match(_Name, PAT_LAND2)
	end
	
	local _HasNewLine = string.match(_Name, "\n")
	if(_HasNewLine) then
		local _TrimIndex = string.find(_Name, "\n")
		_Name = string.sub(_Name, 1, _TrimIndex-1)
	end
		
	if(_IsLand ~= nil) then
		if(DEBUG_ENABLED == true) then	
			printToAll(PREFIX_DEBUG .. "match as a land " .. _Name, "White")
		end
		if(TRACK_LAND_PLAYS == false) then
			return
		end
		
		local _AlreadyTracked = false
		for i,guid in ipairs(KVP_LANDS_PLAYED_GUIDS[_zoneGUID]) do
			if(guid == _cardGUID) then
				_AlreadyTracked = true
				break
			end
		end
		if(_AlreadyTracked == true) then
			if(DEBUG_ENABLED) then
				printToAll(PREFIX_DEBUG .. "land " .. _cardGUID .. " is already tracked", "White")
			end
			return
		end
		
		local _IncrementedLand = UpdateLandKVPTable(true, _zoneGUID, _cardGUID, _Description, _Name)
		local _LandsPlayed = KVP_LANDS_PLAYED_TURN[_zoneGUID]
		if(_IncrementedLand == true) then	
			printToAll(PLAY_ZONE_GUIDS_COLORS[_zoneGUID] .. PREFIX_LAND .. "" .. _Name .. " | " .. _LandsPlayed, "White")
		else
			printToAll(PLAY_ZONE_GUIDS_COLORS[_zoneGUID] .. PREFIX_LAND .. "" .. _Name .. " [i]fetch[/i] | " .. _LandsPlayed, "White")
		end
	else
		local _CheckUpkeep = string.match(_Description, PAT_CHECK_UPKP) ~= nil and true or false
		local _CheckDraw = string.match(_Description, PAT_CHECK_DRAW) ~= nil and true or false
		local _CheckPrecombat = string.match(_Description, PAT_CHECK_PRECMB) ~= nil and true or false
		local _CheckCombat = string.match(_Description, PAT_CHECK_CMB) ~= nil and true or false
		local _CheckEnd = string.match(_Description, PAT_CHECK_END) ~= nil and true or false
	
		if(_CheckUpkeep == true) then
			UpdateNonLandKVPTable(true, KVP_UPKP, PAT_UPKP, _Description, _cardGUID, _Name)
		end
		if(_CheckDraw == true) then
			UpdateNonLandKVPTable(true, KVP_DRAW, PAT_DRAW, _Description, _cardGUID, _Name)
		end
		if(_CheckPrecombat == true) then
			UpdateNonLandKVPTable(true, KVP_PRECMB, PAT_PRECMB, _Description, _cardGUID, _Name)
		end
		if(_CheckCombat == true) then
			if(string.match(_Description, PAT_CMB)) then
				table.addKey(KVP_CMB, _cardGUID, "PAT_CMB", _Name)
			end
		end
		if(_CheckEnd == true) then
			UpdateNonLandKVPTable(true, KVP_END, PAT_END, _Description, _cardGUID, _Name)
		end
	end
end
function onObjectLeaveZone(_zone, _object)
	if(ERROR_FLAGGED == true) then
		return
	end
	local _Color = ColorFromZone(_zone.guid)
	if(_Color == nil or _Color == "") then
		return
	end
	if(_object.isSmoothMoving() == true) then
		if(DEBUG_ENABLED == true) then	
			printToAll(PREFIX_DEBUG .. "card isn't being moved by player", "White")
		end
		return
	end
	
    local _Description = _object.getDescription()
	local _cardGUID = _object.guid
	local _zoneGUID = _zone.guid

	local _Name = _Color .. _object.getName()
	
	local _IsLand = string.match(_Name, PAT_LAND1)
	if(_IsLand == nil or _IsLand == "") then
		_IsLand = string.match(_Name, PAT_LAND2)
	end

	if(_IsLand ~= nil) then
	--[[ -- need to remove land based on entering graveyard zone, not leaving play zone
		if(DEBUG_ENABLED == true) then	
			printToAll(PREFIX_DEBUG .. "match as a land " .. _Name, "White")
		end
		if(TRACK_LAND_PLAYS == false) then
			return
		end
		
		local _RemovedLand = UpdateLandKVPTable(false, _zoneGUID, _cardGUID, _Description, nil)
		if(_RemovedLand == nil or _RemoveLand == "") then
			if(DEBUG_ENABLED) then
				printToAll(PREFIX_DEBUG .. "land " .. _cardGUID .. " is not tracked", "White")
			end
		else
			if(DEBUG_ENABLED) then
				printToAll(PREFIX_DEBUG .. "land " .. _cardGUID .. " was removed from tracking", "White")
			end
		end
		]]
	else
		local _CheckUpkeep = string.match(_Description, PAT_CHECK_UPKP) ~= nil and true or false
		local _CheckDraw = string.match(_Description, PAT_CHECK_DRAW) ~= nil and true or false
		local _CheckPrecombat = string.match(_Description, PAT_CHECK_PRECMB) ~= nil and true or false
		local _CheckCombat = string.match(_Description, PAT_CHECK_CMB) ~= nil and true or false
		local _CheckEnd = string.match(_Description, PAT_CHECK_END) ~= nil and true or false

		if(_CheckUpkeep == true) then
			UpdateNonLandKVPTable(false, KVP_UPKP, PAT_UPKP, _Description, _cardGUID, nil)
		end
		if(_CheckDraw == true) then
			UpdateNonLandKVPTable(false, KVP_DRAW, PAT_DRAW, _Description, _cardGUID, nil)
		end
		if(_CheckPrecombat == true) then
			UpdateNonLandKVPTable(false, KVP_PRECMB, PAT_PRECMB, _Description, _cardGUID, nil)
		end
		if(_CheckCombat == true) then
			if(string.match(_Description, PAT_CMB)) then
				table.removeKey(KVP_CMB, _cardGUID, "PAT_CMB")
			end
		end
		if(_CheckEnd == true) then
			UpdateNonLandKVPTable(false, KVP_END, PAT_END, _Description, _cardGUID, nil)
		end
	end
end
--
-- STARTUP METHODS
function SetupPlayerTables()
	local data = Global.getTable('data')
	if(data == nil) then
		ERROR_FLAGGED = true
		ERROR_DESC = "null global data table"
		return false
	end
	for _,p in pairs(Player.getAvailableColors()) do
		if(data[p] ~= nil) then
			local _zoneGUID = data[p]["playmat"].guid
			local _bbcode = "[" .. colorToHex(stringColorToRGB(p)) .. "]"
			PLAYER_COLORS_GUIDS[p] = _zoneGUID
			PLAY_ZONE_GUIDS_COLORS[_zoneGUID] = _bbcode
		end
	end
	if(DEBUG_ENABLED == true) then
		printToAll(PREFIX_DEBUG .. "printing PLAY_ZONE_GUIDS_COLORS", "White")
		for g,c in pairs(PLAY_ZONE_GUIDS_COLORS) do
			printToAll(PREFIX_DEBUG .. "guid: " .. g .. " | color: " .. c .. "test", "White")
		end
		printToAll(PREFIX_DEBUG .. "printing PLAYER_COLORS_GUIDS", "White")
		for p,g in pairs(PLAYER_COLORS_GUIDS) do
			printToAll(PREFIX_DEBUG .. "player: " .. p .. " | guid: " .. g, "White")
		end
	end
	return true
end
function ValidateZoneGUIDs()
	local ERROR_FLAGGED = false
	for g,c in pairs(PLAY_ZONE_GUIDS_COLORS) do
		if(getObjectFromGUID(g) == nil) then
			ERROR_FLAGGED = true
			if(DEBUG_ENABLED) then
				printToAll(PREFIX_DEBUG .. "for invalid GUID " .. PLAY_ZONE_GUIDS_COLORS[g] .. g, "White")
			end
		end
	end
	if(ERROR_FLAGGED == true) then
		ERROR_DESC = "one or more invalid zone GUID"
		return false
	end
	return true
end
function SetupLandTables()
	for g,c in pairs(PLAY_ZONE_GUIDS_COLORS) do
		KVP_LANDS_PLAYED_TURN[g] = 0
		KVP_LANDS_PLAYED_GUIDS[g] = { }
		if(DEBUG_ENABLED) then
			printToAll(PREFIX_DEBUG .. "land table entry created for " .. PLAY_ZONE_GUIDS_COLORS[g] .. g .. " | " .. KVP_LANDS_PLAYED_TURN[g], "White")
		end
	end
end
--
-- CONTEXT METHODS
function ToggleLandTracking(_playerColor, _menuPosition, _object)
	if(TRACK_LAND_PLAYS == nil or TRACK_LAND_PLAYS == false) then
		TRACK_LAND_PLAYS = true
		printToAll(PREFIX_PLS_DONT .. PLAY_ZONE_GUIDS_COLORS[PLAYER_COLORS_GUIDS[_playerColor]] .. _playerColor .. COLOR_GREEN .. " enabled " .. COLOR_WHITE .. "Land Tracking\n" .. HELP_MESSAGE_LANDS, "White")
	else
		TRACK_LAND_PLAYS = false
		printToAll(PREFIX_PLS_DONT .. PLAY_ZONE_GUIDS_COLORS[PLAYER_COLORS_GUIDS[_playerColor]] .. _playerColor .. COLOR_RED .. " disabled " .. COLOR_WHITE .. "Land Tracking", "White")
	end
	Player[_playerColor].pingTable(_object.getPosition())
end
function ToggleDebugLogging(_playerColor, _menuPosition, _object)
	if(DEBUG_ENABLED == nil or DEBUG_ENABLED == false) then
		DEBUG_ENABLED = true
		printToAll(PREFIX_PLS_DONT .. PLAY_ZONE_GUIDS_COLORS[PLAYER_COLORS_GUIDS[_playerColor]] .. _playerColor .. COLOR_GREEN .. " enabled " .. COLOR_GREY .. "Debug Logging", "White")
	else
		DEBUG_ENABLED = false
		printToAll(PREFIX_PLS_DONT .. PLAY_ZONE_GUIDS_COLORS[PLAYER_COLORS_GUIDS[_playerColor]] .. _playerColor .. COLOR_RED .. " disabled " .. COLOR_GREY .. "Debug Logging", "White")
	end
	Player[_playerColor].pingTable(_object.getPosition())
end
--
-- HELPERS
function UpdateLandKVPTable(_add, _zoneGUID, _cardGUID, _description, _name)
	if(_add == nil or _add == false) then
		local _FoundGUID = ""
		for i, cardguid in pairs(KVP_LANDS_PLAYED_GUIDS[_zoneGUID]) do 
			if(cardguid == _cardGUID) then
				KVP_LANDS_PLAYED_GUIDS[_zoneGUID][i] = nil
				_FoundGUID = cardguid
				break
			end
		end
		if(_FoundGUID == nil or _FoundGUID == "") then
			return false
		end
		return true
	end
	
	local _Fetch = false
	for key, pattern in pairs(PAT_LAND_FETCH) do 
		if(DEBUG_ENABLED == true) then
			printToAll(PREFIX_DEBUG .. "checking for fetch pattern " .. key, "White")
		end
		if(string.match(string.lower(_description), pattern)) then
			_Fetch = true
			if(DEBUG_ENABLED == true) then
				printToAll(PREFIX_DEBUG .. "found fetch match " .. key, "White")
			end
			break
		end
	end
	if(_Fetch == true) then
		return false
	end
	if(DEBUG_ENABLED == true) then
		printToAll(PREFIX_DEBUG .. "not a fetch land", "White")
	end
	KVP_LANDS_PLAYED_GUIDS[_zoneGUID][#KVP_LANDS_PLAYED_GUIDS[_zoneGUID] + 1] = _cardGUID
	IncrementLandTableEntry(_zoneGUID)
	return true
end
function UpdateNonLandKVPTable(_addKey, _kvpTable, _patternTable, _description, _cardGUID, _name)
	for key, pattern in pairs(_patternTable) do 
		if(string.match(_description, pattern)) then
			if(_addKey == true) then
				table.addKey(_kvpTable, _cardGUID, key, _name)
			else
				table.removeKey(_kvpTable, _cardGUID, key)
			end
			break
		end
	end
end
function ValidatePlayerColor(_color)
	local _Match = false
	for color in pairs(PLAYER_COLORS_GUIDS) do
		if(_color == color) then
			_Match = true
			break
		end
	end
	return _Match
end
function ColorFromZone(_zoneGUID)
	local _Color = ""
	for g,c in pairs(PLAY_ZONE_GUIDS_COLORS) do
		if(_zoneGUID == g) then
			_Color = c
			break
		end
	end
	return _Color
end
function IncrementLandTableEntry(_zoneGUID)
	if(KVP_LANDS_PLAYED_TURN[_zoneGUID] == nil or KVP_LANDS_PLAYED_TURN[_zoneGUID] == 0) then
		KVP_LANDS_PLAYED_TURN[_zoneGUID] = 1
	else
		KVP_LANDS_PLAYED_TURN[_zoneGUID] = KVP_LANDS_PLAYED_TURN[_zoneGUID] + 1
	end
	if(DEBUG_ENABLED) then
		printToAll(PREFIX_DEBUG .. "land table entry incremented for " .. PLAY_ZONE_GUIDS_COLORS[_zoneGUID] .. _zoneGUID .. " to " .. KVP_LANDS_PLAYED_TURN[_zoneGUID], "White")
	end
end
function RemoveLandTableGUID(_zoneGUID, _cardGUID)
	local _FoundGUID = ""
	for i, cardguid in pairs(KVP_LANDS_PLAYED_GUIDS[_zoneGUID]) do 
		if(cardguid == _cardGUID) then
			KVP_LANDS_PLAYED_GUIDS[_zoneGUID][i] = nil
			_FoundGUID = cardguid
			break
		end
	end
	return _FoundMatch
end
function ChatSubtractLandTableEntry(_zoneGUID, _count)
	if(KVP_LANDS_PLAYED_TURN[_zoneGUID] ~= nil) then
		if(KVP_LANDS_PLAYED_TURN[_zoneGUID] - _count <= 0) then
			KVP_LANDS_PLAYED_TURN[_zoneGUID] = 0
		else
			KVP_LANDS_PLAYED_TURN[_zoneGUID] = KVP_LANDS_PLAYED_TURN[_zoneGUID] - _count
		end
	else
		if(DEBUG_ENABLED) then
			if(KVP_LANDS_PLAYED_TURN[_zoneGUID] == nil or KVP_LANDS_PLAYED_TURN[_zoneGUID] == 0) then
				printToAll(PREFIX_DEBUG .. "land table entry subtracted " .. _count .. " for " .. PLAY_ZONE_GUIDS_COLORS[_zoneGUID] .. _zoneGUID .. " to 0", "White")
			else
				printToAll(PREFIX_DEBUG .. "land table entry subtracted " .. _count .. " for " .. PLAY_ZONE_GUIDS_COLORS[_zoneGUID] .. _zoneGUID .. " to " .. KVP_LANDS_PLAYED_TURN[_zoneGUID], "White")
			end
		end
	end
	if(DEBUG_ENABLED) then
		printToAll(PREFIX_DEBUG .. "land table entry subtracted " .. _count .. " for " .. PLAY_ZONE_GUIDS_COLORS[_zoneGUID] .. _zoneGUID .. " to " .. KVP_LANDS_PLAYED_TURN[_zoneGUID], "White")
	end
	return KVP_LANDS_PLAYED_TURN[_zoneGUID]
end
function ChatAddLandTableEntry(_zoneGUID, _count)
	if(KVP_LANDS_PLAYED_TURN[_zoneGUID] == nil or KVP_LANDS_PLAYED_TURN[_zoneGUID] == 0) then
		KVP_LANDS_PLAYED_TURN[_zoneGUID] = _count
	else
		KVP_LANDS_PLAYED_TURN[_zoneGUID] = KVP_LANDS_PLAYED_TURN[_zoneGUID] + _count
	end
	if(DEBUG_ENABLED) then
		printToAll(PREFIX_DEBUG .. "land table entry added " .. _count .. " for " .. PLAY_ZONE_GUIDS_COLORS[_zoneGUID] .. _zoneGUID .. " to " .. KVP_LANDS_PLAYED_TURN[_zoneGUID], "White")
	end
	return KVP_LANDS_PLAYED_TURN[_zoneGUID]
end
function ResetLandTableEntry(_zoneGUID)
	KVP_LANDS_PLAYED_TURN[_zoneGUID] = 0
	printToAll(PLAY_ZONE_GUIDS_COLORS[_zoneGUID] .. PREFIX_LAND .. "Start of my turn | " .. KVP_LANDS_PLAYED_TURN[_zoneGUID], "White")
	if(DEBUG_ENABLED) then
		printToAll(PREFIX_DEBUG .. "land table reset for " .. PLAY_ZONE_GUIDS_COLORS[_zoneGUID] .. _zoneGUID, "White")
	end
end
function SetNotes()
	local _NotesText = "\n" .. COLOR_GREY .. "[b]- Upkeep -[/b]\n"
	for guid, name in pairs(KVP_UPKP) do 
		_NotesText = _NotesText .. name .. "\n" 
	end
	
	_NotesText = _NotesText .. "\n" .. COLOR_GREY .. "[b]- Draw -[/b]\n"
	for guid, name in pairs(KVP_DRAW) do 
		_NotesText = _NotesText .. name .. "\n" 
	end
	
	_NotesText = _NotesText .. "\n" .. COLOR_GREY .. "[b]- Pre Combat -[/b]\n"
	for guid, name in pairs(KVP_PRECMB) do 
		_NotesText = _NotesText .. name .. "\n" 
	end
	
	_NotesText = _NotesText .. "\n" .. COLOR_GREY .. "[b]- Combat -[/b]\n"
	for guid, name in pairs(KVP_CMB) do 
		_NotesText = _NotesText .. name .. "\n" 
	end
	
	_NotesText = _NotesText .. "\n" .. COLOR_GREY .. "[b]- End -[/b]\n"
	for guid, name in pairs(KVP_END) do 
		_NotesText = _NotesText .. name .. "\n" 
	end
	
	_NotesText = string.sub(_NotesText, 1, #_NotesText - 1)
	Notes.setNotes(_NotesText)
end
function table.addKey(_table, _key,_pattern, _name)
    _table[_key] = _name
	SetNotes()
	
	if(DEBUG_ENABLED == false) then
		return
	end
	table.print(_table, _pattern)
end
function table.removeKey(_table, _key, _pattern)
    _table[_key] = nil
	SetNotes()
	
	if(DEBUG_ENABLED == false) then
		return
	end
	table.print(_table, _pattern)
end
function table.print(_table, _pattern)
	printToAll(PREFIX_DEBUG .. "for " .. _pattern .. ":", "White")
	for key, value in pairs(_table) do printToAll(key .. ", " .. value, "White") end
end
function colorToHex(color)
  local r = math.floor(color.r * 255 + 0.5)
  local g = math.floor(color.g * 255 + 0.5)
  local b = math.floor(color.b * 255 + 0.5)
  return string.format("%02X%02X%02X", r, g, b)
end
--