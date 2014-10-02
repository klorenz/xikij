@doc = ->
  debugger
  result = xikij.Interface.getDoc()
  console.log "api doc", result
  return result

@run = (request) -> request.path.selectFromObject @doc()
