SRC = \
	src/init.lua \
	src/buttons.lua \
	src/keybinds.lua \
	src/movement.lua \
	src/reveal.lua \
	src/mulligan.lua \
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

.PHONY: clean
clean:
	rm -f main.lua
