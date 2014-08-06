Q = require "q"

module.exports = (Interface) ->
  Interface.define class Env
    shellExpand: (args...) -> @context.shellExpand args...
    dirExpand:   (args...) -> @context.dirExpand args...
    getProjectDirs: (args...) -> @context.getProjectDirs args...
    getProjectDir:  (args...) -> @context.getProjectDir args...
    getEnv:         (args...) -> @context.getEnv args...

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

      Q.fcall -> result

    dirExpand: (s) ->
      if s.match /^~~/
        @getProjectDir().then (v) -> v + s[2..]
      else if (m = s.match /^~([^\/]+)/)
        @getProjectDir(m[1]).then (v) -> v + s[m[0].length..]
      else if /^~/
        @getUserDir().then (v) -> v+s[1..]

    getUserDir: -> Q.fcall -> @getEnv("HOME")

    getProjectDirs: -> Q.fcall -> []

    getProjectDir: (name) ->
      @projectDirs().then (dirs) ->
        unless dirs.length
          throw new Error("No project directories defined")

        return dirs[0] unless name

        for d in dirs
          if path.basename(d) == name
            return d

        throw new Error("Project directory #{name} is not defined")

    getEnv: (name) -> Q.fcall ->
      if name
        process.env[name]
      else
        process.env
