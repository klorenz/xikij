pythonLoader          = require "../lib/extensions/python"
coffeeLoader          = require "../lib/extensions/coffeescript"
executableLoader      = require "../lib/extensions/executable"
{RequestContextClass} = require "../lib/request-context"
{Xikij}               = require "../lib/xikij"
{getOutput}           = require "../lib/util"
os = require "os"
path = require "path"

describe "extensions", ->
  context = null
  xikij   = null

  beforeEach ->
    xikij = new Xikij packagesPath: false, initialization: false

    RequestContext = RequestContextClass(xikij.Context, {
      filePath:    __filename
      username:    "vlad"
      projectDirs: []
      userDir:     "/tmp"
    })

    context = new RequestContext(xikij)

  describe "coffeescript", ->
    it "can load coffeescript extensions", ->
      subject =
        sourceFile: "#{__dirname}/fixture/packages/xikij-executable/menu/hostname.coffee"
        menuType:   "coffee"

      promise = coffeeLoader.load.call({xikij}, subject)
      result = null

      waitsForPromise ->
        promise.then (subject) ->
          result = subject.run()

      runs ->
        expect(result).toEqual os.hostname()


  describe "executable", ->
    it "can load simple executables as extension", ->
      #expect(true).toBe(true)
      subject =
        sourceFile: "#{__dirname}/fixture/packages/xikij-executable/menu/hello_world.sh"

      promise = executableLoader.load.call({xikij}, subject)

      result = null

      waitsForPromise ->
        promise

      waitsForPromise ->
        promise.then (subject) ->
          subject.run.call(context, {}).then (output) ->
            result = output

      runs ->
        expect(result).toBe """
          - hello world
          - fruits
            - plum
            - peach
            - apply\n
        """

    it "does not load normal files as executables", ->
      #expect(true).toBe(true)
      subject =
        sourceFile: "#{__dirname}/fixture/packages/xikij-executable/menu/hostname.coffee"

      waitsForPromise ->
        executableLoader.load.call({xikij}, subject).then (result) ->
          expect(result).toBe false


  describe "ModuleLoader", ->
    it "can load a module", ->
      xikij = new Xikij packagesPath: false, initialization: false
      pkg =
        dir: "#{__dirname}/fixture/packages/xikij-executable"
        name: "xikij-executable"
        modules: {}

      updated = false

      xikij.event.on "package:module-updated", (moduleName, subject) ->

        filename = path.join(pkg.dir, 'menu', 'hostname.coffee')

        m = pkg.modules["xikij-executable/hostname"]

        console.log("m", m)
        expect(m.menuType).toBe "coffee"
        expect(m.sourceFile).toEqual filename
        expect(m.fileName).toEqual filename
        expect(m.moduleName).toBe "xikij-executable/hostname"
        expect(m.menuName).toBe "hostname"

        updated = true

      waitsForPromise ->
        menuDir = path.join(pkg.dir, 'menu')
        xikij.moduleLoader.loadMenu(pkg, menuDir, 'hostname.coffee')

      runs ->
        expect(updated).toBe true
