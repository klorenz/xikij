path   = require 'path'
os     = require 'os'
uuid   = require 'uuid'
fs     = require 'fs'
stream = require 'stream'

module.exports = (Interface) ->

  Interface.define class FileSystem

    isDirectory: (args...) -> @context.isDirectory args...
    readDir:   (args...) -> @context.readDir args...
    exists:    (args...) -> @context.exists args...

    # walk path
    walk:      (args...) -> @context.walk args...

    # return time of last modification of path
    getmtime:  (args...) -> @context.getmtime args...

    # write content to file at path
    writeFile: (args...) -> @context.writeFile args...

    openFile: (args...) -> @context.openFile args...

    # read first count bytes/chars from file.  if no count given, return entire
    # content
    readFile:  (args...) -> @context.readFile args...

    # return current working directory
    getCwd:    (args...) -> @context.getCwd args...

    makeDirs:  (args...) -> @context.makeDirs args...

    listDir:   (args...) -> @context.listDir args...

    # create a temporary file
    tempFile:  (args...) -> @context.tempFile args...

    # remove
    remove:    (args...) -> @context.remove args...

    isAbs: (args...) -> @context.isAbs args...

  Interface.default class FileSystem extends FileSystem
    #
    # All methods of FileSystem interface can work in synchronous or asynchronous
    # mode.  If a callback given, automatically the asynchronous version is done.
    #
    tempFile: (name, content, options, callback) ->
      if typeof options is "function"
        callback = options
        options = {}

      unless @tmpdir
        @tmpdir = path.join (os.tmpdir or os.tmpDir)(), uuid.v4()
        @on 'shutdown', => @remove @tmpdir

      filename = path.join(@tmpdir, name)

      if callback
        myCallback = (err) ->
          callback(err, filename)
      else
        myCallback = null

      if content or content is ""
        @writeFile filename, content, options, myCallback

      filename

    cacheFile: (name, content, options, callback) ->
      @tempFile(name, content, options, callback)

    makeDirs: (dir) ->
      dirParts = dir.split("/")
      for d,i in dirParts
        continue if i is 0
        d = dirParts[..i].join("/")
        fs.mkdirSync(d) unless fs.existsSync(d)

    writeFile: (filename, content, options, callback) ->
      dirname = path.dirname(filename)
      unless @exists dirname
        @makeDirs dirname

      options = options or {}

      if typeof options is "function"
        callback = options
        options = {}

      if callback
        fs.writeFile(filename, content, options, callback)
      else
        fs.writeFileSync(filename, content, options)

    openFile: (filename) ->
      class BinaryChecker extends stream.Transform
        constructor: (@filename) ->
          super()
          @first = true

        _transform: (chunk, encoding, done) ->
          if @first
            for c,i in chunk
              if c < 7 or (c > 13 and c < 27) or (c < 32 and c > 27)
                e = new Error("File is Binary: #{@filename}")
                e.filename = filename
                throw e

            @first = false
          @push chunk
          done()

      fs.createReadStream(filename).pipe(new BinaryChecker(filename))

    readFile: (filename, options, callback) ->
      options = options or {}

      if typeof options is "function"
        callback = options
        options = {}

      if callback
        if options.count
          fs.open filename, "r", (err, fd) =>
            return callback err if err

            count = options.count
            buf = new Buffer(count)
            totalRead = 0

            reader = (err, bytesRead, buffer) =>
              if err
                fs.close fd
                callback err, buffer
              else
                totalRead += bytesRead
                if totalRead < count
                  fs.read fd, buf, totalRead, count - totalRead, totalRead, reader
                else
                  fs.close fd, ->
                    callback err, buffer

            reader null, 0, buf
        else
          fs.readFile filename, options, callback
      else
        if options.count
          fd = fs.openSync filename, "r"
          count = options.count
          buf = new Buffer(count)

          totalRead = 0
          while totalRead < count
            totalRead += fs.readSync fd, buf, totalRead, count-totalRead, totalRead

          fs.closeSync(fd)

          return buf

        else
          fs.readFileSync filename, options

    isDirectory: (filename, callback) ->
      if callback
        fs.stat filename, (stat) ->
          callback stat.isDirectory()
      else
        stat = fs.statSync filename
        return stat.isDirectory()

    readDir: (dir, callback) ->
      handleEntries = (entries) =>
        result = []
        for e in entries
          if @isDirectory path.join(dir, e)
            result.push "#{e}/"
          else
            result.push e

        result

      if callback
        fs.readdir dir, (entries) =>
          callback handleEntries entries

      entries = fs.readdirSync dir
      handleEntries entries

    exists: (filename) -> fs.existsSync(filename)

    # ## walk(dir, fileFunc, [ dirFunc,] [ options ])
    #
    # walk a tree of files and apply fileFunc to all file entries.  A directory
    # is only walked, if dirFunc is not present or returns a true value.  If
    # dirFunc returns a function, the function will be called after directory
    # entries have been processed.
    #
    # example of tree removal:
    #
    # ```coffee
    #    X.walk root,
    #       (fn) -> fs.unlinkSync(fn),
    #       (dn) -> -> fs.rmdirSync(dn)
    # ```
    #
    walk: (dir, fileFunc, dirFunc, options) ->
      options = options or {}

      # argument shift
      if dirFunc
        unless dirFunc instanceof Function
          options = dirFunc
          dirFunc = null

      exclude = options.exclude or [".git", ".hg", ".svn"]
      unless exclude instanceof Array
        exclude = [ exclude ]

      if dirFunc
        dirCallback = dirFunc dir
        return unless dirCallback

      for e in fs.readdirSync dir
        continue if e in exclude

        filename = path.join dir, e
        stat = fs.statSync(filename)

        if stat.isDirectory()
          @walk filename, fileFunc, dirFunc, options
        else
          fileFunc filename, stat, dir, e

      if typeof dirCallback is "function"
        dirCallback()

    remove: (filename, callback) ->
      if @isDirectory filename
        rmtree = ->
          try
            @walk filename,
              (fn) -> fs.unlinkSync(fn),
              (dn) -> -> fs.rmdirSync(dn)
            if callback
              callback()
          catch err
            if callback
              callback(err)

        if callback
          setTimeout rmtree, 1
        else
          rmtree()
      else
        if callback
          fs.unlink filename, callback
        else
          fs.unlinkSync filename

    getmtime: (filename) ->
      stat = fs.statSync(filename)
      return stat.mtime

    getCwd: ->
      return path.resolve(".")

    isAbs: (dir)->
      path.resolve(dir) is dir
