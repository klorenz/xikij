module.exports = (subject) ->
  console.log "python loader", subject
  return Q(false) unless subject.menuType is "py"

  return @xikij.readFile(sourceFile).then (content) =>
    if content.match /^#!/
      # execute file for menu args-protocol
      throw new Error "not implemented"

    else
      bridge = @xikij.getBridge(suffix)
      if bridge?
        bridge.request("registerModule", xikijData, content)
          .then (result) =>
            module = new BridgedModule bridge, result
            pkg.modules[moduleName] = module
            #pkg.modules.push module

            for k,v of context
              if util.isSubClass(v, @xikij.Context)
                @xikij.addContext(k,v)

            @xikij.event.emit "package:module-updated", moduleName, xikijData
          .fail (error) =>
            @handleError pkg, moduleName, error
      else
        throw new Error "not implemented"
