path   = require 'path'
os     = require 'os'
uuid   = require 'uuid'
fs     = require 'fs'
stream = require 'stream'
Q      = require "q"

class DoesNotExist extends Error
  constructor: -> super()

class DoesExist extends Error
  constructor: -> super()

module.exports = (Interface) ->

  Interface.define class FileSystem
    DoesNotExist: DoesNotExist
    DoesExist: DoesExist

    isDirectory: (args...) -> @context.isDirectory args...
    readDir:   (args...) -> @context.readDir args...
    exists:    (args...) -> @context.exists args...
    doesExist:    (args...) -> @context.doesExist args...
    doesntExist:    (args...) -> @context.doesntExist args...

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
    tempDir:  (args...) -> @context.tempDir args...

    cacheFile:  (args...) -> @context.cacheFile args...
    cacheDir:  (args...) -> @context.cacheDir args...

    # remove
    remove:    (args...) -> @context.remove args...

    isAbs: (args...) -> @context.isAbs args...

    symLink: (args...) -> @context.symLink args...

  Interface.default class FileSystem extends FileSystem
    #
    # All methods of FileSystem interface can work in synchronous or asynchronous
    # mode.  If a callback given, automatically the asynchronous version is done.
    #
    tempFile: (name, content, options) ->
      options = {} unless options

      tmpdir = @_tempDir()

      filename = path.join(tmpdir, name)

      if content or content is ""
        return @writeFile(filename, content, options).then -> filename
      else
        return Q(filename)

    _tempDir: ->
      unless @_tmpdir
        @_tmpdir = path.join (os.tmpdir or os.tmpDir)(), "xikij", uuid.v4()
        @on 'shutdown', => @remove @_tmpdir
      @_tmpdir

    tempDir: (name, create=true) ->
      tmpdir = @_tempDir()
      if name
        dir = path.join tmpdir, name
      else
        dir = tmpdir

      if create
        @makeDirs dir
      else
        Q dir

    cacheDir: (name, create=true) ->
      @tempDir path.join("cache", name), create

    cacheFile: (name, content, options) ->
      @tempFile(path.join("cache", name), content, options)

    makeDirs: (dir) -> Q.fcall ->
      dirParts = dir.split("/")
      created = false
      for d,i in dirParts
        continue if i is 0
        d = dirParts[..i].join("/")
        unless fs.existsSync(d)
          fs.mkdirSync(d)
          created = true

      created

    writeFile: (filename, content, options) ->
      dirname = path.dirname(filename)
      options = options or {}

      @makeDirs(dirname).then ->
        deferred = Q.defer()

        fs.writeFile filename, content, options, (err) ->
          if err
            deferred.reject new Error(err)
          else
            deferred.resolve()

        deferred.promise


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

      Q.when filename, (filename) -> fs.createReadStream(filename).pipe(new BinaryChecker(filename))

    readFile: (filename, options) ->
      options = options or {}
      deferred = Q.defer()

      if options.count
        fs.open filename, "r", (err, fd) =>
          return callback err if err

          count = options.count
          buf = new Buffer(count)
          totalRead = 0

          reader = (err, bytesRead, buffer) =>
            if err
              fs.close fd, ->
                deferred.reject new Error(err)
            else
              totalRead += bytesRead
              if totalRead < count
                fs.read fd, buf, totalRead, count - totalRead, totalRead, reader
              else
                fs.close fd, ->
                  deferred.resolve(buffer)

          reader null, 0, buf
      else
        fs.readFile filename, options, (err, buffer) ->
          if err
            deferred.reject(err)
          else
            deferred.resolve(buffer)

      deferred.promise

    isDirectory: (filename) ->
      deferred = Q.defer()
      fs.stat filename, (err, stat) ->
        if err
          deferred.reject err
        else
          deferred.resolve stat.isDirectory()

      deferred.promise

    readDir: (dir) ->
      deferred = Q.defer()

      fs.readdir dir, (err, entries) =>
        if err
          deferred.reject err
        else
          promises = []
          entries.forEach (e) =>
            promises.push @isDirectory(path.join(dir, e)).then (isdir) =>
              if isdir
                "#{e}/"
              else
                e

          Q.all(promises).then (result) =>
            deferred.resolve result

      deferred.promise

    exists: (filename) -> Q.fcall ->
      result =  fs.existsSync filename
      console.log "exists?", filename, result
      result

    doesExist: (filename) -> Q.fcall ->
      throw DoesNotExist(filename) unless fs.existsSync(filename)
      true

    doesNotExist: (filename) -> Q.fcall ->
      throw DoesExist(filename) if fs.existsSync(filename)
      true

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
    # should return a promise for running functions
    # on all entries
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

      promises = []
      for e in fs.readdirSync dir
        continue if e in exclude

        filename = path.join dir, e
        stat = fs.statSync(filename)

        if stat.isDirectory()
          promises.push @walk filename, fileFunc, dirFunc, options
        else
          promises.push Q(fileFunc(filename, stat, dir, e))

      Q.all(promises).then (results) ->
        if typeof dirCallback is "function"
          dirCallback()

        return results

    remove: (filename) ->
      deferred = Q.defer()

      @isDirectory(filename).then (isdir) =>
        if isdir
          @walk filename,
            (fn) -> fs.unlinkSync(fn),
            (dn) -> -> fs.rmdirSync(dn)

        else
          Q(fs.unlinkSync(filename))

    getMTime: (filename) ->
      stat = fs.statSync(filename)
      Q.fcall -> stat.mtime

    getCwd: ->
      Q.fcall -> path.resolve(".")

    isAbs: (dir) ->
      Q.fcall -> path.resolve(dir) == dir

    symLink: (srcpath, dstpath, type) ->
      srcpath = srcpath.replace /\/$/, ''
      dstpath = dstpath.replace /\/$/, ''
      Q.fcall -> fs.symlinkSync srcpath, dstpath, type
