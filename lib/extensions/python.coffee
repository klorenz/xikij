Q = require "q"
console = (require "../logger")("xikij.ModuleLoader.python")
{clone} = require "underscore"
{BridgedModule} = require "../xikij-bridge"

module.exports =
  name: "python"
  load: (subject) ->
    console.log "python loader", subject
    return Q(false) unless subject.menuType is "py"

    

    return @xikij.readFile(subject.fileName).then (content) =>
      content = content.toString()
      if content.match /^#!/
        # execute file for menu args-protocol
        throw new Error "not implemented"

      else
        
        bridge = @xikij.getBridge(subject.menuType)

        if bridge?
          return subject.bridged(@xikij, bridge, content)

          # xikijData = clone(subject)
          # xikijData.package = {
          #   dir: subject.package.dir
          #   name: subject.package.name
          # }
          #
          # return bridge.request(@xikij, "registerModule", xikijData, content)
          #   .then (result) =>
          #     subject.bridged bridge, result
          #     #subject.pkg.modules[moduleName] = module
          #     #pkg.modules.push module
          #
          #     # find out if there are any contexts defined
          #     # for k,v of context
          #     #   if util.isSubClass(v, @xikij.Context)
          #     #     @xikij.addContext(k,v)
          #
          #     #@xikij.event.emit "package:module-updated", moduleName, subject
          #
          #     return subject
          #   .fail (error) =>
          #     @handleError subject.package, subject.moduleName, error
        else
          throw new Error "not implemented"
