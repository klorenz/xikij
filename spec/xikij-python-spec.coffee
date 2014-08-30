uuid = require "uuid"
child_process = require "child_process"

describe "xikijbridge.py", ->

  it "can handle requests", ->
    p = child_process.spawn("#{__dirname}/../xikij/bin/xikijbridge.py")
    result = ''
    error  = ''

    p.stdout.on "data", (data) ->
      result += data.toString()
      console.log "out", data

    p.stderr.on "data", (data) ->
      error += data.toString()
      console.log "err", data

    p.stdin.write JSON.stringify(
      request: uuid.v4()
      xikij: "isDirectory"
      args: [ "#{__dirname}" ]
      )+"\n"

    p.stdin.write JSON.stringify(request: uuid.v4(), xikij: "exit")+"\n"

    closed = false
    p.on "close", ->
      expect(result).toBe "xyz"
      expect(error).toBe "xyz"
      closed = true

    waitsFor -> closed is true
