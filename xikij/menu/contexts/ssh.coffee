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

  does: (xikiRequest, xikiPath) ->
    return false if xikiPath.empty()
    xikiPath = xikiPath.shift() if xikiPath.at(0, "")

    return false if xikiPath.empty()

    if m = xikiPath.first().match(@PATTERN)
      [cmd, user, host, port, cwd] = m
      path = xikiPath.shift()
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
            console.log "opened #{bridgeScript}"
            console.log "command #{copyCmd}"
            @context.execute(copyCmd...).then (proc) =>
              console.log "piping stream to ssh's stdin"
              stream.pipe(proc.stdin)
              proc.on "exit", =>
                console.log "file should be copied"
                # now install the bridge
                deferred.resolve new XikijBridge
                  xikijBridge: ".xikijbridge.py"
                  cmdPrefix: cmd.concat ["python"]
                  onExit: =>
                    delete SSH.bridges[key]
          .fail (error) ->
            console.log "error", error
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



      # unless callback
      #   transformer
      # else
      #   streamConsume transformer, (result) =>
      #     callback(result.split /\n/)

  #readFile: ()

#  exists: (path,
