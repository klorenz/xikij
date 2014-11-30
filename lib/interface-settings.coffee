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

    getSettings: (path, user=null) ->
      if user?
        user = Q(user)
      else
        user = @getUserName()

      user.then (username) =>
        _path = path.split "/"

        # TODO _path should be reversed, this is more robust
        for p,i of _path
          name = _path[..i].join("/")
          if name of xikij.settings
            settings = xikij.settings[name]
            name = _path[i+1..].join("/")
            unless name
              return new UserSettings user, settings
            else
              return settings.get(user, name)

        throw new Error("Settings #{path} not found")


      # if path?
      #   path.selectFromObject @context.getSettings()
      #
      # else
      #   result = {}
      #
      #   for m in @packages.modules()
      #
      #
      #   result = {}
      #
      #   if not @context
      #     for m in @packages.modules()
      #
      #
      #   else
      #     extend(result, @context.getSettings()) if @context
      #
      #   extend(result, @configDefaults) if @configDefaults
