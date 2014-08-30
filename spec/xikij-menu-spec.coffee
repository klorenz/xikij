os = require "os"
{Xikij} = require "../lib/xikij"

describe "Menu", ->
  describe "...written in python", ->
    it "can access xikij API", ->
      xikij = new Xikij packagesPath: "#{__dirname}/fixtures/packages"

      waitsForPromise ->
        xikij.GET("py-hostname").then (hostname) =>
          expect(hostname).toEqual os.hostname()
