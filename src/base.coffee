# Xiki Base
# =========
#
# Class XikiBase forms base of Xiki and implements most interfaces provides
# through xiki contexts.

   {XikiInterfaces} = require './interfaces'

   class XikiBase extends XikiInterfaces(
     'StaticVariable', 'Settings', 'FileSystem',
     'ExecuteProgram', 'Completion', 'XikiData')

# Xiki Data
# ---------
#
# On

    parseData: (string) ->
      {parse} = require './parser'
      parse string.toString()

    assembleData


     #constructor:
