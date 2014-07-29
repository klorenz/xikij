debug = require("debug")('xiki')
user_xikis = {}
path = require "path"
CoffeeScript = require "coffee-script"


{EventEmitter} = require 'events'
XikiExtensions = require './extensions'
{XikijClient} = require "./client"

util = require "./util"

{Response} = require "./response"
_ = require "underscore"
#XikiContext    = require './context'

issubclass = (B, A) -> B.prototype instanceof A

getuser = (req) ->
  # get user either from request or
  # get user from environment (running this process)

{PackageManager} = require "./package-manager"


class Xikij extends EventEmitter

  constructor: (opts) ->
    opts = opts or {}

    Interface = require './interface'
    @Interface = (require './interfaces')(new Interface())
    @Interface.mixDefaultsInto this

    @Context = @Interface.mixInto require './context'

    @_contexts = []
    @_context  = {}

    # first initialize packages
    @packages   = new PackageManager this
    @extensions = new XikiExtensions this

    @opts = opts

    # initialized method has been triggered
    @_initialized = false
    @_packages_loaded = false


  mixInterfacesInto: (target) ->
    @Interface.mixInto target

  _announce_initialized: ->
    if @_initialized and @_initializing and @_packages_loaded
      @_initializing = false
      @emit "initialized"

  initialize: (opts) ->
    return if @_initialized
    return if @_initializing
    @_initializing = true

    @packages.on "loaded", =>
      @_packages_loaded = true
      @_announce_initialized()

    opts = opts or {}
    _.extend @opts, opts

    @packages.add path.normalize path.join __dirname, ".."

    packagesPath = @opts.packagesPath || []
    if typeof packagesPath is "string"
      packagesPath = [ packages Path ]

    for p in packagesPath
      p = path.normalize(p)

      fs.readdir p, (entries) =>
        for e in entries
          @packages.add path.join(p, e)

    @_initialized = true

  # respond gets a Response object, which contains a type and a stream
  request: ({path, body, args, action, context}, respond) ->

    unless @_initialized
      @on "initialized", =>
        @request {path, body, args, action, context}, respond
      return @initialize()

    {parseXikiRequest} = require "./request-parser"
    request = parseXikiRequest {path, body, args, action}

    context = this unless context

    request.process context, (response) ->
      unless response instanceof Response
        response = new Response data: response
      respond response


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
