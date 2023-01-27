# require

## Purpose

The `require` function that comes with Garry's Mod has been modified by Garry
for his needs and programming style, and as a result much of its original
functionality is missing. This addon monkey patches the global environment to
reimplement some of this missing functionality, and allow for traditional
style modules in Garry's Mod.

## Features
* Reimplemented `package.preload`.
* Reimplemented `package.loaders`. (You can even add your own searcher
  functions. See source code for more information.)
* Reimplemented `package.path`
* Detoured `require` to reference package library keyvalues and allow for return
  values
* Added `package.environment`, which is used as the global table for custom
  modules. By default, it mirrors a basic Lua 5.1 environment and contains
  only two extra keyvalues: `default`, which is the default global table, and
  `AddCSLuaFile`.
* Basic support for Lua 5.1 modules (must be pure Lua and take note of
  `package.environment` limitations)

## Example
`autorun/test.lua`:
```lua
--  We still need to send the file to the client if we plan on requiring it
--  there
AddCSLuaFile 'wauterboi/data/constants.lua'

--  There is no need to pollute the global environment - `require` supports
--  return values
local x = require 'wauterboi.data.lorem_ipsum'
print(x.standard)

--  This does not re-execute the module - it's simply fetching the cached
--  return values from `package.loaded`.
y = require 'wauterboi.data.lorem_ipsum'
print(y.translation)
```

`wauterboi/data/constants.lua`:
```lua
print 'Hello'
return {
  standard = 'Lorem ipsum dolor sit amet'
  translated = 'The customer is very happy'
}
```

Output:
```
Hello
Lorem ipsum dolor sit amet
The customer is very happy
```

## LuaRocks support
There is basic support for Lua 5.1 modules. There are some important caveats
to keep in mind, however:

* The `file` and `io` libraries are completely missing in `package.environment`.
  While the missing libraries could probably be reimplemented, doing so is
  outside the scope of this module.
* The `debug` library is missing a lot of functions.
* The modules must be pure Lua.

By default, `package.path` expects these types of modules to exist inside the
`lib` folder. This is so you can run `luarocks install <module> --tree lib`. If
you're not a fan, you can modify `package.path` to fit your needs - preferably
by appending or prepending paths.