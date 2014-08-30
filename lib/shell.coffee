repl    = require "repl"
{XikijClient} = require "./xikij"

xikij = new XikijClient()

session =
  cwd: ''

_output = console.log
_debug = console.log

console.log = ->

class ResponseHandler
  apply_object: (response, done) ->
    if response.data instanceof Array
      result = ""
      for s in response.data
        result += "#{s}\n"
      done(result)

  apply_stream: (response, done) ->
    response.data
      .on "data", (data) =>
        _output data
        #result += ""
      .on "end", =>
        done("")
    ""

  apply_default: (response, done) ->
    done(response.data)

  applyResponse: (response, done) ->
#    _debug response
    handler = "apply_#{response.type}"
    if handler of @
      @[handler] response, done
    else
      @apply_default response, done


rh = new ResponseHandler

util = require "util"

repl.start
  writer: (obj) ->
    if typeof obj is "string"
      return obj
    else
      return util.inspect obj

  eval: (cmd, context, filename, callback) ->
    # cmd is (<userinput>\n)
    #return callback(null, cmd[1...-1])
    cmd = cmd[1...-1].replace /[\n\r \t]+$/, ''

    if cmd
      path = "#{session.cwd}/#{cmd}"
    else
      path = session.cwd

    xikij.request({path}).then (response) ->
      try
        rh.applyResponse response, (result) ->
          #_debug "result", result
          callback null, result
      catch e
        callback e, null
