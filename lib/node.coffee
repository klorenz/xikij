###
Xikij Nodes
===========

Xikij represents objects in list structures.  Usually Object's attributes are
paired as (name, value), where name is the caption in the list (first line) and
value is expandable on demand.

Object attributes are not ordered.  Which may lead into problems, especially
if you want to represent the structure of document (like markdown).

Using Xikij Nodes, you can represent Objects in an ordered way.

Transformation of Markdown to Xikij Nodes
-----------------------------------------

Following text in markdown shall be represented in Xikij.

```markdown
Document Title
==============

First Section
-------------

Here is some very important text.

- first item

- second item
  some more text

  - first
  - second

- third item

Here is some lorem ipsum epilog.

Second Section
--------------

Here only some text.
```

Xikij representation would be

```
- Document Title
  - First Section
    Here is some very important text.

    - first item
    - second item
      some more text
      - first
      - second
    - thrid item

    Here is some lorem ipsum epilog
  - Second Section
    Here only some text.
```

```
- Document Title
  ==============

  - First Section
    -------------

    Here is some very important text.

    - first item

    - second item
      some more text

      - first
      - second

    - thrid item

    Here is some lorem ipsum epilog

  - Second Section
    --------------

    Here only some text.
```

If you are working with it, you start with
```
+ Document Title
```

Which expands to
```
- Document Title
  ==============

  + First Section
  + Second Section
```

Expanding `First Section`:
```
- Document Title
  ==============

  - First Section
    -------------

    Here is some very important text.

    + first item
    + second item
    + thrid item

    Here is some lorem ipsum epilog

  + Second Section
```

Node Structure for this looks like this:
```
  Node(
    text: ""
    children: [
      Node(
        text: "Document Title"
        children: [
          Node(
            text: "==============\n\n",
            children: []
          )
          Node(
            text: "First Section"
            children: [
              Node(
                text: "-------------\n\nHere is some very important text.\n\n"
                children: []
              )
              Node(
                text: "first item"
                children: [
                  Node(
                    text: "\n"
                  )
              ],
              Node(
                text: "second item"
                children: [
                  Node(
                    text: "some more text.\n\n"
                  )
                  Fragment(

                  )
              ]
              )

              )
          ]

          )
      ]
      ),
      Node()
    ]
  )




###

{indented} = require "./util"

class Node
  constructor: (opts) ->
    {@text, @children} = opts ? {}
    @text = @text ? ""
    @children = @children ? []

  pushNode: (node) ->
    @children.push node
    node

  popNode: ->
    @children.pop()

  pushText: (text) ->
    @text += text

  pushLine: (line) ->
    @text += line + "\n"

  popLine: (line) ->
    try
      [text, @text, result] = @text.match /^([\s\S]*\n)?([^\n]*)\n$/
    catch e
      console.error "cannot pop line from: #{@text}"
      return ""

    result

  toString: ->
    result = ""
    result += text

    for child in @children
      result += child.toString()

    return result

  hasChildren: -> !!@children.length

  isText: -> !@children.length

  isEmpty: -> !@children.length and !@text

  toJSON: () ->
    {__class: 'Node', @text, @children}


class Fragment extends Node
  constructor: ({@caption, @children}) ->
    @children = @children ? []

  equals: (fragment) ->
    return @caption == fragment

  toString: ->
    return "- " + @caption + "\n" + indented(super())

module.exports = {Node, Fragment}
