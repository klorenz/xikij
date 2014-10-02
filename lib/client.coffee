{Response} = require "./response"

xikij_next_response_id = 1

class XikijClient

  constructor: (@opts) ->

  # implement _request in other client implementations
  _request: (args...) ->
    unless @xikij
      {Xikij} = require "./xikij"
      @xikij = new Xikij @opts

    @xikij.request args...

  _makeStream: (data, annotate) ->
    class ResultProvider extends stream.Readable
      _read: ->
        _stream = (_data) ->
          unless @done
            @done = true
            @push _data
          else
            @push null

        switch data.type
          when "application/octetstream"
            _stream data.data
          when "application/xikij-error"
            _stream data.data.stack.toString()
          when "application/xikij-list"
            @element = 0 unless @element
            if @element < x.length
              @push "+ #{data.data[@element]}\n"
              @element += 1
            else
              @push null
          when "text/plain"
            _stream data.data
          else
            _stream JSON.stringify data.data
            data.type = "application/json"

    result = new ResultProvider


  request: ({path, body, args, action}, respond) ->
    console.log "args", args
    @_request {path, body, args, action}, respond

module.exports = {XikijClient}
