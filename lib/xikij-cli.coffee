optparse = require 'coffee-script/lib/coffee-script/optparse'
{XikijClient} = require "./xikij"

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
Usage:
  xikij [options] [ path... ]
  xikij --serve [options] [path...]
  xikij --status

If you start only a xikij server, then path is not needed.

To get more help about xikij itself, run `xikij help`.

Examples:

  To get a list of top level menu items, simply run xikij.

    $ xikij

  Print status of running server.

    $ xikij --status

'''

printLine = (line) ->
  process.stdout.write("#{line}\n")

usage = ->
  printLine (new optparse.OptionParser(SWITCHES, BANNER)).help()

main = (opts) ->
  {argv, stdin, stdout, stderr} = opts

  unless argv?
    argv = process.argv[2..]

  optionParser = new optparse.OptionParser(SWITCHES, BANNER)
  opts = optionParse.parse(argv)

  unless stdin?
    stdin = process.stdin

  unless stdout?
    stdout = process.stdout

  client = new XikijClient()

  client.request(path: opts.arguments.join(" "), input: stdin).then (response) =>
    stdout.write(response)

module.exports =
  run: main
