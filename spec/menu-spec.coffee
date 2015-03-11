os      = require "os"
path    = require "path"
uuid    = require "uuid"
fs      = require 'fs'
{Xikij} = require "../lib/xikij"

describe "Menu", ->
  describe "...written in python", ->
    it "can access xikij API", ->
      xikij = new Xikij packagesPath: "#{__dirname}/fixture/packages"

      waitsForPromise ->
        xikij.request("py-hostname").then (hostname) =>
          expect(hostname).toEqual os.hostname()

  describe "...any executable", ->
    it "can provide help", ->
      xikij = new Xikij packagesPath: "#{__dirname}/fixture/packages"

      waitsForPromise ->
        xikij.request("foo").then (x) =>
          expect(x.data).toBe """
            - foo
            - bar\n
          """

  describe "menu manager", ->
    tempdir = null
    result = null
    data = """
      module.exports = (xikij) ->
        @run = -> "hello from menu manager"
      """

    xikij = null
    updated = false

    beforeEach ->
      tempdir = path.join (os.tmpdir or os.tmpDir)(), uuid.v4()
      xikij = new Xikij userPackagesDir: tempdir

      updated = false

      xikij.event.on "package:module-updated", (name, module)->
        console.log "package:module-updated", name, module
        if module.menuName == "amazon" and module.package.name != "xikij"
          debugger
          updated = true

      waitsForPromise ->
        xikij.request(path: "menu/amazon.coffee", input: data).then (response) ->
          result = response


    afterEach ->
      if fs.existsSync tempdir
        xikij.remove(tempdir)

      if xikij
        xikij.shutdown()

    it "can write a menu", ->
      #streamConsumed = false

      runs ->
        expect(result.type).toBe "action"
        expect(result.data.action).toBe "message"
        expect(result.data.message).toBe "menu amazon updated"

        # xikij.util.consumeStream result.data, =>
        #   expect(string).toEqual(data)
        #   streamConsumed = true

      waitsFor -> updated
      # waitsFor ->
      #   streamConsumed is true

    it "can run new menu", ->
      waitsFor -> updated

      waitsForPromise ->
        result = xikij.request(path: "amazon").then (response) ->
          result = response

      runs ->
        expect(result.type).toBe "string"
        expect(result.data).toBe "hello from menu manager"
