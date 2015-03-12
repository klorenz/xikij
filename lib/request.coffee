Q               = require "q"
{promised, getUserHome, getUserName} = require "./util"
{RejectPath}    = require "./context"
{extend, clone} = require "underscore"
{RequestContextClass} = require "./request-context"
path = require 'path'

DEBUG = true
# debug = (args...) ->
#   console.debug "xikij:Request:", args... if DEBUG

getLogger = require "./logger"


_ID = 0

class Request
  constructor: (opts) ->
    {@body, @nodePaths, @args, @action, @input} = opts
    {@before, @after, @prefix} = opts

    @console = getLogger "xikij.Request",
      prefix: "("+[x.toString() for x in @nodePaths].join("@")+")"

    @console.debug "created"
    @console.debug ".body", @body
    @console.debug ".nodePaths", @nodePaths
    @console.debug ".args", @args
    @console.debug ".action", @action
    @console.debug ".input", @input

    for k,v of opts
      this[k] = v

#    console.log "args3", @args

    unless @nodePaths
      @nodePaths = {}

  selectContext: (ctx, reqPath, status) ->
    {contextsDone, promises, deferred} = status
    @console.debug "selectContext()", ctx, reqPath, status

    Q
    .fcall =>
      ctx.does(this, reqPath)

    .then (result) =>
      unless result
        #console.log "reject", reqPath.toPath(), "context", ctx
        return ctx.reject()

      @console.debug ctx, "does", reqPath

      Q.when ctx.getContext(), (ctx) =>
        contextsDone.push ctx
        #console.log "contextsDone-ok", contextsDone

        unless status.selectedContext?
          status.selectedContext = ctx
        else if ctx.weight > status.selectedContext.weight
          status.selectedContext = ctx

        if contextsDone.length == status.contexts.length
          unless status.selectedContext?
            status.selectedContext = status.context

          #console.log "resolve-ok", reqPath.toPath(), "context", selectedContext
          deferred.resolve(status.selectedContext)

    .fail (error) =>
      if not (ctx in contextsDone)
        contextsDone.push ctx

      #console.log "contextsDone-fail", contextsDone

      unless error instanceof RejectPath
        deferred.reject(error)
      else if contextsDone.length == status.contexts.length
        unless status.selectedContext?
          status.selectedContext = status.context
        #console.log "resolve-fail", reqPath.toPath(), "context", selectedContext
        deferred.resolve(status.selectedContext)

    .done()

  getContext: (context, reqPath) ->
    console = @console
    unless reqPath
      context = Q(context)

      @nodePaths.forEach (reqPath) =>
        console.debug "getContext() reqPath"
        context = context.then (ctx) =>
          c = @getContext(ctx, reqPath)
          console.debug "getContext() reqPath", reqPath, "context", c
          c

      return context

    else
      console.log "getContext() get context for reqPath", reqPath

      status =
        promises: []
        deferred: Q.defer()
        selectedContext: null
        contextsDone: []

      ID = ++_ID

      Q.when context, (context) =>
        console.log "context", context
        status.context = context

        context.getContexts().then (contexts) =>
          console.log "contexts", contexts
          status.contexts = contexts
          contexts.forEach (ContextClass, i) =>
            @selectContext new ContextClass(context), reqPath, status

      return status.deferred.promise

    #pathToArgs

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
    console = @console

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
