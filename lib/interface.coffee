class Interface
  constructor: ->
    @_registry = {}
    @_defaults = {}

  define: (cls) ->
    name = cls.name
    @[name] = @_registry[name] = cls

  default: (cls) ->
    @_defaults[cls.name] = cls

  mixDefaultsInto: (target, classes...) ->
    @mixin target, @_defaults, classes...

  implements: (target, classes...) ->
    @mixin target, @_registry, classes...

  mixInto: (target, classes...) ->
    @mixin target, @_registry, classes...

  mixin: (target, source, classes...) ->
    for className, mixin of source

      if classes.length
        continue unless className in classes

      for name, method of mixin::
        continue if name is "constructor"

        if typeof target is "function"
          continue if name of target::
          target::[name] = method
        else
          continue if target[name]
          target[name] = method

    target

  load: (module) ->
    (require module)(this)
    this

  # @clear: ->
  #   for k,cls of Interface::_registry
  #     delete Interface[k]
  #
  #   Interface::_registry = {}
  #   Interface::_defaults = {}

module.exports = Interface
