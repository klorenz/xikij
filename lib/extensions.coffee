path   = require "path"
events = require "events"
fs     = require "fs"
util   = require "./util"
{extend, clone}      = require "underscore"
vm     = require "vm"
Q      = require "q"
{Settings} = require "./settings"

coffeescript   = require "coffee-script"
settingsParser = require "./settings-parser"

pythonLoader     = require "./extensions/python"
coffeeLoader     = require "./extensions/coffeescript"
executableLoader = require "./extensions/executable"

getLogger = require "./logger"

class BridgedModule
  constructor: (@bridge, @spec) ->
    for entry in @spec.callables
      @[entry] = (args...) =>
        @bridge.request "moduleRun", @spec.moduleName, args

class XikijModule
  constructor: ({@fileName, @moduleName, @settingsName, @package, @platform, @menuType, @menuName, @sourceFile}) ->

  bridged: (xikij, bridge, content) ->
    info = clone(@)
    info.package =
      dir: @package.dir
      name: @package.name

    bridge.request(xikij, "registerModule", info, content)
      .then (spec) =>
        debugger
        @bridge  = bridge
        @content = content
        @spec    = spec

        for entry in @spec.callables
          @[entry] = (args...) =>
            @bridge.request "moduleRun", @spec.moduleName, args

        return @


class ModuleLoader

  constructor: (@xikij) ->
    dstdir = null
    moddir = path.resolve __dirname, "..", "node_modules"

    @loaders = {}

    x = @xikij
    # @cachedir = x.cacheDir("modules/node_modules", false)
    #   .then (_dir) =>
    #     dstdir = _dir
    #     x.doesNotExist(_dir)
    #   .then =>
    #     console.log dstdir, "does not exist"
    #     x.makeDirs(dstdir)
    #   .then =>
    #     x.readDir moddir
    #   .then (entries) =>
    #     console.log "entries1", entries
    #     Q.all (x.symLink("#{moddir}/#{e}", "#{dstdir}/#{e}") for e in entries)
    #   .then =>
    #     x.makeDirs("#{dstdir}/xikij")
    #   .then =>
    #     x.readDir "#{__dirname}"
    #   .then (entries) =>
    #     console.log "entries2", entries
    #     Q.all (x.symLink("#{__dirname}/#{e}", "#{dstdir}/xikij/#{e}") for e in entries)
    #   .fail (error) =>
    #     console.log "init moduleloader error", error
    #     if error
    #       throw error unless error is x.DoesNotExist or error is x.DoesExist

    @registerLoader coffeeLoader
    @registerLoader pythonLoader
    @registerLoader executableLoader

    @console = getLogger("xikij.ModuleLoader")

  # Public: registers extension loader
  #
  # * `name`     The {String} name of the loader
  # * `loader`   The {function} doing the loading.
  #
  # `loader` must be a function, which returns a promis on either a XikijModule
  # or a false value.
  registerLoader: (loader) ->
    # if typeof subject is "string"
    #   suffix = subject
    #   subject = (spec) -> return spec.menuType == suffix

    @loaders[loader.name] = loader.load

  # Extended: unregister an extension loader
  unregisterLoader: (name) ->
    delete @loaders[name]

  _loadMenu: (pkg, menuBase) ->
      dir = path.join pkg.dir, menuBase

      @console.debug "ModuleLoader: _loadMenu(#{pkg.name}, #{menuBase})"

      @xikij.exists(dir).then (exists) =>
        return unless exists
        return @xikij.walk dir, (entry) =>
          @loadModule pkg, dir, entry[dir.length+1..]

  # load either an entire package or a
  _load: (pkg, filename, prefix, loader) ->
    bases = [ prefix, "#{prefix}-"+process.platform ]

    if util.isPosix()
      bases.push "#{prefix}-posix"

    if filename
      @console.debug "ModuleLoader: _load(#{pkg.name}, #{filename})", bases

      for base in bases
        dir = path.join(pkg.dir, base)
        entry = path.relative dir, filename
        unless entry.match /^\.\./
          return @[loader] pkg, dir, entry

      return Q(null)

    promises = []

    bases.forEach (base) =>
      promises.push @[loader] pkg, base

