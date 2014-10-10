
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
    console.log "menu menu request", request
    try
      result = request.path.selectFromObject xikij.packages.getModule()
    catch error
      result = null

    if request.input
      return @getUserDir().then (userdir) =>
        menuname = request.path.toPath()

        if result?.sourceFile
          menupath = "#{userdir}/.xikij/#{result.menuName}.#{result.menuType}"
        else if not result?
          menupath = "#{userdir}/.xikij/#{menuname}"

          if not path.extname(menupath)
            menupath += ".xikij"
        else
          throw new Error("#{menuname} is a directory")

        return @makeDirs(path.dirname menupath).then =>
          # check input
          @request(
            path:    menupath
            context: request.context
            input:   request.input
            )

    else if result?.sourceFile
      return @openFile(result.sourceFile)

    return result
