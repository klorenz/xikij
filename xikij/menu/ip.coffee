@doc = """
    Returns IP Address of your computer of current default interface
    """

# get IP address used for connection to outside
@run = ({respond})->
  http = require "http"
  http.get "http://google.com", (res) ->
    respond(res.socket.address().address)
