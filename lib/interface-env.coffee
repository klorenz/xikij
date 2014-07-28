module.exports = (Interface) ->
  Interface.define class Env
    shellExpand: (args...) -> @context.shellExpand args...
    dirExpand:   (args...) -> @context.dirExpand args...

  Interface.default class Env extends Env
    shellExpand: (s) ->
      result = s.replace /\$\{\w+\}/g, (m) ->
        varname = m[2...-1]
        if varname of process.env
          process.env[varname]
        else
          m

      result = result.replace /\$\w+/g, (m) ->
        varname = m[1...]
        if varname of process.env
          process.env[varname]
        else
          m

      result

    dirExpand: (s) ->
      s.replace /^~~/,      (m) -> @xiki.projectDir()
       .replace /^~[^\/]+/, (m) -> @xiki.projectDir(m[1...])
       .replace /^~/,       (m) -> @xiki.userDir()
