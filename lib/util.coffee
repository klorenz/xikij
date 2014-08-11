INDENT = /^[ \t]*/

stream = require 'stream'
{EventEmitter} = require 'events'

#
# Response
#
class Response extends EventEmitter
  constructor: (@stream, @type) ->

  getResult: (callback) ->
    result = ''

    @stream
      .on "data", (data) =>
        console.log "consumed ", data
        result += data

      .on "end", =>
        callback(result)

  pipe: (writable) ->
    @stream.pipe(writable)


module.exports =
  isSubClass: (B, A) ->
    return false unless A and B
    return false unless B.prototype
    return false unless typeof A is "function"

    B.prototype instanceof A

  getIndent: (line) ->
    return INDENT.exec(line)[0]

  removeIndent: (text, indent=null) ->
    unless indent?
      indent = INDENT.exec(line)[0]

    rx     = new RegExp("^#{indent}", "mg")
    text.replace rx, ""

  startsWith: (subject, string) ->
    return false if subject.length < string.length
    return subject[...string.length] == string

  endsWith: (subject, string) ->
    return false if subject.length < string.length
    return subject[-string.length..] == string

  strip: (s) -> s.replace(/^\s+/, '').replace(/\s+$/, '')

  parseCommand: (s) ->
    result = []
    isShellCommand = false
    commandRegex = ///
      (?:^|\s+)
      (?:
        ("(?:\\.|[^"\\]+)*")
        | ('(?:\\.|[^'\\]+)*')
        | (\S+)
      )
      ///
    for m in s.split commandRegex
      continue if m is undefined
      continue if m == ""
      if m[0] == '"' and m[-1..] == '"'
        result.push m[1...-1].replace('\\\\', '\\').replace('\\"', '"')
      else if m[0] == "'" and m[-1..] == "'"
        result.push m[1...-1].replace('\\\\', '\\').replace('\\"', '"')
      else
        return null if /(^[|<>]$|^[12]>|`)/.test m
        result.push m

    return result


  StringReader: class StringReader extends stream.Readable
    constructor: (@subject) ->
      unless Buffer.isBuffer(@subject)
        @subject = new Buffer(@subject)

    pipe: (stream)->
      stream.write(@subject)
      stream

  Indenter: class Indenter extends stream.Transform
    constructor: ({@indent}) ->
      super()
      @firstLine = true
      unless @indent
        @indent = ""

    _transform: (chunk, encoding, done) ->
      if @firstLine
        if @indent
          @push @indent
        @firstLine = false

      @push chunk.toString().replace /\n(?!$)/g, "\n#{@indent}"
      done()

  indented: (thing, indent) ->
    if thing instanceof stream.Readable
      thing.pipe(new Indenter({indent}))
    else
      indent + thing.toString().replace /\n(?!$)/g, "\n#{indent}"

  consumeStream: (stream, callback) ->
    result = ""
    stream
      .on "data", (data) -> result += data.toString()
      .on "end", -> callback(result)

  promised: (promise, callback) ->
    promise.then(callback).fail (error) ->
      console.log error
      throw error #new Error(error)

  cookCoffee: (content, done) ->
    lines = content.toString().split(/\n/)
    isCoffee = false
    isJavaScript = false
    isMenu = false
    out = []
    menu = []
    for line in lines
      if line.match /^```coffee/
        isCoffee = true
        out.push "# ```coffee"
        continue

      if isCoffee and line.match /^\s*\# example/
        menu.push out[out.length-1][2..]
        isCoffee = false

      if isCoffee and line.match /^```$/
        isCoffee = false
        out.push "# ```"
        continue

      if isCoffee
        out.push line
      else
        menu.push line
        if line
          out.push "# "+line
        else
          out.push "#"

    done out.join("\n")+"\n", (menu.join("\n")+"\n").replace(/\n{3,}/, "\n\n")

  #
  # Returns a Response object, where value is a stream
  #
  makeResponse: (x, annotate) ->
    if x instanceof stream.Readable
      return new Response x, "text/plain", annotate

    class ResultProvider extends stream.Readable
      _read: ->

        if x instanceof Buffer
          unless @done
            @done = true
            @push x
          else
            @push null

        if x instanceof Error
          unless @done
            @push x.stack.toString()
            @done = true
          else
            @push null

        if x instanceof Array
          @element = 0 unless @element
          if @element < x.length
            while @push "+ #{x[@element]}\n"
              @element += 1
          else
            @push null

        if typeof x == "string"
          unless @done
            @push x
            @done = true
          else
            @push null

        unless @done
          @done = true
          @push JSON.stringify(x)
        else
          @push null

    result = new ResultProvider()

    # return a json object
    return new Response result, "application/json", annotate \
       if (typeof x == "object") \
         and not (x instanceof Array) \
         and not (x instanceof Buffer)

    return new Response result, "text/plain", annotate
