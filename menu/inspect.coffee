util = require 'util'

module.exports = (xikij) ->

  @doc = """
      Inspect contexts and request, which would be run in current
      context.

      - .deep -- deep inspect, expand everything
      - .menu -- (default) inspect only one level, is pretty simple
                 at this point and does not handle arrays correct
      """


  @run = (request) ->
    if request.path.empty()
      console.log request
      util.inspect request, depth: 0
    else
      list = request.path.toArray()
      parts = []

      if list.length % 2 == 1
        for part in list[1...-1] by 2
          parts.push part

        last = request.path.last()
        while on
          if m = last.match /^\[ (.*)/
            parts.push 0
            last = m[1]
            continue
          if m = last.match /^\{ (.*)/
            last = m[1]
            continue
          break
        parts.push last
      else
        for part in list[1...] by 2
          parts.push part

      console.log "parts", parts

      element = request

      for name in parts
        if m = name.match /([^:\s]+):/
          element = element[m[1]]
          console.log "element.#{m[1]}", element

      if element instanceof Array
        util.inspect element, depth: 1
      else
        util.inspect element, depth: 0

  @deep = (request) ->
    util.inspect request, depth: null
