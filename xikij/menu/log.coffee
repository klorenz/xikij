@doc = """
    Control logging of xikij commands.
    """

@level = (request) ->
  request.reply ->
    if @path.empty()
      @context.getLogLevel()
    else
      @context.setLogLevel @path.toArray()...
