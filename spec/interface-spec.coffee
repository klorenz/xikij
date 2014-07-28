InterfaceClass = require "../lib/interface"

describe "Interface", ->
  it "should be used to define interfaces", ->
  it "should register interfaces"
  it "should provide interfaces"
  it "should register default implementations"
  it "should mixin default implementations into a given instance", ->
    Interface = new InterfaceClass()

    Interface.default class Foo
      foo: -> "foo"

    x = Interface.mixDefaultsInto {}
    expect(x.foo()).toBe "foo"

  it "can mixin default implementations into a given class", ->
    Interface = new InterfaceClass()

    Interface.default class Foo
      foo: -> "foo"

    class Bar
      constructor: ->

    x = Interface.mixDefaultsInto Bar
    y = new x()
    expect(y.foo()).toBe "foo"
