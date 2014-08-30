debug          = require("debug")('xiki')
path           = require "path"
CoffeeScript   = require "coffee-script"
{EventEmitter} = require 'events'
{XikijClient}  = require "./client"
{ModuleLoader} = require "./extensions"
{XikijBridge}  = require "./xikij-bridge.coffee"
util           = require "./util"
{Response}     = require "./response"
_              = require "underscore"
Q              = require "q"
fs             = require "fs"

issubclass = (B, A) -> B.prototype instanceof A

getuser = (req) ->
  # get user either from request or
  # get user from environment (running this process)

{PackageManager} = require "./package-manager"


class Xikij extends EventEmitter

  constructor: (opts) ->
    opts = opts or {}

    Interface  = require './interface'
    @Interface = (require './interfaces')(new Interface())
    @Interface.mixDefaultsInto this

    @Context = @Interface.mixInto require('./context').Context
    @Q = Q

    @_contexts = []
    @_context  = {}

    @_bridges  = {}
    @_bridges['py'] = new XikijBridge(suffix: "py")

    # first initialize packages
    @packages   = new PackageManager this
    @moduleLoader = new ModuleLoader this
#    @extensions = new XikiExtensions this

    @opts = opts

    @initialized = false

    # initialized method has been triggered
#    @_initialized = false
#    @_packages_loaded = false
  getBridge: (suffix) ->
    if suffix of @_bridges
      @_bridges[suffix]
    else
      null

  mixInterfacesInto: (target) ->
    @Interface.mixInto target

  initialize: (opts) ->
    return @initialized if @initialized

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

    @packages.loaded().fail (err) => console.log err

  # GET [action], path, [args]
  GET: (action, path, args=null) ->
    unless args?
      unless path
        path = action
        action = "expand"
      args = {}

    @request {path, action, args}


  # respond gets a Response object, which contains a type and a stream
  request: ({path, body, args, action, context}, respond) ->
    @initialized = @initialize() unless @initialized

    deferred = Q.defer()

    @initialized.then =>

      {parseXikiRequest} = require "./request-parser"
      request = parseXikiRequest {path, body, args, action}

      context = this unless context

      request.process(context).then (response) ->
        console.log "xikij request response", response
        Q .fcall -> response

          .then (response) =>
            console.log "Q xikij request response", response

            unless response instanceof Response
              response = new Response data: response

            if respond
              respond response

            deferred.resolve(response)

          .fail(error) =>
            if respond
              respond response

            deferred.resolve(new Response data: error)

          # ( (error) =>
          #   deferred.resolve(new Response error)
          #   if respond
          #     respons response
          # ))
      #.done()

    deferred.promise


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
