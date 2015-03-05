Q = require "q"

RequestContextClass = (Context, opts) ->
  {projectDirs, filePath, userDir, username} = opts

  # this implements getting things from environment
  class RequestContext extends Context
    getProjectDirs: -> Q(projectDirs or [])
    getFilePath:    ->
      unless filePath
        Q.fcall -> throw new Error("filename not defined")
      else
        Q(filePath)

    # this is home directory equivalent
    getUserDir:     -> Q(userDir or getUserHome())

    # this is system user package equivalent
    getXikijUserDir: -> @getUserName().then (username) =>
      path.join @getXikij().userPackagesDir, "user_modules", username

    # project dir is dependend on @filePath

    getSettings: (path) ->
      Q(xikij: extend({
          xikijUserDirName:    ".xikij"
          xikijProjectDirName: ".xikij"
        },
        opts))

    getUserName: -> Q(username or getUserName())

  RequestContext

module.exports = {RequestContextClass}
