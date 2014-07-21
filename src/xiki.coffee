debug = require("debug")('xiki')
user_xikis = {}
path = require "path"
CoffeeScript = require "coffee-script"

{EventEmitter} = require 'events'
XikiExtensions = require './extensions'
_ = require "underscore"
#XikiContext    = require './context'

issubclass = (B, A) -> B.prototype instanceof A

getuser = (req) ->
  # get user either from request or
  # get user from environment (running this process)


class XikiServer extends EventEmitter

  # Create a xiki object for handling requests
  constructor: (opts) ->
    {@credentials} = opts
    @port = opts.port ? 18181
    @host = opts.host ? "localhost"

    global.xiki = this
    @Context = XikiContext

  serve: () ->
    @app = app = require("express")()
    logger = require 'morgan'
    bodyParser = require 'body-parser'

    app.use logger("dev")
    app.use bodyParser.json()
    app.use bodyParser.urlencoded()
    app.use bodyParser.text()

    # app.use "/web",

    app.use /^\/*/, (req, res) =>
      req.xikiPath = req.params[0]

      action = "open" # default

      if "open" of req.query
        action = "open"
      if "close" of req.query
        action = "close"

      req.xikiAction = action

      try
        parseXikiRequest({req, res}).process this, (err, result) =>
          # result could be a json object or
          res.write(@xikify(result))
      catch err
        console.log err

    app.use (req, res, next) ->
      err = new Error("Not Found")
      err.status = 404
      next err

    if app.get('env') is 'development'
      app.use (err, req, res, next) ->
        res.status(err.status || 500)
        res.render "error", {
          message: err.message
          error: err
        }

    app.use (err, req, res, next) ->
      res.status(err.status || 500)
      res.render "error", {
        message: err.message
        error: {}
        }

    # app.get '*', (req, res) ->
    #   console.log "got request", req
    #   res.send("hello world")
    @extensions = new XikiExtensions this

    server = app.listen @port, @host, =>
      debug("listening to #{@host}:#{@port}")


  # Do a xiki request for given path. Path may be a unixlike file path or
  # uri or a tree.
  request: (path, body, callback) ->
    try
      req = new XikiRequest(path)
      callback(null, req)
    catch err
      callback(err)

  # use anything in this xiki.  This method is to install XikiContexts
  # and maybe more
  use: (thing) ->
    if issubclass(thing, XikiContext)
      @contexts.push thing

  contexts: ->
    #for x in @context

  getdb: (name) ->
    @mongodb = require('mongodb') unless @mongodb
    return @mongodb.
    return

{PackageManager} = require "./package-manager"

class Xiki extends EventEmitter

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
      console.log "announcing initialized"
      console.log @listeners('initialized')
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
  request: ({path, body, args, action}, respond) ->

    unless @_initialized
      @on "initialized", =>
        @request {path, body, args, action}, respond
      return @initialize()

    {parseXikiRequest} = require "./request-parser"
    request = parseXikiRequest {path, body, args, action}

    util = require "./util"

    request.process this, (res) =>
      console.log "create response from", res
      respond util.makeResponse res

  contexts: -> @_context[name] for name in @_contexts

  addContext: (name, ctx) ->
    if not (name in @_contexts)
      @_contexts.push name
    @_context[name] = ctx

  # TODO make ctx reloadable/overridable

  getSearchPath: (type) ->
    @packages.each (pkg) -> path.join pkg.path, type

  # getXiki: ->
  #   @context.getXiki() if @context
  #   this



module.exports =
  # middleware?
  __express: (req, res) ->
    path = req.params[0]
    # req.query has parameters
    #if typeof req.body == "string"

  Xiki: Xiki
