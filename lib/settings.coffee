{EventEmitter} = require "events"
{clone, isObject, isArray} = require "underscore"
{cloneDeep} = require "./util"

class UserSettings
  constructor: (@user, @settings) ->

  get: (name) ->
    @settings.get(@user, name)

  setGlobal: (name, value) ->
    @settings.setGlobal name, value

  set: (name, value) ->
    @settings.set @user, name

class Settings extends EventEmitter
  constructor: ->
    @_settings = {}
    @_merged   = {}
    @_runtime  = {}
    @_order    = []

    @_user_runtime = {}
    @_user_settings = {}
    @_user_order = {}
    @_user_merged = {}

  # update settings object from a settings fragment
  #
  # settings fragment must be an object having at least following attributes:
  # - moduleName, e.g. xikij/hostname
  # - platform, .e.g. null or "windows", "linux", "darwin", ...
  # - settings, settings itself

  update: (settings) ->
    name = settings.moduleName

    if settings.platform?
      name += "-#{settings.platform}"

    if settings.pkg?.isUserPackage()
      console.log "user package settings", settings

      user = settings.pkg.getUserName()
      unless user of @_user_settings
        @_user_settings[user] = {}

      @_user_settings[user][name] = settings

      unless username of @_user_order
        @_user_order[user] = []

      if name of @_user_settings[user]
        @emit "unload", @, @_user_settings[user][name], {name, user}
      else
        @_user_order[user].push name

      @_user_settings[user][name] = settings
      @emit "load", @, settings, {name, user}

      #@emit "refresh",

      @_user_merged[user] = cloneDeep(@_merged)
      for name in @_user_order[user]
        @merge @_user_merged[user], @_user_settings[user][name].settings, merge: true

      return

    if name of @_settings
      @emit "unload", @, @_settings[name], {name}
    else
      @_order.push name

    @_settings[name] = settings
    @emit "load", @, settings, {name}

    @_merged = {}

    for name in @_order
      @merge @_merged, @_settings[name].settings, merge: true

    # this usually means that each user merged array needs to be updated
    for user of @_user_merged
      @_user_merged[user] = cloneDeep(@_merged)
      for name in @_user_order[user]
        @merge @_user_merged[user], @_user_settings[user][name].settings, merge: true


  log: (s) -> console.log s

  merge: (destination, source, {merge}) ->
    path = [] unless path?

    if merge and isArray(destination)
      if isArray(source)
        for e in source
          destination.push e
          return destination
      else
        @warn "Cannot merge non-Array into Array", source

    if merge and isObject(destination)
      if isObject(source)
        for k,v of source
          if m = k.match /(.*)~$/
            key = m[1]
            unless key of destination
              destination[key] = v
              continue

            destination[key] = @merge clone(destination[key]), v, merge: true

          else
            destination[k] = v

      else
        @warn "Cannot merge non-Object into Object", source

    return source

  get: (user, name) ->
    if name of @_runtime
      return @_runtime[name]

    if user of @_user_runtime
      if name of @_user_runtime[user]
        return @_user_runtime[user][name]

    if not (user of @_user_merged)
      @_user_merged[user] = cloneDeep(@_merged)

    return @_user_merged[user][name]

  setGlobal: (name, value) -> @_runtime[name] = value

  set: (user, name, value) ->
    if not (user of @_user_runtime)
      @_user_runtime[user] = {}
    @_user_runtime[user][name] = value

  # set: (name, value, user=null) ->
  #   @_user_runtime[user][name] = value
  #
  # getGlobal: (name) ->
  #   return @_runtime[name]
  #
  # setGlobal:
  #   return @_user_merged





module.exports = {Settings}
