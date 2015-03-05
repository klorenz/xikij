Q               = require "q"
{promised, getUserHome, getUserName} = require "./util"
{RejectPath}    = require "./context"
{extend, clone} = require "underscore"
{RequestContextClass} = require "./request-context"
path = require 'path'

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

    console.log "args2", @args

    for k,v of opts
      this[k] = v

    console.log "args3", @args

    unless @nodePaths
      @nodePaths = {}

  getContext: (context, reqPath) ->
    unless reqPath
      context = Q(context)

      @nodePaths.forEach (reqPath) =>
        console.log "reqPath"
        context = context.then (ctx) =>
          c = @getContext(ctx, reqPath)
          console.log "reqPath", reqPath, "context", c
          c

      return context

    else
      promises = []
      deferred = Q.defer()

      ID = ++_ID

      Q.when context, (context) =>
        context.getContexts().then (contexts) =>

          selectedContext = null
          contextsDone = []

          contexts.forEach (ContextClass, i) =>
            ctx = new ContextClass(context)

            Q .fcall =>
                ctx.does(this, reqPath)
              .then (result) =>

                unless result
                  #console.log "reject", reqPath.toPath(), "context", ctx
                  ctx.reject()

                Q.when ctx.getContext(), (ctx) =>
                  contextsDone.push ctx
                  #console.log "contextsDone-ok", contextsDone

                  unless selectedContext?
                    selectedContext = ctx
                  else if ctx.weight > selectedContext.weight
                    selectedContext = ctx

                  if contextsDone.length == contexts.length
                    unless selectedContext?
                      selectedContext = context

                    #console.log "resolve-ok", reqPath.toPath(), "context", selectedContext
                    deferred.resolve(selectedContext)

              .fail (error) =>
                if not (ctx in contextsDone)
                  contextsDone.push ctx

                #console.log "contextsDone-fail", contextsDone

                unless error instanceof RejectPath
                  deferred.reject(error)
                else if contextsDone.length == contexts.length
                  unless selectedContext?
                    selectedContext = context
                  #console.log "resolve-fail", reqPath.toPath(), "context", selectedContext
                  deferred.resolve(selectedContext)

              .done()

      return deferred.promise

    pathToArgs

    # respond: (responder) ->
    #   responder.apply @


  clone: (opts) ->
    options = {}
    for k,v of this
      options[k] = v

    for k,v of opts
      options[k] = v

    new Request options

  # returns context, such that you can react on its result
  process: (context) ->

    opts = @args or {}

    deferred = Q.defer()

    context.getContextClass()
      .then (Context) =>
        RequestContext = RequestContextClass(Context, opts)

        @getContext(new RequestContext(context)).then (context) =>
          @context = context
          action = @action or "expand"
          result = null
          console.log "CONTEXT for PROCESS", context

          if action of context
            result = context[action](this)

          console.debug "process result", result

          Q(result).then (r) ->
            deferred.resolve(r)

      .fail (e) =>
        #console.log e.stack
        deferred.reject(e)

      # .fail (e) =>
      #   console.log e.stack
      #   #deferred.reject(e)
      #   deferred.resolve(e.stack)
      #
      # .done()

      # .fail (error) =>
      #   console.debug "getContext failed", error
      #   deferred.reject(error)

    deferred.promise


module.exports = {Request}
