@title   = "Menu Manager"
@summary = "Create and Edit Menus"

@doc = """
  Manage menus.
  """

@settingsDefaults = {
}

{sorted, keys} = require "underscore"
{insertToTree} = require "xikij/util"
{Path}         = require "xikij/path"
path           = require "path"

@run = (request) ->

  tree = {}
  for m in xikij.packages.modules()
    insertToTree.call tree, Path.split(m.menuName), m

  result = request.path.selectFromObject tree, objects: true

  if result.sourceFile
    if request.input
      debugger
      return @getUserDir().then (userdir) =>
        menupath = "#{userdir}/.xikij/#{result.menuName}.#{result.menuType}"

        return @makeDirs(path.dirname menupath).then =>
          @request(
            path:    menupath
            context: request.context
            input:   request.input
            )

    return @openFile(result.sourceFile)

  return result


@packages = (request) ->
  return "hello world"
