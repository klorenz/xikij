{last} = require "underscore"
{startsWith, strip, getIndent, isEmpty} = require "./util"

class ContentFinder
  constructor: ->
    @indentation = ['']
    @insertInput = null

  isEmpty: (line) -> /^\s*$/.test line

  doSameLevel: (line) ->

  doLine: (line) ->
    if @insertInput?
      if isEmpty line
        @insertInput.push "\n"
        return true

      ind = getIndent line
      cur = last @indentation

      if startsWith ind, cur
        insertInput.push line[cur.length...]
        return true

      @indentation.pop()

      return @context.request({path: @insertPath, context}).then (response) =>
        @insertInput = null
        @insertPath  = null

        if collecting
          result.push indented response.toString(), ind
          return doLine line
        else
          return doLines indented response.toString(), cur

    if collecting
      if isEmpty line
        result.push "\n"
        return true

      ind = getIndent line
      cur = last @indentation

      unless startsWith ind, cur
        return false

      if ind == cur
        line = line[ind.length...]

        if startsWith line, "<<"
          line = line.replace /\s+$/, ''
          if endsWith line, "<<"
            line = line[...-2].replace /\s+$/, ''
            @insertPath = line
            @needIndent = true
            return true
          else
            return @context.request({path: strip(line[2...]), context}).then (response) =>
              result.push indented response.toString(), ind




  doLines:


findLines = (context, text, path) ->
  #context.debug
  lines = text.replace(/\n$/, '').split("\n")
  result = []
  collecting = false
  needIndent = false
  indentation = ['']

  unless nodePath
    collecting = true

  wasEmpty = false

  insertPath = null
  insertInput = null


  lastSameLine = ''

  iPath = 0
  i = -1

  while i < lines.length
    i += 1
    if i >= lines.length
      break

    line = lines[i]

    if insertInput?
      if /^\s*$/.test line
        insertInput.push "\n"
        continue

      ind = getIndent line
      cur = last indentation

      if startsWith ind, cur
        insertInput.push line[cur.length...]
        continue

      indentation.pop()

      xikij.request({path: insertPath, context}).then (response) ->
        response.toString()

      insert =
