pythonLoader          = require "../lib/extensions/python"
coffeeLoader          = require "../lib/extensions/coffeescript"
executableLoader      = require "../lib/extensions/executable"
{RequestContextClass} = require "../lib/request-context"
{Xikij}               = require "../lib/xikij"
{getOutput}           = require "../lib/util"

describe "extensions", ->
  describe "coffeescript", ->
    it "can load coffeescript extensions", ->
      expect(true).toBe(true)

  describe "executable", ->
    it "can load simple executables as extension", ->
      #expect(true).toBe(true)
      subject =
        sourceFile: "#{__dirname}/fixture/packages/xikij-executable/menu/hello_world.sh"

      xikij   = new Xikij packagesPath: false, initialization: false
      context = {xikij}

      promise = executableLoader.call(context, subject)

      result = null

      waitsForPromise ->
        promise

      waitsForPromise ->
        promise.then (subject) ->
          RequestContext = RequestContextClass(xikij.Context, {
              filePath:    __filename
              username:    "vlad"
              projectDirs: []
              userDir:     "/tmp"
            })

          context = new RequestContext(xikij)

          subject.run.call(context, {}).then (process) ->
            getOutput(process).then (output) ->
              result = output

      runs ->
        expect(result).toBe """
          - hello world
          - fruits
            - plum
            - peach
            - apply\n
        """
