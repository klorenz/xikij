{promised}  = require "./util"
Q = require "q"
{RejectPath} = require "./context"

class Request
  constructor: (opts) ->
    {@body, @nodePaths, @args, @action, @input} = opts
    {@before, @after, @prefix} = opts

    for k,v of opts
      this[k] = v

    unless @nodePaths
      @nodePaths = {}

  getContext: (context, xikiPath) ->
    console.log "getContext", context, xikiPath

    unless xikiPath
      context = Q(context)
      @nodePaths.forEach (xikiPath) =>
        console.log "nodePath", xikiPath
        context = context.then (ctx) =>
          console.log "ctx", ctx
          console.log "xikiPath", xikiPath
          @getContext(ctx, xikiPath)

      return context

    else
      promises = []
      deferred = Q.defer()

      Q.when context, (context) =>
        context.getContexts().then (contexts) =>
          console.log "contexts", contexts

          selectedContext = null
          last = contexts.length-1

          for ContextClass,i in contexts
            ctx = new ContextClass(context)

            f = (ctx, i) =>
              Q .fcall =>
                  ctx.does(this, xikiPath)
                .then (result) =>
                  console.log "ctx.does", result

                  ctx.reject() unless result

                  ctx = ctx.getContext()
                  console.log "ctx.doing!", ctx

                  unless selectedContext?
                    selectedContext = ctx
                  else if selectedContext.weight > ctx.weight
                    selectedContext = ctx

                  console.log "i", i, "last", last

                  if i == last
                    console.log "resolving", selectedContext
                    unless selectedContext?
                      selectedContext = context
                    deferred.resolve(selectedContext)

                .fail (error) =>
                  console.log "error on ctx does", error
                  console.log "i", i, "last", last
                  unless error instanceof RejectPath
                    deferred.reject(error)
                  else if i == last
                    unless selectedContext?
                      selectedContext = context
                    console.log "resolving", selectedContext
                    deferred.resolve(selectedContext)

                .done()

            f(ctx, i)

      return deferred.promise




  # getContext: (context, xikiPath) ->
  #   unless xikiPath
  #     #@nodePaths.forEach
  #     for xikiPath, i in @nodePaths
  #
  #       context = @getContext context, xikiPath
  #     return context
  #
  #   else
  #     promises = []
  #
  #     console.log "context", context
  #     Q.when context, (context) =>
  #       context.getContexts().then (contexts) =>
  #         for ContextClass in contexts
  #           ctx = new ContextClass(context)
  #
  #           promises.push Q.ninvoke(ctx, "does", this, xikiPath).then (result) =>
  #             if result then ctx.getContext() else null
  #
  #         console.debug "promises", promises
  #
  #         Q.fcall =>
  #           selectedContext = null
  #
  #           for promise in promises
  #
  #
  #
  #         return Q.allSettled(promises).then (results) =>
  #           console.debug "all settled"
  #           doingCtx = null
  #
  #           results.forEach (result) =>
  #             console.log "result.state", result.state
  #
  #             return unless result.state is "fulfilled"
  #
  #             ctx = result.value
  #
  #             return unless ctx
  #             return doingCtx = ctx unless doingCtx
  #
  #             if ctx.weight > doingCtx.weight
  #               return doingCtx = ctx
  #
  #           return context unless doingCtx
  #
  #           console.debug "doingCtx", doingCtx
  #
  #           doingCtx

  clone: (opts) ->
    options = {}
    for k,v of this
      options[k] = v

    for k,v of opts
      options[k] = v

    new Request options

  # returns context, such that you can react on its result
  process: (context) ->
    theRequest = this

    deferred = Q.defer()

    context.getContextClass().then (Context) =>

      # this implements getting things from environment
      class Request extends Context
        projectDirs: -> Q.fcall -> theRequest.args.projectDirs
        fileName: -> Q.fcall -> theRequest.args.fileName

      @getContext(new Request(context)).then (context) =>
        @context = context
        action = @action or "expand"
        result = context[action](this)
        console.log "process result", result
        deferred.resolve Q.when result, (r) -> r

      .fail (error) =>
        console.log "getContext failed", error
        deferred.reject(error)

    deferred.promise


module.exports = {Request}
