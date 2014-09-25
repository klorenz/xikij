@doc = """
  Manage menus.
  """

_ = require "underscore"

@run = (request) ->
  if request.path.empty()
    visited = {}
    for m in xikij.packages.modules()
      group = m.moduleName.split("/")[0]
      visited[group] = [] unless group of visited
      visited[group].push m

    debugger

    return _.sorted(_.keys(visited))

@packages = (request) ->
  return "hello world"
