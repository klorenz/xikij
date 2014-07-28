

require("coffee-script/register")

class PackageManager
  # package may contains multiple extensions
  # a package has a fixed directory structure


class ExtensionManager
  # search paths for extensions
  constructor: () ->
    @extensionDirPaths = []
    @modules = {}

    # first add all files from search paths, finally
    # install watcher for these directories.  on updating,
    # change extensions

  addFilesFromPath: (root) ->
    return unless @xiki.exists root

    #for name in @xiki.walk(root)
      # do something


  update: (extdir) ->
    return if @updating

    try
      @updating = true

      for dir in @xiki.getSearchPath(extdir)
        @addFilesFromPath(dir)

    finally
      @updating = false



class Extension


class BaseXiki extends mixOf(
  StaticVariableInterface, SettingsInterface,
  FileSystemInterface, ExecuteProgramInterface,
  CompletionInterface
  )

  constructor: (name) ->
    unless name
      name = @constructor.name
    @name = name

  #   @plugins     = {}
  #   @searchPaths = {}
  #   @cacheDir    = {}
  #   @storage     = {}
  #   @lastExitCode = {}
  #
  # extensions: () ->
  #   @_extensions.update
