menu = (ctx) ->
  @xiki.dialog.input("search amazon").done (query) ->
    url = "http://www.amazon.com/s?field-keywords=#{query}"
  query.on
  if query
  
