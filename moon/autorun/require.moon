AddCSLuaFile filepath for filepath in *{
  'includes/modules/require.lua'
  'require_test.lua'
}

require 'require'

assert(
  require('require_test') == 'Lorem ipsum dolor sit amet',
  'require test failed'
)