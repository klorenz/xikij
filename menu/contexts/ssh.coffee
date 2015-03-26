{join} = require "path"

module.exports = (xikij) ->
  @doc = """
    SSH context enables you to run commands
    on a remote machine.
    """

  console = xikij.getLogger(@moduleName)

  { getOutput, consumeStream, makeCommand, strip, splitLines
  } = xikij.util

  Q = require "q"

  class @SSH extends xikij.Context
    PATTERN: ///^
      ([\w\-]+)  # user
      @
      ([\w\-]+(?:\.[\w\-]+)*) # host
      (?::(\d*))?
      (.*) ///

    SETTINGS:
      remoteShell: "bash"

    does: (request, reqPath) ->
      return false if reqPath.empty()
      reqPath = reqPath.shift() if reqPath.at(0) == ""

      return false if reqPath.empty()


      ssh_dir         = "~/.ssh/xikij"
      sockets_dir     = "#{ssh_dir}/sockets"
      ssh_config_file = "#{ssh_dir}/ssh_config"

      if m = reqPath.first().match(@PATTERN)
        debugger
        [cmd, user, host, port, cwd] = m
        path = reqPath.shift()
        @sshData = {cmd, user, host, port, cwd}

        key = "#{user}@#{host}"
        @console = xikij.getLogger(@moduleName, "(#{key})")

        cmd = ["ssh", "-F", ssh_config_file ]

        if port
          cmd = cmd.concat ["-p", port]
        cmd.push key

        @cmd = cmd

        @makeDirs(sockets_dir)
        .then =>
          @exists(ssh_config_file).then (exists) =>
            unless exists
              @writeFile(ssh_config_file, """
                Host *
                ControlMaster auto
                ControlPath #{ssh_dir}/sockets/%r@%h:%p
                ControlPersist 300
                BatchMode yes
              """)
        .then =>
          true

      else
        return false

    #ssh: (args...) ->
      #@dispatch "execute" @cmd.concat(args)
      #@execute @cmd.concat(args)

    readDir: (dir) -> # @self 'sshBridged', "readDir", dir
      @execute("ls", "-p").then (proc) ->
        getOutput(proc).then (output) ->
          splitLines strip output

    exists: (filename) ->
      @execute("bash").then (proc) ->

        result = getOutput(proc).then (output) ->
          strip(output) == "y"

        proc.stdin.write('''
          [ -e '#{filename}' ] && echo "y" || echo "n"
        ''')
        proc.stdin.close()

        return result

    getProjectDirs: -> Q.fcall -> []

    getSystemDirs: -> Q.fcall -> []

    getCwd: -> Q(@self('sshData')['cwd'] || '.')

    execute: (args...) ->
      @dispatch "execute", @cmd.concat args

    makeDirs: (dir) ->
      @self('exists')(dir).then (exists) =>
        @execute("mkdir", "-p", {stdio: 'ignore'}).then (proc) =>
          deferred = Q.defer()
          proc.on "exit", -> deferred.resolve(!exists)
          deferred.promise

    walk: (dir, fileFunc, dirFunc, options) ->
      throw new Error("not implemented")

      @self('sshBridged')("walk", dir).then (stream) =>
        stream.on "data", (dir) =>

    _checkFile: (filename, type) ->
      @execute("bash").then (proc) ->

        result = getOutput(proc).then (output) ->
          strip(output) == "y"

        proc.stdin.write('''
          [ -#{type} '#{filename}' ] && echo "y" || echo "n"
        ''')
        proc.stdin.close()

        return result

    isDirectory: (filename) -> @self('_checkFile')(filename, 'd')
    isExecutable: (filename) -> @self('_checkFile')(filename, 'x')

    shellExpand: (name) ->
      @execute("bash", "echo", name).then (proc) ->
        getOutput(proc).then (output) -> strip(output)

    openFile: (filename) ->
      textFileStreamFactory filename, (filename) =>
        @execute('cat', filename).then (proc) ->
          proc.stdout

    readFile: (filename, options) ->
      if options.count
        @execute('head', '-c', options.count, filename).then (proc) ->
          getOutput(proc)
      else
        @execute('cat', filename).then (proc) ->
          getOutput(proc)

    writeFile: (path, content) -> #@self('sshBridged') "writeFile", path, content
      @execute('bash', '-c', "cat > '#{path}'").then (proc) ->
        proc.stdin.write(content)
        proc.stdin.close()
        proc.on 'exit', (code) =>
          code

    expanded: ->
      cwd = @self('sshData')['cwd'] || "."
      @isDirectory(cwd).then (isdir) =>
        if isdir
          @readDir(cwd)
        else
          @readFile(cwd)

    collapse: ->
      null

    symLink: (srcpath, dstpath, type) ->
      throw new Error("not implemented")

    getMTime: (filename) ->
      throw new Error("not implemented")

    remove: (filename) ->
      throw new Error("not implemented")




  #  exists: (path,
