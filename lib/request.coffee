{EventEmitter} = require "events"

class Request extends EventEmitter
  constructor: (opts) ->
    {@body, @nodePaths, @args, @action, @input} = opts
    {@before, @after, @prefix} = opts

    for k,v of opts
      this[k] = v

    unless @nodePaths
      @nodePaths = {}

  getContext: (context, xikiPath) ->
    unless xikiPath
      for xikiPath, i in @nodePaths
        context = @getContext context, xikiPath
      return context

    else
      promises = []

      for ContextClass in context.contexts()
        ctx = new ContextClass(context)
        promises.push Q(ctx.does(this, xikiPath))

      return Q.allSettled(promises).then (results) =>
        doingCtx = null

        results.forEach (result) =>
          return unless result.state is "fulfilled"

          ctx = result.value
          return unless ctx
          return doingCtx = ctx unless doingCtx

          if ctx.weight > doingCtx.weight
            return doingCtx = ctx

        doingCtx

  clone: (opts) ->
    options = {}
    for k,v of this
      options[k] = v

    for k,v of opts
      options[k] = v

    new Request options

  # returns context, such that you can react on its result
  process: (context) ->
    Context    = context.getContextClass()
    theRequest = this

    # this implements getting things from environment
    class Request extends Context
      projectDirs: -> Q.fcall -> theRequest.args.projectDirs
      fileName: -> Q.fcall -> theRequest.args.fileName

    @getContext(new Request(context)).then (@context) =>
      action = @action or "expand"
      @context[action](this)

module.exports = {Request}
