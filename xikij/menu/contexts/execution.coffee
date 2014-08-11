{parseCommand} = @require "util"
stream = require "stream"
debugger

class @Execution extends xikij.Context
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
    @context.getCwd()
      .then (cwd) =>
        console.log "cwd", cwd
        opts = {cwd: cwd}
      .then (opts) =>
        unless cmd
          @context.executeShell command, opts
        else
          @context.execute (cmd.concat [ opts ])...
      .then (proc) =>
        proc.stdout.pipe(output)
        proc.stderr.pipe(output)

        if req.input
          proc.stdin.write(req.input)
          proc.stdin.end()

        output

    # we could p.on "close" -> output.write("[error: returned x]") or emit a special event on output
