@doc = """
  Handle Menus.  Menus are simple extensions to xiki-Ray.
  You have multiple opportunities to add active content to a menu.
  """

class @Menu extends xikij.Context
  _matchPath: (a, b) ->
    minlen = min(a.length, b.length)
    if a[...minlen] == b[...minlen]
      if a.length < b.length
        b[minlen...]
      else
        a[m]

  does: (xikiRequest, xikiPath) ->
    return no if xikiPath.rooted()

    #return false unless xikiPath
    @xikiPath = xikiPath
    @menuName = xp = xikiPath.toPath().replace(/\/$/, '')
    @menuPath = null
    @menuDir  = null
    xp = xikiPath.toPath().replace(/\/$/, '')

    max_minlen = 0
    for m in xikij.packages.modules()
      #console.log "mod", m
      mn = m.menuName

      minlen = Math.min(mn.length, xp.length)
      continue if minlen < max_minlen
      continue unless mn[...minlen] == xp[...minlen]

      max_minlen = minlen

      if mn.length <= xp.length
        @menuPath = xp[minlen...].replace /^\//, ''
      else
        @menuDir = mn[minlen...].replace /^\//, ''

      @module = m

    @weight = max_minlen

    return yes if max_minlen

    @reject()

  expand: (request) ->
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
      req = request.clone xikiPath: @xikiPath, menuName: @menuName

      if @module.expand
        return @module.expand req

      if @module.menu
        return @module.menu req
