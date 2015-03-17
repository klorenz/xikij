Q = require "q"

module.exports =
  name: "text"
  load: (subject) ->
    return Q(false) unless subject.menuType.match /^(re?st|md|markdown|txt)$/

    return @xikij.readFile(subject.fileName).then (content) =>
      subject.content = content.toString()

      subject.run = (request) ->
        return subject.content

      subject
