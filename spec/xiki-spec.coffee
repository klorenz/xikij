{Xiki} = require '../src/xiki'

path = require "path"
_ = require 'underscore'



describe "Xiki", ->

  it "should trigger 'loaded' event for packages", ->
    loadedHook = jasmine.createSpy("loadedHook")
    initializedHook = jasmine.createSpy("initializedHook")
    initialized = false

    xiki = new Xiki()
    xiki.packages.on "loaded", ->
      loadedHook()

    xiki.on "initialized", ->
      expect(loadedHook).toHaveBeenCalled()
      initializedHook()
      initialized = true

    runs ->
      xiki.initialize()

    waitsFor (-> initialized), "xiki has been initialized", 1000

    runs ->
      expect(initializedHook).toHaveBeenCalled()

  describe "when xiki object has been created", ->

    it "should have loaded basic package", ->
      xiki = new Xiki()

      xiki.packages.on "loaded", ->

        expect( (pkg.asObject('dir', 'name') for pkg in xiki.packages.all()) ).toEqual [
          dir: path.resolve(__dirname, "..", "xiki"), name: "xikijs"
          ]

        expect( (pkg.asObject('dir', 'name', 'errors') for pkg in xiki.packages.failed()) ).toEqual []

        expect( (m.moduleName for m in xiki.packages.modules()).sort() )
          .toEqual ["xikijs-directory", "xikijs-execution", "xikijs-ssh"]

      xiki.initialize()

  describe "when you request a xiki response", ->
    describe "when passing a path", ->
      it "should handle the path", ->
        xiki = new Xiki()
        requestResponded = false
        os = require "os"

        runs ->
          xiki.request {path: "/hostname"}, (response) ->
            response.getResult (result) ->
              expect(result).toBe os.hostname()

            requestResponded = true

        waitsFor (-> requestResponded), "xiki has responded", 1000

    describe "passing no path, but a body", ->
    describe "passing no path, but a body and parameters", ->
    describe "passing a path and a body", ->
    describe "passing a path and a body", ->
