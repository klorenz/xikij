{XikijBridge} = require "../lib/xikij-bridge"

bridge_test = (suffix) ->
  ->
    bridge = null

    beforeEach ->
      bridge = new XikijBridge {suffix}

    afterEach ->
      waitsForPromise ->
        bridge.close()

    it "can check if path is a directory", ->
      waitsForPromise ->
        bridge.request null, "isDirectory", __dirname
          .then (isdir) => expect(isdir).toBe true

      waitsForPromise ->
        bridge.request null, "isDirectory", __filename
          .then (isdir) => expect(isdir).toBe false


fdescribe "Xikij Bridge", ->
  describe "python", bridge_test("py")
