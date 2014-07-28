{EventEmitter} = require "events"

class Request extends EventEmitter
  constructor: (opts) ->
    {@body, @nodePaths, @args, @action, @req, @res} = opts
    {@before, @after, @prefix} = opts

    for k,v of opts
      this[k] = v

    @input = @body

    unless @nodePaths
      @nodePaths = {}

  getContext: (context, xikiPath) ->
    unless xikiPath
      for xikiPath, i in @nodePaths
        context = @getContext context, xikiPath
      return context
    else
      for ContextClass in context.contexts()
        ctx = new ContextClass(context)

        if ctx.does this, xikiPath
          return ctx.getContext()

    return context

  clone: (opts) ->
    options = {}
    for k,v of this
      options[k] = v

    for k,v of opts
      options[k] = v

    new Request options

  # returns context, such that you can react on its result
  process: (context, respond) ->
    console.log "getting context"
    @context = @getContext context
    @respond = respond

    console.log "doing action"

    action = @action or "expand"

    try
      result = @context[action](this)
    catch err
      console.log err
      respond(err)

    unless result is undefined
      @respond result

module.exports = {Request}
