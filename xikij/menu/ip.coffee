@doc = """
    Returns IP Address of your computer of current default interface
    """

# get IP address used for connection to outside
@run = ->
  http = require "http"

  @respond (respond) ->
    http.get "http://google.com", (res) ->
      respond res.socket.address().address
