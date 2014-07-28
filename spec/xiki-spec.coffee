{Xikij} = require '../lib/xikij'

path = require "path"
_ = require 'underscore'

describe "Xikij", ->

  it "should trigger 'loaded' event for packages", ->
    loadedHook = jasmine.createSpy("loadedHook")
    initializedHook = jasmine.createSpy("initializedHook")
    initialized = false

    xiki = new Xikij()
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
      xiki = new Xikij()

      xiki.packages.on "loaded", ->

        expect( (pkg.asObject('dir', 'name') for pkg in xiki.packages.all()) ).toEqual [
          dir: path.resolve(__dirname, "..", "xikij"), name: "xikij"
          ]

        expect( (pkg.asObject('dir', 'name', 'errors') for pkg in xiki.packages.failed()) ).toEqual []

        expect( (m.moduleName for m in xiki.packages.modules()).sort() )
          .toEqual [
            "xikij/amazon"
            "xikij/bookmarklet"
            "xikij/contexts/directory"
            "xikij/contexts/execution"
            "xikij/contexts/menu"
            "xikij/contexts/root"
            "xikij/contexts/ssh"
            "xikij/hostname"
            "xikij/ip"
          ]

        expect( (n for [n,c] in xiki.contexts(named: true)) ).toEqual [
          "Directory"
          "Execution"
          "Menu"
        ]

      xiki.initialize()

  describe "when you request a xiki response", ->
    describe "when passing a path", ->
      it "should handle the path", ->
        xiki = new Xikij()
        requestResponded = false
        os = require "os"

        runs ->
          xiki.request {path: "/hostname"}, (response) ->
            expect(response.data).toBe os.hostname()

            requestResponded = true

        waitsFor (-> requestResponded), "xiki has responded", 1000

    describe "passing no path, but a body", ->
    describe "passing no path, but a body and parameters", ->
    describe "passing a path and a body", ->
    describe "passing a path and a body", ->
