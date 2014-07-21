path = require "path"
{EventEmitter} = require "events"

class Package extends EventEmitter

  constructor: (@dir, @name) ->
    unless @name
      @name = path.basename(@dir)

    @dir += "/xiki"
    @modules = []
    @errors = null

  loaded: (name, doneEvent) ->
    unless doneEvent
      doneEvent = "package-loaded"

    if name
      index = @loading.indexOf name
      if index > -1
        @loading = @loading.splice index, 1

    unless @loading.length
      @emit doneEvent

  asObject: (attributes...)->
    obj = {}

    for k,v of this
      if attributes.length
        continue if not (k in attributes)

      obj[k] = v

    obj


class PackageManager extends EventEmitter
  constructor: (@xiki) ->
    @_packages = []
    @loading = []

  add: (dir, name) ->
    pkg = new Package dir, name

    @loading.push pkg.name

    # pkg.on "package-loaded", =>
    #   pkg.loaded.apply this, [pkg.name, "loaded"]
    #   @emit "package-loaded", pkg

    @_packages.push pkg

    packageLoaders = @listeners("load-package").length
    console.log "packageLoaders #{packageLoaders}"

    @emit "load-package", pkg, =>
      packageLoaders--
      console.log "packageLoaders #{packageLoaders}"
      unless packageLoaders
        console.log "emit loaded"
      @emit "loaded" unless packageLoaders

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
        result.push m.xikiModule
    result

module.exports = {Package, PackageManager}
