module.exports = (Interface) ->
  Interface.define class Contexts
    # ### expand
    #
    contexts: (args...) -> @context.contexts args...

    addContext: (args...) -> @context.addContext args...

  Interface.default class Contexts extends Contexts

    contexts: (objects) ->
      named = objects?.named? ? false

      if named
        [name, @_context[name]] for name in @_contexts
      else
        @_context[name] for name in @_contexts

    addContext: (name, ctx) ->
      if not (name in @_contexts)
        @_contexts.push name
      @_context[name] = ctx
