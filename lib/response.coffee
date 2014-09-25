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

module.exports = {Response}
