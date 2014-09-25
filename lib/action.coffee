class Action
  constructor: (obj) ->
    for k,v of obj
      @[k] = v

module.exports = {Action}
