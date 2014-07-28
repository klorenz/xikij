module.exports = (Interface) ->
  # ## Namespace Interface
  #
  # Provide a namespace for applications like settings.

  Interface.define class Namespace

    # return name of current namespace, this is useful for classifying settings
    getNamespace: -> @NAMESPACE ? @constructor.name

    # return a list of user defined names
    getNamespaces: ->
      @getSetting ".namespaces", @getNamespace(), []
