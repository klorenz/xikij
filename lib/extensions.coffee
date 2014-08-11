path   = require "path"
events = require "events"
fs     = require "fs"
util   = require "./util"
_      = require "underscore"
vm     = require "vm"
Q      = require "q"

coffeescript = require "coffee-script"

class ModuleLoader

  constructor: (@xikij) ->

  load: (pkg) ->
    dir = path.join pkg.dir, "menu"

    @xikij.exists(dir).then (exists) =>
      return unless exists
      return @xikij.walk dir, (entry) =>
        @loadModule pkg, dir, entry[dir.length+1..]

  loadCoffeeScript: (code, xikijData) ->
    filename = xikijData.fileName

    compiled = Q.fcall ->
      o = {filename, sourceMap: on, bare: on}
      coffeescript.compile code, o

    compiled.then (answer) => @runJavaScript answer.js, filename, xikijData

  runJavaScript: (js, filename, context, sourceMap) ->
    # TODO
    # idea is to run each part by part.  maybe md5 hashed names, each part
    # is executed in same context, each part may be different language
    # which compiles to javascript

    Module = require 'module'

    #funcname = "xikij$"+context.moduleName.replace( /\W+/g, "$" )

    vars  = "var menu = this, xikiMenu = this, xikiModule = this";

    # TODO add source map
    # use http://www.html5rocks.com/en/tutorials/developertools/sourcemaps/
    # sourceMappingURL=path/to/map.file
    # may also be a inline data:... url see compile-cache of atom

    # put a wrapping function for providing the xiki
    script = """
      module.exports = { module: module, modfunc: function (xikij, module) { var xikij = xikij, module = module; #{vars}; #{js}
      } }
    """

    @xikij.cacheFile(context.moduleName+".js", script).then (filename) =>
      #if filename in cache remove from module cache
      exported = require filename
      context.result = exported.modfunc.call context, @xikij

      # module.exports may be mutated
      context

  handleError: (pkg, moduleName, error) ->
    pkg.errors = [] unless pkg.errors
    pkg.errors.push
      moduleName: moduleName
      message: error.toString()
      error: error
    console.log error.stack.toString()

  loadModule: (pkg, dir, entry) ->
    console.log "loadModule", pkg, dir, entry

    sourceFile = path.join dir, entry
    #name = path.basename sourceFile

    moduleName = ""

    name = entry.replace(/\..*$/, '') # strip extensions
    moduleName = "#{pkg.name}/#{name}"

    xikijData =
      sourceFile: sourceFile
      fileName:   sourceFile
      moduleName: moduleName
      menuName:   name
      package:    pkg
      require: (name) -> require "#{__dirname}/#{name}"

    switch path.extname(sourceFile)
      when ".coffee"
        return @xikij.readFile(sourceFile).then (content) =>
          @loadCoffeeScript(content.toString(), xikijData)
            .then (context) =>
              pkg.modules.push context

              for k,v of context
                if util.isSubClass(v, @xikij.Context)
                  @xikij.addContext(k,v)
            .fail (error) =>
              @handleError pkg, moduleName, error

module.exports = {ModuleLoader}
