@doc = """
  Handle Menus.  Menus are simple extensions to xiki-Ray.
  You have multiple opportunities to add active content to a menu.
  """

class @Menu extends xiki.Context
  _matchPath: (a, b) ->
    minlen = min(a.length, b.length)
    if a[...minlen] == b[...minlen]
      if a.length < b.length
        b[minlen...]
      else
        a[m]

  does: (xikiRequest, xikiPath) ->
    #return false unless xikiPath
    @xikiPath = xikiPath
    @menuName = xp = xikiPath.toPath().replace(/^\//, '').replace(/\/$/, '')
    @menuPath = null
    @menuDir  = null

    console.log "Menu Requ", xikiRequest
    console.log "Menu Path", xikiPath

    xp = xikiPath.toPath().replace(/^\//, '').replace(/\/$/, '')

    max_minlen = 0
    for m in xiki.packages.modules()
      console.log "mod", m
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

    return yes if max_minlen

    return no

  expand: (request) ->
    console.log "menu: expand", request

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
      console.log "cloning request"
      req = request.clone xikiPath: @xikiPath, menuName: @menuName

      if @module.expand
        return @module.expand req

      if @module.menu
        return @module.menu req
