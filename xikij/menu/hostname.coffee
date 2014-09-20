@doc = """
  Print hostname of machine running xikij
  """

@menu = ->
  os = require "os"
  os.hostname()
