MOON_DIR = moon
LUA_DIR = lua

MOON_FILES = $(shell find $(MOON_DIR)/ -type f -name '*.moon')
LUA_FILES = $(patsubst $(MOON_DIR)/%.moon, $(LUA_DIR)/%.lua, $(MOON_FILES))

all: $(LUA_FILES)

$(LUA_DIR)/%.lua: $(MOON_DIR)/%.moon
	mkdir -p "$(@D)"
	moonc -o "$@" "$<"
	
.PHONY: clean
clean:
	rm -rf $(LUA_DIR)