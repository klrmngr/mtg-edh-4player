SRC = \
	src/init.lua \
	src/buttons.lua \
	src/keybinds.lua \
	src/movement.lua \
	src/reveal.lua \
	src/mulligan.lua \
	src/reset.lua \
	src/command_buttons.lua \
	src/etali.lua \
	src/coinflip.lua \
	src/stickers.lua \
	src/landtracker.lua \
	src/restricted_abilities.lua \
	src/fetchland.lua \
	src/dfc.lua \
	src/frozen.lua \
	src/untap.lua \
	src/draw.lua \
	src/helpers.lua \
	src/context_menus.lua \
	src/cascade.lua \
	src/reveal_type.lua \
	src/chat.lua \
	src/scryfall.lua \
	src/patchnotes.lua \
	src/json.lua

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
