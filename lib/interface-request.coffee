module.exports = (Interface) ->
  Interface.define class Request
    request: (args...) -> @context.request args...

  Interface.default class Request extends Request
    request: (opts, respond) ->
      opts.context = this unless opts.context
      @context.request opts, respond
