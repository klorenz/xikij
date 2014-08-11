@doc = """
  This context lets you browse directory
  trees.  Commands executed in this context
  are run in current directory as working
  directory.

  - / -- for root
  - ~/ -- for home directory
  - ./ -- for directory of current view
  - ~PROJECT_NAME/ -- for current project
  """

path = require "path"

Q = xikij.Q

class @Directory extends xikij.Context
  PS1 = "  $ "

  rootMenuItems: ->
    # where to get project paths? Environment?
    @projectDirs().concat ["~/", "./", "/"]

  does: (xikiRequest, xikiPath) ->
    p      = null
    fsRoot = null

    @context.shellExpand(xikiPath.toPath())
      .then (xp) =>
        p = xp.replace("\\", "/").split('/')

        @fileName = null
        @filePath = null

        p[...2].join("/")

      .then (fsRoot) =>
        @isAbs fsRoot

      .then (isabs) =>
        if isabs
          p = p[2..]
          fsRoot
        else if p[0] == '.'
          p = p[1..]
          @context.getCwd()
        else if p[0].match /^~/
          @dirExpand(p.join("/"))
        else
          @reject()

      .then (cwd) =>
        @reject() unless cwd
        @reject() unless @exists cwd
        @cwd = cwd

      .then (cwd) =>
        unless @isDirectory cwd
          @filePath = @cwd
          @cwd      = path.dirname @cwd
          @fileName = path.basename @filePath

        @weight = @cwd.length

  expand: ->
    if @filePath
      return @openFile @filePath

      # if lines
      #   unless typeof lines == "string"
      #     lines = lines.join('')
      #
      #   return lines.replace /^/m, "| "
    else
      return @readDir @cwd

  getCwd: Q.fcall => @cwd
