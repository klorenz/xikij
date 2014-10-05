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

    @dispatchedContexts = []

    #@on "open", (xikiRequest) => @open(xikiRequest)
    #@on "open", (xikiRequest) => @open(xikiRequest)

  CONTEXT: null
  PATTERN: null

  dispatch: (method, args) ->
    context = @context
    while context
      #console.log "dispatch: try #{method} at context", context

      if context.hasOwnProperty(method)
        return context[method].apply @, args

      if context.__proto__.hasOwnProperty(method)
        return context[method].apply @, args

      context = context.context

  self: (attr, args...) ->
    context = @

    found = 0
    while context
      if context.hasOwnProperty(attr)
        result = context[attr]
        found = 1
        break

      if context.__proto__.hasOwnProperty(attr)
        result = context[attr]
        found = 1
        break

      context = context.context

    if found
      if result instanceof Function
        if args.length
          return result.apply context, args
        else
          return (args...) -> result.apply context, args
      return result

    return undefined


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
