path           = require "path"
fs             = require 'fs'
{EventEmitter} = require "events"
Q              = require "q"
{makeTree}     = require "./util"
{keys}         = require "underscore"
{Path}         = require "./path"

class Package

  constructor: (@dir, @name) ->
    unless @name
      @name = path.basename(@dir)
      if @isUserPackage()
        @name = "user-#{@name}"

    @modules = {}
    @settings = {}
    @errors = null

  isUserPackage: () ->
    return "user_modules" in @dir

  load: (xikij) ->
    xikij.moduleLoader.load this

    watchEventHandler = (event, filename) =>
      # event is 'rename' or 'change'
      console.log "file event", event, filename

      xikij.moduleLoader.load this, filename

    # TODO: remove watcher on xikij close
    @watcher = fs.watch @dir, watchEventHandler

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


class PackageManager extends EventEmitter
  constructor: (@xikij) ->
    @_packages = []
    @_user_packages = []

    @loading = []
    #@loaded =  # be a promise
    @_modules = null
    @_settings = null
    #@_user_modules = null

  loaded: ->
    Q.all(@loading).then (result) =>
      @emit "loaded"
      return result
    .fail (err) =>
      console.log "err loading packages", err

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

  failed: ->
    result = []
    for pkg in @_packages
      console.log "failed?", pkg
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

    if not @_modules?
      @_modules = {}
      for pkg in @_packages
        makeTree pkg.modules, @_modules, (key,value) ->
          # if value.menuType
          #   key = "#{key}.#{value.menuType}"
          key.split("/")[1..]

    unless name?
      return @_modules

    Path(name).selectFromTree @_modules, found: (object, path, i) ->
      # if is module
      if "moduleName" of object
        return object
      else
        false

  getPackages: ->
    return @_packages

module.exports = {Package, PackageManager}
