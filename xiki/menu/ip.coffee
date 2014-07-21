docs = """
    Returns IP Address of your computer of current default interface
    """

# get IP address used for connection to outside
menu = ({respond})->
  http = require "http"
  http.get "http://google.com", (res) ->
    respond(res.socket.address().address)
