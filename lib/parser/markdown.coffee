# Get structured xikij data out of markdown
#

{splitLines} = require "../util"

{Node, Fragment} = require "../node"
{last} = require "underscore"

console = (require "../logger")("xikij.parser.markdown")

parse = (content, level=0) ->
  base = node = new Node()
  level = 0
  stack = [base]
  currentIndent = ""
  indentStack = [currentIndent]
  textNode = null

  addNode = (caption) ->
    if caption?
      n = new Node(text: caption)
    else
      n = new Node()

    node.pushNode n
    stack.push n
    n

  popEmptyTextNode = ->
    if textNode.isEmpty()
      node.popNode()
      stack.pop()
      textNode = null

  newSection = (target_level, caption) ->
    if textNode
      node = stack.pop()

    while target_level > level+1
     level += 1
     node = addNode()

    while target_level <= level
      level -= 1
      
      stack.pop()

      node = last(stack)

    level += 1
    node = addNode caption
    textNode = null

  processLine = (line) ->

  mode = null
  indentation = ['']
  
  for line in splitLines(content)
    console.debug "line", line, node

    if line.match /^\s*$/
      unless textNode
        textNode = addNode()

      textNode.pushLine ""
      continue

    [line, indent, s] = line.match /^(\s*)(.*)/
    currentIndentation = last(indentation)

    while currentIndentation > indent
      indentation.pop()
      currentIndentation = last(indentation)

      popEmptyTextNode() if textNode
      stack.pop() if textNode

      stack.pop()
      node = last(stack)

    if indent > currentIndentation
      textNode.pushLine line[currentIndentation.length...]
      continue

    if m = s.match /^(#+) (.*)/
      newSection(m[1].length, m[2])

    if m = s.match /^=+$/
      caption = textNode.popLine()
      popEmptyTextNode()
      newSection(1, caption)

    if m = s.match /^-+$/
      caption = textNode.popLine()
      popEmptyTextNode()
      newSection(2, caption)

    if m = s.match /^[+*-] (.*)$/
#      popEmptyTextNode() if textNode
#      if textNode
#        node = stack.pop()

      node = addNode m[1]
      textNode = null
      indentation.push "#{currentIndentation}  "
      continue

    unless textNode
      textNode = addNode()

    textNode.pushLine s

  base

module.exports = parse
