
class HttpServer extends XikijClient

  # Create a xiki object for handling requests
  constructor: (opts) ->
    {@credentials} = opts
    @port = opts.port ? 18181
    @host = opts.host ? "localhost"

    @xiki = new Xiki opts

  serve: () ->
    @app = app = require("express")()
    logger = require 'morgan'
    bodyParser = require 'body-parser'

    app.use logger("dev")
    app.use bodyParser.json()
    app.use bodyParser.urlencoded()
    app.use bodyParser.text()

    # app.use "/web",

    app.use "*", (req, res) =>
      path = req.params[0]

      action = "expand"

      # you may pass action as part of URL
      m = /^\/(\w+):\/(.*)/.exec(path)
      if m
        if @xiki.isAction m[1]
          [action, path] = m[1..]

      args = req.query

      body = null
      unless req.is('application/x-www-form-urlencoded')
        body = req.body
      else
        _.extend args, req.body

      # you may also pass it as xikijAction parameter
      if 'xikijAction' of args
        action = args.xikijAction
        delete args.xikijAction

      @request {path, body, args, action}, (response) =>
        {data, type, mimeType} = response
        if mimeType
          res.set("Content-Type", mimeType)

        switch type
          when "stream"
            res.status(200)
            data.pipe(res)
          when "buffer"
            res.status(200).send(data)
          when "string"
            res.status(200).send(data.toString())
          when "number"
            res.status(200).send(data.toString())
          when "error"
            res.status(500).json(
              errorMessage: data.message
              stackTrace: data.stack.toString()
            )
          when "array"
            result = ""
            for s in data
              if typeof s is "object"
                result = response.data
                break
              else
                result += "+ #{s}\n"

            res.status(200).send(response.data)

          else
            res.status(200).json(response.data)

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

    @xiki.once "initialized", =>
      server = app.listen @port, @host, =>
        debug("listening to #{@host}:#{@port}")

    @xiki.initialize()


class HttpClient extends XikijClient

  constructor: (@opts) ->

  request: (thing, respond) ->
    if typeof thing is "string"
      if /^(https?|xikijs?)/.test thing # url given
        @opts = thing = url.parse thing

    if "uri" of thing
      @opts = url.parse thing.uri
      thing.path = @opts.path

    http.request(thing)



module.exports = XikijServer
