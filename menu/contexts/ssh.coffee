module.exports = (xikij) ->
  @doc = """
    SSH context enables you to run commands
    on a remote machine.
    """

  { getOutput, consumeStream, makeCommand,
    xikijBridgeScript } = xikij.util


  Q = require "q"

  class @SSH extends xikij.Context
    PATTERN: ///
      ([\w\-]+)  # user
      @
      ([\w\-]+(?:\.[\w\-]+)*) # host
      (?::(\d*))?
      (.*) ///

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

          console.log "ssh cmd", cmd

          copyCmd = cmd.concat ["sh", "-c", "cat > .xikijbridge.py"]

          bridgeScript = xikijBridgeScript()

          deferred = Q.defer()
          SSH.bridges[key] = deferred.promise

          @context.openFile(bridgeScript)
            .then (stream) =>
              @context.execute(copyCmd...).then (proc) =>
                stream.pipe(proc.stdin)
                proc.on "exit", =>
                  console.log "copyCmd cmd", cmd

                  cmdPrefix = cmd.concat ["python"]

                  console.log "cmdPrefix", cmdPrefix
                  data = {
                    xikijBridge: ".xikijbridge.py",
                    cmdPrefix:   cmdPrefix,
                    onExit:      => delete SSH.bridges[key]
                    }
                  console.log "data", data

                  bridge = new xikij.Bridge data
                  console.log "deferred", deferred
                  # now install the bridge
                  deferred.resolve bridge

                  console.log "promise resolved"
            .fail (error) ->
              deferred.reject(error)

        @bridge = SSH.bridges[key]

        return true
      else
        return false

    # this method will always be called with instance of this object instance
    sshBridged: (args...) ->
      console.log "bridged", args
      @bridge
        .then (bridge) =>
          bridge.request @, args...

    readDir: (dir) -> @self 'sshBridged', "readDir", dir

    exists: (filename) -> @self 'sshBridged', "exists", dir

    getProjectDirs: -> return []

    getSystemDirs: -> return []

    getCwd: -> Q(@self('sshData')['cwd'] || '.')

    execute: (args...) -> @self('sshBridged') "execute", args...

    executeShell: (args...) -> @self('sshBridged') "executeShell", args...

    makeDirs: (dir) -> @self('sshBridged') "makeDirs", dir

    walk: (dir, fileFunc, dirFunc, options) ->
      throw new Error("not implemented")
      @self('sshBridged')("walk", dir).then (stream) =>
        stream.on "data", (dir) =>
      #    ...
      # @execute("find", root, "-type", "f").then (proc) =filen>
      #   consumeStream proc.stdout, (result) =>
      #     for line in splitLines(result)

        # yield line

    isDirectory: (filename) -> @self('sshBridged') "isDirectory", filename

    shellExpand: (name) ->
      
      @self('sshBridged') "shellExpand", name

    openFile: (filename) -> @self('sshBridged') "openFile", filename

    readFile: (filename, options) -> @self('sshBridged') "readFile", filename, options

    writeFile: (path, content) -> @self('sshBridged') "writeFile", path, content

    expanded: ->
      cwd = @sshData['cwd'] || "."
      @self('sshBridged') "isDirectory", cwd
        .then (isdir) =>
          if isdir
            @self('sshBridged') "readDir", cwd
          else
            @self('sshBridged') "readFile", cwd

    # on collapse, we can end bridge command
    collapse: ->
      @self('sshBridged') "exit"
      null

  #  exists: (path,
