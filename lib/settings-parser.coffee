###
connections:

    Here is a list of your configured connections.  They are listed
    in fogbugz menu.

    SampleConnection:
        url: "https://fogbugz.com"

        You can either define a token for authentication.  If token
        is empty (default), username and password are taken.

        token: ""

        Or you can define username and password.

        username: "Your Username"
        password: "Your Password"

    SampleList:

      Here you find a sample list.  If you want to write examples in your
      descriptions, or list like this:

      * first
      * second
      * third

      As configurations only lists with hyphens are recognized.

      - first
      - second
      - third

You do not need necessarily quotations around single line strings, but you need
it for multiline string.

some key: """
    Here is a mutliline value.

    Here is more text.
    """

Now what about definitions in comments:

   I have here some comment with a little definition list:

   first:
      here is some text

   second: here is more text

   third:
      - here
      - is
      - a
      - list

   what makes this different from the configuration value, which is here:

   connection: foo

   well ... it is nothing, they are simply part of the settings, but they
   have no semantic meaning for the program, because it only looks for connection
   value.  Humans see the context.

###
CSON = require "cson-safe"
{first, last, extend, isArray, isObject} = require "underscore"

initConfigObject = (config) ->
  unless config.value? and isObject(config.value)
    config.value = {}
  if isArray(config.value)
    config.value = {}

reduceStack = (stack) ->
  value = stack.pop()
  config = last(stack)

  if "key" of config
    v = config.value
    if not (typeof v is "object") or v instanceof Array
      config.value = {}
    config.value[config.key] = value.value
    delete config.key

  else if config.value instanceof Array
    v = last(config.value)
    if typeof value.value is "object" and not (value.value instanceof Array)
      extend(v, value.value)
    else
      config.value.pop()
      config.value.push value.value

  config

store = (stack, value, {haveArray, force}) ->
  config = last(stack)

  if haveArray
    config.value = [] unless config.value instanceof Array
    config.value.push value
    return

  if "key" of config
    initConfigObject config
    config.value[config.key] = value
    delete config.key
    return

  if typeof value is "object"
    initConfigObject config
    extend(config.value, value)
    return

  if force
    config.value = value
  else unless isObject(config.value)
    config.value = value


parse = (lines) ->
  if typeof lines is "string"
    lines = lines.split /\n/

  indentation = [ "" ]

  config = value: null
  stack = [ config ]

  s = null
  expect = null

  debugger
  for line in lines
    if expect
      value += "\n#{line}"

    [line, indent, s] = /^(\s*)(.*)/.exec line
    currentIndentation = last(indentation)

    continue if line.match /^\s*$/

    if expect?
      if line[-3..] == expect
        expect = null
        value = CSON.parse(value)
        meta = stack.pop()
        if meta.key?
          obj = {}
          obj[meta.key] = value
        else
          obj = value
        store(stack, obj, {})
      continue

    if indent > currentIndentation
      config = value: null
      stack.push config
      indentation.push indent

    else if indent < currentIndentation
      indentation.pop()

      config = reduceStack(stack)

      # else if config.value instanceof Array
      #   config.value.push value

    if m = s.match(/^(.*):\s*$/)
      config.key = m[1]
      initConfigObject config
      continue

    haveArray = false

    if m = s.match(/^-\s+(.*)/)
      haveArray = true
      s = m[1]

    #if m = s.match(/^-)
    try
      value = CSON.parse(s)
      store(stack, value, {haveArray, force: true})
      continue
    catch
      if m = s.match(/^(.*):\s+(.*)/)
        if _m = m[2].match /^('''|""")/
          expect = _m[1]
          stack.push key: m[1]
          value = m[2]
          continue

        value = {}
        try
          _val = CSON.parse(m[2])
        catch
          _val = m[2]

        value[m[1]] = _val

      else if _m = s.match /^('''|""")/
        value = s
        expect = _m[1]
        stack.push {}
        continue
      else
        value = s
        # if there is already a value, this weak value won't override
        continue if config.value? and not haveArray

    store(stack, value, {haveArray})

  while stack.length > 1
    reduceStack(stack)

  return first(stack).value

module.exports = {parse}
