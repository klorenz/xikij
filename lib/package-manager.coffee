path           = require "path"
{EventEmitter} = require "events"
Q              = require "q"
{makeTree}     = require "./util"
{keys}         = require "underscore"
{Path}         = require "./path"

class Package

  constructor: (@dir, @name) ->
    unless @name
      @name = path.basename(@dir)

    # TODO try also .xikij

    @modules = {}
    @errors = null

  load: (xikij) ->
    xikij.moduleLoader.load this

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
    @loading = []
    #@loaded =  # be a promise
    @_modules = null

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


module.exports = {Package, PackageManager}
