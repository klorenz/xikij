{Readable} = require 'stream'
{Action}   = require "./action"

next_response_id = 1
class Response
  constructor: (opts) ->
    {@mimeType, @data, @type} = opts
    @id = next_response_id++
    unless @type
      @type = @typeOf(@data)

  typeOf: (x) ->
    type = typeof x
    if type is "object"
      if x instanceof Buffer
        type = "buffer"
      if x instanceof Readable
        type = "stream"
      if x instanceof Error
        type = "error"
      if x instanceof Action
        type = "action"
      if x instanceof Array
        type = "array"

        result = ""
        for s in x
          if typeof s is "object"
            return type
          else
            result += "+ #{s}\n"
        @data = result
        return "string"
      unless x?
        type = "nothing"

    return type

class ResponseHandler
  __doc: """A Basic response Handler class, which you can configure or extend.

  Methods you must define or implement:

  doDefault:
    This will be called as default with any data.


  Methods you can define
  """
  constructor: (opts) ->
    {doMessage, doDefault, doText} = opts

    if doDefault?
      @doDefault = doDefault

    @doMessage = doMessage ? @doDefault

  doText: (text, response, indent) ->
    indent = indent ? "#{response.indent}"
    text = util.indented(text, indent)
    text += "\n" unless text.match /\n$/
    @doDefault text

  handle_error: (response, done) ->
    done @doText response.data.stack, response, "#{response.indent}! "

  handle_string: (response, done) ->
    done @doText response.data

  handle_array: (response, done) ->
    result = ""
    for e in response.data
      result += "+ #{e}\n"

    done @doText result


  handle_object: (response, done) ->
    result = ""
    for k in keys(response.data).sort()
      result += "+ .#{k}\n"

    done @doText result


  handle_stream: (response, done) ->
    hadLF = false
    if @onStream?
      @onStream response, done

    else
      util.indented(response.data, "#{response.indent}")
        .on "data", (data) =>
          data  = cleanup(data.toString())
          @doDefault data
          hadLF = data.match /\n$/
        .on "end", (data) =>
          unless hadLF
            @doDefault "\n"
          done()
        .on "error", (data) =>
          done @doText data.stack, response, "  ! "

  handle_action: (response, done) ->
    if response.data.action is "message"
      done @doMessage response.data.message
    else
      done()

  handle_default: (response, done) ->
    return done() unless response.data
    done @doText response.data


  handleResponse: (response, done) ->
    handler = "handle_#{response.type}"
    if handler of @
      @[handler] response, done
    else
      @handle_default response, done

module.exports = {Response, ResponseHandler}
