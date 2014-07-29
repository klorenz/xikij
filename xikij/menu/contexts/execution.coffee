{parseCommand} = @require "util"
stream = require "stream"

class @Execution extends xiki.Context
  PS1 = "$ "

  does: (xikiRequest, xikiPath) ->
    xp = xikiPath.toPath()
    m = /^\s*\$\s+(.*)/.exec(xp)
    return false unless m
    @mob = m
    return true

  expand: (req) ->
    command = @mob[1]
    return "" if /^\s*$/.test command

    cmd = parseCommand(command)

    output = stream.PassThrough()
    opts = {}

    unless cmd
      p = @context.executeShell command, opts
    else
      p = @context.execute (cmd.concat [ opts ])...

    p.stdout.pipe(output)
    p.stderr.pipe(output)

    output
