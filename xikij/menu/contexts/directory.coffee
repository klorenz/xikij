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
Q = require "q"
_ = require "underscore"

DEBUG = true

debug = (args...) ->
  console.debug "CTX:Directory:", args... if DEBUG

class @Directory extends xikij.Context
  PS1 = "  $ "

  rootMenuItems: ->
    # where to get project paths? Environment?
    @projectDirs().concat ["~/", "./", "/"]

  does: (xikiRequest, xikiPath) ->
    p        = null
    fsRoot   = null
    menuPath = null

    @context.shellExpand xikiPath.toPath()
      .then (xp) =>
        menuPath = xp
        debug "xp", xp
        p = xp.replace("\\", "/").split('/')

        @fileName = null
        @filePath = null

        p[...2].join("/")

      .then (fsRoot) =>
        @isAbs fsRoot

      .then (isabs) =>
        if isabs
          menuPath

        else if p[0] == '.'
          p = p[1..]
          @context.getCwd()
        else if p[0].match /^~/
          @dirExpand(p.join("/"))
        else
          @reject("directory")

      .then (cwd) =>
        debug "cwd1", cwd

        @reject("directory") unless cwd
        @cwd = cwd
        unless _.last(xikiRequest.nodePaths) is xikiPath
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
            @_yes(cwd, false)

  _yes: (filePath, isdir) ->
    @filePath = filePath
    @isdir    = isdir
    @weight   = filePath.length
    @fileName = path.basename filePath
    @dirName  = path.dirname filePath
    if isdir
      @cwd = @filePath
    else
      @cwd = @dirName
    debug "yes:", filePath
    yes

  expand: ->
    unless @isdir
      return @openFile @filePath

      # if lines
      #   unless typeof lines == "string"
      #     lines = lines.join('')
      #
      #   return lines.replace /^/m, "| "
    else
      return @readDir @cwd

  getCwd: -> Q.fcall => @cwd
