-- Bundled by luabundle {"luaVersion":"5.2","version":"1.7.0"}
local __bundle_require, __bundle_loaded, __bundle_register, __bundle_modules = (function(superRequire)
	local loadingPlaceholder = {[{}] = true}

	local register
	local modules = {}

	local require
	local loaded = {}

	register = function(name, body)
		if not modules[name] then
			modules[name] = body
		end
	end

	require = function(name)
		local loadedModule = loaded[name]

		if loadedModule then
			if loadedModule == loadingPlaceholder then
				return nil
			end
		else
			if not modules[name] then
				if not superRequire then
					local identifier = type(name) == 'string' and '\"' .. name .. '\"' or tostring(name)
					error('Tried to require ' .. identifier .. ', but no such module has been registered')
				else
					return superRequire(name)
				end
			end

			loaded[name] = loadingPlaceholder
			loadedModule = modules[name](require, loaded, register, modules)
			loaded[name] = loadedModule
		end

		return loadedModule
	end

	return require, loaded, register, modules
end)(nil)
__bundle_register("__root", function(require, _LOADED, __bundle_register, __bundle_modules)
require("import")

end)
__bundle_register("import", function(require, _LOADED, __bundle_register, __bundle_modules)
local M = {}

local asset_base_url = 'https://importer-static.rikrassen.xyz'
local env = 'PROD'
-- local env = 'STAGING'
-- local env = 'DEV'

if env == 'PROD' then
  BaseURL = 'https://importer.rikrassen.xyz'
elseif env == 'STAGING' then
  BaseURL = 'https://importer-staging.rikrassen.xyz'
else
  BaseURL = 'http://localhost:8080'
  asset_base_url = 'http://localhost:8082'
end
local assets = require("assets").build(asset_base_url)

local modal = require("modal")
local utils = require("utils")
local api = require("api")

function onLoad()
  utils.set_guid(self.getGUID())

  self.createButton({
    click_function = 'click_show_import',
    function_owner = self,
    tooltip = 'Open Importer GUI',
    position = {0, 0.1, 0},
    height = 750,
    width = 1000,
    color = {0, 0, 0, 0.8},
    label = "deck importer",
    font_size = 140,
    font_color = {1, 1, 1, 2},
  })
end

local function render_defaults()
  return {
    tag = 'Defaults',
    attributes = { id = 'tts-importer-defaults' },
    children = {
      { tag = 'Button', attributes = { rectAlignment = 'UpperLeft' } },
      {
        tag = 'InputField',
        attributes = {
          rectAlignment = 'UpperLeft',
          fontSize = '20',
          caretWidth = '2',
          font = 'Roboto/Roboto-Regular',
        },
      },
      {
        tag = 'Text',
        attributes = {
          rectAlignment = 'UpperLeft',
          tooltipPosition = 'Left',
          tooltipBackgroundColor = 'rgb(0,0,0)',
          font = 'Roboto/Roboto-Regular',
          alignment = 'UpperLeft',
          color = 'White',
        },
      },
      { tag = 'Image',  attributes = { rectAlignment = 'UpperLeft' } },
      { tag = 'Toggle', attributes = { rectAlignment = 'UpperLeft' } },
      {
        tag = 'Dropdown',
        attributes = {
          rectAlignment = 'UpperLeft',
          font = 'Roboto/Roboto-Regular',
        },
      },
    },
  }
end

--- Show the import modal
--- @param importer Object
--- @param color string
function click_show_import(importer, color)
  M.show_import(importer, color)
end

function remote_show_import(color)
  M.show_import(self, color)
end

--- Check for a new version of the importer script
--- @param importer Object
--- @param color string
function M.check_for_update(importer, color)
  api.check_version(BaseURL, asset_base_url, function(new_script)
    importer.setVar('checked_version', true)
    if not new_script then
      M.show_import(importer, color)
      return
    end

    log('Updating importer GUI...')
    importer.setLuaScript(new_script)
    local new_importer = importer.reload()
    -- Wait for the object to reload before calling show_import again
    M._wait_for_stable(function()
      new_importer.setVar('checked_version', true)
      new_importer.call('remote_show_import', color)
    end)
  end)
end

local function load_custom_assets()
  local custom_assets = UI.getCustomAssets()
  local new_assets = {}
  local dirty = false
  for _, asset in ipairs(assets) do
    local found = false
    for i, custom_asset in ipairs(custom_assets) do
      if asset.name == custom_asset.name then
        found = true
        if asset.url == custom_asset.url and asset.type == custom_asset.type then
          break
        end
        custom_assets[i] = asset
        dirty = true
        break
      end
    end
    if not found then
      table.insert(new_assets, asset)
      dirty = true
    end
  end
  if not dirty then
    return
  end
  for _, asset in ipairs(new_assets) do
    table.insert(custom_assets, asset)
  end
  UI.setCustomAssets(custom_assets)
end

---@private
---@params fn function()
function M._wait_for_stable(fn)
  Wait.condition(
    fn,
    function()
      return not UI.loading
    end,
    5,
    fn
  )
end

---@param color string
local function render_modal(color)
  local ui = UI.getXmlTable()
  if UI.getAttribute('tts-importer-defaults', 'id') == nil then
    table.insert(ui, render_defaults())
  end

  local m = modal.Modal.new(color)
  local modal_xml = m:render()
  table.insert(ui, modal_xml)
  UI.setXmlTable(ui)

  M._wait_for_stable(function()
    m:show()
  end)
end

--- Show the import modal
--- @param importer Object
--- @param color string
function M.show_import(importer, color)
  if not importer.getVar('checked_version') then
    M.check_for_update(importer, color)
    return
  end

  if modal.exists(color) then
    modal.show(color)
    return
  end

  load_custom_assets()

  M._wait_for_stable(function()
    render_modal(color)
  end)
end

end)
__bundle_register("api", function(require, _LOADED, __bundle_register, __bundle_modules)
local CLIENT_VERSION = 'v0.11.0'
local M = {}

local function split_lines(resp)
  local lines = {}
  for s in resp:gmatch('[^\r\n]+') do
    table.insert(lines, s)
  end
  return lines
end

local function postJSON(url, req, cb)
  local lang = req.lang
  req.lang = nil
  WebRequest.custom(url, 'POST', true, JSON.encode(req), {
    Accept = 'application/x-ndjson',
    ['Content-Type'] = 'application/json',
    ['X-Client-Version'] = CLIENT_VERSION,
    ['Accept-Language'] = lang,
  }, cb)
end

local function callback(resp, player, reqType, next)
  next()

  if resp.error ~= nil then
    if string.find(resp.text, '"error"') then
      local data = JSON.decode(resp.text)
      broadcastToColor('There appears to be an issue with your ' .. reqType .. ': ' .. data.error,
        player.color, Color.Red)
    else
      broadcastToColor('There was an issue with the server, please try again later', player.color,
        Color.Red)
    end
    log(player.color .. ': server returned the error: ' .. resp.error)
    return
  end

  if not resp.is_done then
    return
  end

  broadcastToColor('Rendering ' .. reqType .. '...', player.color, Color.Yellow)

  local issues = {}
  for _, obj in ipairs(split_lines(resp.text)) do
    if string.match(obj, '^{"error":') then
      local error = JSON.decode(obj)
      issues[#issues + 1] = error.error
    else
      spawnObjectJSON({ json = obj })
    end
  end
  if #issues > 0 then
    local issue_text
    if #issues > 1 then
      issue_text = 'are multiple issues'
    else
      issue_text = 'is an issue'
    end
    broadcastToColor('There ' .. issue_text .. ' with your ' .. reqType .. ': ' .. table.concat(issues, ', '),
      player.color, Color.Red)
  end
end

function M.draft_cube(color, data, next)
  if data.url == '' then
    broadcastToColor('Please enter a cube', color, 'Red')
    return
  end

  broadcastToColor('Building cube...', color, 'Yellow')

  local player = Player[color]
  postJSON(BaseURL .. '/draftCube', data, function(resp)
    callback(resp, player, 'cube', next)
  end)
end

function M.deck(color, data, next)
  if data.data == '' and data.url == '' then
    broadcastToColor('Please enter a deck', color, 'Red')
    return
  end

  broadcastToColor('Building deck...', color, 'Yellow')

  local player = Player[color]
  local hand = player.getHandTransform(1)
  if hand == nil then
    broadcastToColor('You need to take a seat for your deck to be generated', color, 'Red')
    return
  end

  data.hand = hand
  postJSON(BaseURL .. '/build', data, function(resp)
    callback(resp, player, 'deck', next)
  end)
end

function M.draft(color, data, next)
  if data.set == '' then
    broadcastToColor('Please enter a set', color, 'Red')
    return
  end

  broadcastToAll('Building boosters...', 'Yellow')

  local hands = {}
  for _, seatedPlayer in ipairs(getSeatedPlayers()) do
    local player = Player[seatedPlayer]
    local hand = player.getHandTransform(1)
    -- Skip players that don't actually have a seat.
    if hand == nil then
      broadcastToColor('You need to take a seat for packs to be generated', seatedPlayer, 'Red')
    else
      table.insert(hands, { position = hand.position, forward = hand.forward, right = hand.right })
    end
  end

  local player = Player[color]

  data.hands = hands
  postJSON(BaseURL .. '/draft', data, function(resp)
    callback(resp, player, 'boosters', next)
  end)
end

--- Check for a new version of the client
--- @param base_url string
--- @param asset_base_url string
--- @param cb function(new_script: string?)
function M.check_version(base_url, asset_base_url, cb)
  WebRequest.get(base_url .. '/version', function(resp)
    if resp.error ~= nil then
      cb()
      return
    end
    if resp.text == CLIENT_VERSION then
      cb()
      return
    end
    WebRequest.get(asset_base_url .. '/importer.lua', function(script_resp)
      if script_resp.error ~= nil then
        cb()
        return
      end
      cb(script_resp.text)
    end)
  end)
end

return M

end)
__bundle_register("utils", function(require, _LOADED, __bundle_register, __bundle_modules)
local M = { _guid = '' }

function M.flatten(...)
  local result = {}
  for _, arr in ipairs({ ... }) do
    for _, v in ipairs(arr) do
      result[#result + 1] = v
    end
  end
  return result
end

function M.set_guid(guid)
  M._guid = guid
end

function M.callback(name, fn)
  if M._guid == '' then
    error('GUID is undefined')
  end
  _G[name] = fn
  return M._guid .. '/' .. name
end

function M.merge(tbl, ...)
  for _, m in ipairs({ ... }) do
    for k, v in pairs(m) do
      tbl[k] = v
    end
  end
  return tbl
end

return M

end)
__bundle_register("modal", function(require, _LOADED, __bundle_register, __bundle_modules)
local utils = require("utils")
local api = require("api")

local M = {}

local AllModals = {}

function M.exists(color)
  return AllModals[color] ~= nil
end

function M.show(color)
  if AllModals[color] == nil then
    error('no modal for ' .. tostring(color))
  end
  AllModals[color]:show()
end

---@class Modal
---@field color string
---@field _deck_form table
---@field _draft_form table
---@field _cube_draft_form table
---@field _settings table
---@field _tab string
local Modal = {}
Modal.__index = Modal

M.Modal = Modal

--- Create a new Modal
--- @param color string
--- @return Modal
function Modal.new(color)
  if M.exists(color) then
    return AllModals[color]
  end

  local self = setmetatable({ color = color }, Modal)

  self._deck_form = { url = '', data = '' }
  self._draft_form = { set = '' }
  self._cube_draft_form = { url = '', drafters = 1, packSize = 15, packCount = 3 }
  self._settings = {
    useStates = true,
    preferOriginalPrinting = false,
    lang = 'en',
  }
  self._tab = 'deck'

  AllModals[color] = self

  return self
end

function Modal:_id()
  return 'modal-' .. self.color
end

function Modal:show()
  UI.setAttribute(self:_id(), 'visibility', self.color)
  self:update_form_values()
end

function Modal:hide()
  UI.setAttribute(self:_id(), 'visibility', 'false')
end

function Modal:id(suffix)
  return self.color .. '-' .. suffix
end

function Modal:set_tab(tab)
  UI.setAttribute(self:id(self._tab .. '-btn'), 'visibility', '')
  UI.setAttribute(self:id(tab .. '-btn'), 'visibility', 'false')
  self._tab = tab

  local tabs = { 'deck', 'draft', 'cube', 'settings' }
  for _, tabName in ipairs(tabs) do
    local tabId = self:id(tabName .. '-tab')
    if tabName == tab then
      UI.setAttribute(tabId, 'active', 'true')
    else
      UI.setAttribute(tabId, 'active', 'false')
    end
  end
end

function Modal:update_form_values()
  UI.setValue(self:id('deck-input'), self._deck_form.data)
  UI.setValue(self:id('url-input'), self._deck_form.url)

  UI.setValue(self:id('set-input'), self._draft_form.set)

  UI.setAttribute(self:id('state-input'), 'isOn', self._settings.useStates)
  UI.setAttribute(self:id('original-printing-input'), 'isOn', self._settings.preferOriginalPrinting)
end

function Modal:render_deck_button()
  return {
    tag = 'Button',
    attributes = {
      id = self:id('deck-btn'),

      onClick = utils.callback(self:id('switch-to-deck'), function()
        self:set_tab('deck')
      end),

      visibility = 'false',
      transition = 'SpriteSwap',
      sprite = 'deck_tab_button',
      highlightedSprite = 'deck_tab_button_hover',
      pressedSprite = 'deck_tab_button_hover',

      offsetXY = '135 0',
      height = 40,
      width = 100,
    },
  }
end

function Modal:render_draft_button()
  return {
    tag = 'Button',
    attributes = {
      id = self:id('draft-btn'),
      onClick = utils.callback(self:id('switch-to-draft'), function()
        self:set_tab('draft')
      end),

      transition = 'SpriteSwap',
      sprite = 'draft_tab_button',
      highlightedSprite = 'draft_tab_button_hover',
      pressedSprite = 'draft_tab_button_hover',

      offsetXY = '235 0',
      height = 40,
      width = 100,
    },
  }
end

function Modal:render_cube_button()
  return {
    tag = 'Button',
    attributes = {
      id = self:id('cube-btn'),

      onClick = utils.callback(self:id('switch-to-cube'), function()
        self:set_tab('cube')
      end),

      transition = 'SpriteSwap',
      sprite = 'cube_tab_button',
      highlightedSprite = 'cube_tab_button_hover',
      pressedSprite = 'cube_tab_button_hover',

      offsetXY = '335 0',
      height = 40,
      width = 100,
    },
  }
end

function Modal:render_submit_button(onclick)
  return {
    tag = 'Button',
    attributes = {
      onClick = onclick,
      transition = 'SpriteSwap',
      sprite = 'submit_button',
      highlightedSprite = 'submit_button_hover',
      pressedSprite = 'submit_button_hover',

      offsetXY = '488 -558',
      height = 29,
      width = 80,
    },
  }
end

function Modal:render_settings_button()
  return {
    tag = 'Button',
    attributes = {
      id = self:id('settings-btn'),

      onClick = utils.callback(self:id('switch-to-settings'), function()
        self:set_tab('settings')
      end),

      transition = 'SpriteSwap',
      sprite = 'settings_button',
      highlightedSprite = 'settings_button_hover',
      pressedSprite = 'settings_button_hover',

      offsetXY = '532 -8',
      height = 24,
      width = 24,
    },
  }
end

function Modal:render_buttons()
  return {
    self:render_deck_button(),
    self:render_draft_button(),
    self:render_cube_button(),
    self:render_settings_button(),
  }
end

function Modal:render_deck_tab()
  return {
    tag = 'Panel',
    attributes = { id = self:id('deck-tab'), rectAlignment = 'UpperLeft', active = 'true' },
    children = {
      { tag = 'Image', attributes = { image = 'deck_tab', width = 600, height = 600 } },
      {
        tag = 'Text',
        attributes = {
          text = 'Deck site URL',

          offsetXY = '21 -57',
          fontSize = '40'
        },
      },
      {
        tag = 'InputField',
        attributes = {
          id = self:id('url-input'),

          onEndEdit = utils.callback(self:id('set-deck-url'), function(_, text, _)
            self._deck_form.url = text
          end),
          lineType = 'SingleLine',
          placeholder = 'https://scryfall.com/@rikrassen/decks/abc-123',

          offsetXY = '32 -118',
          height = 46,
          width = 535,
        },
      },
      {
        tag = 'Text',
        attributes = {
          text = 'or enter a decklist',

          offsetXY = '23 -178',
          fontSize = '40'
        },
      },
      {
        tag = 'Image',
        attributes = {
          image = 'question_button',

          offsetXY = '276 -64',
          width = 22,
          height = 22,
        }
      },
      {
        tag = 'Text',
        attributes = {
          tooltip = [[<size="20">Deck builder URL

Supported sites are:
  - aetherhub.com
  - archidekt.com
  - decks.tcgplayer.com
  - deckstats.net
  - infinite.tcgplayer.com
  - manabox.app
  - moxfield.com
  - mtgazone.com
  - mtggoldfish.com
  - mtgsalvation.com
  - mtgtop8.com
  - mtgvault.com
  - scryfall.com
  - tappedout.net</size>]],

          offsetXY = '276 -64',
          height = 22,
          width = 22,
        },
      },
      {
        tag = 'Image',
        attributes = {
          image = 'question_button',

          offsetXY = '353 -186',
          width = 22,
          height = 22,
        },
      },
      {
        tag = 'Text',
        attributes = {
          tooltip = [[<size="20">Paste in your deck in one of the following formats.

1. .dec format
     e.g. "1 [9ED] Storm Crow"

2. MTG Arena .txt
     e.g. "1 Storm Crow (9ED) 100

Note: the final number is the collector's number. This allows you
      to specify a certain printing within a set, i.e. lands or
      showcase.

3. MTG Online .txt (a.k.a. simple format)
     e.g. "1 Storm Crow"

Notes:
  - Double-faced cards are specified using the name of the front,
    i.e. "Treasure Map", or both faces, separated by //,
    i.e. "Treasure Map // Treasure Cove"
  - All lines beginning with // are ignored.</size>]],

          offsetXY = '353 -186',
          height = 22,
          width = 22,
        },
      },
      {
        tag = 'InputField',
        attributes = {
          id = self:id('deck-input'),
          onEndEdit = utils.callback(self:id('set-deck'), function(_, text, _)
            self._deck_form.data = text
          end),
          lineType = 'MultiLineNewline',

          offsetXY = '32 -240',
          height = 305,
          width = 535,
        },
      },
      self:render_submit_button(utils.callback(self:id('deck-submit'), function()
        api.deck(self.color, utils.merge({}, self._deck_form, self._settings), function()
          self:hide()
        end)
      end)),
    },
  }
end

function Modal:render_draft_tab()
  return {
    tag = 'Panel',
    attributes = { id = self:id('draft-tab'), active = 'false', rectAlignment = 'UpperLeft' },
    children = {
      { tag = 'Image', attributes = { image = 'draft_tab', width = 600, height = 600 } },
      {
        tag = 'InputField',
        attributes = {
          id = self:id('set-input'),
          onEndEdit = utils.callback(self:id('set-set'), function(_, text, _)
            self._draft_form.set = text
          end),
          lineType = 'SingleLine',
          placeholder = 'i.e. CMR',

          offsetXY = '32 -118',
          height = 46,
          width = 535,
        },
      },
      {
        tag = 'Text',
        attributes = {
          text = 'Set code to draft',

          offsetXY = '21 -57',
          fontSize = '40'
        },
      },
      {
        tag = 'Image',
        attributes = {
          image = 'question_button',

          offsetXY = '327 -63',
          width = 22,
          height = 22,
        },
      },
      {
        tag = 'Text',
        attributes = {
          tooltip = [[<size="20">Generates 3 booster packs (or 2 for Jumpstart) in front of each seated player.
Drafting must be completed manually after that</size>]],
          offsetXY = '327 -63',
          height = 24,
          width = 24,
        },
      },
      self:render_submit_button(utils.callback(self:id('draft-submit'), function()
        api.draft(self.color, utils.merge({}, self._draft_form, self._settings), function()
          self:hide()
        end)
      end)),
    },
  }
end

function Modal:render_cube_tab()
  local num_seated_players = #getSeatedPlayers()
  local pack_size = 15
  local pack_count = 3
  self._cube_draft_form.drafters = num_seated_players
  self._cube_draft_form.packSize = pack_size
  self._cube_draft_form.packCount = pack_count
  return {
    tag = 'Panel',
    attributes = { id = self:id('cube-tab'), rectAlignment = 'UpperLeft', active = 'false' },
    children = {
      { tag = 'Image', attributes = { image = 'cube_tab', width = 600, height = 600 } },
      {
        tag = 'InputField',
        attributes = {
          id = self:id('cube-url-input'),
          onEndEdit = utils.callback(self:id('set-cube-url'), function(_, text, _)
            self._cube_draft_form.url = text
          end),
          lineType = 'SingleLine',
          placeholder = 'https://cubecobra.com/cube/list/5d2cb3f44153591614458e5d',

          offsetXY = '32 -118',
          height = 46,
          width = 535,
        },
      },
      {
        tag = 'Text',
        attributes = {
          text = 'Cube site URL',

          offsetXY = '21 -57',
          fontSize = '40'
        },
      },
      {
        tag = 'Image',
        attributes = {
          image = 'question_button',

          offsetXY = '276 -64',
          width = 22,
          height = 22,
        },
      },
      {
        tag = 'Text',
        attributes = {
          tooltip = [[<size="20">Cube site URL

Supported sites are:
  - cubecobra.com
  - scryfall.com
  - tappedout.net</size>]],

          offsetXY = '276 -64',
          height = 22,
          width = 22,
        },
      },
      {
        tag = 'Text',
        attributes = {
          text = '# Players',

          offsetXY = '21 -194',
          fontSize = '40'
        },
      },
      {
        tag = 'InputField',
        attributes = {
          id = self:id('cube-players-input'),
          onEndEdit = utils.callback(self:id('set-cube-players'), function(_, text, _)
            self._cube_draft_form.drafters = tonumber(text)
          end),
          lineType = 'SingleLine',
          placeholder = ' ',
          text = num_seated_players,
          characterValidation = 'Integer',

          offsetXY = '382 -193',
          height = 46,
          width = 78,
        },
      },
      {
        tag = 'Text',
        attributes = {
          text = 'Cards per pack',

          offsetXY = '21 -272',
          fontSize = '40'
        },
      },
      {
        tag = 'InputField',
        attributes = {
          id = self:id('cube-pack-size-input'),
          onEndEdit = utils.callback(self:id('set-cube-pack-size'), function(_, text, _)
            self._cube_draft_form.packSize = tonumber(text)
          end),
          lineType = 'SingleLine',
          placeholder = ' ',
          text = pack_size,
          characterValidation = 'Integer',

          offsetXY = '382 -273',
          height = 46,
          width = 78,
        },
      },
      {
        tag = 'Text',
        attributes = {
          text = '# Packs per player',

          offsetXY = '21 -345',
          fontSize = '40'
        },
      },
      {
        tag = 'InputField',
        attributes = {
          id = self:id('cube-pack-count-input'),
          onEndEdit = utils.callback(self:id('set-cube-pack-count'), function(_, text, _)
            self._cube_draft_form.packCount = tonumber(text)
          end),
          lineType = 'SingleLine',
          placeholder = ' ',
          text = pack_count,
          characterValidation = 'Integer',

          offsetXY = '382 -345',
          height = 46,
          width = 78,
        },
      },
      self:render_submit_button(utils.callback(self:id('cube-submit'), function()
        api.draft_cube(self.color, utils.merge({}, self._cube_draft_form, self._settings),
          function()
            self:hide()
          end)
      end)),
    },
  }
end

function Modal:render_settings_tab()
  local options = {}
  local langs = {
    ['English'] = 'en',
    ['français'] = 'fr',
    -- 'grc' = Greek, but only one card exists, omitted,
    ['Русский язык'] = 'ru',
    ['简体中文'] = 'zhs',
    -- 'ph' = "Phryrexian", omitted,
    -- 'ar' = Arabic, omitted,
    -- 'he' = Hebrew, omitted,
    ['Português'] = 'pt',
    ['繁體中文'] = 'zht',
    ['日本語'] = 'ja',
    ['한국어'] = 'ko',
    ['italiano'] = 'it',
    ['español'] = 'es',
    -- 'la' = latin, omitted,
    -- 'sa' = sandskrit (probably), omitted,
    ['Deutsch'] = 'de',
    [''] = '',
  }
  for lang in pairs(langs) do
    table.insert(options, { tag = 'Option', value = lang })
  end
  options[1].attributes = { selected = 'true' }

  return {
    tag = 'Panel',
    attributes = { id = self:id('settings-tab'), rectAlignment = 'UpperLeft', active = 'false' },
    children = {
      { tag = 'Image', attributes = { image = 'settings_tab', width = 600, height = 600 } },
      {
        tag = 'Text',
        attributes = {
          text = 'Language',

          offsetXY = '21 -57',
          fontSize = '40'
        },
      },
      {
        tag = 'Image',
        attributes = {
          image = 'question_button',

          offsetXY = '209 -63',
          width = 22,
          height = 22,
        },
      },
      {
        tag = 'Text',
        attributes = {
          tooltip = [[<size="20">Language

If the card exists in the selected language (on Scryfall) that card will be
used. An English card will be used as a fallback. Specific printings are still
respected as they apply.</size>]],

          offsetXY = '209 -63',
          height = 22,
          width = 22,
        },
      },
      {
        tag = 'Dropdown',
        attributes = {
          onValueChanged = utils.callback(self:id('set-language'), function(_, option, _)
            if option == '' then
              return
            end
            local lang = ''
            for k, v in pairs(langs) do
              if k == option then
                lang = v
                break
              end
            end
            self._settings.lang = lang
          end),

          offsetXY = '32 -118',
          height = '47',
          width = '535',
        },
        children = options,
      },
      {
        tag = 'Text',
        attributes = {
          text = 'Card Back URL',

          offsetXY = '21 -182',
          fontSize = '40'
        },
      },
      {
        tag = 'InputField',
        attributes = {
          onValueChanged = utils.callback(self:id('set-back-url'), function(_, val, _)
            self._settings.backURL = val
          end),

          offsetXY = '32 -244',
          height = '47',
          width = '535',
        },
      },
      {
        tag = 'Toggle',
        attributes = {
          id = self:id('state-input'),

          onValueChanged = utils.callback(self:id('set-use-states'), function(_, val, _)
            self._settings.useStates = val == 'True'
          end),

          toggleHeight = '22',
          toggleWidth = '23',

          offsetXY = '25 -322',

          height = '22',
          width = '23',
        },
      },
      {
        tag = 'Text',
        attributes = {
          text = 'Use states for double-sided cards',

          offsetXY = '60 -318',
          fontSize = '28'
        },
      },
      -- A transparent box to act like a HTML click box for the dropdown
      {
        tag = 'Text',
        attributes = {
          offsetXY = '25 -330',
          height = '22',
          width = '442',
          onClick = utils.callback(self:id('set-use-states-label'), function()
            self._settings.useStates = not self._settings.useStates
            UI.setAttribute(self:id('state-input'), 'isOn', self._settings.useStates)
          end),
        },
      },
      {
        tag = 'Toggle',
        attributes = {
          id = self:id('original-printing-input'),

          onValueChanged = utils.callback(self:id('set-prefer-original-printing'), function(_, val, _)
            self._settings.preferOriginalPrinting = val == 'True'
          end),

          toggleHeight = '22',
          toggleWidth = '23',

          offsetXY = '25 -380',

          height = '22',
          width = '23',
        },
      },
      {
        tag = 'Text',
        attributes = {
          text = 'Prefer original printings',

          offsetXY = '60 -376',
          fontSize = '28'
        },
      },
      -- A transparent box to act like a HTML click box for the dropdown
      {
        tag = 'Text',
        attributes = {
          offsetXY = '25 -384',
          height = '22',
          width = '342',
          onClick = utils.callback(self:id('set-prefer-original-printing-label'), function()
            self._settings.preferOriginalPrinting = not self._settings.useOriginalPrinting
            UI.setAttribute(self:id('original-printing-input'), 'isOn', self._settings.preferOriginalPrinting)
          end),
        },
      },
      {
        tag = 'Text',
        attributes = {
          text =
          'Consider buying me a coffee and helping to support future development\nhttps://buymeacoffee.com/rikrassen',
          offsetXY = '21 -500',
        },
      },
      {
        tag = 'Image',
        attributes = {
          image = 'buy_me_a_coffee',

          offsetXY = '416 -520',
          height = 50,
          width = 50,
        },
      }
    },
  }
end

function Modal:render()
  return {
    tag = 'Panel',
    attributes = {
      height = 600,
      width = 600,
      id = self:_id(),
      visibility = self.color,
      allowDragging = true,
      returnToOriginalPositionWhenReleased = false,
    },
    children = utils.flatten({
      self:render_deck_tab(),
      self:render_draft_tab(),
      self:render_cube_tab(),
      self:render_settings_tab(),
    }, self:render_buttons(), {
      {
        tag = 'Button',
        attributes = {
          onClick = utils.callback(self:id('on-cancel'), function()
            self:hide()
          end),

          transition = 'SpriteSwap',
          sprite = 'close_button',
          highlightedSprite = 'close_button_hover',
          pressedSprite = 'close_button_hover',

          offsetXY = '569 -9',
          height = 23,
          width = 23,
        },
      },
    }),
  }
end

return M

end)
__bundle_register("assets", function(require, _LOADED, __bundle_register, __bundle_modules)
return {
  ---@param base_url string
  ---@return UI.CustomAsset[]
  build = function(base_url)
    local assets = {
      { name = 'deck_tab',        url = 'deck_tab_v0_10_1.png' },
      { name = 'deck_tab_button', url = 'deck_tab_button.png' },
      {
        name = 'deck_tab_button_hover',
        url = 'deck_tab_button_hover.png',
      },
      { name = 'draft_tab',       url = 'draft_tab_v0_10_1.png' },
      {
        name = 'draft_tab_button',
        url = 'draft_tab_button.png',
      },
      {
        name = 'draft_tab_button_hover',
        url = 'draft_tab_button_hover.png',
      },
      { name = 'cube_tab',        url = 'cube_tab_v0_10_1.png' },
      { name = 'cube_tab_button', url = 'cube_tab_button.png' },
      {
        name = 'cube_tab_button_hover',
        url = 'cube_tab_button_hover.png',
      },
      { name = 'close_button',  url = 'close_button.png' },
      {
        name = 'close_button_hover',
        url = 'close_button_hover.png',
      },
      { name = 'submit_button', url = 'submit_button_v0_10_1.png' },
      {
        name = 'submit_button_hover',
        url = 'submit_button_hover_v0_10_1.png',
      },
      { name = 'settings_button', url = 'settings_button.png' },
      {
        name = 'settings_button_hover',
        url = 'settings_button_hover.png',
      },
      { name = 'settings_tab',    url = 'settings_tab_v0_10_1.png' },
      { name = 'question_button', url = 'question_button.png' },
      { name = 'buy_me_a_coffee', url = 'buy_me_a_coffee.png' },
      -- type = 1 means AssetBundle
      { name = 'Roboto',          url = 'roboto.unity3d',          type = 1 },
    }
    for _, asset in ipairs(assets) do
      -- if not asset.url:startsWith('https://') then
      if not asset.url:match('https://') then
        asset.url = base_url .. '/' .. asset.url
      end
    end
    return assets
  end,
}

end)
return __bundle_require("__root")