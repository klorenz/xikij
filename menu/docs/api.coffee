module.exports = (xikij) ->
  @doc = ->
    result = xikij.Interface.getDoc()
    return result

  @run = (request) -> request.path.selectFromObject @doc()
