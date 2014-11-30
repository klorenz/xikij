path   = require "path"
events = require "events"
fs     = require "fs"
util   = require "./util"
{extend}      = require "underscore"
vm     = require "vm"
Q      = require "q"
{Settings} = require "./settings"

coffeescript   = require "coffee-script"
settingsParser = require "./settings-parser"

class BridgedModule

  constructor: (@bridge, @spec) ->
    for entry in @spec.callables
      @[entry] = (args...) =>
        @bridge.request "moduleRun", @spec.moduleName, args


class ModuleLoader

  constructor: (@xikij) ->
    dstdir = null
    moddir = path.resolve __dirname, "..", "node_modules"

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

  _loadMenu: (pkg, menuBase) ->
      dir = path.join pkg.dir, menuBase

      console.log "load package from filename #{filename}"

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
      console.log "load package from filename #{filename}"
      for base in bases
        dir = path.join(pkg.dir, base)
        entry = path.relative dir, filename
        unless entry.match /^\.\./
          return @[loader] pkg, dir, entry

      console.log "nothing to do for #{filename}"
      return Q(null)

    promises = []

    bases.forEach (base) =>
      promises.push @[loader] pkg, base

    console.log "promises", promises

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
    console.log error.stack.toString()

  loadSettings: (pkg, dir, entry) ->
    console.log ">> load settings", pkg, dir, entry

    unless entry?
      dir = path.join pkg.dir, dir

      return @xikij.exists(dir).then (exists) =>
        return unless exists
        return @xikij.walk dir, (entry) =>
          @loadSettings pkg, dir, entry[dir.length+1..]

    sourceFile = path.join dir, entry

    console.log "load settings #{sourceFile}"

    name = entry.replace(/\..*$/, '') # strip extensions
    settingsName = "#{pkg.name}/#{name}"

    platform = null
    if util.endsWith("posix")
      platform = posix
    else if util.endsWith process.platform
      platform = process.platform

    xikijData =
      fileName:     sourceFile
      moduleName:   moduleName
      settingsName: name
      package:      pkg
      platform:     platform

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

    console.log "load menu #{sourceFile}"

    moduleName = ""

    name   = entry
    suffix = ""

    # maybe use path.extname?
    if m = entry.match /(.*)\.(.*)$/
      name   = m[1]
      suffix = m[2]

    name = entry.replace(/\..*$/, '') # strip extensions
    moduleName = "#{pkg.name}/#{name}"

    console.log "load module #{moduleName}"

    xikijData =
      sourceFile: sourceFile
      fileName:   sourceFile
      moduleName: moduleName
      menuName:   name
      menuType:   suffix
      package:    pkg

    # moduleDir = path.dirname(moduleName)
    # if not moduleDir of pkg.modules
    #   pkg.modules[moduleDir] = pkg

    switch suffix

      when "coffee"
        return Q.fcall =>
          try
            resolved = require.resolve sourceFile
            if resolved of require.cache
              delete require.cache[resolved]

            refined = factory = require sourceFile
            if factory instanceof Function
              refined = factory.call xikijData, @xikij

              # now xikijData may be extended or refined may have data.
              # what if both present?

              refined = xikijData

              # unless refined
              #   refined = xikijData

            unless refined.moduleName
              extend(refined, xikijData)

            pkg.modules[moduleName] = refined

            for k,v of refined
              if util.isSubClass(v, @xikij.Context)
                @xikij.addContext k, v

            @xikij.event.emit "package:module-updated", moduleName, xikijData

          catch error
            @handleError pkg, moduleName, error

        # do it like this:
        #  - require the module
        #  - if the module returns a function:
        #    call function with (xikij)
        #  - if the module returns a class:
        #    create instance with (xikij)

        # return @xikij.readFile(sourceFile).then (content) =>
        #   @loadCoffeeScript(content.toString(), xikijData)
        #     .then (context) =>
        #       pkg.modules.push context
        #
        #       for k,v of context
        #         if util.isSubClass(v, @xikij.Context)
        #           @xikij.addContext(k,v)
        #     .fail (error) =>
        #       @handleError pkg, moduleName, error
      when "py"
        return @xikij.readFile(sourceFile).then (content) =>
          if content.match /^#!/
            # execute file for menu args-protocol
            throw new Error "not implemented"

          else
            bridge = @xikij.getBridge(suffix)
            if bridge?
              bridge.request("registerModule", xikijData, content)
                .then (result) =>
                  module = new BridgedModule bridge, result
                  pkg.modules[moduleName] = module
                  #pkg.modules.push module

                  for k,v of context
                    if util.isSubClass(v, @xikij.Context)
                      @xikij.addContext(k,v)

                  @xikij.event.emit "package:module-updated", moduleName, xikijData
                .fail (error) =>
                  @handleError pkg, moduleName, error
            else
              throw new Error "not implemented"

      # if isexecutable
      # foo.sh => whatever there comes, if is json compilable or cson compilable
      # do it and this is result
      #
      # foo.sh + => Do a full expanded menu, whatever that means, default same
      #    like without args
      #
      # foo.sh first => expand menu item "first"
      #
      #
      # args are passed as --arg foo or better arg=foo ?
      #
      # input is passed as stdin
      #
      # result:
      # - json
      # - cson
      # - xikij text (parsed into obj)


module.exports = {ModuleLoader}
