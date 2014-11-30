coffee = require("coffee-script/register")
module.exports = require("./xikij")
module.exports.run = function (opts) {
  return require("./xikij-cli").main(opts)
}
