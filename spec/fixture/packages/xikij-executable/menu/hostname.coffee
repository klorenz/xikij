module.exports =
  doc: """
    Print hostname of machine running xikij
    """

  run: ->
    os = require "os"
    os.hostname()
