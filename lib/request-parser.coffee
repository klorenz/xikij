# A XikiRequest contains a sequence of XikiPath objects.  Each XikiPath object
# defines a context, which is the context for next XikiPath object.

{Request}            = require "./request"
{Path, PathFragment} = require "./path"
{last}               = require "underscore"

throw "Path not defined" unless Path

STRING      = /(\\.|[^"\\]+)*/
INDEX       = /\[(\d+)\](?=\/|$)/
BULLET      = /^[\-–—+]\s/
CONTEXT     = /[@$]/
NODE_LINE_1 = /^(\s*)@\s*(.*)/
INDENT      = /^[ \t]*/
FREE_LINE   = /(\s*)([^\-–—+].*)/
NODE_LINE_PROMPT_COMMENT = /^(\s*\$.*)\s+(?:—|–|\#)\s+.*$/
NODE_LINE_COMMENT = /^(\s*(?!\$).*)\s+(?:--|—|–|\#)\s+.*$/
PATH_SEP    = /(?:\/| -> | → )/
BUTTON      = /^(\s*)\[(\w+)\](?:\s+\[\w+\])*\s*$/

{getIndent, removeIndent, strip} = require "./util"



matchTreeLine = (s) ->
  r = {}
  # s is like @menuitem
  if m = NODE_LINE_1.exec(s)
    return  indent: m[1], ctx: "@", node: m[2]

  r = indent: getIndent(s), ctx: null
  # s is like something -- here is a comment
  if m = NODE_LINE_COMMENT.exec(s)
    s = m[1]
  # s is like $ foo bar # here is a comment
  if m = NODE_LINE_PROMPT_COMMENT.exec(s)
    s = m[1]

  s = s.replace(/^\s+/, '').replace(/\s+$/, '')

  # s startswith + or -
  if BULLET.test(s)
    s = s[1..].replace(/^\s+/, '')

  # unless s startswith @ or $
  else unless CONTEXT.test(s[0])
    # if r.indent is not set, this might be a path
    #unless r.indent
    if s[-1..] == "/"
        #s = s[...-1]
      #r.node = s.split PATH_SEP
      r.node = Path.split s
  #      r.node[r.node.length-1] += "/"
    else
      r.node = Path.split s
#     r.node = [ s ]
    return r
    #return null

  if s[0] == "@"
    s = s[1...].replace(/^\s+/, '')
    r.ctx = "@"
  else if s[...2] == "$ "
    r.ctx = "$"
  else if s[...2] == "``" and s[-2...] == "``"
    s = s[2...-2]
    r.ctx = '``'
  else if s[0] == "`" and s[-1...] == "`"
    s = s[1...-1]
    r.ctx  = '`'
  else if s[0] == "`" and s[-2...] == "`_"
    s = s[1...-2]
    r.ctx  = '`'
  else if s[-1...] == "?"
    r.ctx = "?"
  else if s[-1...] == "*"
    r.ctx = "*"

# TODO: respect quotes and paranthesis
  if s[0] != "$"
    if s[-1..] == "/"
      #s = s[...-1]
      r.node = Path.split(s)
#      r.node[r.node.length-1] += "/"
    else
      r.node = Path.split(s)

    # for i in [0 ... r.node.length]
    #   r.node[i] += '/'
  else
    r.node = [ s ]

  return r

parseXikiPath = (path) ->
  np  = Path.split(path)
  nodePath = []
  nodePaths = [nodePath]

  for p,i in np
    if p[...2] == "$ "
      unless nodePath.length
        nodePaths.pop()

      nodePaths.push [ new PathFragment np[i..].join "/" ]
      break

    if p[0] == "@"
      unless nodePath.length
        nodePaths.pop()

      nodePath = [ new PathFragment strip p[1..] ]
      nodePaths.push nodePath
      continue

    if p[-1...] == "?"
      nodePath.push [ new PathFragment p ]
      nodePath = []
      nodePaths.push nodePath
      continue

    if p[-1...] == "*"
      nodePath.push [ new PathFragment p ]
      nodePath = []
      nodePaths.push nodePath
      continue

    nodePath.push new PathFragment p

  nodePaths


parseXikiRequest = (request) ->
  {path, body, action, args, req, res} = request

  input = body || null
  action = action || "expand"

  # eequest root menu
  if path is ""
    nodePaths = [ new Path([ new PathFragment "" ]) ]
    new Request {body, nodePaths, input, action, args, req, res}
  else
    unless request.path
      parseXikiRequestFromTree(request)
    else
      nodePaths = (new Path(p) for p in parseXikiPath(path))
      new Request {body, nodePaths, input, action, args, req, res}

parseXikiRequestFromTree = ({path, body, action, args}) ->

  action = null unless action
  input  = null
  lines  = (body.replace(/\s+$/, '')).split(/\n/)

  if args
    if 'line' of args
      input = removeIndent(lines[args.line+1..].join("\n")+"\n")
      lines = lines[..args.line]

  node_path     = []
  node_paths    = [ node_path ]
  old_line      = null
  indent        = null
  collect_lines = false

  for line in lines.reverse().concat [null]
    #
    # There may be contined lines
    #
    process_line = null
    unless line?
      process_line = old_line
    else if /\\\n$/.test line
      line = line[...-2] + old_line.replace(/^\s+/, '')
    else
      process_line = old_line

    old_line = line

    continue unless process_line?

    line = process_line
    line_stripped = line.replace(/^\s+/, '').replace(/\s$/, '')

    if collect_lines
      unless line_stripped
        input.push "#{indent}\n"
        continue
      if line[...indent.length] == indent
        input.push line
        continue

      input = removeIndent(input.join(''))
      collect_lines = false
      indent = null

    unless indent?
      if m = BUTTON.exec line
        input = []
        [indent, action] = [m[1], m[2]]
        collect_lines = true
        continue

    mob = matchTreeLine line

    unless mob
      if indent is null
        m = INDENT.exec(line)
        indent = m[0]
        node_path.push new PathFragment(line_stripped)
        node_path = []
        node_paths.push node_path
      continue

    unless line_stripped
      continue

    if mob.ctx in [ "@", "?", "*" ]
      more_node_paths = parseXikiPath(mob.node)
      node_paths[-1..] = more_node_paths[0]
      if more_node_paths.length > 1
        node_paths.push mode_node_paths[1..]...

      continue

    _indent = mob.indent
    continue if indent and _indent.length > indent.length

    s = mob.node[0]
    nodes = mob.node[1..]

    for n in nodes.reverse()
      node_path.push new PathFragment(n)

    if indent is null
      indent = _indent
      node_path.push new PathFragment(s)

      break unless s

      if mob.ctx
        node_path = []
        node_paths.push node_path

      continue

    if _indent.length == 0
      node_path.push new PathFragment(s)
      break

    if _indent.length == indent.length
      if node_path.length
        last_node_path = node_path[node_path.length-1]
        if last_node_path.name == s
          last_node_path.position += 1
          continue

    if 0 < _indent.length and _indent.length < indent.length
      node_path.push new PathFragment(s)
      if mob.ctx
        node_path = []
        node_paths.push node_path
      indent = _indent

  unless node_path.length
    node_paths = node_paths[...-1]


  for np,i in node_paths
    node_paths[i] = np.reverse()

  node_paths.reverse()

  nodePaths = (new Path(p) for p in node_paths)

  return new Request {body, nodePaths, input, action}


module.exports = {matchTreeLine, parseXikiRequest, parseXikiPath,
  parseXikiRequestFromTree}
