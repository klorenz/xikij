Q = require "q"
{Response} = require "../response"

console = (require "../logger")("xikij.interface.Request")

module.exports = (Interface, xikij) ->
  Interface.define class Request
    request: (args...) -> @dispatch "request", args
    respond: (args...) -> @dispatch "respond", args


  Interface.default class Request extends Request
    # request: (opts, respond) ->
    #   opts.context = this unless opts.context
    #   @context.request opts, respond

    respond: (func) ->
      if not (func instanceof Function)
        return Q(func)

      deferred = Q.defer()
      try
        func(deferred.resolve)
      catch error
        deferred.resolve(error)

      deferred.promise

    # respond gets a Response object, which contains a type and a stream
    request: (opts, _respond) ->
      if typeof opts is "string"
        opts = path: opts

      {path, body, args, action, context, input} = opts

      #xikij.initialized = xikij.initialize() unless xikij.initialized

      deferred = Q.defer()

      respond = (response) ->
        if _respond
           _respond response
        deferred.resolve response

      xikij.initialized
        .then =>
          {parseXikiRequest} = require "../request-parser"

          request = parseXikiRequest {path, body, args, input, action}

          context = this unless context

          request.process(context)
            .then (response) ->
              console.log "xikij request response", response

              Q(response)

                .then (response) =>
                  console.log "Q xikij request response", response

                  unless response instanceof Response
                    response = new Response data: response

                  respond response

                .fail (error) =>
                  response = new Response data: error, type: "error"

                  respond response

            .fail (error) ->
              console.log error.stack
              response = new Response data: error, type: "error"

              respond response

        .fail (error) =>
          console.log error.stack
          response = new Response data: error, type: "error"

          respond response

      deferred.promise
