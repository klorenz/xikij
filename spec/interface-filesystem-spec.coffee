path = require "path"

describe "Interface Filesystem", ->
  describe "Default Filesystem Implementation", ->
    Interface = new (require "../lib/interface")()
    Interface.load('../lib/interfaces/filesystem')
    fs = Interface.mixDefaultsInto {}, 'FileSystem'
    fixture = path.resolve(__dirname, "fixture/interface-filesystem")

    it "can walk directory trees", ->
      files = []
      fs.walk fixture, (e) ->
        files.push e.replace /.*fixture\/interface-filesystem\//, ''
      expect(files).toEqual ["file1.txt", "file2.txt", "folder1/sub1/x.md",
        "folder1/sub1/y.md", "folder1/sub2/z.md"]

    it "can skip unwanted folders", ->
      files = []

      # first method
      fs.walk fixture,
        ((e) -> files.push(e.replace /.*fixture\/interface-filesystem\//, '')),
        ((d) -> path.basename(d) != "sub1")
      expect(files).toEqual ["file1.txt", "file2.txt", "folder1/sub2/z.md"]

      files = []
      # second method
      fs.walk fixture,
        ((e) -> files.push(e.replace /.*fixture\/interface-filesystem\//, '')),
        {exclude: "sub1"}
      expect(files).toEqual ["file1.txt", "file2.txt", "folder1/sub2/z.md"]

    it "can read a file synchronously", ->
      content = null

      waitsForPromise ->
        fs.readFile(path.resolve(fixture, "file1.txt")).then (buffer) ->
          expect(buffer.toString()).toBe "content of file1\n"

    it "can read a file asynchronously", ->
      fs.readFile path.resolve(fixture, "file1.txt"), (err, content) ->
        expect(content.toString()).toBe "content of file1\n"
