{Readable} = require 'stream'

next_response_id = 1
class Response
  constructor: (opts) ->
    {@mimeType, @data} = opts
    @id = next_response_id++
    @type = @typeOf(@data)

  typeOf: (x) ->
    type = typeof x
    if type is "object"
      if x instanceof Buffer
        type = "buffer"
      if x instanceof Readable
        type = "stream"
      if x instanceof Array
        type = "array"

        result = ""
        for s in data
          if typeof s is "object"
            result = response.data
            break
          else
            result += "+ #{s}\n"

            return type

    return type

  # toString: ->
  #   if @type

module.exports = {Response}
