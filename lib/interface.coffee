fs = require 'fs'
console = (require "./logger")("xikij.Interface")

# Provide an interface to xikij
#
# You can extend the interface from your menu module like this:
#
# ```coffee
#   # you can extend interface with
#   module.exports = (xikij) ->
#     xikij.Interface.register __filename, (Interface, xikij) =>
#       Interface.extend class MyClass
#          mymethod: (foo, bar) ->
#            console.log "this is the default", foo, bar
# ```
#
# This is equivalent to following form, which defines explicitly
# methods, which shall be mixed into dispatching class and into
# class containing default behaviours:
#
#   module.exports = (xikij) ->
#     xikij.Interface.register __filename, (Interface, xikij) =>
#       Interface.define class MyClass
#          mymethod: (args...) -> @dispatch "mymethod", args
#
#       Interface.default class MyClass extends MyClass
#          mymethod: (foo, bar) ->
#            console.log "this is the default", foo, bar
# ```
#
#
class Interface
  constructor: (@_xikij) ->
    @_registry = {}
    @_defaults = {}
    @_files    = {}
    @_docs     = {}

    @_targetDefaults = null
    @_targetDefines  = null

  # returns an object containing interface documentation
  getDoc: (name) ->
    unless name
      for k of @_registry
        unless k of @_docs
          @getDoc(k)
      return @_docs

    if name of @_docs
      return @_docs[name]

    lines   = fs.readFileSync(@_files[name]).toString().split /\n/
    methods = {}
    docs    = {}
    wasDoc  = 0

    mode = "description"
    method = null

    for line in lines
      if mob = line.match /^\s*\#(.*)/
        unless wasDoc
          doc = ""

        comment = mob[1]
        if comment.length
          comment = comment[1..]

        doc += "#{comment}\n"
        wasDoc = 1
        continue

      else if wasDoc
        if not (mode of docs)
          docs[mode] = []

        docs[mode].push doc

        wasDoc = 0

      if line.match /^\s*Interface.define/
        mode = "define"
        continue

      if line.match /^\s*Interface.default/
        mode = "default"
        continue

      if line.match /^\s*Interface.extend/
        mode = "define"
        continue

      if mode in ["define", "default"]
        console.log "line", line

        if mob = line.match /^\s*([\w$]+)\s*:\s*(?:\(([^\)]*)\)|\s*[=-]>)?/
          if mode of docs
            docs[mode].pop()

          method = mob[1]
          if method is "constructor" or method.match /^_/
            continue

          if not (method of methods)
            _args = mob[2] or ""
            console.log "args", _args
            methods[method] = docobj = {name: mob[1], args: _args}

          else
            console.log methods
            docobj = methods[method]
            console.log "docobj", docobj
            if docobj.args.match /^\w+\.\.\.$/
              docobj.args = mob[2]

          docobj[mode] = doc
          doc = ""

    for k,v of docs
      docs[k] = ("\n"+v.join("\n")+"\n").replace(/^\n+/, "\n").replace(/\n+$/, "\n\n")

      if docs[k].match /^\n*$/
        delete docs[k]

    docs.methods = meths = {}
    for k,v of methods
      if m = k.match /(.*)\$dispatcher$/
        k = m[1]

      key = "#{k}(#{v.args})"

      description = ""

      for x in ['define', 'default']
        if v[x]
          description += "\n" if description
          description += v[x]

      meths[key] = ("\n#{description}\n").replace(/^\n+/, "\n").replace(/\n+$/, "\n\n")

      if meths[key].match /^\n*$/
        meths[key] = "\nno documentation available :(\n\n"

    delete docs.default if docs.default
    delete docs.define  if docs.define

    @_docs[name] = docs
    return docs

  define: (cls) ->
    name = cls.name
    @[name] = @_registry[name] = cls
    @_files[name] = @currentFile

    if @_targetDefines?
      o = {}
      o[name] = cls
      @mixin @_targetDefines, o

  default: (cls) ->
    @_defaults[cls.name] = cls

    if @_targetDefaults?
      o = {}
      o[cls.name] = cls
      @mixin @_targetDefaults, o

  mixDefaultsInto: (target, classes...) ->
    @_targetDefaults = target unless @_targetDefaults?
    @mixin target, @_defaults, classes...

  implements: (target, classes...) ->
    @mixin target, @_registry, classes...

  mixInto: (target, classes...) ->
    @_targetDefines = target unless @_targetDefines?
    @mixin target, @_registry, classes...

  mixin: (target, source, classes...) ->
    for className, mixin of source

      if classes.length
        continue unless className in classes

      for name, method of mixin::
        continue if name is "constructor"

        if typeof target is "function"
          if name of target::
            console.log "WARNING: #{name} already defined in interface"
            continue

          target::[name] = method
        else
          continue if target[name]
          target[name] = method

    target

  # this does, what
  extend: (filename, cls) ->
    name = cls.name
    @[name] = @_registry[name] = cls
    @_files[name] = @currentFile

    dispatcher = (name) ->
      (args...) -> @dispatch name, args

    setprototype = (cls, name, method) ->
      throw new Error "ERROR: #{name} already defined in interface (#{cls.constructor.name})"
      cls::[name] = method

    for className, mixin of source
      for name, method of mixin::
        continue if name is "constructor"

        if m = name.match /(.*)\$dispatcher$/
          setprototype @_targetDefines, m[1], method

        else
          setprototype @_targetDefaults, name, method

          if not (name of @_targetDefines::)
            @_targetDefines::[name] = dispatcher name

  register: (filename, registrar) ->
    @currentFile = filename
    registrar(this, @_xikij)

  load: (module) ->
    @register require.resolve(module), require(module)
    this

  # @clear: ->
  #   for k,cls of Interface::_registry
  #     delete Interface[k]
  #
  #   Interface::_registry = {}
  #   Interface::_defaults = {}

module.exports = Interface
