--- A copy of the default `require` function that comes with Garry's Mod. It
--  is selectively ran via our `require` replacement for binary modules.
--  @realm    : shared
--  @scope    : global
--  @type     : function
--  @params   :
--    1.  name: string
--        module name
--  @warning  :
--    1.  Cannot be protected with `pcall` or `xpcall`.
STOCK_REQUIRE     = _G.require
_G.STOCK_REQUIRE  = STOCK_REQUIRE

local *

--- Compiles a file into a callback and sets its environment before returning it
--  @realm    : shared
--  @scope    : global
--  @type     : function
--  @params   :
--    1.  filepath: string
--        filepath relative to `lua` folder
--    2.  environment: table or `nil`
--        optional table to use as global environment
--  @returns  :
--    1.  function
--        compiled callback
compile = (filepath, environment) ->
  loader = CompileFile filepath
  return setfenv loader, environment or _G

--- Environment for modules loaded using `get_custom_loader`. It is meant to
--  serve as an environment as close to the traditional Lua 5.1 environment
--  as reasonable, while providing the default global library through the
--  `default` global keyvalue.
--  @realm    : shared
--  @scope    : global
--  @type     : table
--  @keyvalue :
--    *   string -> any
--        global keyvalue
--  @warning  :
--    1.  `file` and `io` libraries are missing.
--    2.  Many of the `debug` methods are missing.
--    3.  The `string` table does not represent the actual string metatable.
package.environment = do
  copy = (tab, keys) -> {key, tab[key] for key in *keys}
  {
    :AddCSLuaFile
    :_G
    :_VERSION
    :assert
    :collectgarbage
    :dofile
    :error
    :getfenv
    :getmetatable
    :ipairs
    :load
    :loadfile
    :loadstring
    :module
    :next
    :pairs
    :pcall
    :print
    :rawequal
    :rawget
    :rawset
    :require
    :select
    :setfenv
    :setmetatable
    :tonumber
    :tostring
    :type
    :unpack
    :xpcall
    default: _G
    coroutine: copy coroutine, {
      'create'
      'resume'
      'running'
      'status'
      'wrap'
      'yield'
    }
    debug: copy debug, {
      'debug'
      'getfenv'
      'gethook'
      'getinfo'
      'getlocal'
      'getmetatable'
      'getregistry'
      'getupvalue'
      'setfenv'
      'sethook'
      'setlocal'
      'setmetatable'
      'setupvalue'
      'traceback'
    }
    math: copy math, {
      'abs'
      'acos'
      'asin'
      'atan'
      'atan2'
      'ceil'
      'cos'
      'cosh'
      'deg'
      'exp'
      'floor'
      'fmod'
      'frexp'
      'huge'
      'ldexp'
      'log'
      'log10'
      'max'
      'min'
      'modf'
      'pi'
      'pow'
      'rad'
      'random'
      'randomseed'
      'sin'
      'sinh'
      'sqrt'
      'tan'
      'tanh'
    }
    os: copy os, {
      'clock'
      'date'
      'difftime'
      'time'
    }
    package: copy os, {
      'loaded'
      'loaders'
      'path'
      'seeall'
    }
    string: copy string, {
      'byte'
      'char'
      'dump'
      'find'
      'format'
      'gmatch'
      'gsub'
      'len'
      'lower'
      'match'
      'rep'
      'reserve'
      'sub'
      'upper'
    }
    table: copy table, {
      'concat'
      'insert'
      'maxn'
      'remove'
      'sort'
    }
    utf8: copy utf8, {
      'char'
      'charpattern'
      'codepoint'
      'codes'
      'len'
      'offset'
    }
  }

--- Cache table for conversions of module names to file fragments. This exists
--  to prevent the searchers from repeatedly processing the module name.
--  @realm    : shared
--  @scope    : local
--  @type     : table
--  @keyvalue :
--    *   string -> string or nil
--        module names point to converted fragments of filepath if cached
fragments = do
  metatable = {}

  metatable.__index = (name) =>
    fragment = string.gsub name, '%.', '/'
    @[name] = fragment
    fragment

  setmetatable {}, metatable

