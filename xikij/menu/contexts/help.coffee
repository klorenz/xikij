@doc = """
  Provide a context for help for all and everything.  If a line endswith "?",
  this will handle it.
  """

Q = require "q"

class @Help extends xikij.Context
  rootMenuItems: () ->
    Q(["?"])

  doc: ->
    deferred = Q.defer()
    xikij.request(path: "").then ({data}) ->
      helpDetails = data
        .replace /^(\s+[\+\-][^\n]*)\n/gm, (m) -> "#{m}?\n"
        .replace /\?\?\n/, "?\n"

      deferred.resolve """
        Help for all and everything.

        #{helpDetails}
        """

    deferred.promise

  does: (request, reqPath) ->
    debugger
    return false unless m = reqPath.last().match /(.*)\?$/

    @weight = reqPath.toPath().length

    @path = reqPath.clone()
    unless m[1]
      @helpOn = @
    else
      #@path.at(-1, m[1])
      @path.at(-1, m[1])
      @req = request
      @helpOn = null

    return true

  getContext: ->
    unless @helpOn
      @req.getContext(@context, @path).then (context) =>
        @context = @helpOn = context
        @
    else
      @

  expand: (request) ->
    debugger
    if @helpOn.doc
      if typeof @helpOn.doc is "function"
        Q.when @helpOn.doc(), (doc) =>
          if doc
            doc
          else
            ":( No help available"
      else
        @helpOn.doc
    else
      ":( No help available"
