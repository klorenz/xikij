{getIndent, strip, isEmpty} = require "./util"
{last}             = require "underscore"
{Path}             = require "./path"
Q = require "q"

class LineFinder
  constructor: (@path, @opts) ->
    @iPath       = 0
    @indentation = ['']
    @needIndent  = false
    @doContinue  = Q(null)
    unless @path instanceof Path
      @path = new Path(@path)

    unless @opts
      @opts = {expanded: false}

  collectLine: (result, line) ->
    unless @expanded
      if /^- /.test line
        line = '+'+line[1...]

    if @wasEmpty
      result.push ""

    result.push line

  findLine: (line) ->
    

    if @iPath >= @path.getLength()
      return @doContinue if !@needIndent and !@collecting

    indent  = getIndent line
    current = last @indentation
    line    = line[indent.length...]

    result = []

    if @collecting

      if isEmpty line
        @wasEmpty = true
        # care only about empty lines if next line follows
        # and collapse empty lines to one empty line

      if indent.length < current.length
        @collecting = false
        # we are done now

      else if indent.length == current.length
        @collectLine result, line
        return Q(result)

      else if @expanded
        @collectLine result, line
        return Q(result)

      # else skip more indented code

      return @doContinue


    if @needIndent
      if indent.length > current.length
        @indentation.push indent
        current = indent

        #if @insertPath

        if @iPath >= @path.getLength()
          @collecting = true
          @collectLine result, line
          @lastSameLine = line
          @needIndent = false
          return Q(result)

      @needIndent = false

      if @iPath >= @path.getLength()
        return @doContinue

    if /^[-@]/.test line
      return @doContinue if indent.length > current.length
      essence = line[2...]

      _essence_path = Path.split(essence)

      for p,i in _essence_path
        if p != @path.at(@iPath+i)
          return @doContinue

      @iPath      += i
      @needIndent  = true
      return @doContinue

    return @doContinue

  findLines: (text) ->
    if typeof text is "string"
      lines = text.replace(/\n$/, '').split("\n")
    else
      lines = text

    #deferred = Q.defer()

    promise = Q([])
    lines.forEach (line) =>
      promise = promise.then (result) =>

        @findLine(line).then (r) ->
          if r?
            for e in r
              result.push e

          result

    promise.then (result) ->
      result.join("\n")+"\n"

class ContentFinder
  constructor: (@xikij) ->

  find: (text, path) ->
    (new LineFinder path).findLines(text)

module.exports = {ContentFinder}
