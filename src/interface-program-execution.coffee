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

      unless 'cwd' of opts
        opts.cwd = @getcwd()
