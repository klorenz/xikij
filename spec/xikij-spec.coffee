{Xikij} = require '../lib/xikij'
{consumeStream} = require "../lib/util"
{keys} = require "underscore"

path = require "path"
_ = require 'underscore'

describe "Xikij", ->

  MENU = """
    + amazon
    + bookmarklet
    + contexts
    + docs
    + echo
    + filepath
    + hostname
    + inspect
    + ip
    + log
    + menu
    + packages
    + pwd
    + terminal\n
    """

  xikij = null

  afterEach ->
    if xikij
      xikij.shutdown()
      xikij = null

  it "should load packages", ->
    loaded_event = false

    xikij = Xikij packagesPath: false
    xikij.event.on "loaded", ->
      loaded_event = true
    xikij.initialize()

    loaded = false
    waitsForPromise ->
      xikij.packages.loaded().then -> loaded = true

    runs ->
      expect(loaded).toBe true
      expect(loaded_event).toBe true

      xikij.shutdown()


  # fit "should trigger 'loaded' event for packages", ->
  #   loadedHook = jasmine.createSpy("loadedHook")
  #   initializedHook = jasmine.createSpy("initializedHook")
  #   initialized = false
  #
  #   xiki = Xikij()
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

    it "should provide modules", ->
      xikij = Xikij packagesPath: false
      xikij.initialize()

      waitsForPromise ->
        xikij.packages.loaded()

      runs ->
        hostname = xikij.packages.getModule("hostname")
        expect(hostname.moduleName).toBe("xikij/hostname")
        expect(hostname.run).toBeTruthy()


    it "should have loaded basic package", ->
      xiki = Xikij packagesPath: false

      xiki.packages.loaded().then ->

        expect( (pkg.asObject('dir', 'name') for pkg in xiki.packages.all()) ).toEqual [
          dir: path.resolve(__dirname, ".."), name: "xikij"
          ]

        expect( (pkg.asObject('dir', 'name', 'errors') for pkg in xiki.packages.failed()) ).toEqual []

        expect( (m.moduleName for m in xiki.packages.modules()).sort() )
          .toEqual [
            "xikij/amazon"
            "xikij/bookmarklet"
            "xikij/contexts/all"
            "xikij/contexts/directory"
            "xikij/contexts/execution"
            "xikij/contexts/help"
            "xikij/contexts/menu"
            "xikij/contexts/root"
            "xikij/contexts/ssh"
            "xikij/docs/api"
            "xikij/echo"
            "xikij/filepath"
            "xikij/hostname"
            "xikij/inspect"
            "xikij/ip"
            "xikij/log"
            "xikij/menu"
            "xikij/packages"
            "xikij/pwd"
            "xikij/terminal"
          ]

        expect( (n for [n,c] in xiki.contexts(named: true)) ).toEqual [
          "Directory"
          "Execution"
          "Menu"
        ]

      xiki.initialize()

    it "can load other packages", ->
      xikij = Xikij packagesPath: "#{__dirname}/fixture/packages"

      waitsForPromise ->
        xikij.initialized.then ->
          console.log "finally loaded"
          packages = xikij.packages.getPackages()
          expect( (p.name for p in packages) ).toEqual [
            "xikij",
            "xikij-executable",
            "xikij-python"
          ]

          expect(keys packages[1].modules).toEqual [
             'xikij-executable/hostname', 'xikij-executable/foo',
             'xikij-executable/hello', 'xikij-executable/hello_world'
          ]

      xikij.initialize()

  describe "xikij context", ->
    it "can list context prompts", ->
      xikij = Xikij()
      waitsForPromise ->
        Xikij().getPrompts().then (prompts) ->
          expect(prompts).toEqual ['$ ']

  describe "when you request a xiki response", ->
    describe "when passing 'path'", ->

      doPromisedRequest = (request, callback) ->
        xikij = Xikij packagesPath: false
        waitsForPromise ->
          promise = xikij.request(request)
          promise
            .then callback
            .fail (error) -> throw error

      it "should handle the path with callback", ->
        xikij = Xikij packagesPath: false
        requestResponded = false
        os = require "os"

        runs ->
          xikij.request {path: "hostname"}, (response) ->
            expect(response.data).toEqual os.hostname()
            requestResponded = true

        waitsFor (-> requestResponded), "xiki command has responded", 1000

      it "should handle an empty path", ->
        xikij = Xikij packagesPath: false
        requestResponded = false
        os = require "os"

        runs ->
          xikij.request {path: ""}, (response) ->
            expect(response.data).toEqual """
              + ~/
              + ./
              + /
              + ?
              #{MENU}
            """

            requestResponded = true

        waitsFor (-> requestResponded), "xiki command has responded", 1000

      it "should handle the path with promise", ->
        os = require "os"

        doPromisedRequest {path: "hostname"}, (response) ->
          expect(response.data).toEqual os.hostname()

      it "can run commands", ->
        requestResponded = false

        doPromisedRequest {path: '$ echo "hello world"'}, (response) ->
          expect(response.type).toBe "stream"
          consumeStream response.data, (result) ->
            expect(result).toBe "hello world\n"

      it "can run commands in contexts", ->

        doPromisedRequest {body: "#{__dirname}\n  $ pwd\n"}, (response) ->
          expect(response.type).toBe "stream"
          consumeStream response.data, (result) ->
            expect(result).toBe "#{__dirname}\n"

      fit "can run commands via SSH", ->
        debugger
        user = process.env['USER']
        body = """
          #{user}@localhost:#{__dirname}
            $ pwd\n
          """

        doPromisedRequest {body}, (response) ->
          expect(response.type).toBe "stream"
          consumeStream response.data, (result) ->
            expect(result).toBe "#{__dirname}\n"

      it "can provide help", ->
        doPromisedRequest {body: "?\n"}, (response) ->
          expect(response.type).toBe "string"
          expect(response.data).toMatch /^Help for all and everything/  #StartWi xikij.packages.getModule("xikij/contexts/help").doc

      it "can manage menu", ->
        doPromisedRequest {body: "menu"}, (response) ->
          expect(response.type).toBe "string"
          expect(response.data).toBe """
              + amazon.coffee
              + bookmarklet.coffee
              + contexts
              + docs
              + echo.coffee
              + filepath.coffee
              + hostname.coffee
              + inspect.coffee
              + ip.coffee
              + log.coffee
              + menu.coffee
              + packages.coffee
              + pwd.coffee
              + terminal.coffee\n
          """

      it "can handle menus in directory ./", ->
        doPromisedRequest {
          path: "./@pwd",
          args: {filePath: __filename}
        }, (response) ->
          expect(response.data).toBe __dirname

      it "can handle menus in directory ./ from tree", ->
        doPromisedRequest {
          body: "./\n  @pwd",
          args: {filePath: __filename}
        }, (response) ->
          expect(response.data).toBe __dirname

      it "can return the selected path", ->
        doPromisedRequest {
          body: "./#{path.basename(__filename)}\n  @filepath",
          args: {filePath: __filename}
        }, (response) ->

          expect(response.data).toBe __filename

      it "can handle menus in directory ../", ->
        doPromisedRequest {
          path: "../@pwd",
          args: {filePath: __filename}
        }, (response) ->
          expect(response.data).toBe path.resolve __dirname, ".."

      it "can handle menus in directory ~/", ->
        {getUserHome} = require "../lib/util"
        doPromisedRequest {
          path: "~/@pwd",
          args: {filePath: __filename, userDir: "/tmp" }
        }, (response) ->
          expect(response.data).toBe "/tmp"
      #it "can browse files in context of ", ->

    describe "passing no path, but a body", ->
    describe "passing no path, but a body and parameters", ->
    describe "passing a path and a body", ->
    describe "passing a path and a body", ->
