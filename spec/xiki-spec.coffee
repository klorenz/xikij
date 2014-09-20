{Xikij} = require '../lib/xikij'
{consumeStream} = require "../lib/util"

path = require "path"
_ = require 'underscore'

describe "Xikij", ->

  it "should load packages", ->

    xikij = new Xikij()
    xikij.initialize()

    waitsForPromise ->
      xikij.packages.loaded()

  # fit "should trigger 'loaded' event for packages", ->
  #   loadedHook = jasmine.createSpy("loadedHook")
  #   initializedHook = jasmine.createSpy("initializedHook")
  #   initialized = false
  #
  #   xiki = new Xikij()
  #
  #   # xiki.packages.on "loaded", ->
  #   #   loadedHook()
  #   #
  #   # xiki.on "initialized", ->
  #   #   expect(loadedHook).toHaveBeenCalled()
  #   #   initializedHook()
  #   #   initialized = true
  #
  #   runs ->
  #     xiki.initialize()
  #
  #   waitsFor (-> initialized), "xiki has been initialized", 1000
  #
  #   runs ->
  #     expect(initializedHook).toHaveBeenCalled()
  #
  describe "when xiki object has been created", ->

    it "should have loaded basic package", ->
      xiki = new Xikij()

      xiki.packages.loaded().then ->

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
            "xikij/contexts/help"
            "xikij/contexts/menu"
            "xikij/contexts/root"
            "xikij/contexts/ssh"
            "xikij/hostname"
            "xikij/inspect"
            "xikij/ip"
            "xikij/log"
          ]

        expect( (n for [n,c] in xiki.contexts(named: true)) ).toEqual [
          "Directory"
          "Execution"
          "Menu"
        ]

      xiki.initialize()

  describe "when you request a xiki response", ->
    describe "when passing 'path'", ->

      doPromisedRequest = (xikij, request, callback) ->
        waitsForPromise ->
          promise = xikij.request(request)
          promise
            .then callback
            .fail (error) -> throw error

      it "should handle the path with callback", ->
        xikij = new Xikij()
        requestResponded = false
        os = require "os"

        runs ->
          xikij.request {path: "hostname"}, (response) ->
            expect(response.data).toEqual os.hostname()
            requestResponded = true

        waitsFor (-> requestResponded), "xiki command has responded", 1000

      it "should handle an empty path", ->
        xikij = new Xikij()
        requestResponded = false
        os = require "os"

        runs ->
          xikij.request {path: ""}, (response) ->
            expect(response.data).toEqual """
              + ~/
              + ./
              + /
              + ?
              + amazon
              + bookmarklet
              + contexts
              + hostname
              + inspect
              + ip
              + log\n
            """

            requestResponded = true

        waitsFor (-> requestResponded), "xiki command has responded", 1000

      it "should handle the path with promise", ->
        xikij = new Xikij()
        os = require "os"

        doPromisedRequest xikij, {path: "hostname"}, (response) ->
          expect(response.data).toEqual os.hostname()

      it "can run commands", ->
        xikij = new Xikij()
        requestResponded = false

        doPromisedRequest xikij, {path: '$ echo "hello world"'}, (response) ->
          expect(response.type).toBe "stream"
          consumeStream response.data, (result) ->
            expect(result).toBe "hello world\n"

      it "can run commands in contexts", ->
        xikij = new Xikij()

        doPromisedRequest xikij, {body: "#{__dirname}\n  $ pwd\n"}, (response) ->
          expect(response.type).toBe "stream"
          consumeStream response.data, (result) ->
            expect(result).toBe "#{__dirname}\n"

      it "can run commands via SSH", ->
        xikij = new Xikij()
        user = process.env['USER']
        body = """
          #{user}@localhost:#{__dirname}
            $ pwd\n
          """

        doPromisedRequest xikij, {body}, (response) ->
          expect(response.type).toBe "stream"
          consumeStream response.data, (result) ->
            expect(result).toBe "#{__dirname}\n"

      it "can provide help", ->
        xikij = new Xikij()
        doPromisedRequest xikij, {body: "?\n"}, (response) ->
          expect(response.type).toBe "string"
          expect(response.data).toMatch /^Help for all and everything/  #StartWi xikij.packages.getModule("xikij/contexts/help").doc

      it "can browse files in context of ", ->


    describe "passing no path, but a body", ->
    describe "passing no path, but a body and parameters", ->
    describe "passing a path and a body", ->
    describe "passing a path and a body", ->
