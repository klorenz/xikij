parse = require "../../lib/parser/markdown.coffee"
{toJSON} = require "../../lib/util"

describe "markdown parser", ->
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

        console.debug @actual, expected

        _match @actual, expected


  it "can parse a markdown - more complex text", ->
    output = parse("""
      Document Title
      ==============

      First Section
      -------------

      Here is some very important text.

      - first item

      - second item
        some more text

        - first
        - second

      - third item

      Here is some lorem ipsum epilog.

      Second Section
      --------------

      Here only some text.
    """)

    expect(toJSON output).toEqual {}

  it "can parse markdown - sections same level", ->
    output = parse """
        First
        =====

        Second
        ======
    """
    expect(JSON.parse toJSON output).toDeepMatch {
      text:     ""
      children: [
        {
          text: "First"
          children: [
            {
              text: "=====\n\n"
              children: []
            }
          ]
        },
        {
          text: "Second"
          children: [
            {
              text: "======\n"
              children: []
            }
          ]
        }
      ]
    }

  it "can parse markdown - sections same level with text", ->
    output = parse """
        First
        =====

        some text

        Second
        ======

        some text\n
    """
    expect(JSON.parse toJSON output).toDeepMatch {
      text:     ""
      children: [
        {
          text: "First"
          children: [
            {
              text: "=====\n\nsome text\n\n"
              children: []
            }
          ]
        },
        {
          text: "Second"
          children: [
            {
              text: "======\n\nsome text\n"
              children: []
            }
          ]
        }
      ]
    }

  it "can parse markdown - a list only", ->
    output = parse """
        - first
        - second
        - third
    """
    expect(JSON.parse toJSON output).toDeepMatch {
      text:     ""
      children: [
        {
          text: "first"
          children: []
        },
        {
          text: "second"
          children: []
        },
        {
          text: "third"
          children: []
        }
      ]
    }

  it "can parse markdown - a list with subitems", ->
    output = parse """
        - first

          One more paragraph.

        - second

          - with another
          - list here

        - third
    """
    expect(JSON.parse toJSON output).toDeepMatch {
      text:     ""
      children: [
        {
          text: "first"
          children: [
            {
              text: "\nOne more paragraph.\n\n"
              children: []
            }
          ]
        },
        {
          text: "second"
          children: [
            {
              text: "\n"
              children: []
            },
            {
              text: "with another"
              children: []
            },
            {
              text: "list here"
              children: [
                {
                  text: "\n"
                  children: []
                },
              ]
            }
          ]
        },
        {
          text: "third"
          children: []
        }
      ]
    }
