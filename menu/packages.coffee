###
$ npm install github --save
###

module.exports = (xikij) ->
  packageProviders = []

  class PackageProvider
    @registry: []
    @register: (packageProvider) ->
      PackageProvider.registry.push packageProvider

      ###
      ###

  # Events
  # ------
  #
  # Event packages:collect-package-providers
  #
  # parameters: function register(packageProvider)
  #
  # will be emitted if xikij is initilized to collect initial package
  # providers.
  #
  #
  # Event packages:add-package-provider
  #
  # emit this event (via xikij.event) to add a package provider
  #
  initialized = xikij.initialized.then () ->
    xikij.event.emit "packages:collect-package-providers", PackageProvider
    xikij.event.on "packages:get-package-provider", (callback) ->
      callback PackageProvider

  @run = (request) -> [
      "browse"
      "path"
    ]

  @browse = (request) ->
    console.log "browse"
    if request.path.empty()
      (p.name for p in xikij.packages.getPackages())
    else
      result = {}
      for p in xikij.packages.getPackages()
        result[p.name] = p.modules

      console.log "request.path", request.path
      console.log "result", result

      request.path.selectFromTree result


  @install = (request) ->
    # curl "https://api.github.com/search/repositories?q=xikij-&per_page=100" | grep '"name"' | wc -l
    # npm.commands.list
    # npm.commands.install

  _npm_packages = ->
    npm = require "npm"
    xikij.Q.nfcall(npm.commands.search /^xikij-/.source, true).then (data) =>
      console.log data
      data

  _github_packages = ->
    github = require "github"

  PackageProvider.register(_npm_packages)
  PackageProvider.register(_github_packages)

  @list = (request) ->
    packages = []
    packageProviders.forEach (pp) =>
      packages = packages.concat pp()

    # packagesProvided = Q(null)
    # packageProviders.forEach (pp) =>
    #   packagesProvided = packagesProvided.then (packages) =>
    #
    #
    # for pp
    # _npm_packages().then (data) =>
    #   _github_packages().then (data) =>


  @path = (request) ->
    xikij.packagesPath
