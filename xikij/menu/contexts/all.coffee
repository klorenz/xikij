@doc = """
  Provide a context to open all options of a menu item.  If a
  line ends with `*`, this context will handle it.
  """

Q = require "q"
_ = require "underscore"

class @All extends xikij.Context
  does: (request, reqPath) ->
    return false unless m = reqPath.last().match /(.*)\*$/

    @weight = reqPath.toPath().length
    @path = reqPath.clone()
    unless m[1]
      @allOn = @
    else
      @path.at(-1, m[1])
      @req = request
      @allOn = null

    return true

  getContext: ->
    unless @allOn
      @req.getContext(@context, @path).then (context) =>
        @context = @allOn = context
        @
    else
      @

  expand: (request) ->
    @allOn.getSubject().then (subject) =>
      result = []
      if subject?
        for key in _.keys subject
          result.push ".#{key}"

      result
