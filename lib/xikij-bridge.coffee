path           = require 'path'
stream         = require 'stream'
child_process  = require "child_process"
uuid           = require "uuid"
Q              = require "q"
{xikijBridgeScript} = require "./util"
{EventEmitter} = require "events"

class OutputProvider extends stream.PassThrough
  constructor: () ->
    super()

class InputProvider extends stream.Writable
  constructor: (@opts) ->
    super()
    {@request, @bridge} = opts

  write: (chunk, encoding, done) ->
    if opts.decodeStrings
      # encoding specifies enc of chunk
      @bridge.write req: @request.request.req, input: chunk
    else
      @bridge.write req: @request.request.req, input: chunk.toString()

  end: (chunk, encoding, done) ->
    if chunk
      @write chunk, encoding, done

    @bridge.write req: @request.request.req, input: null


class ProcessProvider extends EventEmitter
  constructor: (bridge, request) ->
    @stdout  = stream.PassThrough()
    @stderr  = stream.PassThrough()
    @request = request
    @stdin   = InputProvider(request: request, bridge: bridge)
#    @stdin  =

#
# This can be called from SSH on
#
class XikijBridge
  constructor: ({xikijBridge, cmdPrefix, onExit, suffix}) ->
    unless cmdPrefix
      cmdPrefix = []
    unless suffix
      suffix = "py"
    unless xikijBridge
      # default is python bridge
      xikijBridge = xikijBridgeScript(suffix)

    if typeof cmdPrefix is "string"
      cmdPrefix = parseCommand cmdPrefix

    @cmd = cmdPrefix.concat [ xikijBridge ]

    @bridge = child_process.spawn @cmd[0], @cmd[1..]

    buffer = ''
    @bridge.stdout.on "data", (data) =>
      buffer += data.toString()
      lines = buffer.split("\n")
      buffer = lines[lines.length-1]
      for line in lines[...-1]
        @response line

    # this is most unlikely, because not specified by protocol
    @bridge.stdout.on "end", =>
      if buffer.length
        @response buffer

    stderr = ''
    @bridge.stderr.on "data", (data) =>
      stderr += data.toString()
      console.log "err", data.toString()

    if onExit
      @bridge.on "exit", (result) =>
        if result != 0
          for uid,request of @requests
            request.deferred.reject(new Error stderr)

        onExit()

    @requests = {}

  response: (s) ->

    console.log "response: #{s}"

    response = JSON.parse(s)
    uid = response.res

    # bridge does a request to this
    #if not uid of @requests
    #if uid not of requests

    request = @requests[uid]

    # handle stream response
    unless request.response

      if response.process
        request.response = new ProcessProvider(@, request)
        request.deferred.resolve(request.response)

      else if response.cnk
        request.response = stream.PassThrough()
        request.deferred.resolve(request.response)

      else
        # handle errors
        if response.error
          try
            throw new Error(response.error,
              details: "Got error running bridge #{@cmd}:\n#{response.stack}")
          catch e
            request.deferred.reject(e)
        else
          # handle results
          request.deferred.resolve(response.ret)
        delete @requests[uid]
      return

    if request.response instanceof ProcessProvider
      chunk = response.cnk
      if chunk
        if 'cnl' of response
          channel = response.cnl
        else
          channel = 'stdout'
        request.response[channel].write(chunk)
      else
        if response.exit
          request.response.stdout.end()
          request.response.stderr.end()
          request.response.emit "exit", response.exit
      return

    if request.response instanceof stream.PPassThrough
      chunk = response.cnk
      if chunk
        request.response.write(chunk)
      else
        request.response.end()
        delete @requests[uid]
      return

    # if response.chunk
    #   request.response.emit "data", response.chunk

  close: ->
    @request(null, "exit")

  write: (req) ->
    @bridge.stdin.write JSON.stringify(req)+"\n"

  request: (context, cmd, args...) ->

    uid = uuid.v4()

    @requests[uid] = req =
      context: context
      deferred: Q.defer()
      request: {
        req: uid
        cmd: cmd
        args: args
      }

    console.log "bridged req", req

    @write req.request

    req.deferred.promise

module.exports = {XikijBridge}
