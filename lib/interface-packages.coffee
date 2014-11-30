Q = require "q"
path = require 'path'

module.exports = (Interface, xikij) ->
  Interface.define class Packages

    userPackageUpdateMenu: (args...) -> @dispatch "userPackageUpdateMenu", args


  Interface.default class Packages extends Packages

    userPackageUpdateMenu: (opts) ->
      {menu, content, module} = opts

      debugger

      @getXikijUserDir().then (userdir) =>
        debugger

        if module?.sourceFile
          menupath = "#{userdir}/menu/#{module.menuName}.#{module.menuType}"
        else if not result?
          menupath = "#{userdir}/menu/#{menu}"

        if not path.extname(menupath)
          menupath += ".xikij"
        # else
        #   throw new Error("#{menu} is a directory")

        @makeDirs(path.dirname menupath).then (created) =>
          @writeFile(menupath, content).then =>
            debugger
            if created
              xikij.packages.add userdir
