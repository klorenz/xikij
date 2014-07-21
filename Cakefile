{spawn, exec} = require 'child_process'

path = require 'path'
fs   = require 'fs'

node = process.argv[0]

run = (args, cb) ->
  coffee = path.resolve(path.normalize('node_modules/.bin'), '/usr/local/bin', '/usr/bin', 'coffee')
  coffee = "/usr/local/bin/coffee"

  console.log "coffee: #{coffee}"

  proc = spawn node, [ coffee ].concat args
  proc.stderr.on 'data', (buffer) -> console.log buffer.toString()
  proc.on        'exit', (status) ->
    process.exit(1) if status != 0
    cb() if typeof cb is 'function'

run_test = (node) ->
  jasmine = spawn node, [
    # '--harmony_collections'
    "node_modules/.bin/jasmine-node"
    '--coffee'
    '--captureExceptions'
    'spec'
  ]
  jasmine.stderr.on 'data', (data) ->
    process.stderr.write data.toString()
  jasmine.stdout.on 'data', (data) ->
    process.stdout.write data.toString()
  jasmine.on 'exit', (code) ->
    callback?() if code is 0

task "test", "run test specs", ->
  run_test node

task "debug", "run test specs in debug mode", ->
  run_test "#{node}-debug"

task "build", "build syntax tools", ->
  for file in fs.readdirSync "src"
    console.log file
    if /\.coffee\.md$/.test(file)
      lines = (fs.readFileSync "src/#{file}").toString().split(/\n/)
      isCoffee = false
      out = []
      for line in lines
        if line.match /^```coffee/
          isCoffee = true
          out.push "# ```coffee"
          continue

        if isCoffee and line.match /^\s*\# example/
          isCoffee = false
        if isCoffee and line.match /^```$/
          isCoffee = false

        if isCoffee
          out.push line
        else
          out.push "# "+line

      outfile = path.basename(file, ".md")
      fs.writeFileSync("/tmp/"+outfile, out.join("\n")+"\n")
      run ['-c', '-o', 'lib', '/tmp/'+outfile]

    if /\.coffee$/.test(file)
      run ['-c', '-o', 'lib', 'src/'+file]
