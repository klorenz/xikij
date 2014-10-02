@doc = """
    Control logging of xikij commands.
    """

@level = (request) ->
  if request.path.empty()
    @getLogLevel()
  else
    @setLogLevel request.path.toArray()...
