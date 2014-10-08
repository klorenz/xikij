child_process = require 'child_process'
os            = require 'os'
Q             = require "q"
{last}        = require "underscore"
{makeCommand} = require "./util"
path          = require "path"

module.exports = (Interface) ->
  # Originally only intended to execute programs.  But looking at implementation of
  # execution context, it interpretes whatever is written behind ``$`` prompt.

  Interface.define class ProgramExecution

  # This method executes whatever is written behind the ``$`` prompt.  Originally
  # it is intended to execute pro(grams, but implementing it in a different way in
  # your context, you can do anything you like with ``$`` prompt.

      execute: (args...) -> @dispatch "execute", args

  # This method executes whatever is written behind the ``$`` prompt, but is
  # intended for more complex expressions.
      executeShell: (args...) -> @dispatch "executeShell", args


  Interface.default class ProgramExecution extends ProgramExecution
    ## @depends: -> [ Interface.FileSystem ]

    execute: (args...) ->
      console.log "execute", args
      opts = args.pop()
      unless typeof opts is "object"
        args.push opts
        opts = {}

      promises = []
      unless 'cwd' of opts
        promise = @getCwd()
          .then (cwd) ->
            opts.cwd = cwd
            console.log "exec getCwd settled"
          .fail (error) ->
            console.log error.stack
            console.log "exec getCwd settled"

        promises.push promise

      unless 'env' of opts
        opts.env = {}
        promises.push @getEnv().then (env) ->
          for k,v of env
            unless k of opts.env
              opts.env[k] = v
          console.log "exec getEnv settled"

      promise = @getFileName()
        .then (filename) ->
          console.log "exec getFileName settled"
          if filename?
            opts.env["FILE_PATH"]      = filename
            opts.env["FILE_NAME"]      = path.basename(filename)
            opts.env["FILE_EXTENSION"] = path.extname(filename)
        .fail (error) ->
          console.log error.stack
          console.log "exec getFileName settled"
      promises.push promise

      promise = @getProjectDir()
        .then (projectdir) ->
          opts.env["PROJECT_DIR"]    = projectdir
          console.log "exec getProjectDir settled"
        .fail (error) ->
          console.log error.stack
          console.log "exec getProjectDir settled"
      promises.push promise

      console.log "promises", promises

      Q.allSettled(promises).then ->
        console.log "path", process.env['PATH']
        console.log "spawn", args[0], args[1..], opts
        child_process.spawn args[0], args[1..], opts

      # if args[0] does not exist, we get a ENOENT error


      ## 'darwin', 'freebsd', 'linux', 'sunos' or 'win32'

    executeShell: (args...) ->
      console.log "executeShell", args
      opts = last(args)
      if typeof opts is "object"
        opts = args.pop()
      else
        opts = {}

      if args.length == 1
        cmd = args[0].toString()
      else
        cmd = makeCommand(args)

      switch os.platform()
        when 'win32'
          @execute.apply this, ["cmd", "/c", cmd, opts]
        else
          @execute.apply this, ["bash", "-c", cmd, opts]
