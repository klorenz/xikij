Q = require "q"
path = require 'path'

module.exports = (Interface, xikij) ->
  Interface.define class Packages

    userPackageUpdateMenu: (args...) -> @dispatch "userPackageUpdateMenu", args


  Interface.default class Packages extends Packages

    userPackageUpdateMenu: (opts) ->
      {menu, content, module} = opts

      console.log "user package update menu #{menu} -> start"

      @getXikijUserDir().then (userdir) =>

        if module?.fileName
          menupath = "#{userdir}/menu/#{module.name}.#{module.menuType}"
        else if not result?
          menupath = "#{userdir}/menu/#{menu}"

        if not path.extname(menupath)
          menupath += ".xikij"
        # else
        #   throw new Error("#{menu} is a directory")

        @makeDirs(path.dirname menupath).then (created) =>
          console.log "user package update menu #{menu} -> write file #{menupath}"

          @writeFile(menupath, content).then =>
            if created
              xikij.packages.add userdir
