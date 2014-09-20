
Object.defineProperty global, '__xikij_stack',
  get: ->
    debugger
    orig = Error.prepareStackTrace;
    Error.prepareStackTrace = (_, stack) -> stack
    err = new Error;
    Error.captureStackTrace(err, arguments.callee);
    stack = err.stack;
    Error.prepareStackTrace = orig;
    return stack;

Object.defineProperty global, '__xikij_line',

log = (level, levels, args...) ->
  unless log of lines
    log.lines = []

  # if level in levels
  #   log.lines
  #         console.log @.constructor.name, "line #{line}", args...



module.exports = (Interface) ->
  Interface.define class Logger
    _level: null


    getLogLevel: ->
      if @_level?
        Q(@_level)
      else
        @context.getLogLevel()

    info: (args...) ->
      line = __xikij_line
      @getLogLevel().then (level) ->
        if level in ["info", "debug"]
          console.log @.constructor.name, "line #{line}", args...

    debug: (args...) ->
      line = __xikij_line
      @getLogLevel().then (level) ->
        if level in ["debug"]
          console.log @.constructor.name, "line #{line}", args...

    # set log level of containing context to level
    setLogLevel: (level) ->
      @context._level = level

  Interface.default class Logger extends Logger
