{Response, ResponseHandler} = require "../lib/response.coffee"

fdescribe "response", ->
  result = ""
  responseHandler = new ResponseHandler
    doDefault: (s) -> result += s

  is_done = false

  done = ->
    is_done = true

  beforeEach ->
    result = ""
    is_done = false

  it "can create a string response object", ->
    response = new Response data: "hello"
    expect(response.data).toBe "hello"
    expect(response.type).toBe "string"

  it "can create an error response object", ->
    try
      throw "An Exception"
    catch e
      response = new Response data: e

    expect(response.data).toBe "hello"
    expect(response.type).toBe "string"

  it "can handle string response", ->
    response = new Response data: "hello"
    responseHandler.handleResponse response, done
    waitsFor (-> is_done), "response handled", 1000
    runs ->
      expect(result).toBe 'hello'
