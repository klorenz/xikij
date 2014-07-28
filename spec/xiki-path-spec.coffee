{Path} = require "../lib/path"
{Xikij} = require "../lib/xikij"
{consumeStream} = require "../lib/util"

describe "Xikij Path", ->
  it "represents a node path", ->
    path = new Path "foo/bar"
    expect(path.toPath()).toBe "foo/bar"

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
