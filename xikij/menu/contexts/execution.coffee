module.exports = (xikij) ->

  {parseCommand} = xikij.util

  stream = require "stream"

  class @Execution extends xikij.Context
    PS1 = "$ "

    does: (request, reqPath) ->
      rp = reqPath.toPath escape: false
      return no unless @mob = /^\s*\$\s+(.*)/.exec(rp)
      return yes

    expand: (req) ->
      debugger
      command = @mob[1]
      return "" if /^\s*$/.test command

      cmd = parseCommand(command)
      console.log "cmd", cmd

      @getCwd()
        .then (cwd) =>
          console.log "have cwd"
          opts = {cwd: cwd}

          debugger

          unless cmd
            console.log "execute shell:", command
            @executeShell command, opts
          else
            console.log "execute:", cmd
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
