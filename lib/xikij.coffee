debug           = require("debug")('xiki')
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

issubclass = (B, A) -> B.prototype instanceof A

getuser = (req) ->
  # get user either from request or
  # get user from environment (running this process)

{PackageManager} = require "./package-manager"


class Xikij extends Context

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
    @Q = Q

    @_contexts = []
    @_context  = {}

    @_bridges  = {}
    @_bridges['py'] = new XikijBridge(suffix: "py")
    @Bridge = XikijBridge

    @contentFinder = new ContentFinder this
    @util = util
    @Path = Path

    # first initialize packages
    @packages   = new PackageManager this
    @moduleLoader = new ModuleLoader this
#    @extensions = new XikiExtensions this

    @opts = opts

    @_initStarted   = false
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

  on: (event, callback) ->
    console.log "event", event

  mixInterfacesInto: (target) ->
    @Interface.mixInto target

  initialize: (opts) ->
    return @initialized if @_initStarted

    @_initStarted = true

    opts = opts or {}
    _.extend @opts, opts

    @packages.add path.normalize path.join __dirname, ".."

    packagesPath = @opts.packagesPath || []
    if typeof packagesPath is "string"
      packagesPath = [ packagesPath ]

    for p in packagesPath
      p = path.normalize(p)

      fs.readdir p, (entries) =>
        for e in entries
          @packages.add path.join(p, e)

    @packages.loaded()
      .then =>
        @initialization.resolve(true)
      .fail (err) =>
        console.log err.stack
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
