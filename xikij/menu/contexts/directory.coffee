module.exports = (xikij) ->
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

  @docs =
    '/': """
      Starting a path with `/`, anchors it in filesystem's root.
      """

    './': """
      Starting a path with `./`, anchors it at current directory.  This is
      context dependend.
      """

    '~/': """
      Home directory.
      """

  path = require "path"
  Q = require "q"
  _ = require "underscore"

  DEBUG = true

  debug = (args...) ->
    console.debug "CTX:Directory:", args... if DEBUG

  class @Directory extends xikij.Context
    PS1 = "  $ "

    rootMenuItems: ->
      # where to get project paths? Environment?
      @getProjectDirs().then (result) ->
        result.concat ["~/", "./", "/"]

    does: (request, reqPath) ->
      p        = null
      fsRoot   = null
      menuPath = null

      @_input = request.input

      @shellExpand reqPath.toPath()
        .then (rp) =>
          menuPath = rp

          @_fileName = null
          @_filePath = null
          p = rp.split("/")
          p[...2].join("/")

        .then (fsRoot) =>
          @isAbs fsRoot

        .then (isabs) =>
          if isabs
            menuPath
          else if p[0] in [".", ".."]
            @getCwd().then (cwd) =>
              path.normalize path.resolve cwd, p.join("/")
          else if p[0].match /^~/
            @dirExpand(p.join("/"))
          else
            @reject("directory")

        .then (cwd) =>
          @reject("directory") unless cwd
          debugger

          unless _.last(request.nodePaths) is reqPath
            debug "is intermediate"
            # intermediate path, which must have an existing directory
            # part, which can serve as cwd
            @isDirectory(cwd).then (isdir) =>
              unless isdir
                dir = path.dirname cwd
                @isDirectory(dir).then (isdir) =>
                  @reject("#{dir} is no directory") unless isdir
                  @_yes(cwd, false)
                # TODO: check if assert @filePath exists needed
              else
                @_yes(cwd, true)
          else
            debug "is last"
            if menuPath.match /\/$/
              @_yes(menuPath[...-1], true)
            else
              @isDirectory(cwd).then (isdir) =>
                @_yes(cwd, isdir)

    _yes: (filePath, isdir) ->
      @_filePath = filePath
      @_isdir    = isdir
      @weight    = filePath.length
      @_fileName = path.basename filePath
      @_dirName  = path.dirname filePath
      if isdir
        @_cwd = @_filePath
      else
        @_cwd = @_dirName
      debug "yes:", filePath
      yes

    expand: (request) ->
      unless @_isdir
        if request.input
          @writeFile(@_filePath, request.input)
          return xikij.Action message: "saved", action: "message"

        return @openFile @_filePath

      else
        return @readDir @_cwd

    getCwd: -> Q(@_cwd)
