
This context lets you browse directory
trees.  Commands exectued in this context
are run in current directory as working
directory.

- ``/`` -- for root
- ``~/`` -- for home directory
- ``./`` -- for directory of current view
- ``~PROJECT_NAME/`` -- for current project

```coffee
  xiki.use class Directory extends xiki.Context
    PS1 = "  $ "

    rootMenuItems: ->
      # where to get project paths? Environment?
      @projectDirs().concat ["~/", "./", "/"]

    does: (xikiPath) ->
      p = xikiPath.toPath()
      p = @shellExpand(p).replace "\\", "/"
      p = p.split('/')

      @fileName = null
      @filePath = null

      fsRoot = p[2..].join("/")

      if @isAbs fsRoot
        @cwd = fsRoot
        p = p[2..]
      else if p[0] == '.'
        @cwd = @getCwd()
        p = p[1..]
      else if p[0] == '~'
        @cwd = @shellExpand("~")
        p = p[1..]
      else if p[0][0] == '~'
        f = p[0][1..].replace(/\/+$/, '').replace(/^\//, '')

        unless f in @getSystemDirs()
          unless f in @getProjectDirs()
            return false

        @cwd = @expandDir(f)

        p = p[1..]
      else
        return false

      @cwd = path.join.apply undefined, [ @cwd ].concat p

      unless @isDir @cwd
        @filePath = @cwd
        @cwd = path.dirname(@cwd)
        @fileName = path.basename(@filePath)

      return true

    open: ->
      if @filePath
        lines = @openFile @filePath

        if lines
          unless typeof lines == "string"
            lines = lines.join('')

          return lines.replace /^/m, "| "
      else
        return ("+ #{entry}\n" for entry in @listDir(@cwd)).join('')

    execute: (opts) ->
      {cwd} = opts
      unless cwd:
        opts = @cwd
      @context.execute opts

```
