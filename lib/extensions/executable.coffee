###
Protocol for executables.

Basic protocol is:

```
   $ foo
   + first
   + second
   + third
```

```
   $ foo second
   - unexpandable
   + expandable
```

```
   $ foo --help
   This script does incredible things and it supports xikij interface.

```

Xikij Interface:

For simply linking programs:

- If you call the program `foo` and it returns a value != 0, it is tried to run
  `foo help`, if still != 0, it is run `foo --help`.  Output is taken and parsed.

For extension scripts:

- There are three types of interface, which you can mix
- Simple Interface:

  - call of program returns xikij code
  - call of program with path as parameter returns xikij code.

- Complex Interface:

  - script supports --xikij-capabilities option
    this returns an object

    - either xikij style or JSON or CSON
      (for start only json supported)
    - following cababilities
      - type: XikijCaps
      - format: json, cson

        list of supported formats
      - stream: stdio | off     (off)
      - start: demand | startup (demand)
      - timeout: 120

        (exit communication after seconds of inactivity, 0 means no timeout)

  - call of program returns JSON or CSON
  -

###

Q = require "q"
{isFileExecutable,getOutput} = require "../util.coffee"
console = (require "../logger")("xikij.ModuleLoader.executable")

module.exports =
  name: "executable"
  load: (subject) ->
    console.log "executable loader", subject
    deferred = Q.defer()

    isFileExecutable subject.sourceFile, (err, is_executable) =>
      if err
        deferred.reject(err)
      else if not is_executable
        deferred.resolve(false)
      else
        subject.doc = () ->
          @execute(subject.sourceFile, "--help").then (proc) ->
            getOutput(proc)

        subject.run = (request) ->
          @execute("/bin/bash", subject.sourceFile).then (proc) ->
            getOutput(proc)

        console.log "executable loaded", subject
        deferred.resolve(subject)

    return deferred.promise
