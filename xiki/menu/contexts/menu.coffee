doc = """
  Handle Menus.  Menus are simple extensions to xiki-Ray.
  You have multiple opportunities to add active content to a menu.
  """

class Menu extends xiki.Context
  does: (xikiRequest, xikiPath) ->
    #return false unless xikiPath

    xiki.packages.modules()
    
