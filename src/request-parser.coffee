# A XikiRequest contains a sequence of XikiPath objects.  Each XikiPath object
# defines a context, which is the context for next XikiPath object.

{EventEmitter} = require "events"

class XikiRequest extends EventEmitter
  constructor: (opts) ->
    {@body, @nodePaths, @args, @action, @req, @res} = opts
    {@before, @after, @prefix} = opts
    @input = @body

  getContext: (context, xikiPath) ->
    debugger
    unless xikiPath
      for xikiPath in @nodePaths
        context = @getContext context, xikiPath
      return context
    else
      for ContextClass in context.contexts()
        ctx = new ContextClass()
        if ctx.does this, xikiPath
          return ctx.getContext()

    return context

  # returns context, such that you can react on its result
  process: (context, respond) ->
    @context = @getContext context
    @respond = respond

    try
      result = @context[@action](this)
    catch err
      respond(err)

    unless result is undefined
      @respond result


class XikiPath
  constructor: (@nodePath) ->

  # return the first portion of path
  first: -> @nodePath[0].name

  slice: (args...) ->
    new XikiPath @nodePath.slice args...

  unshift: (thing)->
    if thing instanceof Array
      @nodePath.unshift new PathFragment thing...
    else if typeof thing is "string"
      @nodePath.unshift new PathFragment thing
    else if thing instanceof PathFragment
      @nodePath.unshift thing
    else
      throw "cannot unshift thing: #{thing}"

  shift: -> @[1..]

  empty: -> @nodePath.length == 0

  toPath: ->
    (frag.name for frag in @nodePath).join("/")



STRING      = /(\\.|[^"\\]+)*/
INDEX       = /\[(\d+)\](?=\/|$)/
BULLET      = /[\-–—+]\s/
CONTEXT     = /[@$]/
NODE_LINE_1 = /(\s*)@\s*(.*)/
INDENT      = /^[ \t]*/
FREE_LINE   = /(\s*)([^\-–—+].*)/
NODE_LINE_COMMENT = /^(.*)\s+(?:--|—|–|\#)\s+.*$/
PATH_SEP    = /(?:\/| -> | → )/
BUTTON      = /^(\s*)\[(\w+)\](?:\s+\[\w+\])*\s*$/

{getIndent} = require "./util"



match_tree_line = (s) ->
  r = {}
  if m = NODE_LINE_1.exec(s)
    return  indent: m[1], ctx: "@", node: [ m[2] ]

  r = indent: getIndent(s), ctx: null
  if m = NODE_LINE_COMMENT.exec(s)
    s = m[1]

  s = s.replace(/^\s+/, '').replace(/\s+$/, '')

  if BULLET.test(s)
    s = s.slice(1).replace(/^\s+/, '')
  else unless CONTEXT.test(s[0])
    unless r.indent
      r.node = [ s ]
      return r
    return null

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

  if s[0] != "$"
    if s[-1..] == "/"
      s = s[...-1]
      r.node = s.split PATH_SEP
#      r.node[r.node.length-1] += "/"
    else
      r.node = s.split PATH_SEP

    # for i in [0 ... r.node.length]
    #   r.node[i] += '/'
  else
    r.node = [ s ]

  return r

parseXikiPath = (path) ->
  np  = path.split /\//
  nodePath = []
  nodePaths = [nodePath]

  for p,i in np
    if p[...2] == "$ "
      nodePaths.push [ new PathFragment np[i..].join "/" ]
      break

    if p[0] == "@"
      nodePath = [ new PathFragment p[1..] ]
      nodePaths.push nodePath
      continue

    nodePath.push new PathFragment p

  nodePaths

class PathFragment
  constructor: (@name, @position=0) ->

  toString: ->
    if @position > 0
      "#{@name}[#{@position}]"
    else
      @name

parseXikiRequest = (request) ->
  {path, body, action, args, req, res} = request

  input = body || null
  action = action || "expand"
  # request root menu
  if request.path is ""
    nodePaths = [ new PathFragment "" ]
    new XikiRequest {body, nodePaths, input, action, args, req, res}
  else
    unless request.path
      parseXikiPathFromTree(request)
    else
      nodePaths = parseXikiPath(path)
      new XikiRequest {body, nodePaths, input, action, args, req, res}


parseXikiRequestFromTree = ({path, body, action, req, res}) ->

  action = null unless action

  lines         = body.split /\n/
  node_path     = []
  node_paths    = [ node_path ]
  old_line      = null
  indent        = null
  lines         = body.replace(/\s+$/, '') + "\n"
  collect_lines = false
  input         = null

  for line in lines.split(/\n/).reverse().concat [null]
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
        input.append(indent+"\n")
        continue
      if line[...indent.length] == indent
        input.append(line)
        continue

      input = unindent(input.join(''))
      collect_lines = false
      indent = null

    unless indent?
      if m = BUTTON.exec line
        input = []
        [indent, action] = [m[1], m[2]]
        collect_lines = true
        continue

    mob = match_tree_line line

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

    _indent = mob.indent

    s = mob.node[0]
    nodes = mob.node[1..]

    for n in nodes
      node_path.push new PathFragment(n)

    if indent is null
      indent = _indent
      break unless s

      node_path.push new PathFragment(s)

      if mob.ctx
        node_path = []
        node_paths.append node_path

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

  nodePaths = (new XikiPath(p) for p in node_paths)

  return new XikiRequest {body, nodePaths, input, action, req, res}


module.exports = {match_tree_line, parseXikiRequest, parseXikiPath,
  parseXikiRequestFromTree}