--- Returns the `stock` require function as the "loader" for binary modules.
--  @realm    : shared
--  @scope    : global
--  @type     : function
--  @params   :
--    1.  name: string
--        module name
--  @returns  :
--    1.  function or string
--        stock `require` function if valid and error message if not
--  @warning  :
--    1.  The stock `require` function is unable to be protected. See
--        `STOCK_REQUIRE` for more information.
get_binary_loader = do
  --  Local "constant" filepath template
  MODULE_PATH = do
    realm = assert(
      (SERVER or MENU_DLL) and 'sv' or CLIENT and 'cl',
      'failed to resolve realm'
    )
    os    = assert(
      system.IsWindows! and 'win' or
      system.IsLinux! and 'linux' or
      system.IsOSX! and 'osx',
      'failed to resolve operating system'
    )
    arch = switch os
      when 'win'    then  BRANCH == 'x86-64' and '64' or '32'
      when 'linux'  then  BRANCH == 'x86-64' and '64' or ''
      else ''

    table.concat {'bin/gm', realm, '_?_', os, arch, '.dll'}

  --  Actual `get_binary_loader` function
  (name) ->
    fragment  = fragments[name]
    filepath  = string.gsub MODULE_PATH, '?', fragment
    if file.Exists filepath, 'LUA' then return loader
    --
    string.format "no binary module for '%s', tried %s", name, filepath

--- Returns the cached loader for the module if possible.
--  @realm    : shared
--  @scope    : global
--  @type     : function
--  @params   :
--    1.  name: string
--        module name
--  @returns  :
--    1.  function or string
--        loader function if valid and error message if not
--  @warning  :
--    1.  The stock `require` function is unable to be protected and is used for
--        binary modules. See `STOCK_REQUIRE` for more information.
get_cached_loader = (name) ->
  if loader = loaders[name] then return loader
  string.format "no cached loader for '%s'", name

--- Returns the custom compiled loader for the module if possible.
--  @realm    : shared
--  @scope    : global
--  @type     : function
--  @params   :
--    1.  name: string
--        module name
--  @returns  :
--    1.  function or string
--        loader function if valid and error message if not
--  @warning  :
--    1.  The returned loader has its environment set to `package.environment`,
--        which more closely resembles a Lua 5.1 environment. The only Garry's
--        Mod function included is `AddCSLuaFile`, and the default global
--        environment can only be accessed through the `default` keyvalue.
get_custom_loader = (name) ->
  fragment  = fragments[name]
  log       = for template in string.gmatch package.path, '([^;]+)'
    filepath  = string.gsub template, '?', fragment
    if file.Exists filepath, 'LUA'
      return compile filepath, package.environment
    string.format "no custom module for '%s', tried %s", name, filepath
  table.concat log, '\n\t'

--- Iterates over all searchers to find a suitable loader for the module.
--  @realm    : shared
--  @scope    : global
--  @type     : function
--  @params   :
--    1.  name: string
--        module name
--  @returns  :
--    1.  function
--        loader function
--  @warning  :
--    1.  If no searcher is satisfied and returns a loader value, an error
--        will be thrown.
get_loader = (name) ->
  log = for index, searcher in iterate_searchers!
    result    = searcher name
    result_t  = type result
    switch result_t
      when 'function'
        loaders[name] = result
        return result
      when 'string'   then result
      else
        error(
          string.format "expected table or string from searcher %u, got %s",
          index,
          result_t or 'nil'
        )
  error string.format "no module '%s'\n\t%s", name, table.concat log, '\n\t'

