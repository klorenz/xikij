levels = [ 'debug', 'dir', 'time', 'timeEnd', 'trace', 'log', 'info', 'warn', 'error' ]

class Logger
  constructor: ({@parent, @name, @level, @prefix}) ->
    @parent = null unless @parent
    @name = "" unless @name

    if typeof @level is "string"
      @level = levels.indexOf(@level)
    else
      @level = -1 if not @level and @level != 0

    @setPrefix(@prefix)

    @_loggers = {}

  updateLevel: () ->
    @setLevel(-1) if @level < 0

  setPrefix: (prefix) ->
    prefix = [] unless prefix?
    unless prefix instanceof Array
      prefix = [prefix]
    @prefix = prefix

    @updateFunctions(@level, @prefix)

  setLevel: (level) ->
    @level = level

    _level = levels.indexOf(level)

    if _level == -1
      _level = 0
      if @parent
        _level = @parent.getLevel()

    @updateFunctions(_level, @prefix)

  updateFunctions: (level, prefix) ->
    for name, i in levels
      @[name] = ()->
      if i >= level
        if prefix.length > 4
          throw "prefix must not have more than 4 elements"

        if @prefix.length == 0
            @[name] = console[name].bind(console, "[#{@name}]")
        if @prefix.length == 1
            @[name] = console[name].bind(console, "[#{@name}]", prefix[0])
        if @prefix.length == 2
            @[name] = console[name].bind(console, "[#{@name}]", prefix[0], prefix[1])
        if @prefix.length == 3
            @[name] = console[name].bind(console, "[#{@name}]", prefix[0], prefix[1], prefix[2])
        if @prefix.length == 4
            @[name] = console[name].bind(console, "[#{@name}]", prefix[0], prefix[1], prefix[2], prefix[3])

    for name, logger of @_loggers
      logger.updateLevel()

  getLogger: (opts) ->
    {name, prefix, level} = opts
    if typeof name is "string"
      name = name.split "."

    if name[0] not in @_loggers
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
      if level?
        logger.setLevel(level)

      return logger

rootLogger = new Logger level: 4

getLogger = (name, opts) ->
  {prefix, level} = opts or {}
  return rootLogger unless name
  rootLogger.getLogger({name, prefix, level})

module.exports = {getLogger}
