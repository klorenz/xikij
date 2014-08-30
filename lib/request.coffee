{promised}  = require "./util"
Q = require "q"
{RejectPath} = require "./context"

DEBUG = true
# debug = (args...) ->
#   console.debug "xikij:Request:", args... if DEBUG

unless console.debug
  console.debug = ->

_ID = 0

class Request
  constructor: (opts) ->
    {@body, @nodePaths, @args, @action, @input} = opts
    {@before, @after, @prefix} = opts

    for k,v of opts
      this[k] = v

    unless @nodePaths
      @nodePaths = {}

  getContext: (context, xikiPath) ->
    console.debug "xikij:Request:", "getContext", context, xikiPath

    unless xikiPath
      context = Q(context)
      @nodePaths.forEach (xikiPath) =>
        console.debug "-> nodePath", xikiPath
        context = context.then (ctx) =>
          console.debug "-> ctx", ctx
          console.debug "-> xikiPath", xikiPath
          @getContext(ctx, xikiPath)

      return context

    else
      promises = []
      deferred = Q.defer()

      ID = ++_ID

      Q.when context, (context) =>
        context.getContexts().then (contexts) =>
          console.debug ID, "contexts", contexts

          selectedContext = null
          contextsDone = []
          console.debug ID, "contextsDone (init)", contextsDone

          contexts.forEach (ContextClass, i) =>
            ctx = new ContextClass(context)
            console.debug ID, i, "parent", context, "child", ctx

            Q .fcall =>
                ctx.does(this, xikiPath)
              .then (result) =>
                contextsDone.push ctx
                console.debug ID, "contextsDone (then)", contextsDone

                console.debug ID, "ctx.does", ctx, result

                ctx.reject() unless result

                ctx = ctx.getContext()

                console.debug ID, "ctx.doing!", ctx

                unless selectedContext?
                  selectedContext = ctx
                else if selectedContext.weight > ctx.weight
                  selectedContext = ctx

                if contextsDone.length == contexts.length
                  console.debug ID, "==> resolving", selectedContext
                  unless selectedContext?
                    selectedContext = context
                  deferred.resolve(selectedContext)

              .fail (error) =>
                if not (ctx in contextsDone)
                  contextsDone.push ctx
                console.debug ID, "contextsDone (fail)", contextsDone

                console.debug ID, "error on ctx does", error
                unless error instanceof RejectPath
                  deferred.reject(error)
                else if contextsDone.length == contexts.length
                  unless selectedContext?
                    selectedContext = context
                  console.debug ID, "==> resolving", selectedContext
                  deferred.resolve(selectedContext)

              .done()

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

    context.getContextClass()
      .then (Context) =>

        # this implements getting things from environment
        class Request extends Context
          projectDirs: -> Q.fcall -> theRequest.args.projectDirs
          fileName: -> Q.fcall -> theRequest.args.fileName

        @getContext(new Request(context)).then (context) =>
          @context = context
          action = @action or "expand"
          result = null
          if action of context
            result = context[action](this)

          console.debug "process result", result
          deferred.resolve Q.when result, (r) -> r

      .done()

      # .fail (error) =>
      #   console.debug "getContext failed", error
      #   deferred.reject(error)

    deferred.promise


module.exports = {Request}
