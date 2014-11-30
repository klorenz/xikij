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

      @shellExpand reqPath.toPath()
        .then (rp) =>
          debug "rp", rp
          menuPath = rp

          @_fileName = null
          @_filePath = null
          p = rp.split("/")
          p[...2].join("/")

        .then (fsRoot) =>
          debug "fsRoot", fsRoot
          @isAbs fsRoot

        .then (isabs) =>
          debug "isabs", isabs
          if isabs
            menuPath
          else if p[0] in [".", ".."]
            @context.getCwd().then (cwd) =>
              console.log "getCwd gave", cwd, "p is", p.join("/")
              path.resolve cwd, p.join("/")

          else if p[0].match /^~/
            @dirExpand(p.join("/"))
          else
            @reject("directory")

        .then (cwd) =>
          debug "cwd", cwd
          @reject("directory") unless cwd

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
              @_yes(cwd, true)
            else
              @isDirectory(cwd).then (isdir) =>
                @_yes(cwd, isdir)

    _yes: (filePath, isdir) ->
      @weight = filePath.length

      @_directoryFilePath = filePath
      @_directoryIsDir    = isdir
      @_directoryFileName = path.basename filePath
      @_directoryDirName  = path.dirname filePath

      if isdir
        @_directoryCwd = filePath
      else
        @_directoryCwd = @_directoryDirName
      debug "yes:", filePath
      yes

    expanded: (request) ->
      unless @self '_directoryIsDir'
        filePath = @self '_directoryFilePath'
        if request.input
          return @writeFile(filePath, request.input).then =>
            new xikij.Action message: "saved", action: "message"

        return @openFile filePath

      else
        return @readDir @self '_directoryCwd'

    getCwd: -> Q(@self '_directoryCwd')

    getFilePath: -> Q(@self '_directoryFilePath')
