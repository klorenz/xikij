Q = require "q"

console = (require "../logger")(name: "xikij.interface.Contexts")

module.exports = (Interface, xikij) ->
  Interface.define class Contexts
    # ### expand
    #
    getContexts: (args...) -> @dispatch "getContexts", args

    addContext: (args...) -> @dispatch "addContext", args

    #getContextClass: (args...) -> @context.getContextClass.call @, args...

    getContextClass: (args...) -> @dispatch "getContextClass", args

    getPrompts: (args...) -> @dispatch "getPrompts", args

  Interface.default class Contexts extends Contexts

    getContexts: (objects) ->
      xikij.initialized.then =>
        named = objects?.named? ? false
        console.debug "xikij contexts", xikij._contexts

        if named
          [name, xikij._context[name]] for name in xikij._contexts
        else
          xikij._context[name] for name in xikij._contexts

    addContext: (name, ctx) ->
      if not (name in xikij._contexts)
        xikij._contexts.push name
      xikij._context[name] = ctx

    getContextClass: -> Q(xikij.Context)

    getPrompts: -> @getContexts().then (contexts) ->

      prompts = []
      for context in contexts
        x = context::
        if "PS1" of context::
          prompts.push context::PS1

      return prompts
