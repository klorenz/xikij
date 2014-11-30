{parse} = require "../lib/settings-parser"

describe "Settings Parser", ->

  it "can parse a string",   -> expect(parse "some value").toBe "some value"
  it "can parse an integer", -> expect(parse "1").toBe 1
  it "can parse a float",    -> expect(parse "1.10").toBe 1.10
  it "can parse a bool",     -> expect(parse "yes").toBe true

  it "can parse a dictionary", ->
    expect parse """
      first: value1
      second: value2
    """
      .toEqual {
        first: "value1"
        second: "value2"
      }

  it "can parse an array", ->
    expect parse """
      - first
      - second
    """
      .toEqual [ "first", "second"]

  it "can parse multiline strings", ->
    expect parse """
      '''this is a
      multiline
      string'''
    """
      .toEqual "this is a\nmultiline\nstring"

  it "can override values", ->
    expect parse """
      value1:
        10

        Bla bla bla

        11
        yes
    """
      .toEqual {value1: yes}
  it "can override more values, but only with CSON parseables", ->
    expect parse """
      value1:
        Here is some text with

        - first
        - second

        And here is more text
      value2:
        Here is some text with

        - first
        - second

        "And here is more text"
    """
      .toEqual { value1: ["first", "second"], value2: "And here is more text" }


  #fit "cannot override objects"

  it "can parse things with comments", ->
    expect parse '''
      group1:
        First value is an
        integer

        value1: 1

        Second value is a bool

        value2: yes

        value3: """
          this is some {template}
          string.
          """
    '''
      .toEqual {
        group1:
          value1: 1
          value2: true
          value3: "this is some {template}\nstring."
      }


###
Here is one more idea for creating templates for new settings.

.
connections:
  .new:
      ${1:Name of Connection}:

        url     : "${1:http://fogbugz.com/}"

        Enter username/password ...
        username: "$2"
        password: "$3"

        ... or an authentication token
        token   : "$4"

  /(.*)/:
      .new


###
