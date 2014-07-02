INDENT = /^[ \t]*/

module.exports =
  get_indent: (line) ->
    return INDENT.exec(line)[0]
