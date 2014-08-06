child_process = require 'child_process'
os = require 'os'
Q = require "q"

module.exports = (Interface) ->
  # ## ProgramExecution Interface
  #
  # Originally only intended to execute programs.  But looking at implementation of
  # execution context, it interpretes whatever is written behind ``$`` prompt.

  Interface.define class ProgramExecution

  # ### execute
  #
  # This method executes whatever is written behind the ``$`` prompt.  Originally
  # it is intended to execute pro(grams, but implementing it in a different way in
  # your context, you can do anything you like with ``$`` prompt.

      execute: (args...) -> @context.execute args...

  # ### executeShell
  #
  # This method executes whatever is written behind the ``$`` prompt, but is
  # intended for more complex expressions.

      executeShell: (args...) -> @context.execute args...

  Interface.default class ProgramExecution extends ProgramExecution
    # @depends: -> [ Interface.FileSystem ]

    execute: (args...) ->
      opts = args.pop()
      unless typeof opts is "object"
        args.push opts
        opts = {}

      promises = []
      unless 'cwd' of opts
        promises.push @getCwd().then (cwd) => opts.cwd = cwd

      unless 'env' of opts
        opts.env = {}
        promises.push @getEnv().then (env) ->
          for k,v of env
            unless k of opts.env
              opts.env[k] = v

      Q.allSettled(promises).then ->
        child_process.spawn args[0], args[1..], opts

    executeShell: (args...) ->
      switch os.platform()
        when 'win32'
          @execute.apply this, ["cmd", "/c"].concat args
        else
          @execute.apply this, ["bash", "-c"].concat args

      # 'darwin', 'freebsd', 'linux', 'sunos' or 'win32'
