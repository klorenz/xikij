
module.exports = (xikij) ->

  @title   = "Menu Manager"
  @summary = "Create and Edit Menus"

  @doc = """
    Manage menus.
    """

  @settingsDefaults = {
  }

  {sorted, keys} = require "underscore"
  {insertToTree} = xikij.util
  {Path}         = xikij.Path
  path           = require "path"

  @run = (request) ->
    debugger

    try
      module = request.path.selectFromObject xikij.packages.getModuleWithSuffix()
    catch error
      module = null

    if request.input
      menu = request.path.toPath()

      return @userPackageUpdateMenu({menu, content: request.input, module}).then =>
        new xikij.Action message: "menu #{menu} updated", action: "message", code: 0

    else if module?.sourceFile
      return @openFile(module.sourceFile)

    return module