#    console.log "promises", promises

    return Q.all(promises)

  # load either an entire package or a
  load: (pkg, filename) ->
    @_load(pkg, filename, "menu", "loadMenu").then =>
      @_load(pkg, filename, "settings", "loadSettings").then =>
        @xikij.event.emit "package:updated", pkg, filename

  # loadCoffeeScript: (code, xikijData) ->
  #   filename = xikijData.fileName
  #
  #   compiled = Q.fcall ->
  #     o = {filename, sourceMap: on, bare: on}
  #     coffeescript.compile code, o
  #
  #   compiled.then (answer) => @runJavaScript answer.js, filename, xikijData
  #
  # runJavaScript: (js, filename, context, sourceMap) ->
  #   # TODO
  #   # idea is to run each part by part.  maybe md5 hashed names, each part
  #   # is executed in same context, each part may be different language
  #   # which compiles to javascript
  #
  #   Module = require 'module'
  #
  #   #funcname = "xikij$"+context.moduleName.replace( /\W+/g, "$" )
  #
  #   vars  = "var menu = this, xikijMenu = this, xikijModule = this";
  #
  #   # TODO add source map
  #   # use http://www.html5rocks.com/en/tutorials/developertools/sourcemaps/
  #   # sourceMappingURL=path/to/map.file
  #   # may also be a inline data:... url see compile-cache of atom
  #
  #   # put a wrapping function for providing the xiki
  #   script = """
  #     module.exports = { module: module, modfunc: function (xikij, module) { var xikij = xikij, module = module; #{vars}; #{js}
  #     } }
  #   """
  #
  #   @cachedir
  #     .then =>
  #       @xikij.cacheFile("modules/#{context.moduleName}.js", script).then (filename) =>
  #
  #         console.log "importing", filename
  #
  #         #if filename in cache remove from module cache
  #         exported = require filename
  #         context.result = exported.modfunc.call context, @xikij
  #         if typeof context.result is "undefined"
  #           delete context.result
  #
  #         context.toString = ->
  #           "[Module: #{@moduleName}]"
  #
  #         # module.exports may be mutated
  #         console.log "have module context", context
  #         context

  handleError: (pkg, moduleName, error) ->
    pkg.errors = [] unless pkg.errors

    pkg.errors.push
      moduleName: moduleName
      message: error.toString()
      error: error

    @console.error error.stack

  loadSettings: (pkg, dir, entry) ->
    @console.debug "ModuleLoader(#{pkg.name}) load settings", pkg, dir, entry

    unless entry?
      dir = path.join pkg.dir, dir

      return @xikij.exists(dir).then (exists) =>
        return unless exists
        return @xikij.walk dir, (entry) =>
          @loadSettings pkg, dir, entry[dir.length+1..]

    sourceFile = path.join dir, entry

    @console.debug "ModuleLoader(#{pkg.name} load settings from #{sourceFile}"

    name = entry.replace(/\..*$/, '') # strip extensions
    settingsName = "#{pkg.name}/#{name}"

    platform = null
    if util.endsWith("posix")
      platform = posix
    else if util.endsWith process.platform
      platform = process.platform

    xikijData = new XikijModule {
      fileName:     sourceFile
      moduleName:   moduleName
      settingsName: name
      package:      pkg
      platform:     platform
    }

    return @xikij.readFile(sourceFile).then (content) =>
      xikijData.settings = settingsParser.parse(content)

      if not (name of @xikij.settings)
        @xikij.settings[name] = new Settings()

      @xikij.settings[name].update(xikijData)


  loadMenu: (pkg, dir, entry) ->
    unless entry?
      dir = path.join pkg.dir, dir

      return @xikij.exists(dir).then (exists) =>
        return unless exists
        return @xikij.walk dir, (entry) =>
          @loadMenu pkg, dir, entry[dir.length+1..]

    sourceFile = path.join dir, entry

    @console.debug "ModuleLoader(#{pkg.name} load menu from #{sourceFile}"

    moduleName = ""

    name   = entry
    suffix = ""

    # maybe use path.extname?
    if m = entry.match /(.*)\.(.*)$/
      name   = m[1]
      suffix = m[2]

    name = entry.replace(/\..*$/, '') # strip extensions
    moduleName = "#{pkg.name}/#{name}"

    @console.debug "ModuleLoader(#{pkg.name}) load module #{moduleName} (#{suffix})"

    xikijData = new XikijModule {
      sourceFile: sourceFile
      fileName:   sourceFile
      moduleName: moduleName
      menuName:   name
      menuType:   suffix
      package:    pkg
    }

    # moduleDir = path.dirname(moduleName)
    # if not moduleDir of pkg.modules
    #   pkg.modules[moduleDir] = pkg

    loading = []

    for name, load of @loaders
      ( (name, load) =>
          @console.debug "ModuleLoader(#{pkg.name}) try loader #{name} for #{moduleName} (#{suffix})"
          promise = load.call(this, xikijData)
            .then((subject) =>
              if subject
                pkg.modules[moduleName] = subject

                @console.debug "ModuleLoader(#{pkg.name}) #{name} loaded #{moduleName}", subject

                @xikij.event.emit "package:module-updated", moduleName, subject
              else
                @console.debug "#{name} cannot load #{moduleName}"
            )
            .fail((error) =>
              @handleError pkg, moduleName, error
            )
          loading.push promise
      )(name, load)

    return Q.allSettled(loading)


module.exports = {ModuleLoader}
