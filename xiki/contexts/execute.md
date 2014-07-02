Execute
=======

Execute a command.  Indicator for
execution command is ``$`` prompt.

```sh
    $ echo "hello world"
```

Command is always executed within current
context, i.e. it uses execute method
from parent context.  Execute context is
smart about its input.  If you have
anything in command, which indicates, that
this command should be rather executed in
a shell, then it is executed in shell.

```sh
    $ echo "executed from shell" | echo
```

```coffee

    class Exec extends XikiContext

      PATTERN = /^\s*\$\s+(.*)/
      PS1 = "$ "

      COMMAND_PARTS = ///
      (?:^|\s)
      (?:
      "((?:\\.|[^"\\]+)*)"
      | '((?:\\.|[^\\]+)*)'
      | (\S+)
      )
      ///

      parseCommand: (s) ->
        result = []
        isShellCommand = false
        for m,i in split COMMAND_PARTS
          continue unless m

          if i % 3  # unquoted
            return null if ( /`/.test(m)
                 or (m in ["|", ">", "<"])
                 or (m[...2] in ["1>", "2>"])
                 )
            result.push m
          else if i % 2  # single quoted
            result.push m.replace("\\'", "'").replace("\\\\", "\\")
          else if i % 1
            result.push m.replace('\\"', '"').replace("\\\\", "\\")
        return result

      open: ->
        s = @mob[1]
        return "" unless s.replace(/^\s+/, '').replace(/\s+$//, '')

        cmd = @parseCommand(s)
        unless cmd
          @context.executeShell(s)
        else
          @context.execute(cmd)

```
