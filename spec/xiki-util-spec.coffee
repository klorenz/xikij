util = require "../src/util"

describe "Xiki Utilities", ->
  describe "when you need line's indentation", ->
    it "provides get_indent function", ->
      expect(util.get_indent("")).toBe ""
      expect(util.get_indent("\n")).toBe ""
      expect(util.get_indent("foo\n")).toBe ""
      expect(util.get_indent("  foo\n")).toBe "  "
      expect(util.get_indent(" \tfoo\n")).toBe " \t"
