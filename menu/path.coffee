module.exports = ->
  @doc = """
    Print path of current filename.
  """
  @run = (request) ->
    
    @getFilePath()
