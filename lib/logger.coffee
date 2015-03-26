levels = [ 'debug', 'dir', 'time', 'timeEnd', 'trace', 'log', 'info', 'warn', 'error', 'none' ]

class Logger
  constructor: ({@parent, @name, @level, @prefix}) ->
    @parent = null unless @parent
    @name = "" unless @name

    @level = "" if not @level

    @setPrefix(@prefix)

    @_loggers = {}

  printConfig: ->
    for name, logger of @_loggers
      logger.printConfig()

  setPrefix: (prefix) ->
    prefix = [] unless prefix?
    unless prefix instanceof Array
      prefix = [prefix]
    @prefix = prefix

    @setLevel(@level)

    #@updateFunctions(@level, @prefix)

  setLevel: (level) ->
    @level = level
    @updateFunctions()

    for name, logger of @_loggers
      logger.setLevel(level)

  getLevel: () -> @level

  updateFunctions: () ->
    level = levels.indexOf(@level)

    if level == -1
      level = 0
      if @parent
        level = levels.indexOf(@parent.getLevel())

        if level == -1
          level = 0

    prefix = @prefix

    for name, i in levels
      @[name] = (args...) ->
        # console.log "[DUMMY: #{levels[level]}] (#{args})"

      if i >= level
        if prefix.length > 4
          throw "prefix must not have more than 4 elements"

        unless name of console
          console[name] = console.log

        if prefix.length == 0
            @[name] = console[name].bind(console, "[#{name}] [#{@name}]")
        if prefix.length == 1
            @[name] = console[name].bind(console, "[#{name}] [#{@name}]", prefix[0])
        if prefix.length == 2
            @[name] = console[name].bind(console, "[#{name}] [#{@name}]", prefix[0], prefix[1])
        if prefix.length == 3
            @[name] = console[name].bind(console, "[#{name}] [#{@name}]", prefix[0], prefix[1], prefix[2])
        if prefix.length == 4
            @[name] = console[name].bind(console, "[#{name}] [#{@name}]", prefix[0], prefix[1], prefix[2], prefix[3])


  getLogger: (opts) ->
    {name, prefix, level} = opts
    if typeof name is "string"
      name = name.split "."

    if name[0] not of @_loggers
      if @name
        _name = "#{@name}.#{name[0]}"
      else
        _name = "#{name[0]}"

      logger = new Logger parent: @, name: _name

      @_loggers[name[0]] = logger

    logger = @_loggers[name[0]]
    if name.length > 1
      return logger.getLogger({name: name[1..], prefix, level})
    else
      if prefix?
        logger.setPrefix(prefix)

      unless level?
        if @parent
          level = @parent.getLevel()
        else
          level = "error"

      logger.setLevel(level)

      return logger

rootLogger = new Logger name: "", level: "error"

getLogger = (name, opts) ->
  {prefix, level} = opts or {}
  return rootLogger unless name
  rootLogger.getLogger({name, prefix, level})

module.exports = getLogger
