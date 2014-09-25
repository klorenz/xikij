@doc = """
  Handle Menus.  Menus are simple extensions to xiki-Ray.
  You have multiple opportunities to add active content to a menu.
  """

Q = require "q"
{Path} = require "xikij/path"

class @Menu extends xikij.Context
  _matchPath: (a, b) ->
    minlen = min(a.length, b.length)
    if a[...minlen] == b[...minlen]
      if a.length < b.length
        b[minlen...]
      else
        a[m]

  rootMenuItems: () ->
    result = []
    for m in xikij.packages.modules()
      r = m.menuName.replace(/\/.*/, '')
      result.push r unless r in result
    Q(result)

  does: (request, reqPath) ->
    return no if reqPath.rooted()

    #return false unless reqPath
    @path = reqPath
    @menuName = rp = reqPath.toPath().replace(/\/$/, '').replace(/[:*?]\//, '/').replace(/:$/, '')
    @menuPath = null
    @menuDir  = null

    max_minlen = 0
    for m in xikij.packages.modules()
      #console.log "mod", m
      mn = m.menuName

      minlen = Math.min(mn.length, rp.length)
      continue if minlen < max_minlen
      continue unless mn[...minlen] == rp[...minlen]

      max_minlen = minlen

      if mn.length <= rp.length
        @menuPath = rp[minlen...].replace /^\//, ''
      else
        @menuDir = mn[minlen...].replace /^\//, ''

      @module = m

    @weight = max_minlen

    return yes if max_minlen

    @reject()

  doc: ->
    if @menuDir?
      """
      A collection of menus.  Hit #{xikij.keys.expand} to list available menus.
      """
    else if @menuPath?
      path = new Path(@menuPath)

      if m = path.first().match /^\.(.*)/
        method = m[1]
        if method of @module
          if @module.docs
            if method of @module.docs
              doc = @module.docs[method]
              if typeof doc is "function"
                return doc()
              else
                return doc
            else
              return null

        return "%{method} is no method of #{@menuName}"

      else
        return @module.doc


  expand: (request) ->
    debugger
    if @menuDir?
      len = @menuDir.length
      result = []
      for m in xiki.packages.modules()
        if m.menuName[...len] == @menuDir
          item = m.menuName[len+1...].split("/", 1)[0]
          continue unless item
          result.append item

      return result

    if @menuPath?
      debugger
      path = new Path(@menuPath)

      if m = path.first().match /^\.(.*)/
        return path.selectFromObject(@module,
          (frag)       -> frag.replace(/^\./, ''),
          (func, path) => func request.clone {path, @menuName}
          )
      # else
      #   throw new Error("method #{method} does not exist in #{@menuName}")

      req = request.clone path: path[1..], menuName: @menuName
      if @module.expand
        return @module.expand req

      if @module.run
        return @module.run req

  getSubject: (req) ->
    if @menuDir?
      Q(null)
    else
      Q(@module)
