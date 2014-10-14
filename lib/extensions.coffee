path   = require "path"
events = require "events"
fs     = require "fs"
util   = require "./util"
{extend}      = require "underscore"
vm     = require "vm"
Q      = require "q"

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

      @xikij.exists(dir).then (exists) =>
        return unless exists
        return @xikij.walk dir, (entry) =>
          @loadModule pkg, dir, entry[dir.length+1..]

  # load either an entire package or a
  load: (pkg, filename) ->
    bases = [ "menu", "menu-"+process.platform ]

    if util.isPosix()
      bases.push "menu-posix"

    if filename
      for base in bases
        dir = path.join(pkg.dir, base)
        entry = path.relative dir, filename
        unless entry.match /^\.\./
          return @loadModule pkg, dir, entry

      dir = path.join(pkg.dir, "settings")
      entry = path.relative dir, filename
      unless entry.match /^\.\./
        return @loadSettings pkg, dir, entry

      console.log "nothing to do for #{filename}"
      return



    promises = []

    bases.forEach (menuBase) =>
      promises.push @_loadMenu pkg, menuBase

    return Q.all(promises)

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
    sourceFile = path.join dir, entry

    name = entry.replace(/\..*$/, '') # strip extensions
    moduleName = "#{pkg.name}/#{name}"

    xikijData =
      fileName:     sourceFile
      moduleName:   moduleName
      settingsName: name
      package:      pkg

    return @xikij.readFile(sourceFile).then (content) =>
      xikijData.settings = settingsParser.parse(content)

      pkg.settings[settingsName] = xikijData


  loadModule: (pkg, dir, entry) ->
    sourceFile = path.join dir, entry

    #name = path.basename sourceFile

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
