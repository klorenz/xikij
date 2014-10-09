module.exports = (xikij) ->
  @doc = """
    Echoes either the given input or the rest of the path

    @ echo/foo/bar

    @ echo
      foo/bar
  """

  @run = (request) ->
    if request.input
      request.input
    else
      request.path.toPath()
