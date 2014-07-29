util = require "../lib/util"

describe "Xiki Utilities", ->
  describe "when you need line's indentation", ->
    it "provides getIndent function", ->
      expect(util.getIndent("")).toBe ""
      expect(util.getIndent("\n")).toBe ""
      expect(util.getIndent("foo\n")).toBe ""
      expect(util.getIndent("  foo\n")).toBe "  "
      expect(util.getIndent(" \tfoo\n")).toBe " \t"

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
