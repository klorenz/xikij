rp = require "../lib/request-parser.coffee"

_ = require "underscore"

describe "Request Parser", ->
  beforeEach ->
    @addMatchers
      toDeepMatch: (expected) ->
        # actual is expected to have all keys/elements of expected
        _match = (val, exp) ->
          if exp instanceof Array
            for e,i in exp
              return no unless _match val[i], e
            return yes

          if typeof exp == "object"
            for k,v of exp
              return no unless _match val[k], v
            return yes

          return val == exp

        _match @actual, expected

  describe "matchTreeLine", ->
    parsed = (s) -> rp.matchTreeLine s
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

      it "can have comments in commands", ->
        expect parsed "$ foo # comment"
          .toEqual indent: '', ctx: "$", node: ['$ foo']
        expect parsed "$ foo -- no-comment"
          .toEqual indent: '', ctx: "$", node: ['$ foo -- no-comment']


    describe "when it is a xiki reference", ->
      it "has ctx @", ->
        expected = {
            indent: ""
            ctx: "@"
            node: ["path", "to", "foo"]
          }
        expect rp.matchTreeLine("@ path/to/foo")
          .toEqual expected
        expect rp.matchTreeLine("- @path/to/foo")
          .toEqual expected

    describe "when it is a command", ->
      it "has ctx $", ->
        expect parsed("$ some command/with/path/parameter/")
          .toEqual result(
            ctx: '$'
            node:   ["$ some command/with/path/parameter/"]
            )

    describe "when it is a double-backtick code str", ->
      it "has ctx ``", ->
        expect(rp.matchTreeLine("- ``some/path`` -- comment"))
          .toEqual result(ctx: "``", node: ["some", "path" ])

    describe "when it is a backtick code str", ->
      it "has ctx `", ->
        expect(rp.matchTreeLine("- `some/path` -- comment"))
          .toEqual result(ctx: "`", node: ["some", "path" ])

    describe "when it is a backtick rst-URL", ->
      it "has ctx `", ->
        expect(rp.matchTreeLine("- `some/path`_ -- comment"))
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


    it "assumes, that last line shall be run by user", ->
      parsed = rp.parseXikiRequestFromTree {body}
      expect(parsed).toDeepMatch {
          body: body
          nodePaths: [
            { nodePath: [
                { name: "hello world", position: 0 },
                { name: "hello doggies", position: 0},
              ]
            }
          ]
        }

    it "can parse a command in directory context", ->
      body = """
        #{__dirname}
          $ ls -al
      """
      parsed = rp.parseXikiRequestFromTree {body}
      _nodePath = ({name: f, position: 0} for f in __dirname.split("/"))

      expect(parsed).toDeepMatch {
          body: body
          nodePaths: [
            { nodePath: _nodePath }
            { nodePath: [{name: "$ ls -al", position: 0}] }
          ]
        }
