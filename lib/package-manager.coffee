path           = require "path"
fs             = require 'fs'
{EventEmitter} = require "events"
Q              = require "q"
{makeTree}     = require "./util"
{keys}         = require "underscore"
{Path}         = require "./path"
getLogger    = require "./logger"

class Package

  constructor: (@dir, @name) ->
    unless @name
      @name = path.basename(@dir)
      if @isUserPackage()
        @_username = @name
        @name = "user-#{@name}"

    @modules = {}
    @settings = {}
    @errors = null

    debugger
    @log = getLogger("xikij.Package", prefix: "(#{@name})", level: "debug")

  isUserPackage: () ->
    return "user_modules" in @dir

  getUserName: () -> @_username

  load: (xikij) ->
    @log.debug "load package from directory", @dir

    watchEventHandler = (event, filename) =>
      # event is 'rename' or 'change'
      @log.debug "watcher event:", event, filename

      xikij.moduleLoader.load(this, filename).then =>
        @log.debug "reload #{filename}"

      # maybe send event, that module has been updated

    if @watcher
      @unwatch()

    # TODO: remove watcher on xikij close
    @log.debug "add watcher of #{@dir}"
    @watcher = fs.watch @dir, {recursive: true}, watchEventHandler

    xikij.event.on "shutdown", (xikij) =>
      @unload(xikij)

    xikij.moduleLoader.load(this).then =>
      @log.debug "loaded", @modules, @settings

  unwatch: ->
    if @watcher
      @log.debug "stop watcher of #{@dir}"
      @watcher.close()
      @watcher = null

  unload: (xikij) ->
    @log.debug "package(#{@name}) unload"
    @unwatch()

  asObject: (attributes...)->
    obj = {}

    for k,v of this
      if attributes.length
        continue if not (k in attributes)

      obj[k] = v

    obj

  # run: (request) ->
  #   tree = makeTree @modules
  #
  #   if not request.path.empty()
  #     obj = request.path.selectFromTree tree
  #   else
  #     obj = tree
  #
  #   return obj

  toString: -> "name: #{@name}"


class PackageManager
  constructor: (@xikij) ->
    @_packages = []
    @_user_packages = []

    @loading = []
    #@loaded =  # be a promise
    @_settings = null
    #@_user_modules = null

    @_modules_suff = {}
    @_modules = {}

    @xikij.event.on "package:module-updated", (name, module) =>
      @log.debug "package:module-updated", name, module

      data = {}
      data["#{module.menuName}.#{module.menuType}"] = module
      makeTree data, @_modules_suff

      data = {}
      data["#{module.menuName}"] = module
      makeTree data, @_modules

    @log = getLogger("xikij.PackageManager")

  loaded: ->
    Q.allSettled(@loading).then (result) =>
      @xikij.event.emit "loaded"
      @log.debug "loaded all packages", result
      return result
    .fail (err) =>
      @log.debug "error in loading packages", err.stack

  add: (dir, name) ->
    pkg = new Package dir, name

    @loading.push pkg.load @xikij

    @_packages.push pkg

    # packageLoaders = @listeners("load-package").length
    # console.log "packageLoaders #{packageLoaders}"
    #
    #
    #
    # @emit "load-package", pkg, =>
    #   packageLoaders--
    #   @emit "loaded" unless packageLoaders

  all: -> @_packages

  userPackages: -> (pkg for pkg in @_packages when pkg.isUserPackage())

  getUserPackage: (user) ->
    for pkg in @userPackages()
      return pkg if pkg.getUserName() == user

  failed: ->
    result = []
    for pkg in @_packages
      result.push pkg if pkg.errors

    result

  modules: (req) ->
    #if req
      # 1. if there is a home directory set in request, then
      #    this is first package
      #
      # 2. if there is a project path set in request, then
      #    this is second package
      #
      # 3. all other packages, finally xikijs package
      #
    # else

    result = []
    for pkg in @_packages
      for k,m of pkg.modules
        result.push m

    return result

  getModules: -> @_modules

  # getPackageModule: (name) ->
  #   for pkg in @_packages
  #
  #   if not @_modules? ->
  #     for
  #


  getPackageSettings: (name, packageName=null) ->
    if not @_settings?
      @_settings = {}

      for pkg in @_packages
        continue if pkg.isUserPackage()

        makeTree pkg.settings, @_settings, (key,value) ->
          # if value.menuType
          #   key = "#{key}.#{value.menuType}"
          key.split("/")[1..]

    unless name?
      return @_settings

  getUserSettings: (user, name) ->
    # if not @_user_settings?
    #   for pkg in @userPackages()
    #     if pkg.name == user


  # get a module without respect of package (merged packages)
  getModule: (name) ->

    # if not @_modules?
    #   @_modules = {}
    #   for pkg in @_packages
    #     makeTree pkg.modules, @_modules, (key,value) ->
    #       # if value.menuType
    #       #   key = "#{key}.#{value.menuType}"
    #       key.split("/")[1..]
    mods = @_modules
    unless name?
      return mods

    (new Path(name)).selectFromTree mods, found: (object, path, i) ->
      # if is module
      if "moduleName" of object
        return object
      else
        false

  # get a module without respect of package (merged packages)
  getModuleWithSuffix: (name) ->

    # if not @_modules?
    #   @_modules = {}
    #   for pkg in @_packages
    #     makeTree pkg.modules, @_modules, (key,value) ->
    #       # if value.menuType
    #       #   key = "#{key}.#{value.menuType}"
    #       key.split("/")[1..]
    mods = @_modules_suff

    unless name?
      return mods

    (new Path(name)).selectFromTree mods, found: (object, path, i) ->
      # if is module
      if "moduleName" of object
        return object
      else
        false

  getPackages: ->
    return @_packages

module.exports = {Package, PackageManager}
