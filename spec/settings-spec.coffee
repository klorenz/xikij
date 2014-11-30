{Settings} = require "../lib/settings"

describe "settings", ->
  it "can store and retrieve settings", ->
    debugger
    settings = new Settings
    settings.update
      moduleName: "foo/bar"
      settings:
        first: "first"
        second: "second"
        third: "third"

    expect(settings.get "user", "first").toBe "first"

  it "merges settings on top level", ->
    settings = new Settings
    settings.update
      moduleName: "first/bar"
      settings:
        first: "first"
        second: "second"

    settings.update
      moduleName: "second/bar"
      settings:
        second: "x"
        third: "third"

    expect(settings.get "user", "first").toBe "first"
    expect(settings.get "user", "third").toBe "third"
    expect(settings.get "user", "second").toBe "x"
