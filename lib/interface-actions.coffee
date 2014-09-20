Q = require "q"

module.exports = (Interface) ->
  Interface.define class Actions
    # ### expand
    #
    expand: (req) -> @context.expand req

    collapse: (req) -> @context.collapse req

    expanded: (req) -> @context.expanded req

    complete: (req) -> @context.complete req

    isAction: (name) -> name in ['expand', 'collapse', 'expanded', 'complete']


  Interface.default class Actions extends Actions

    expand:   (req) ->
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

    expanded: (req) -> @expand req

    complete: (req) -> Q.fcall -> null
