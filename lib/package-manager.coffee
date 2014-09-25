path = require "path"
{EventEmitter} = require "events"
Q = require "q"

class Package

  constructor: (@dir, @name) ->
    unless @name
      @name = path.basename(@dir)

    # TODO try also .xikij


    @dir += "/xikij"
    @modules = []
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

  toString: -> "name: #{@name}"


class PackageManager extends EventEmitter
  constructor: (@xikij) ->
    @_packages = []
    @loading = []
    #@loaded =  # be a promise

  loaded: ->
    Q.all(@loading).then (result) =>
      @emit "loaded"
      return result

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
      for m in pkg.modules
        result.push m
    result

  getModule: (name) ->
    for pkg in @_packages
      for m in pkg.modules
        return m if m.moduleName == name

module.exports = {Package, PackageManager}
