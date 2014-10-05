module.exports = (xikij) ->
  @title = "Search Amazon"

  @doc = """
     Search Amazon.  Input can be passed

     - as path

       @amazon/cool books

     - as search argument (user input)

       @amazon -- you will be asked interactively for search input

  """

  @run = (request) ->
    #@resolveInput [name: "search", title: "Search Amazon", default: ""], =>
    #   @osOpen  "http://www.amazon.com/s?field-keywords=#{search}"

    #@resolveInput name: "search", title: "Search Amazon", default: "", =>
    #   @osOpen  "http://www.amazon.com/s?field-keywords=#{search}"

    if not request.path.empty()
      input = request.path.toPath()
    else if request.args.search
      input = request.args.search
    else
      return @getUserInput name: "search", title: "Search Amazon", default: ""

    @osOpen "http://www.amazon.com/s?field-keywords=#{input}"
