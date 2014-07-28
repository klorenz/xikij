{getIndent, startsWith, endsWith, strip, StringReader} = require "./util"
{last} = require "underscore"
stream = require "stream"

isEmpty = (l) -> /^\s*$/.test(l)
INDENT = "  "

class PathFragment
  constructor: (@name, @position=0) ->

  toString: ->
    if @position > 0
      "#{@name}[#{@position}]"
    else
      @name

class Path
  constructor: (@nodePath) ->
    if typeof @nodePath is "string"
      @nodePath = (new PathFragment(x) for x in @nodePath.split("/"))

  # return the first portion of path
  first: -> @nodePath[0].name

  slice: (args...) ->
    new Path @nodePath.slice args...

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

  empty: -> @nodePath.length == 0

  toPath: ->
    (frag.name for frag in @nodePath).join("/")

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
      @push null
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
    console.log "pushing null"
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
        console.log "pushing EOL"
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
      debugger
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
