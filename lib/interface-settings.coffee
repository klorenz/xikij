Q = require "q"

module.exports = (Interface, xikij) ->
  Interface.define class Request
    getConfig:   (args...) -> @dispatch "getConfig", args
    setConfig:   (args...) -> @dispatch "setConfig", args
    getSettings: (args...) -> @dispatch "getSettings", args


  Interface.default class Request extends Request
    getConfig: (path) -> Q(null)
      path.selectFromObject

    setConfig: (args...) -> Q(null)

    getSettings: (path=null) ->
      if path?
        path.selectFromObject @context.getSettings()
      else
        result = {}

        for m in @packages.modules()


        result = {}

        if not @context
          for m in @packages.modules()


        else
          extend(result, @context.getSettings()) if @context

        extend(result, @configDefaults) if @configDefaults
