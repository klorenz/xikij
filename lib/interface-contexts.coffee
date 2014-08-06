Q = require "q"

module.exports = (Interface) ->
  Interface.define class Contexts
    # ### expand
    #
    getContexts: (args...) -> @context.contexts args...

    addContext: (args...) -> @context.addContext args...

    getContextClass: -> Q.fcall =>
      if "Context" of this
        @Context
      else
        @context.getContextClass()

  Interface.default class Contexts extends Contexts

    getContexts: (objects) -> Q.fcall =>
      named = objects?.named? ? false

      if named
        [name, @_context[name]] for name in @_contexts
      else
        @_context[name] for name in @_contexts

    addContext: (name, ctx) ->
      if not (name in @_contexts)
        @_contexts.push name
      @_context[name] = ctx
