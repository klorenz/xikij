module.exports = (xikij) ->
  @doc = """
    Handle Menus.  Menus are simple extensions to xiki-Ray.
    You have multiple opportunities to add active content to a menu.
    """

  Q    = xikij.Q
  Path = xikij.Path

  class @Menu extends xikij.Context
    _matchPath: (a, b) ->
      minlen = min(a.length, b.length)
      if a[...minlen] == b[...minlen]
        if a.length < b.length
          b[minlen...]
        else
          a[m]

    rootMenuItems: () ->

      # in future rather return object
      # tree = {}
      # for m in xikij.packages.modules()
      #   insertToTree.call tree, Path.split(m.menuName), m
      #
      # Q(tree)

      result = []

      for m in xikij.packages.modules()
        r = m.menuName.replace(/\/.*/, '')
        result.push r unless r in result
      Q(result)

    isMenuItem: ->
      return @menuItem.menuName?

    menuExpand: (req) ->
      if @menuItem.expanded
        return @menuItem.expand req

      if @menuItem.expand
        return @menuItem.expand req

      if @menuItem.run
        return @menuItem.run.call @, req

      # else it is an object
      return @menuItem

    does: (request, reqPath) ->
      return no if reqPath.rooted()

      #@menuName = reqPath.toPath().replace(/\/$/, '').replace(/[:*?]\//, '/').replace(/:$/, '')

      @weight = null

      path = new Path(reqPath.toPath()
              .replace(/\/$/, '')
              .replace(/[:*?]\//, '/')
              .replace(/:$/, '')
              )

      try
        path.selectFromTree(
          xikij.packages.getModule(),
          found: (o, p, i) =>

            console.debug "found", o, p, i
            if o.moduleName?
              @weight   = reqPath[..i].toPath().length
              @menuName = o.menuName
              @menuItem = o
              @menuPath = p[i+1..]
              return true
          )
        return yes

      catch error
        console.log "warning in menu.does:", error.stack

      return no

      #return false unless reqPath
      @path = reqPath
      @menuName = rp = reqPath.toPath().replace(/\/$/, '').replace(/[:*?]\//, '/').replace(/:$/, '')
      @menuPath = null
      @menuDir  = null

      #try


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
      if not @self('isMenuItem')()
        return @self "menuItem"

      menuPath = @self "menuPath"
      menuItem = @self "menuItem"

      if menuPath.empty()
        if menuItem.doc instanceof Function
          return menuItem.doc()
        else
          return menuItem.doc

      return "Not implemented to get doc from sub-items"


      if @menuDir?
        """
        A collection of menus.  Hit #{xikij.keys.expand} to list available menus.
        """
      else if @menuPath?
        if @menuPath
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
          if @module.doc instanceof Function
            return @module.doc()
          else
            return @module.doc

    expanded: (request) ->
      @
      path     = @self "menuPath"
      menuItem = @self "menuItem"
      menuName = menuItem.menuName

      if not path.empty()

        if path.first().replace(/^\./, '') of menuItem

          return path.selectFromObject menuItem,
            transform: (frag) -> frag.replace /^\./, ''
            caller:    (func, path) -> func request.clone {path, menuName}

      req = request.clone {path, menuName}

      # if @menuItem.expanded
      #   return @menuItem.expand req
      #
      # if @menuItem.expand
      #   return @menuItem.expand req

      if menuItem.run
        return menuItem.run.call @, req

      # else it is an object
      return menuItem


    getSubject: (req) ->
      menuItem = @self "menuItem"
      if menuItem.menuName
        if menuItem.init
          Q(menuItem.init()).then (value) => value ? menuItem
        else
          Q(menuItem)
      else
        Q(null)

      # if @menuPath?
      #   Q(null)
      # else
      #   Q(@module)
