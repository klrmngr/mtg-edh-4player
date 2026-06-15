--::[[ Auto Player Promoter ]]::--
-- Version 1.0
-- By Kevin O'Mara (Quickle)
-- https://steamcommunity.com/profiles/76561197997376704

--[[
This script runs in the background and makes sure all players are promoted so
they have "host" powers (delete/spawn/copy/paste/etc.) For more info on host:
http://berserk-games.com/knowledgebase/player-roles/

Additionally, if a player gets "demoted", the script takes care they are never
automatically promoted again (i.e. when the player drops and re-joins the match,
the game is saved and loaded in the future, or time is rewound/fast forwarded).

Players are promoted at the following times:
* All players are promoted each time the game first loads (including Undo/Redo).
* New players are promoted upon joining the match.

Whether a player is "demoted" is recorded at the following times:
* All players are recorded when the game saves (including auto saves).
* Individual players are recorded when they leave the match.

Undo / Redo
* Undo - A demoted player may become promoted again if time rewinds to a point
  when they were previously promoted.
* Redo - A player will never become demoted when time fast forwards, even if
  they had previously been demoted at that autosave.
--]]



--------------------------------------------------------------------------------
--[[ CONFIGURATION  ]]----------------------------------------------------------
--------------------------------------------------------------------------------
--[[
You can modify the script's behavior by changing these variables:
--]]

-- When true, this object is interactable by Players.
-- You may wish to lock this object and hide it somewhere. To do so, simply:
--  1. Set this value to 'true' & save the script.
--  2. Move the object somewhere & save the game.
--  3. Set this value back to 'false' & save the script.
local objectIsInteractable = true

-- When true, a chat message announces each time a player is automatically
-- promoted or would have been promoted (but wasn't because they are "demoted").
-- Lets players know they are being promoted by a script rather than the host.
local chatEnabled = false

-- When true, debug information is written the log window (host only).
local loggingEnabled = false


--------------------------------------------------------------------------------
--[[ SCRIPT CODE  ]]------------------------------------------------------------
--------------------------------------------------------------------------------

--[[ Utility Methods ]]---------------------------------------------------------

local function _log(element, label)
    -- Log a message with the prefix "AutoPlayerPromoter: ".
    -- Wrapper for `log()`: https://api.tabletopsimulator.com/base/#log
    if loggingEnabled then
        log(element, "AutoPlayerPromoter: " .. tostring(label))
    end
end

local function _printToAll(message)
    -- Print a message to chat, but only if `chatEnabled` is `true`.
    -- Wrapper for `print()`: https://api.tabletopsimulator.com/base/#print
    if chatEnabled then
        printToAll(message)
    end
end

local function _playerAsTable(player)
    -- Return a <Player> object (https://api.tabletopsimulator.com/player/) as a
    -- simple key-value table, which can be expanded by the built-in logging
    -- method: https://api.tabletopsimulator.com/base/#log
    return {
        steam_name  = player.steam_name,
        steam_id    = player.steam_id,
        promoted    = player.promoted,
        host        = player.host,
        admin       = player.admin,
        color       = player.color,
        team        = player.team,
        seated      = player.seated,
        blindfolded = player.blindfolded,
        lift_height = player.lift_height,
    }
end
--//////////////////////////////////////////////////////////////////////////////



--[[ Player Promotion Tracker ]]------------------------------------------------
--[[
Keeps track of which players are demoted and offers a method to promote players.
--]]

-- Steam IDs of Players who have had their promotion revoked.
-- @type: Set<string>
local _demotedPlayerSteamIds = {}

function isOnDemotedPlayerList(player)
    -- @param player <Player> (https://api.tabletopsimulator.com/player/)
    return _demotedPlayerSteamIds[player.steam_id] ~= nil
end

function isPromoted(player)
    -- @param player <Player> (https://api.tabletopsimulator.com/player/)
    return player.promoted or player.host
end

function tryPromotePlayer(player)
    -- @param player <Player> (https://api.tabletopsimulator.com/player/)
    if isOnDemotedPlayerList(player) then
        _log(_playerAsTable(player), "Will not promote player because they are on the Demoted Player List: ")
        _printToAll("AutoPlayerPromoter: Not promoting player " .. tostring(player.steam_name) .. ", because they were demoted by host.")
    elseif isPromoted(player) then
        _log(_playerAsTable(player), "Will not promote player because they are already promoted or host: ")
    else
        _log(_playerAsTable(player), "Promoting player: ")
        _printToAll("AutoPlayerPromoter: Promoting " .. tostring(player.steam_name))
        player.promote()
    end
end

function savePlayerPromotionState(player)
    -- @param player <Player> (https://api.tabletopsimulator.com/player/)
    if isPromoted(player) then
        _log(_playerAsTable(player), "Saving player's promotion status. Player is <promoted>: ")
        _demotedPlayerSteamIds[player.steam_id] = nil
    else
        _log(_playerAsTable(player), "Saving player's promotion status. Player is <demoted>: ")
        _demotedPlayerSteamIds[player.steam_id] = {}
    end
end
--//////////////////////////////////////////////////////////////////////////////



--[[ Event Hooks ]]-------------------------------------------------------------
--[[
Makes sure players are getting promoted and recorded at the right times by
responding to events.
--]]

function onLoad(saveData)
    self.interactable = objectIsInteractable

    _log(saveData, "Loading from script state: ")
    if saveData == "" then
        _demotedPlayerSteamIds = {}
    else
        _demotedPlayerSteamIds = JSON.decode(saveData)
    end

    local players = Player.getPlayers()
    for _, player in ipairs(players) do
        tryPromotePlayer(player)
    end
end

function onPlayerConnect(player)
    -- @param player <Player> (https://api.tabletopsimulator.com/player/)
    tryPromotePlayer(player)
end

function onPlayerDisconnect(player)
    -- @param player <Player> (https://api.tabletopsimulator.com/player/)
    savePlayerPromotionState(player)
end

function onSave()
    local players = Player.getPlayers()
    for _, player in ipairs(players) do
        savePlayerPromotionState(player)
    end

    saveData = JSON.encode(_demotedPlayerSteamIds)
    _log(saveData, "Saving script state: ")
    return saveData
end
--//////////////////////////////////////////////////////////////////////////////