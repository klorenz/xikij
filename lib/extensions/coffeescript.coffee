Q        = require "q"
{extend} = require "underscore"
util     = require "../util"
log      = (require "../logger")("xikij.ModuleLoader.coffee")

module.exports =
  name: "coffeescript"
  load: (subject) ->
    log.log "coffeescript loader", subject
    return Q(false) if subject.menuType != "coffee"

    resolved = require.resolve subject.sourceFile

    if resolved of require.cache
      delete require.cache[resolved]

    refined = factory = require subject.sourceFile

    if factory instanceof Function
      refined = factory.call subject, @xikij

        # now xikijData may be extended or refined may have data.
        # what if both present?

      refined = subject

        # unless refined
        #   refined = xikijData

    unless refined.moduleName
      extend(refined, subject)

    for k,v of refined
      if util.isSubClass(v, @xikij.Context)
        @xikij.addContext k, v

    return Q(refined)
