@doc = """
  SSH context enables you to run commands
  on a remote machine.
  """

class @SSH extends xikij.Context
  PATTERN = ///
    ([\w\-]+)  # user
    @
    ([\w\-]+(?:\.[\w\-]+)*) # host
    (?::(\d*))?
    ///

  SETTINGS = {
    remoteShell: "bash"
  }

  does: (xikiRequest, xikiPath) ->
    return false if xikiPath.empty()
    xikiPath = xikiPath.shift() if xikiPath.at(0, "")

    if m = xikiPath.first().match(@PATTERN)
      [cmd, user, host, port] = m
      path = xikiPath.shift()
      @sshData = {cmd, user, host, port}
    else
      return false

  sshCmd: ->
    cmd = ["ssh", "-o", "BatchMode yes"]
    {user, host, port} = @sshData
    if port
      cmd = cmd.concat ["-p", port]

    cmd.concat [ "#{user}@#{host}"]

  readDir: (dir, callback) ->
    done = false

    unless dir
      output = @execute "ls", "-F"

    else
      output = @execute "ls", "-F", path

    transformer = util.transform output, (line) =>
      if /[*=>@|]$/.test line
        line[...-1]+"\n"
      else
        line+"\n"

    unless callback
      transformer
    else
      streamConsume transformer, (result) =>
        callback(result.split /\n/)

  #readFile: ()

#  exists: (path,
