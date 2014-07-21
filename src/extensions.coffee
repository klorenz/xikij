path   = require "path"
events = require "events"
fs     = require "fs"
util   = require "./util"
_      = require "underscore"
vm     = require "vm"

coffeescript = require "coffee-script"

module.exports =
  # XikiExtensions is a loades, which reacts on load-package events.
  #
  class XikiExtensions extends events.EventEmitter

    constructor: (@xiki) ->
      @xiki.packages.on "load-package", (pkg, done) =>
        @addMenuFilesFromPackage pkg, done

    addMenuFilesFromPackage: (pkg, done) ->
      # look into menu dir
      dir = path.join pkg.dir, "menu"

      # TODO: add listener for dir

      return unless @xiki.exists dir

      filesToProcess = 1

      fileProcessed = ->
        filesToProcess--
        console.debug "filesToProcess #{filesToProcess}"
        done() if filesToProcess == 0

      @xiki.walk dir, (entry) =>
        console.log "entry", entry
        filesToProcess++
        @loadModule dir, pkg, entry[dir.length+1...], fileProcessed

      fileProcessed()


    loadCoffeeScript: (code, xikiData) ->
      filename = xikiData.filename

      o = {filename, sourceMap: on}

      o.bare = on # ensure return value
      answer = coffeescript.compile code, o

      _globals =
        xiki: @xiki
        modulename: xikiData.moduleName
        xikiModule: xikiData

      @runJavaScript answer.js, filename, _globals


    handleError: (pkg, moduleName, error) ->
      pkg.errors = [] unless pkg.errors
      pkg.errors.push
        moduleName: moduleName
        message: error.toString()
        error: error
      console.log error.stack.toString()

    loadModule: (dir, pkg, relFilename, done) ->

      sourceFile = path.join dir, relFilename

      name = path.basename sourceFile

      coffeeFile = "packages/#{pkg.name}/"+path.basename(sourceFile, ".md")
      coffeeFile += ".coffee"

      name = relFilename.replace(/\..*$/, '') # strip extensions
      moduleName = "#{pkg.name}/#{name}"

      xikiData =
        sourceFile: sourceFile
        fileName:   sourceFile
        moduleName: moduleName
        package:    pkg

      text = null

      if path.extname(sourceFile) == ".coffee"
        @xiki.readFile sourceFile, (err, content) =>
          try
            context = @loadCoffeeScript content.toString(), xikiData
            pkg.modules.push context

            for k,v of context
              if util.isSubClass(v, @xiki.Context)
                xiki.addContext(k,v)

          catch error
            @handleError pkg, moduleName, error

          done()

      else if path.extname(sourceFile) == ".md"

        @xiki.readFile sourceFile, (err, content) =>
          util.cookCoffee content, (code, text) =>

            @xiki.cacheFile coffeeFile, code, (err, filename) =>

              xikiData.fileName = filename
              xikiData.text = text

              try
                pkg.modules.push @loadCoffeeScript code, xikiData

              catch error
                @handleError pkg, error

              done()
      else
        done()

    runJavaScript: (js, filename, context) ->
      # TODO
      # idea is to run each part by part.  maybe md5 hashed names, each part
      # is executed in same context, each part may be different language
      # which compiles to javascript

      sandbox = vm.createContext(context)
      sandbox.GLOBAL = sandbox.root = sandbox.global = sandbox
      sandbox.__filename = filename
      sandbox.__dirname = path.dirname filename

      Module = require 'module'
      sandbox.module  = _module  = new Module(context.modulename || 'eval')
      sandbox.require = _require = (path) ->  Module._load path, _module, true
      _module.filename = sandbox.__filename
      _require[r] = require[r] for r in Object.getOwnPropertyNames require when r isnt 'paths'

      # use the same hack node currently uses for their own REPL
      _require.paths = _module.paths = Module._nodeModulePaths process.cwd()
      _require.resolve = (request) -> Module._resolveFilename request, _module

      if sandbox.xikiModule
        sandbox.xikiModule.sandbox = sandbox

      result = vm.runInContext js, sandbox, filename

      delete sandbox.GLOBAL
      delete sandbox.global
      delete sandbox.root

      sandbox


exports.eval = (code, options = {}) ->
  return unless code = code.trim()
  Script = vm.Script
  if Script
    if options.sandbox?
      if options.sandbox instanceof Script.createContext().constructor
        sandbox = options.sandbox
      else
        sandbox = Script.createContext()
        sandbox[k] = v for own k, v of options.sandbox
      sandbox.global = sandbox.root = sandbox.GLOBAL = sandbox
    else
      sandbox = global
    sandbox.__filename = options.filename || 'eval'
    sandbox.__dirname  = path.dirname sandbox.__filename
    # define module/require only if they chose not to specify their own
    unless sandbox isnt global or sandbox.module or sandbox.require
      Module = require 'module'
      sandbox.module  = _module  = new Module(options.modulename || 'eval')
      sandbox.require = _require = (path) ->  Module._load path, _module, true
      _module.filename = sandbox.__filename
      _require[r] = require[r] for r in Object.getOwnPropertyNames require when r isnt 'paths'
      # use the same hack node currently uses for their own REPL
      _require.paths = _module.paths = Module._nodeModulePaths process.cwd()
      _require.resolve = (request) -> Module._resolveFilename request, _module
  o = {}
  o[k] = v for own k, v of options
  o.bare = on # ensure return value
  js = compile code, o
  if sandbox is global
    vm.runInThisContext js
  else
    vm.runInContext js, sandbox




    # requireModule: (file, metadata) ->
    #
    #
    #             pkg.modules.push @requireModule moduleFile,
    #               _xikiFile: sourceFile
    #               _xikiModuleFile: moduleFile
    #               _xikiName: moduleName
    #               _xikiPackage: pkg
    #               _xikiText: text
    #
    #
    #   console.log "file", file
    #
    #   module = require file
    #
    #   return {} unless module
    #
    #   _.extend module, metadata
    #
    #   unless module.menu
    #     module.menu = metadata._xikiText if metadata._xikiText
    #
    #   #@modules.push module
    #
    #   module

      # if path.extname(file) == ".litcoffee"
      # if path.extname(file) == ".xiki"
        # collect all non-code as menu text
      #if path.extname(file) == ".rst"
