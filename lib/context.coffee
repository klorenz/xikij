module.exports =
  class Context

    NAME: null
    MENU: null

    constructor: (@context) ->

      if typeof @PATTERN is "string"
        @PATTERN = new Regexp @PATTERN

      @nodePath = null
      @xikiPath = null
      @subcontext = null

      #@on "open", (xikiRequest) => @open(xikiRequest)
      #@on "open", (xikiRequest) => @open(xikiRequest)

    CONTEXT: null
    PATTERN: null

    does: (xikiRequest, xikiPath) ->
      if @PATTERN?
        m = @PATTERN.exec xikiPath.toPath()
        if m
          @mob = m
          return true

      return false unless xikiPath

      # mob contains match object from @PATTERN

    rootMenuItems: -> return ''

    # called to get context for this context
    getContext: -> this
