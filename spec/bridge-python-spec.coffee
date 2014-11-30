uuid = require "uuid"
child_process = require "child_process"

describe "xikijbridge.py", ->

  it "can handle requests", ->
    p = child_process.spawn("#{__dirname}/../bin/xikijbridge.py")
    result = ''
    error  = ''

    p.stdout.on "data", (data) ->
      result += data.toString()
      console.log "out", data.toString()

    p.stderr.on "data", (data) ->
      error += data.toString()
      console.log "err", data.toString()

    p.stdin.write JSON.stringify(
      req: uuid.v4()
      cmd: "isDirectory"
      args: [ "#{__dirname}" ]
      )+"\n"

    p.stdin.write JSON.stringify(req: uuid.v4(), cmd: "exit")+"\n"

    closed = false
    p.on "close", ->
      lines = result.replace(/\s*$/, '').split("\n")
      r1 = JSON.parse(lines[0])
      r2 = JSON.parse(lines[1])
      expect(r1.ret).toBe true
      expect(r2.ret).toBe "exited"
      closed = true

    waitsFor -> closed is true
