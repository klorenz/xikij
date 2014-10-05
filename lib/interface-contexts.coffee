Q = require "q"

module.exports = (Interface, xikij) ->
  Interface.define class Contexts
    # ### expand
    #
    getContexts: (args...) -> @dispatch "getContexts", args

    addContext: (args...) -> @dispatch "addContext", args

    #getContextClass: (args...) -> @context.getContextClass.call @, args...

    getContextClass: (args...) -> @dispatch "getContextClass", args

  Interface.default class Contexts extends Contexts

    getContexts: (objects) -> Q.fcall =>
      named = objects?.named? ? false

      if named
        [name, xikij._context[name]] for name in xikij._contexts
      else
        xikij._context[name] for name in xikij._contexts

    addContext: (name, ctx) ->
      if not (name in xikij._contexts)
        xikij._contexts.push name
      xikij._context[name] = ctx

    getContextClass: -> Q(xikij.Context)
