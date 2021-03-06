{getIndent, startsWith, endsWith, strip, StringReader} = require "./util"
{last, keys} = require "underscore"
{Node} = require "./node"
stream = require "stream"
console = (require "./logger")("xikij.path")

splitPath = (path) ->
  tokens = path.split /(\\.|[()\[\]{}<>"'\/])/
  result = [""]
  closer = {"{": "}", "(": ")", "[": "]", "<": ">", '"': '"', "'": "'" }
  special = /^[()\[\]{}<>"'\/]$/
  stack  = []
  for token in tokens
    continue unless token.length

    # create new path element
    if token is "/" and not stack.length
      result.push ""
      continue

    if token[0] is "\\"
      if token[1].match special
        result[result.length-1] += token[1]
      else
        result[result.length-1] += token
      continue

    result[result.length-1] += token

    if token == last(stack)
      stack.pop()
      continue

    if token of closer
      stack.push closer[token]
      continue

  return result

joinPath = (args...) ->
  if args.length == 1 and args[0] instanceof Array
    args = args[0]

  opts = last(args)
  if typeof opts is "object"
    args = args[...-1]
  else
    opts = {escape: true}

  if opts.escape
    (arg.replace(/[\\()\[\]{}<>"'\/]/g, (m) -> "\\#{m}") for arg in args).join("/")
  else
    return args.join("/")



isEmpty = (l) -> /^\s*$/.test(l)
INDENT = "  "

class PathFragment
  constructor: (@name, @position=0) ->
    if typeof @name is "object"
      @position = @name.position
      @name     = @name.name

    if m = @name.match /(.*)\[(\d+)\]$/
      @name     = m[1]
      @position = parseInt(m[2])

  toString: ->
    if @position > 0
      "#{@name}[#{@position}]"
    else
      @name

  toJSON: ->
    return [@name, @position]

class Path
  constructor: (@nodePath) ->
    @nodePath = [] unless @nodePath

    if @nodePath instanceof Path
      @nodePath = (new PathFragment(x) for x in @nodePath.nodePath)
    if typeof @nodePath is "string"
      @nodePath = (new PathFragment(x) for x in splitPath(@nodePath))

  # @split: (string) -> splitPath(string)
  # @join:  (array) -> joinPath(array)
  # split:  (string) -> splitPath(string)
  # join:   (array) -> joinPath(array)

  @split: (string) -> splitPath(string)
  @join: (array) -> joinPath(array)

  rooted: ->
    return no if @empty()
    @nodePath[0].name is ""

  getLength: ->
    @nodePath.length

  # return the first portion of path
  first: -> @nodePath[0].name

  # return the first portion of path
  last: -> @nodePath[@nodePath.length-1].name

  slice: (args...) ->
    new Path @nodePath.slice args...

  clone: ->
    new Path [ new PathFragment(frag) for frag in @nodePath ]

  # string is optional
  toArray: (string) ->
    if string
      splitPath(string)
    else
      (x.name for x in @nodePath.slice())

  toJSON: ->
    return @nodePath

  unshift: (thing)->
    if thing instanceof Array
      @nodePath.unshift new PathFragment thing...
    else if typeof thing is "string"
      @nodePath.unshift new PathFragment thing
    else if thing instanceof PathFragment
      @nodePath.unshift thing
    else
      throw "cannot unshift thing: #{thing}"

  shift: -> @[1..]

  # at index, [ value ]
  #
  # return value at index.  if value given, set the value
  at: (index, value) ->
    while index < 0
      index = @nodePath.length + index

    if typeof value is "string"
      @nodePath[index].name = value
    else
      @nodePath[index].name

  get: (index) ->
    return @nodePath[index]

  empty: -> @nodePath.length == 0

  toPath: (opts) ->
    opts = opts or {}
    joinPath (frag.name for frag in @nodePath).concat [ opts ]

  toString: -> @toPath()

  selectFromObject: (original, opts) ->
    obj  = original
    opts = opts or {}

    transform = opts.transform or ((x) -> x.replace(/^\./, ''))
    callfunc  = opts.caller    or ((f, p) -> null)
    #result    = opts.result    or ((object, p, i) -> {object, path: @p[i..]})
    found     = opts.found     or ((object, p, i) -> false)


    if 'objects' of opts
      keysOnly = not opts.objects
    else
      keysOnly = false

    for frag,i in @nodePath
      console.debug "frag: #{frag}, i: #{i}"

      if obj instanceof Array
        _equals = 0
        _found = no
        for e,i in obj
          if e.toString() == frag.name
            if _equals == frag.position
              obj = e
              _found = yes
              break
            else
              _equals++

          if e instanceof Node
            if e.label == frag.name
              if _equals == frag.position
                obj = e.content
                _found = yes
              else
                _equals++

        break unless _found
        continue

      key = transform frag.name

      console.debug "key: #{key}, obj", obj

      break unless key of obj

      break unless found obj[key], @, i

      obj = obj[key]

      if obj instanceof Function
        obj = callfunc obj, @[i+1..]

    if obj is original and @nodePath.length > 0
      throw new Error("path not in object")

    if typeof obj is "string" or obj instanceof Array
      return obj

    if keysOnly
      obj = keys(obj)

    return obj

  selectFromTree: (args...) -> @selectFromObject args...

  selectFromText: (context, text) ->
    unless text instanceof stream.Readable
      text = new StringReader(text)

    transformer = new SelectFromText {context, @nodePath}
    text.pipe(transformer)
    #text.on "readable", -> transformer.write(text.read())
    #text.end()



class SelectFromText extends stream.Transform

  constructor: (opts) ->
    super()

    {@context, @nodePath} = opts

    # last chunk ended with incomplete line
    @incompleteLine  = null

    # is collecting lines?
    @isCollecting    = false

    # need more indented text at next line
    @needIndent      = false

    # stack of indentations
    @indentation     = ['']

    # was last line an empty line?
    @wasEmpty        = false

    # xikij path to insert content from
    @insertXikijPath = null

    # content to insert
    @insertInput     = null

    # if there are multiple lines with same content
    @lastSameLine    = ""

    # index of path fragment
    @path_i          = 0

    # finished processing this stream
    @finished = false

  _transform: (@chunk, @encoding, @done) ->
    if @finished
      return @done()

    @start = 0
    @end = @start
    @processChunk()

  _flush: (done) ->
    done()

  processChunk: ->
    unless Buffer.isBuffer(@chunk)
      @chunk = new Buffer(@chunk)

    for c,i in @chunk
      if c is 10 # \n
        @end = i
        line = @chunk.toString 'utf8', @start, @end
        @start = i+1

        if @incompleteLine?
          s = @incompleteLine+s
          @incompleteLine = null

        # if there was returned a false value, process a substream
        return unless @processLine(line)

    if @start < @chunk.length
      @incompleteLine = @chunk.toString 'utf8', @start

    @done()

  myFinish: ->
    @push null
    @finished = true
    @done()
    null

  prependChunk: (string) ->
    @chunk = new Buffer string+@chunk.toString('utf8', @start)
    @start = @end = 0
    @processChunk()

  doRequest: (request) ->
    @context.request request, (response) =>
      string = ""
      if response.type == "stream"
        response.data
          .on "data", (chunk) => string += chunk.toString()
          .on "end", => @prependChunk(@xikijIndent + string.replace(/\n/, "\n#{@xikijIndent}"))

      else
        string = response.data.toString()
        unless /\n$/.test string
          string += "\n"
        @prependChunk @xikijIndent + string.replace("\n", "\n#{@xikijIndent}")
    return null

  processLine: (line) ->
    curInd = last @indentation

    if @insertInput?
      unless isEmpty line
        return @insertInput.push "\n"

      indent = getIndent line
      if startsWith ind, curInd
        return @insertInput.push line[curInd.length..]

      @indentation.pop()

      return @doRequest path: @insertXikijPath, body: @insertInput, indent: indent

    unless @isCollecting
      if isEmpty line
        @wasEmpty = true
        return true
      else
        @wasEmpty = false
    else
      if isEmpty line
        return @push "\n"

      indent = getIndent line

      return @myFinish() unless startsWith indent, curInd

      if indent.length == curInd.length
        line = line[indent.length..]

        if startsWith line, "<<"
          line = line.replace /\s+$/, ''
          @xikijIndent = indent
          if endsWith line, "<<"
            line = line[...-2].replace /\s+/, ''
            insertXikijPath = line
            needIndent = true
            return true
          else
            return @doRequest path: line[2..].replace(/^\s+/, '').replace(/\s+$/, '')

        else
          if startsWith line, "- "
            line = "+"+line[1..]
            if "::" in line
              line = line.split("::", 1)[0]

          console.log "pushing #{line}"
          @push line

        @lastSameLine = line

      if indent.length > curInd.length
        unless startsWith @lastSameLine, "+"
          console.log "pushing #{line}"
          @push line

        return true

    unless startsWith line, curInd
      @indentation.pop()
      @needIndent = false
      @path_i -= 1
      return @myFinish()

    indent = getIndent line
    line = line[indent.length..].replace /\s+$/, ''

    if @needIndent
      if indent.length > curInd.length
        @indentation.push indent
        curInd = indent

        if @insertXikijPath
          @insertInput = []
          if @wasEmpty
            @insertInput.push "\n"

          @insertInput.push "#{line}\n"
          @needIndent = false
          @lastSameLine = line
          return true

        if @path_i >= @nodePath.length
          @isCollecting = true
          if line[0] == '-'
            line = "+"+line[1..]

          @push "\n" if @wasEmpty

          console.log "pushing #{line}"
          @push "#{line}\n"
          @lastSameLine = line
          @needIndent = false
          return true

      @needIndent = false
      if @path_i >= @nodePath.length
        console.log "pushing nothing"
        @push ""
        return @myFinish()

    if startsWith line, "<<"
      if endsWith line, "<<"
        line = line[...-2].replace /\s+$/, ''
        @insertXikijPath = line
        @needIndent = true
      else
        @xikijIndent = indent
        return @doRequest path: line[2..].replace(/^\s+/, '').replace(/\s+$/, '')

      return true

    if line[0] in ["-", "@"]
      return true if indent.length > curInd.length

      command = null
      _line = line[1..].replace(/^\s+/, '').replace(/\s$/, '')

      if /::/.test _line
        [_line, command] = (strip(x) for x in _line.split("::", 1))

      if /:/.test _line
        _line = _line.split(':', 1)[0]

      return true if _line != @nodePath[@path_i].name

      if _line == @nodePath[@path_i].name
        if command?
          @xikijIndent = indent + INDENT
          return @doRequest path: command, action: "expanded"
        else
          @path_i += 1
          @needIndent = true

    return true

module.exports = {Path, PathFragment}
