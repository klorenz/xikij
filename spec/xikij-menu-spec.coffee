os = require "os"
{Xikij} = require "../lib/xikij"

describe "Menu", ->
  describe "...written in python", ->
    it "can access xikij API", ->
      xikij = new Xikij packagesPath: "#{__dirname}/fixtures/packages"

      waitsForPromise ->
        xikij.GET("py-hostname").then (hostname) =>
          expect(hostname).toEqual os.hostname()


  describe "menu manager", ->
    tempdir = null
    result = null
    data = """
      module.exports = (xikij) ->
        @run -> "hello world"
      """

    xikij = null

    beforeEach ->
      xikij = new Xikij

      waitsForPromise ->
        xikij.tempDir('userdir').then (_tempdir) ->
          tempdir = _tempdir

      waitsForPromise ->
        result = xikij.request path: "menu/amazon", input: data, args: {
          userDir: tempdir
        }
        result

    it "can write a menu", ->
      streamConsumed = false

      runs ->
        expect(result.type).toBe "stream"

        xikij.util.consumeStream result.data, =>
          expect(string).toEqual(data)
          streamConsumed = true

      waitsFor ->
        streamConsumed is true

    it "can run new menu", ->
      waitsForPromise ->
        result = xikij.request path: "menu/amazon", args: {userDir: tempdir}

      runs ->
        expect(result.type).toBe "string"
        expect(result.data).toBe "hello world"
