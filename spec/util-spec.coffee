util = require "../lib/util"

fixture = "#{__dirname}/fixture"
executable_file = "#{fixture}/packages/xikij-executable/menu/hello.sh"
not_executable_file = "#{fixture}/packages/xikij-executable/menu/hostname.coffee"

describe "Xiki Utilities", ->
  it "can extract indentation of text", ->
      expect(util.getIndent("")).toBe ""
      expect(util.getIndent("\n")).toBe ""
      expect(util.getIndent("foo\n")).toBe ""
      expect(util.getIndent("  foo\n")).toBe "  "
      expect(util.getIndent(" \tfoo\n")).toBe " \t"

  it "can indent text", ->
    expect(util.indented("foo\nbar\n", "  ")).toBe "  foo\n  bar\n"

  fit "can indent text with special first line", ->
    expect(util.indented("foo\nbar\n", "  ", "- ")).toBe "- foo\n  bar\n"

  it "can remove indentation from text", ->
    expect(util.removeIndent("  first\n    second\n  third\n", "  ")).toBe "first\n  second\nthird\n"

    # just to make clear that this function only removes indentation and does
    expect(util.removeIndent("  first\n    second\nthird\n", "  ")).toBe "first\n  second\nthird\n"

  it "can tell, if a file is executable", ->

    util.isFileExecutable executable_file, (error, result) ->
      expect(result).toBe(true)
      done()

  it "can tell, if a file is not executable", ->
    util.isFileExecutable not_executable_file, (error, result) ->
      expect(result).toBe(false)
      done()

  describe "when you make result ready for output", ->
    it "handles numbers", ->
      util.makeResponse 10, (result) -> expect(result).toBe "10"

    it "handles objects", ->
      util.makeResponse {x: "y"}, (result) -> expect(result).toBe '{"x":"y"}'

    it "handles buffers", ->
      util.makeResponse new Buffer("line 1\nline 2\n"), (result) ->
        expect(result).toBe "line 1\nline 2\n"

  describe "cookCoffee", ->
    it "can handle a simple script", ->
      util.cookCoffee """
      ```coffee
      f = -> return 1
      ```
      """, (code, menu) ->
        expect(code).toBe """
        # ```coffee
        f = -> return 1
        # ```
        """ + "\n"
        expect(menu).toBe "\n"

    it "can handle a simple menu", ->
      util.cookCoffee """
      - first
      - second
      """, (code, menu) ->
        expect(code).toBe """
        # - first
        # - second
        """+"\n"

        expect(menu).toBe """
        - first
        - second
        """+"\n"

    describe "parseCommand", ->
      it "parses space separated command", ->
        expect util.parseCommand "hello world and else"
          .toEqual [ "hello", "world", "and", "else"]
      it "parses strings as arguments", ->
        expect util.parseCommand 'echo "hello world"'
          .toEqual [ "echo", "hello world"]

    describe "can handle a complex menu", ->
      util.cookCoffee """
        This is an example of embedded coffee script.

        ```coffee
        f = (b) ->
          a = 1 + b
        ```

        Followed by a usage example

        ```coffee
           # example
           f(x) == x + 1
        ```

        Then more text and more code:

        ```coffee
        g = (x) -> f(x)
        ```
        """, (code, menu) ->

          checkLines = (name, a, b) ->
            aLines = a.split("\n")
            bLines = b.split("\n")
            console.log "aLines", aLines
            console.log "bLines", bLines
            for aLine, i in aLines
              ((aLine, bLine) ->
                it "has equal #{name} line #{i+1}", ->
                  expect(aLine).toEqual bLine
              )(aLine, bLines[i])

          checkLines "code", code, """
            # This is an example of embedded coffee script.
            #
            # ```coffee
            f = (b) ->
              a = 1 + b
            # ```
            #
            # Followed by a usage example
            #
            # ```coffee
            #    # example
            #    f(x) == x + 1
            # ```
            #
            # Then more text and more code:
            #
            # ```coffee
            g = (x) -> f(x)
            # ```
            """+"\n"

          checkLines "menu", menu, """
            This is an example of embedded coffee script.

            Followed by a usage example

            ```coffee
               # example
               f(x) == x + 1
            ```

            Then more text and more code:

            """+"\n"
