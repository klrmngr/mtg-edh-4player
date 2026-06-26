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
	src/landtracker.lua \
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

.PHONY: clean
clean:
	rm -f main.lua
