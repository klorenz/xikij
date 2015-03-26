optparse = require 'coffee-script/lib/coffee-script/optparse'
{XikijClient} = require "./client"
{Response, ResponseHandler} = require "./response"

SWITCHES = [
  ["-s", "--serve",                    "spawn xikij server if not yet running" ]
  ["-p", "--port [PORT]",              "port to listen to (XIKIJ_PORT)"]
  ["-a", "--address [ADDRESS]",        "address to listen to (XIKIJ_ADDRESS)"]
  ["-h", "--help",                     "print this help"]
  [      "--pid-file [PIDFILE]",       "path to pidfile (XIKIJ_PIDFILE)"]
  ["-r", "--root [ROOTDIR]",           "path to xikij root dir (~/.xikij) (XIKIJ_ROOT)"]
  ["-C", "--config-file [CONFIGFILE]", "path to configfile (XIKIJ_CONFIG)"]
]

BANNER = '''
usage: xikij <path>

Xikij is a xiki clone written in node.  Run `xikij help` for help.

Here you find a list of all top level commands, which you can use as <path>:
\n'''

printLine = (line) ->
  process.stdout.write("#{line}\n")

usage = ->
  printLine (new optparse.OptionParser(SWITCHES, BANNER)).help()

getLogger = require "./logger"
getLogger().setLevel("warn", propagate: yes)

main = (opts) ->
  opts = opts || {}
  {argv, stdin, stdout, stderr} = opts

  getLogger().setLevel("warn", propagate: yes)

  unless argv?
    argv = process.argv[2..]

  optionParser = new optparse.OptionParser(SWITCHES, BANNER)
  opts = optionParser.parse(argv)

#    client.request

  unless stdin?
    stdin = process.stdin

  unless stdout?
    stdout = process.stdout

  client = new XikijClient()

  unless opts.arguments.length
    stdout.write BANNER

  responseHandler = new ResponseHandler
    doDefault: (s) -> stdout.write s

  client.request(path: opts.arguments.join(" "), input: stdin)
  .then (response) =>
    responseHandler.handleResponse(response)

  .fail (error) =>
    responseHandler.handleResponse(new Response error)

module.exports =
  run: main
