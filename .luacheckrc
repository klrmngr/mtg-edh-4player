-- Linter config for the mod's Lua. Run with `make lint`; CI runs it on every
-- PR via .github/workflows/lint.yml.
--
-- The hand-written source is src/*.lua; main.lua is `cat`-ed from it by the
-- Makefile. We lint the built main.lua rather than the individual src files,
-- because they share one global namespace at runtime -- a helper defined in
-- src/core/helpers.lua is called from src/zones/draw.lua, and luacheck can
-- only resolve that if it sees them as a single chunk.

-- TTS runs MoonSharp, which tracks Lua 5.2.
std = "lua52"

-- Only the generated bundle. objects/*.lua are exported TTS object scripts,
-- several of them vendored from other mods, so they are not ours to lint.
include_files = { "main.lua" }

-- The mod is one big flat namespace: state and functions are intentionally
-- global so that any src file can reach them. So don't flag *declaring* a
-- global. Reading a name that is never assigned anywhere stays a warning,
-- and that is the check that earns its keep -- it is what catches reading
-- `fSize` where `fsize` was assigned.
allow_defined = true

ignore = {
	-- 131: unused global. Nearly every global function here is called only
	-- by name from somewhere luacheck cannot see: TTS itself (onLoad,
	-- onSave, onObjectDrop, ...) or a click_function / onValueChanged
	-- target in ui.xml.
	"131",
	-- 212/213: unused argument / loop variable. TTS callbacks have fixed
	-- signatures, so handlers routinely ignore a parameter.
	"212",
	"213",
	-- 631: line too long. stylua owns line width (120 columns) and
	-- deliberately leaves long string literals alone.
	"631",
}

-- TTS static classes and singletons. In `globals` rather than `read_globals`
-- because the mod assigns to their fields (Turns.enable, Hands.disable_unused).
globals = {
	"Backgrounds",
	"Color",
	"Global",
	"Grid",
	"Hands",
	"JSON",
	"Lighting",
	"Music",
	"Notes",
	"Physics",
	"Player",
	"TextTool",
	"Time",
	"Timer",
	"Turns",
	"UI",
	"Vector",
	"WebRequest",
	"Wait",
}

read_globals = {
	-- TTS base functions
	"addContextMenuItem",
	"addHotkey",
	"addNotebookTab",
	"broadcastToAll",
	"broadcastToColor",
	"clearContextMenu",
	"copy",
	"destroyObject",
	"editNotebookTab",
	"getAllObjects",
	"getNotebookTabs",
	"getObjectFromGUID",
	"getObjects",
	"getObjectsWithAllTags",
	"getObjectsWithAnyTags",
	"getObjectsWithTag",
	"getSeatedPlayers",
	"group",
	"log",
	"logString",
	"logStyle",
	"paste",
	"printToAll",
	"printToColor",
	"removeNotebookTab",
	"sendExternalMessage",
	"spawnObject",
	"spawnObjectData",
	"spawnObjectJSON",
	"startLuaCoroutine",
	"stringColorToRGB",
	"vector",
	-- `self` is the script's own object; in Global it is nil, which TTS
	-- accepts everywhere we pass it as a button's function_owner.
	"self",
	-- published by the Encoder object via Global.setVar("Encoder", self)
	"Encoder",
}
