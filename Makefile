SRC = \
	src/core/init.lua \
	src/ui/buttons.lua \
	src/ui/keybinds.lua \
	src/zones/movement.lua \
	src/zones/reveal.lua \
	src/zones/mulligan.lua \
	src/core/reset.lua \
	src/core/pregame.lua \
	src/ui/command_buttons.lua \
	src/cards/etali.lua \
	src/cards/obnix.lua \
	src/mechanics/coinflip.lua \
	src/mechanics/stickers.lua \
	src/zones/landtracker.lua \
	src/mechanics/restricted_abilities.lua \
	src/zones/fetchland.lua \
	src/mechanics/dfc.lua \
	src/mechanics/keyword_tokens.lua \
	src/zones/untap.lua \
	src/zones/draw.lua \
	src/zones/draw_triggers.lua \
	src/core/helpers.lua \
	src/ui/context_menus.lua \
	src/mechanics/ownership.lua \
	src/mechanics/cascade.lua \
	src/zones/reveal_type.lua \
	src/external/chat.lua \
	src/external/scryfall.lua \
	src/ui/patchnotes.lua \
	src/core/settings.lua \
	src/ui/bugreport.lua \
	src/core/json.lua

main.lua: $(SRC)
	cat $(SRC) > main.lua

# fail if the committed main.lua doesn't match a fresh build from src/ -- catches
# edits made directly to the generated main.lua (which a rebuild would clobber)
.PHONY: check
check:
	@cat $(SRC) > main.lua
	@git diff --exit-code -- main.lua \
		&& echo "main.lua is in sync with src/" \
		|| { echo "ERROR: main.lua differs from src/ build -- commit the rebuild"; exit 1; }

# Reassemble save.template.json + objects/*.json + main.lua + ui.xml into a
# full, loadable TTS save named "MTG EDH 4-player (χ) <version>-<timestamp>.json".
# By default it writes to SAVE_DIR from .env; override the directory with
# SAVE_OUT, e.g. make save SAVE_OUT="$HOME/.local/share/Tabletop Simulator/Saves"
SAVE_OUT ?=
.PHONY: save
save: main.lua
	python3 tts_save.py build $(if $(SAVE_OUT),--out-dir "$(SAVE_OUT)")

# Decompose a TTS save back into per-object JSON + save.template.json.
# Defaults to the most-recently-modified TS_Save; override with SAVE=path.
.PHONY: split
split:
	python3 tts_save.py split $(SAVE)

.PHONY: clean
clean:
	rm -f main.lua
