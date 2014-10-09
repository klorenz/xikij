module.exports = (xikij) ->
  @run = (request) -> [
      "browse"
      "path"
    ]

  @browse = (request) ->
    console.log "browse"
    if request.path.empty()
      (p.name for p in xikij.packages.getPackages())
    else
      result = {}
      for p in xikij.packages.getPackages()
        result[p.name] = p.modules

      console.log "request.path", request.path
      console.log "result", result

      request.path.selectFromTree result

  @path = (request) ->
    xikij.packagesPath
