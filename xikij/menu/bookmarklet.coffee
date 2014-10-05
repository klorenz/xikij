
menu = ({name, context, body, user}) ->
  name ?= "name"

  unless body
    # return xiki.Snippet """
    # - ${1:#{name}}
    #   // add code of bookmarklet below
    #   ${2:alert("hello world");}
    #   ${3:[submit]}
    # """

    {input, textarea, submit} = xiki.Form
    return xiki.Form [
      [ input "name", name ]
      [ text  "code of bookmarklet",
          text: (s) -> "// add #{s} below"
          html: (s) -> s[0].toUpperCase() + s[1..] ]
      [ textarea "bookmarklet", """
        alert("hello world");
        """ ]
      [ submit() ]
      ]

  # ClientOpen shall call platform's open to open a url.  If client is a browser
  # client can open this directly

  return xiki.ClientOpen "text/html", xiki.$$ ->
    @title "Bookmarklet",
    @p """
      Click the link and try it out.  Then drag teh link to your
      toolbar to create a bookmarklet:
      """,
      @a name, href: "javascript:(function(){#{bookmarklet}})"

  #return xiki.ClientPlatformOpen tempfile