--- Returns the compiled loader for the module if possible. This uses
--  `CompileFile` instead of the stock require function. TODO: Can this
--  be protected with `pcall` or `xpcall`?
--  @realm    : shared
--  @scope    : global
--  @type     : function
--  @params   :
--    1.  name: string
--        module name
--  @returns  :
--    1.  function or string
--        loader function if valid and error message if not
get_stock_loader = do
  --  Local "constant" filepath template
  MODULE_PATH = 'includes/modules/?.lua'

  --  The actual `get_stock_loader` function
  (name) ->
    fragment  = fragments[name]
    filepath  = string.gsub MODULE_PATH, '?', fragment
    if file.Exists filepath, 'LUA' then compile filepath, _G
    string.format "no stock module for '%s', tried %s", name, filepath

--- Bogus value meant to signify an attempt to recursively require a module.
--  @realm    : shared
--  @scope    : local
--  @type     : table
--  @warning  :
guard = {}

--- Iterates over all searchers in the `searchers`/`package.loaders` table.
--  The binary loader, which is not in the table, is always attempted last.
--  @realm    : shared
--  @scope    : global
--  @type     : function
--  @returns  :
--    1.  function
--        callback to execute the first iteration
--  @warning  :
--    *   While this iterates over `searchers`/`package.loaders`, it will
--        also return `get_binary_loader` once the array is exhausted.
iterate_searchers = ->
  index = 0
  stop  = false
  ->
    index += 1
    if searcher = searchers[index]
      return index, searcher
    --
    if stop == false
      stop = true
      return index, get_binary_loader

--- Stores module-specific loaders.
--  @realm    : shared
--  @scope    : global
--  @type     : table
--  @keyvalue :
--    *   string -> function or `nil`
--        the module name points to its loader if precached
loaders = package.preload

--- Module search path templates. See `package.path` in the Lua 5.1 manual for
--  more information.
--  @realm    : shared
--  @scope    : global
--  @type     : string
--  @warning  :
--    *   The `file` library does not support leading slashes, so neither does
--        this function.
package.path = table.concat {
  '?.lua'
  '?/init.lua'
  'lib/share/lua/5.1/?.lua'
  'lib/share/lua/5.1/?/init.lua'
}, ';'

--- Cached return values. If a module is executed but returns no values, `true`
--  is stored in its place. See `package.loaded` in the Lua 5.1 manual for more
--  information.
--  @realm    : shared
--  @scope    : global
--  @type     : table
--  @keyvalue :
--    *   string -> any
--        if cached, module name points to return value or `true`
--  @warning  :
--    *   To mirror Lua 5.1's functionality, varargs are not supported. Only
--        the first return value is cached and returned.
returns = package.loaded

--- An array of searcher functions. Searcher functions take a module name and
--  produce a "loader" function if successful or an error message if not. The
--  returned function is responsible for executing the source code of the module
--  and accepts one argument: the module name.
--  @realm    : shared
--  @scope    : global
--  @type     : table
--  @array    :
--    *   function
--        Searcher function which takes a module name. Returns a loader
--        function if successful and an error message otherwise. The loader
--        function is what actually executes the source code.
searchers = package.loaders

--- Replacement for `require` which is functionally closer to the traditional
--  `require` function that comes with Lua 5.1. See `require` in the Lua 5.1
--  manual for more information.
--  @realm    : shared
--  @scope    : global
--  @type     : function
--  @params   :
--    1.    name
--          module name
--  @returns  :
--    1.    the return value of the module or `true`
--  @warning  :
--    *     If none of the module searchers are satisfied, an error will
--          be thrown. See `get_loader` for more information.
--    *     Since binary modules are executed with the stock `require` function,
--          requiring binary modules cannot be protected. See `STOCK_REQUIRE`
--          for more information.
_G.require = (name) ->
  lookup = returns[name]
  if lookup == guard
    error string.format "recursive require for module '%s' detected", name
  if lookup ~= nil
    return lookup

  returns[name] = guard

  loader        = get_loader name
  loaders[name] = loader

  result        = loader(name) or true
  returns[name] = result
  result

-- Replace `require` in the custom environment
package.environment.require = require

-- Add default searchers
for searcher in *{get_cached_loader, get_stock_loader, get_custom_loader}
  table.insert searchers, searcher