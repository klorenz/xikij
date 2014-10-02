@doc = """
  SSH context enables you to run commands
  on a remote machine.
  """

{ getOutput, consumeStream, makeCommand,
  xikijBridgeScript } = require "xikij/util"

{XikijBridge} = require "xikij/xikij-bridge"

Q = require "q"

class @SSH extends xikij.Context
  PATTERN: ///
    ([\w\-]+)  # user
    @
    ([\w\-]+(?:\.[\w\-]+)*) # host
    (?::(\d*))?
    (.*)
    ///

  SETTINGS:
    remoteShell: "bash"

  @bridges: {}

  does: (request, reqPath) ->
    return false if reqPath.empty()
    reqPath = reqPath.shift() if reqPath.at(0) == ""

    return false if reqPath.empty()

    if m = reqPath.first().match(@PATTERN)
      [cmd, user, host, port, cwd] = m
      path = reqPath.shift()
      @sshData = {cmd, user, host, port, cwd}
      key = "#{user}@#{host}"

      SSH = @constructor

      # unless bridge installed, install it
      unless key of SSH.bridges
        SSH.bridges[key] = null

        # copy xikij.py
        cmd = ["ssh", "-o", "BatchMode yes"]
        if port
          cmd = cmd.concat ["-p", port]
        cmd.push key

        copyCmd = cmd.concat ["sh", "-c", "cat > .xikijbridge.py"]

        bridgeScript = xikijBridgeScript()

        deferred = Q.defer()
        SSH.bridges[key] = deferred.promise

        @context.openFile(bridgeScript)
          .then (stream) =>
            @context.execute(copyCmd...).then (proc) =>
              stream.pipe(proc.stdin)
              proc.on "exit", =>
                # now install the bridge
                deferred.resolve new XikijBridge
                  xikijBridge: ".xikijbridge.py"
                  cmdPrefix: cmd.concat ["python"]
                  onExit: =>
                    delete SSH.bridges[key]
          .fail (error) ->
            deferred.reject(error)

      @bridge = SSH.bridges[key]

      return true
    else
      return false

  bridged: (args...) ->
    console.log "bridged", args
    @bridge
      .then (bridge) =>
        bridge.request @, args...

  readDir: (dir) ->
    @bridged "readDir", dir

  exists: (filename) -> @bridged "exists", dir

  getProjectDirs: -> return []

  getSystemDirs: -> return []

  _getCwd: ->
    return @sshData['cwd'] || '.'

  getCwd: -> Q.fcall => @_getCwd()

  execute: (args...) -> @bridged "execute", args...

  executeShell: (args...) -> @bridged "executeShell", args...

  makeDirs: (dir) -> @bridged "makeDirs", dir

  walk: (dir, fileFunc, dirFunc, options) ->
    throw new Error("not implemented")
    @bridged("walk", dir).then (stream) =>
      stream.on "data", (dir) =>
    #    ...
    # @execute("find", root, "-type", "f").then (proc) =filen>
    #   consumeStream proc.stdout, (result) =>
    #     for line in splitLines(result)

      # yield line

  isDirectory: (filename) -> @bridged "isDirectory", filename

  shellExpand: (name) -> @bridged "shellExpand", name

  openFile: (filename) -> @bridged "openFile", filename

  readFile: (filename, options) -> @bridged "readFile", filename, options

  writeFile: (path, content) -> @bridged "writeFile", path, content

  expand: ->
    cwd = @sshData['cwd'] || "."
    @bridged "isDirectory", cwd
      .then (isdir) =>
        if isdir
          @bridged "readDir", cwd
        else
          @bridged "readFile", cwd

  # on collapse, we can end bridge command
  collapse: ->
    @bridged "exit"
    null

#  exists: (path,
