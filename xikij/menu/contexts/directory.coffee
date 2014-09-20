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

    @input = request.input

    @context.shellExpand reqPath.toPath()
      .then (rp) =>
        menuPath = rp
        debug "rp", rp
        p = rp.replace("\\", "/").split('/')

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
      if @input
        # TODO: store content
        @writeFile @filePath, @input
        return {message: "saved", action: "message"}

      return @openFile @filePath

      # if lines
      #   unless typeof lines == "string"
      #     lines = lines.join('')
      #
      #   return lines.replace /^/m, "| "
    else
      return @readDir @cwd

  getCwd: -> Q.fcall => @cwd
