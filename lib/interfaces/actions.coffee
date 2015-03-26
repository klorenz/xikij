# Actions are used
#
#

Q          = require "q"
{keys}     = require "underscore"
{Readable} = require "stream"
{Action}   = require "../action"
{Response} = require "../response"

console = (require "../logger")("xikij.interface.Actions")

module.exports = (Interface) ->
  Interface.define class Actions
    # expand an entry one level
    expand: (args...) -> @dispatch "expand", args

    # collapse current entry
    collapse: (args...) -> @dispatch "collapse", args

    # expand an entry completely.  This works only for objects
    # and xikij files.
    expanded: (args...) -> @dispatch "expanded", args

    # completion
    complete: (args...) -> @dispatch "complete", args

    # return true if `name` is an action's name
    isAction: (name) -> name in ['expand', 'collapse', 'expanded', 'complete']

    # return subject of a context.  Usually it is context itself, but
    # in menu context it is selected menu module.
    #
    # - req: Request
    #
    getSubject: (args...) -> @dispatch "getSubject", args

    userDialog: (args...) -> @dispatch "userDialog", args

    getUserInput: (args...) -> @dispatch "userInput", args

    osOpen:     (args...) -> @dispatch "osOpen", args

  Interface.default class Actions extends Actions

    expanded:   (req) ->
      @getContexts().then (contexts) =>
        result = []
        promise = Q(result)
        contexts.forEach (ContextClass) ->
          ctx = new ContextClass req.context
          promise = promise.then (result) ->
            ctx.rootMenuItems()
              .then (items) ->
                result.concat items
              .fail (error) ->
                console.log error

        promise

    collapse: (req) -> Q.fcall -> null

    complete: (req) -> Q.fcall -> null

    getSubject: (req) -> Q.fcall -> null

    expand: (req) ->
      Q(@expanded(req)).then (result) =>
        console.log "expand result", result
        return result if not (typeof result is "object")
        return result if result instanceof Response
        return result if result instanceof Array
        return result if result instanceof Buffer
        return result if result instanceof Action
        return result if result instanceof Readable
        return keys result

    osOpen: (name) ->
      Q(xikij.Action(action: "osOpen", name: name))

    #userDialog: ()

    getUserInput: (opts) ->
      name     = opts.name
      _default = opts.default or ""

      Q xikij.Action action: "userInput", name: name, default: _default
