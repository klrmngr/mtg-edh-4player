-------------------------------- PATCH NOTES -----------------------------------
-- Version currently deployed. Bump this when cutting a new release.
VERSION = "v0.1.3"

local PATCH_NOTES_TAG = "patchNotesButton"
local RELEASES_API = "https://api.github.com/repos/klrmngr/mtg-edh-4player/releases"

-- spawn a clickable tile off to the side of the table (called from onload)
function spawnPatchNotesButton()
	-- remove any leftover patch-notes tile so reloads don't stack duplicates
	for _, obj in ipairs(getAllObjects()) do
		if obj.getGMNotes() == PATCH_NOTES_TAG then
			destroyObject(obj)
		end
	end
	spawnObject({
		type = "BlockSquare",
		position = { -42, 1.1, 0 },
		rotation = { 0, 90, 0 },
		scale = { 1.1, 0.2, 0.9 },
		callback_function = function(obj)
			obj.setName("Patch Notes")
			obj.setGMNotes(PATCH_NOTES_TAG)
			obj.setColorTint({ 0.12, 0.12, 0.14 })
			obj.interactable = false
			-- lock at the spawn position so it can't fall off the table edge
			obj.setLock(true)
			obj.createButton({
				click_function = "showPatchNotes",
				function_owner = self,
				label = VERSION .. "\npatchnotes",
				position = { 0, 0.6, 0 },
				width = 950,
				height = 650,
				font_size = 200,
				color = { 0.95, 0.95, 0.95, 1 },
				font_color = { 0, 0, 0, 1 },
				tooltip = "click to view the patch notes",
			})
		end,
	})
end

-- click handler: fetch every release and show the combined patch notes
function showPatchNotes(obj, color, alt)
	if color == "Grey" then
		return
	end
	WebRequest.get(RELEASES_API, function(req)
		if req.is_error then
			broadcastToColor("Patch notes: couldn't reach GitHub (" .. tostring(req.error) .. ")", color, { 1, 0.4, 0.4 })
			return
		end
		local releases = JSONdecode(req.text)
		if type(releases) ~= "table" then
			broadcastToColor("Patch notes: couldn't parse releases.", color, { 1, 0.4, 0.4 })
			return
		end
		local parts = {}
		for _, rel in ipairs(releases) do
			local tag = rel.tag_name or rel.name or "?"
			local notes = ""
			if type(rel.body) == "string" then
				notes = cleanPatchNotes(rel.body)
			end
			table.insert(parts, "<b>" .. tag .. "</b>\n" .. notes)
		end
		UI.setAttribute("PatchNotesTitle", "text", "Patch Notes")
		UI.setValue("PatchNotesText", table.concat(parts, "\n\n"))
		visibleOpenRules(color, "PatchNotesPanel")
	end)
end

function closePatchNotes(player, value, id)
	visibleCloseRules(player, "PatchNotesPanel")
end

-- turn one release's GitHub-generated body into a clean, readable change list
function cleanPatchNotes(body)
	body = body:gsub("\r", "")
	-- drop the auto-generated sections we don't want
	body = body:gsub("%s*## New Contributors.*", "") -- New Contributors (+ anything after)
	body = body:gsub("%s*%*%*Full Changelog%*%*:.*", "") -- Full Changelog line
	body = body:gsub("## What's Changed%s*", "") -- redundant with the version header
	-- strip the "by @user in <pr-url>" trailer and collapse markdown links to text
	body = body:gsub(" by @%S+ in %S+", "")
	body = body:gsub("%[(.-)%]%((.-)%)", "%1")
	-- escape XML specials so stray <, >, & in the notes (e.g. a PR title that
	-- mentions a tag) don't break the panel's XML when injected via setValue
	body = body:gsub("&", "&amp;")
	body = body:gsub("<", "&lt;")
	body = body:gsub(">", "&gt;")
	-- markdown -> TTS rich text (these tags are produced after escaping, so they
	-- stay real tags while the notes' own angle brackets are now literal text)
	body = body:gsub("%*%*(.-)%*%*", "<b>%1</b>")
	body = body:gsub("## (.-)\n", "<b>%1</b>\n")
	body = body:gsub("\n%s*%* ", "\n• ")
	body = body:gsub("^%* ", "• ")
	-- trim surrounding whitespace
	body = body:gsub("^%s+", ""):gsub("%s+$", "")
	return body
end
