module.exports = (Interface) ->
  Interface.define class Actions
    # ### expand
    #
    expand: (req) -> @context.expand req

    collapse: (req) -> @context.collapse req

    expanded: (req) -> @context.expanded req

    complete: (req) -> @context.complete req

    isAction: (name) -> name in ['expand', 'collapse', 'expanded', 'complete']


  Interface.default class Actions extends Actions

    expand: (req) -> ""

    collapse: (req) -> null

    expanded: (req) -> @expand req

    complete: (req) -> null
