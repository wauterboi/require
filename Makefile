PROJECT_NAME := $(shell basename $(PWD))

TARGET_MOON_FILES := $(shell find . -type "f" -name '*.moon')
TARGET_LUA_FILES := $(patsubst %.moon, %.lua, $(TARGET_MOON_FILES))

all: $(TARGET_LUA_FILES)

%.lua: %.moon
	moonc -o "$@" "$<"

.PHONY: clean bundle
clean:
	rm -f $(shell find . -type f -name '*.lua')
	
bundle: clean all
	echo $(TARGET_MOON_FILES)
	mkdir -p releases
	zip -q releases/$(PROJECT_NAME)-X.X.X.zip\
		$(TARGET_LUA_FILES)\
		maps\
		backgrounds\
		gamemodes\
		materials\
		scenes\
		models\
		scripts\
		particles\
		sound\
		resource