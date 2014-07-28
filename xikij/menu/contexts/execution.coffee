class @Execution extends xiki.Context
  PATTERN = /^\s*\$\s+(.*)/
  PS1 = "$ "

  COMMAND_RE = ///
    (?:^|\s+)
    (?:
      ("(?:\\.|[^"\\]+)*")
      | ('(?:\\.|[^'\\]+)*')
      | (\S+)
    )
    ///

  parseCommand: (s) ->
    result = []
    isShellCommand = false
    for m in s.split @COMMAND_RE
      continue if m is undefined
      continue if m == ""
      if m[0] == '"' and m[-1..] == '"'
        result.push m[1...-1].replace('\\\\', '\\').replace('\\"', '"')
      else if m[0] == "'" and m[-1..] == "'"
        result.push m[1...-1].replace('\\\\', '\\').replace('\\"', '"')
      else
        return null if /(^[|<>]$|^[12]>|`)/.test m
        result.push m

    return result

  expand: ->
    command = @mob[1]
    return "" if /^\s*$/.test command

    cmd = @parseCommand(command)

    unless cmd
      return @context.executeShell command
    else
      return @context.execute cmd...
