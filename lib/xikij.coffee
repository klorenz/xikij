path            = require "path"
CoffeeScript    = require "coffee-script"
{EventEmitter}  = require 'events'
{XikijClient}   = require "./client"
{ModuleLoader}  = require "./extensions"
{ContentFinder} = require "./content-finder"
{XikijBridge}   = require "./xikij-bridge"
util            = require "./util"
{Response}      = require "./response"
{Action}        = require "./action"
{Path}          = require "./path"
_               = require "underscore"
Q               = require "q"
fs              = require "fs"
{Context}       = require "./context"
cli             = require "./xikij-cli"
{getLogger}     = require "./logger"

log = getLogger("xikij", level: "debug")

issubclass = (B, A) -> B.prototype instanceof A

getuser = (req) ->
  # get user either from request or
  # get user from environment (running this process)

{PackageManager} = require "./package-manager"

class Xikij

  configDefaults:
    xikij: {
      userDir:             util.getUserHome()
      xikijUserDirName:    '.xikij'
      xikijProjectDirName: '.xikij'
    }

  constructor: (opts) ->
    opts = opts or {}

    Interface  = require './interface'
    @Interface = (require './interfaces')(new Interface(this))
    @Interface.mixDefaultsInto this

    @Action = Action

    @Context = @Interface.mixInto Context

    # need these Context specific methods, to be fully context compatible
    # beeing a context does not work, because of mixing defaults into this
    # and interface definitions into Context
    @dispatch = Context::dispatch
    @self     = Context::self

    @event    = new EventEmitter()

    @Q = Q

    @_contexts = []
    @_context  = {}

    @_bridges  = {}
    @_bridges['py'] = new XikijBridge(suffix: "py")
    @Bridge = XikijBridge

    @contentFinder = new ContentFinder this
    @util = util
    @Path = Path

    @settings = {}

    # first initialize packages
    @packages   = new PackageManager this
    @moduleLoader = new ModuleLoader this
#    @extensions = new XikiExtensions this

    @opts = opts

    @_initStarted   = false

    if not opts.initialization?
      opts.initialization = true

    if not opts.initialization
      @initialized = Q(true)
    else
      @initialization = Q.defer()
      @initialized    = @initialization.promise
      @initialize()

    # initialized method has been triggered
#    @_initialized = false
#    @_packages_loaded = false
  getBridge: (suffix) ->
    if suffix of @_bridges
      @_bridges[suffix]
    else
      null

  shutdown: ->
    @event.emit "shutdown", @

  on: (event, callback) ->
    log.debug "event", event

  mixInterfacesInto: (target) ->
    @Interface.mixInto target

  initialize: (opts) ->
    return @initialized if @_initStarted

    @_initStarted = true

    opts = opts or {}
    _.extend @opts, opts

    log.debug "opts: ", @opts


    userDir  = @opts.userDir  ? util.getUserHome()
    userBase = @opts.userBase ? ".xikij"

    @packages.add path.normalize path.join __dirname, ".."

    if @opts.userPackagesDir
      @userPackagesDir = @opts.userPackagesDir
    else
      @userPackagesDir = path.resolve userDir, userBase

    log.debug "userPackagesDir", @userPackagesDir

    #@userPackagesDir = path.resolve userDir, userBase

    # if opts.packages.Path is explicitely false, do not use path
    # else use default path
    if @opts.packagesPath is false
      packagesPath = []

    else unless @opts.packagesPath?
      packagesPath = []

      if fs.existsSync @userPackagesDir

        node_modules_dir = path.join @userPackagesDir, "node_modules"
        if fs.existsSync node_modules_dir
          packagesPath.push node_modules_dir

        user_modules_dir = path.join @userPackagesDir, "user_modules"
        if fs.existsSync user_modules_dir
          packagesPath.push user_modules_dir

        # for dir in fs.readdirSync @userPackagesDir
        #   continue if dir == "node_modules"
        #   continue if dir == "user_modules"
        #
        #   p = path.resolve @userPackagesDir, dir
        #   stat = fs.statSync p
        #   if stat.isDirectory()
        #     packagesPath.push p
    else
      packagesPath = @opts.packagesPath

    if typeof packagesPath is "string"
      packagesPath = [ packagesPath ]

    for p in packagesPath
      p = path.normalize(p)

      log.debug "loading packages from #{p}"

      for e in fs.readdirSync p
        _path = path.join(p, e)
        stat = fs.statSync _path
        if stat.isDirectory()
          log.debug "add", _path
          @packages.add _path

    @packages.loaded()
      .then =>
        @initialization.resolve(true)
      .fail (err) =>
        log.debug err.stack
        @initialization.resolve(false)

  # GET [action], path, [args]
  GET: (action, path, args=null) ->
    unless args?
      unless path
        path = action
        action = "expand"
      args = {}

    @request {path, action, args}

  # TODO make ctx reloadable/overridable

  getSearchPath: (type) ->
    @packages.each (pkg) -> path.join pkg.path, type

module.exports =
  # middleware?
  __express: (req, res) ->
    path = req.params[0]
    # req.query has parameters
    #if typeof req.body == "string"

  Xikij: Xikij
  XikijClient: XikijClient
  util: util
  Q: Q
