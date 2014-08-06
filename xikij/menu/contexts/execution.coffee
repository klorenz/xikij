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
    debugger
    command = @mob[1]
    return "" if /^\s*$/.test command

    cmd = parseCommand(command)

    output = stream.PassThrough()
    opts = { cwd: @context.getCwd() }

    unless cmd
      p = @context.executeShell command, opts
    else
      p = @context.execute (cmd.concat [ opts ])...

    p.stdout.pipe(output)
    p.stderr.pipe(output)

    if req.input
      p.stdin.write(req.input)
      p.stdin.end()

    # we could p.on "close" -> output.write("[error: returned x]") or emit a special event on output

    output
