Q = require "q"
{promised} = require "./util"

module.exports = (Interface, xikij) ->
  Interface.define class Env
    shellExpand:    (args...) -> @dispatch "shellExpand", args
    dirExpand:      (args...) -> @dispatch "dirExpand", args
    getProjectDirs: (args...) -> @dispatch "getProjectDirs", args
    getProjectDir:  (args...) -> @dispatch "getProjectDir", args
    getUserDir:     (args...) -> @dispatch "getUserDir", args
    getEnv:         (args...) -> @dispatch "getEnv", args
    # return full pathname of file of interest
    #
    # this is usually the path of file opened in editor, but also
    # a {Directory} context provides the path of file referenced.
    getFilePath:    (args...) -> @dispatch "getFilePath", args

  Interface.default class Env extends Env
    shellExpand: (s) ->
      @getEnv()
        .then (env) =>
          result = s.replace /\$\{\w+\}/g, (m) ->
            varname = m[2...-1]
            if varname of env
              env[varname]
            else
              m

          result = result.replace /\$\w+/g, (m) ->
            varname = m[1...]
            if varname of env
              env[varname]
            else
              m

          console.log "shellExpand", result

          result

    dirExpand: (s) ->
      if s.match /^~~/
        @getProjectDir().then (v) -> v + s[2..]
      else if (m = s.match /^~([^\/]+)/)
        @getProjectDir(m[1]).then (v) -> v + s[m[0].length..]
      else if s.match /^~/
        @getUserDir().then (v) -> v+s[1..]
      else
        s

    getUserDir: ->
      deferred = Q.defer()
      @getEnv("HOME")
        .then (result) =>
          deferred.resolve(result)
        .fail (error) =>
          @getEnv("USERPROFILE")
            .then (result) ->
              deferred.resolve(result)
            .fail (error) ->
              deferred.reject(result)

      deferred.promise

    getProjectDir: (name) ->
      deferred = Q.defer()

      @getProjectDirs()
        .then (dirs) =>
          unless dirs.length
            throw new Error("No project directories defined")

          unless name
            @getFilePath()
              .then (fileName) ->
                for d in dirs
                  if not path.relative(fileName, d).match /^\.\./
                    return deferred.resolve(d)

                # project dir and fileName unrelated, return first
                deferred.resolve(dirs[0])
              .fail (error) ->
                deferred.resolve(dirs[0])

          return deferred.resolve(dirs[0]) unless name

          for d in dirs
            if path.basename(d) == name
              return deferred.resolve(d)

          throw new Error("Project directory #{name} is not defined")
        .fail (error) ->
          deferred.reject(error)

      deferred.promise

    getProjectDirs: -> Q.fcall -> []

    getEnv: (name) -> Q.fcall ->
      if name
        process.env[name]
      else
        process.env

    getFilePath: -> Q.fcall -> throw new Error "filename not defined"
