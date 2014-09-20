Q = require 'q'

class RejectPath extends Error
  constructor: (s) -> super()

class Context

  NAME: null
  MENU: null

  constructor: (@context) ->

    if typeof @PATTERN is "string"
      @PATTERN = new Regexp @PATTERN

    @nodePath = null
    @path = null
    @subcontext = null

    @weight = 1

    #@on "open", (xikiRequest) => @open(xikiRequest)
    #@on "open", (xikiRequest) => @open(xikiRequest)

  CONTEXT: null
  PATTERN: null

  does: (request, requestPath) ->
    if @PATTERN?
      m = @PATTERN.exec requestPath.toPath()
      if m
        @mob = m
        return true

    return false unless requestPath

    # mob contains match object from @PATTERN

  reject: (s)->
    throw new RejectPath(s)

  rootMenuItems: -> Q.fcall -> return []

  # called to get context for this context
  getContext: -> this

module.exports = {Context, RejectPath}
