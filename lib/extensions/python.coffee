Q = require "q"

module.exports =
  name: "python"
  load: (subject) ->
    console.log "python loader", subject
    return Q(false) unless subject.menuType is "py"

    return @xikij.readFile(subject.sourceFile).then (content) =>
      content = content.toString()
      if content.match /^#!/
        # execute file for menu args-protocol
        throw new Error "not implemented"

      else
        bridge = @xikij.getBridge(subject.menuType)
        if bridge?
          return bridge.request("registerModule", subject, content)
            .then (result) =>
              module = new BridgedModule bridge, result
              #subject.pkg.modules[moduleName] = module
              #pkg.modules.push module

              for k,v of context
                if util.isSubClass(v, @xikij.Context)
                  @xikij.addContext(k,v)

              @xikij.event.emit "package:module-updated", moduleName, xikijData

              return module
            .fail (error) =>
              @handleError pkg, moduleName, error
        else
          throw new Error "not implemented"
