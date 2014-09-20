{parseCommand} = require "xikij/util"

stream = require "stream"

class @Execution extends xikij.Context
  PS1 = "$ "

  does: (request, reqPath) ->
    debugger
    rp = reqPath.toPath()
    return no unless @mob = /^\s*\$\s+(.*)/.exec(rp)
    return yes

  expand: (req) ->
    command = @mob[1]
    return "" if /^\s*$/.test command

    cmd = parseCommand(command)

    @getCwd()
      .then (cwd) =>
        opts = {cwd: cwd}

        debugger

        unless cmd
          @executeShell command, opts
        else
          @execute cmd.concat([opts])...

      .then (proc) =>
        debugger
        output = stream.PassThrough()

        proc.stdout.pipe(output)
        proc.stderr.pipe(output)

        if req.input
          proc.stdin.write(req.input)
          proc.stdin.end()

        output

    # we could p.on "close" -> output.write("[error: returned x]") or emit a special event on output
