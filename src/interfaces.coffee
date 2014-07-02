# A Xiki context can influence behaviour of child operations.  As an example
# running pwd in two different directories.
#
# ```
# /foo/bar
#   $ pwd
#     /foo/bar
# /tmp
#   $ pwd
#     /tmp
# ```
#
# In this case directory context set working directory, which made child
# operations to be run in different working directories.
#
# Final xiki context class is composed by a mix of various interfaces.
#

mixOf = (base, mixins...) ->
  class Mixed extends base
  for mixin in mixins by -1 #earlier mixins override later ones
    for name, method of mixin::
      Mixed::[name] = method
  Mixed

# base class for all context mixins
class Interface
  constructor: (@context) ->

  dispatch: (name) ->
    (-> @context[name].apply @context, arguments[1..])

class ExecuteProgramInterface

  execute: () ->

  executeShell: () ->


class NamespaceInterface

  # return name of current namespace, this is useful for classifying settings
  getNamespace: -> @NAMESPACE ? @constructor.name

  # return a list of user defined names
  getNamespaces: ->
    @getSetting ".namespaces", @getNamespace(), []


class FileSystemInterface

  isdir:    (path) -> @context.isdir path
  listdir:  (path) -> @context.listdir path
  exists:   (path) -> @context.exists path

  # walk path
  walk:     (path) -> @context.walk path

  # return time of last modification of path
  getmtime: (path) -> @context.getmtime path

  # write content to file at path
  writeFile: (path, content)   -> @context.writeFile path, content

  # read first count bytes/chars from file.  if no count given, return entire
  # content
  readFile:  (path, count=null) -> @context.readFile path, count

  # return current working directory
  getcwd: ->

  makedirs: () -> @context.makedirs.apply @context, arguments

  # create a temporary file
  tempfile: (name, content) -> @context.tempfile
  
