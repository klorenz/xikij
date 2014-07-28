rp = require "../lib/request-parser.coffee"

describe "Request Parser", ->
  describe "match_tree_line", ->
    parsed = (s) -> rp.match_tree_line s
    result = (opts) ->
      r = indent: '', ctx: null
      for k,v of opts
        r[k] = v
      return r

    describe "when there is a comment", ->
      it "is stripped from node", ->
        expected = indent: '', ctx: null, node: ['foo']

        expect parsed("foo -- some comment")
          .toEqual expected
        expect parsed("foo — some comment")
          .toEqual expected
        expect parsed("foo – some comment")
          .toEqual expected
        expect parsed("foo  # some comment")
          .toEqual expected

    describe "when it is a xiki reference", ->
      it "has ctx @", ->
        expect rp.match_tree_line("@ path/to/foo")
          .toBe ""
        expect rp.match_tree_line("- @path/to/foo")
          .toBe ""

    describe "when it is a command", ->
      it "has ctx $", ->
        expect parsed("$ some command/with/path/parameter/")
          .toEqual result(
            ctx: '$'
            node:   ["$ some command/with/path/parameter/"]
            )

    describe "when it is a double-backtick code str", ->
      it "has ctx ``", ->
        expect(rp.match_tree_line("- ``some/path`` -- comment"))
          .toEqual result(ctx: "``", node: ["some", "path" ])

    describe "when it is a backtick code str", ->
      it "has ctx `", ->
        expect(rp.match_tree_line("- `some/path` -- comment"))
          .toEqual result(ctx: "`", node: ["some", "path" ])

    describe "when it is a backtick rst-URL", ->
      it "has ctx `", ->
        expect(rp.match_tree_line("- `some/path`_ -- comment"))
          .toEqual result(ctx: "`", node: ["some", "path" ])

    describe "when it contains a path", ->
      it "is splitted apart", ->
        expect parsed("- ``foo/bar/glork``")
          .toEqual result(ctx: "``", node: ["foo", "bar", 'glork'])
        expect parsed("- foo/bar/glork")
          .toEqual result(node: ["foo", "bar", 'glork'])

  describe "parseXikiRequestFromTree", ->
    parsed = null
    body =  """
      hello world
        - hello kittens
        - hello doggies
      """

    beforeEach ->
      parsed = rp.parseXikiRequestFromTree body

    it "assumes, that last line shall be run by user", ->
      expect parsed.toString()
        .toEqual {
          "body": body
          nodePaths: [
            { nodePath: [
                { name: "hello world", position: 0 },
                { name: "hello doggies", position: 0},
              ]
            }
          ]
          input: null
          action: null
        }.toString()
