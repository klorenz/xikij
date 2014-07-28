@docs = """
  Print hostname of machine running xiki-Ray
  """

@menu = ->
  os = require "os"
  os.hostname()
