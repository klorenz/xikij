{Xikij} = require "../lib/xikij"

describe "content-finder", ->
  body = """
    - fruits
      - peach
      - plum
      - apple
        - golden delicious
        - elstar

    - more complex things
      - starting/with/path
        - first
        - second

    """

  it "can find content in a xikij file", ->
    xikij = Xikij()
    content = null

    waitsForPromise ->
      xikij.contentFinder.find(body, "fruits").then (result) ->
        content = result

    runs ->
      expect(content).toBe """
      + peach
      + plum
      + apple\n
      """

  it "can find content in more complex things", ->
    xikij = Xikij()
    content = null

    waitsForPromise ->
      xikij.contentFinder.find(body, "more complex things/starting/with/path").then (result) ->
          content = result

    runs ->
      expect(content).toBe """
        + first
        + second\n
        """

  it "can find content in more complex things 2", ->
    xikij = Xikij()
    content = null

    waitsForPromise ->
      xikij.contentFinder.find(body, "more complex things").then (result) ->
          content = result

    runs ->
      expect(content).toBe """
        + starting/with/path\n
        """
