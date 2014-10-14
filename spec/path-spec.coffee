{Path} = require "../lib/path"
{Xikij} = require "../lib/xikij"
{consumeStream} = require "../lib/util"

describe "Xikij Path", ->
  it "represents a node path", ->
    path = new Path "foo/bar"
    expect(path.toPath()).toBe "foo/bar"
  it "represents also a complex path", ->
    path = new Path ".package/[Module: xikij/foo/bar]/.moduleName"
    expect((x.name for x in path.nodePath)).toEqual [
      '.package',  '[Module: xikij/foo/bar]', '.moduleName'
    ]

  describe "when select a part of xikij document", ->
    xikij = null
    xikijDoc = null

    beforeEach ->
      xikij = new Xikij()
      xikijDoc = """
      - foo
        - bar
          - hello
          - world
        - glork
          - hicks
      - bar
      """

    it "can select foo/bar", ->
      path = new Path "foo/bar"
      stream = path.selectFromText xikij, xikijDoc
      consumeStream stream, (result) ->
        expect(result).toBe """
        + hello
        + world
      """

    it "can select foo", ->
      path = new Path "foo"
      stream = path.selectFromText xikij, xikijDoc
      consumeStream stream, (result) ->
        expect(result).toBe """
        + bar
        + glork
        """

  describe "when select a part of an object", ->
    object = null

    beforeEach ->
      object = {
        "cat": [ "legs", "ears", "eyes" ]
        "dog": [ {"eats": "dog food"}, {"smells": "well"} ]
      }

    it "can select cat", ->
      path = new Path "cat"
      expect(path.selectFromObject(object)).toEqual object['cat']

    it "can select dog food", ->
      path = new Path "dog/[object Object]/eats"
      expect(path.selectFromObject(object)).toEqual "dog food"

    it "can select smells", ->
      path = new Path "dog/[object Object][1]/smells"
      expect(path.selectFromObject(object)).toEqual "well"


  describe "when you need to split a path", ->

    it "can split path foo/bar", ->
      xpath = Path.split("foo/bar")
      expect(xpath).toEqual [ "foo", "bar" ]

    it "can split path foo/[X/Y]/foo", ->
      xpath = Path.split("foo/[X/Y]/bar")
      expect(xpath).toEqual [ "foo", "[X/Y]", "bar" ]
