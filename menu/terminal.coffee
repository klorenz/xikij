module.exports = (xikij) ->
  @doc = """
      Run terminal in current working directory.
  """

  ###
  @run = =>
    getTerminalCommand = =>
      @getSettings('terminal-command').then (cmd) =>
        if cmd instanceof Array
          promise = Q(null)
          term.forEach (t) =>
            promise = promise.then (found) =>
              return found if found
              @exists(t).then (exists) =>
                return t if exists

        else
          return Q(cmd)

    @getCwd()
      .then (cwd) =>
        getTerminalCommand().then (cmd) =>
          @execute cmd, {cwd}
   ###
