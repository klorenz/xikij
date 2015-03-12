#!/usr/bin/python
#
# xikij.py
#
# this is a xikij shell, for being executed on other side of
# ssh connection, for keeping a connection open and run things
# there
#
import sys, json, os, uuid, subprocess, re
from types import GeneratorType

PY3 = sys.version_info[0] >= 3

def exec_code(code, globals=None, locals=None):
    if PY3:
        import builtins
        getattr(builtins, 'exec')(code, globals, locals)
#        exec(code, globals, locals)
    else:
        exec(code, globals, locals)

from threading import Thread, Condition, Lock

threads = {}
def shellRequest(request):
  threads[request['req']] = t = ShellRequestThread(request)
  t.start()

def xikijRequest(request):
  threads[request['req']] = t = XikijShellRequestThread(request)
  t.start()


class ProcessProvider:
  def __init__(self, process, encoding):
    self.process  = process
    self.encoding = encoding
    self.doing_input = False

  def start_input(self, reqthread):
    if self.doing_input: return

    self.doing_input = True

    def consume_input():
      for input in reqthread:
        self.process.stdin.write(input)
      self.process.stdin.close()

    Thread(target=consume_input).start()

  def output(self, reqthread, request):
    p        = self.process
    encoding = self.encoding
    line_bundle = 50

    # we rather bundle some lines to a package, then doing the
    # protocol overhead for each single line

    def _output(**kargs):
      return output(res=request['req'], **kargs)

    def consume_output(stream, name):
      i = 0
      lines = ''
      for i, line in enumerate(iter(stream.readline,'')):
        if isinstance(line, bytes):
          line = line.decode(encoding) # .replace('\r', '')

        # TODO maybe fire a funcion on timeout, which will provide data
        # earlier than 10 lines are collected, if it takes longer

        lines += line
        if i % line_bundle == 0:
          _output(chl=name, cnk=lines)
          lines = ''

        if p.poll() is not None:
          break

      data = stream.read()
      if isinstance(data, bytes):
        data = data.decode(encoding)

      if data:
        lines += data

      if lines:
        _output(chl=name, cnk=lines)

    #def

    _output(process=p.pid)

    stdout_handler = Thread(target=consume_output, args=(p.stdout, 'stdout'))
    stderr_handler = Thread(target=consume_output, args=(p.stderr, 'stderr'))

#    stdin_handler  = Thread(target=provide_input, args=(p.stdin, 'stdin'))

    stdout_handler.start()
    stderr_handler.start()
    stdout_handler.join()
    stderr_handler.join()

    _output(exit=p.wait())


outputLock = Lock()

modules = {}

def output(*args, **kargs):
  if len(args):
    object = args[0]
  else:
    object = kargs
  try:
    outputLock.acquire()
    sys.stdout.write(json.dumps(object)+"\n")
    sys.stdout.flush()
  finally:
    outputLock.release()

class XikijShell:
  """
  This is a shell to xikij methods.  It provides xikij API to python
  menu files.
  """
  def __getattr__(self, name):
    def _request(*args):
      xikijRequest({'req': str(uuid.uuidv4()), 'cmd': name, 'args': args})
    return _request

xikij = XikijShell()

class Shell:
  """
  Methods of this class will be called from Xikij to have a remote
  shell (with xikij API) e.g. on a foreign machine.
  """

  def readDir(self, path):
    return [ os.path.isdir(p) and p+"/" or p for p in os.listdir(path) ]

  def exists(self, path):
    return os.path.exists(path)

  # create a stream
  def openFile(self, path):
    fh = open(path, 'rb')
    while True:
      chunk = fh.read(8192)
      if not chunk: break
      yield chunk
    fh.close()

  #def writeFile(sel,f ):

  def isDirectory(self, path):
    return os.path.isdir(path)

  def respond(self, uuid, type, value):
    try:
      self.iolock.acquire()
      sys.stdout.write(json.dumps({'response': uuid, type: value})+"\n")
      sys.stdout.flush()
    finally:
      self.iolock.release()

  def registerModule(self, data, content):
    import imp
    modName    = data['moduleName'].replace('-', '_').replace("/", ".")
    m          = imp.new_module(modName)
    m.__file__ = data['sourceFile']
    m.os       = os
    m.re       = re
    m.sys      = sys
    #m.xikij    = Xikij

    code = compile(content, filename=data['sourceFile'], mode="exec")
    exec_code(code, m.__dict__)
    modules[data['moduleName']] = m

    result = data.copy()
    result.update({'callables': [], 'contexts': []})
    for entry in dir(m):
      if entry in ('__file__', 'os', 're', 'sys', 'xikij'): continue
      if callable(entry):
        result['callables'].append(entry)

      # if entry describes a context, also add it to contexts

    return result

  def updateModule(self, data, content):
    self.registerModule(data, content)

  def moduleRun(self, module, method, args, opts):
    return getattr(modules[data.moduleName], method)(*args, **opts)

  def shellExpand(self, string):
    return os.path.expandvars(string)

  def dirExpand(self, string): return os.path.exanduser(string)

  def execute(self, *args):
    opts = {}
    if isinstance(args[-1], dict):
      opts = args[-1]
      args = args[:-1]

    kwargs = {}
    kwargs['cwd'] = cwd = opts.get('cwd', None)
    if cwd is None:
      kwargs['cwd'] = xikij.getCwd()

    stdin = None
    if 'input' in opts:
      if opts['input'] is not None:
        stdin = opts['input']
        kwargs['stdin'] = subprocess.PIPE

    encoding = 'utf-8'
    if 'encoding' in opts:
      encoding = opts['encoding']

    if subprocess.mswindows:
      su = subprocess.STARTUPINFO()
      su.dwFlags |= subprocess.STARTF_USESHOWWINDOW
      su.wShowWindow = subprocess.SW_HIDE
      kwargs['startupinfo'] = su

    p = subprocess.Popen(list(args),
      stdout = subprocess.PIPE,
      stderr = subprocess.PIPE,
      **kwargs
      )

    if stdin:
      import errno
      try:
        p.stdin.write(stdin.encode(encoding))
      except IOError as e:
        if e.errno != errno.EPIPE:
          raise
      p.stdin.close()

    return ProcessProvider(p, encoding)


class XikijRequestThread(Thread):
  def __init__(self, request, inputAvailable=None):
    """
      request is a simple object with keys:
      - xikij: which function to call
      - context: a context may be provided
      - args: args for function to call, may be an array or dict
      - request: a uuid for request

      if you are making a request, rather than handling one, you
      have to pass inputAvailable condition.  As soon it is notified,
      you can get input from thread
    """
    Thread.__init__(self)
    self.request = request

    self.inputAvailable = inputAvailable
    self.inputDone = None
    if inputAvailable:
      self.awaitingInput = True
      self.inputConsumed  = Condition()

  def request(self, function, *args):
    xikijRequest({'xikij': function, 'args': args})

  def __iter__(self):
    if self.inputAvailable is None:
      self.inputAvailable = Condition()
      self.inputConsumed  = Condition()
      self.awaitingInput = True

    while True:
      with self.inputAvailable:
        self.inputAvailable.wait()
        yield self.input
        self.inputConsumed.notify()

        if not self.awaitingInput: break

  def input(self, request):
    if self.inputAvailable is None:
      self.inputAvailable = Condition()
      self.inputConsumed  = Condition()

    if self.process:
      self.process.start_input(self)

    if self.inputDone is None:
      self.inputDone = Condition()

    with self.inputAvailable:
      if 'cnk' in request:
        self.input = request['cnk']
      elif 'ret' in request:
        self.input = request['ret']
      elif 'input' in request:
        self.input = request['input']
      else:
        self.input = ''

      self.inputAvailable.notify()
      self.inputConsumed.wait()

      if 'ret' in request or not self.input:
        self.awaitingInput = False
        with self.inputDone:
          self.inputDone.notify()

  def output(self, object):
    output(object)

  def registerMenu(self, path):
    createMenu(path)

  def runMenu(self, menu):
    self.menus[menu]

  def run(self):
    try:
      # handle a request to xikij server
      if 'req' not in self.request:
        self.inputDone = Condition()
        self.request['req'] = str(uuid.uuid4())
        self.output(self.request)
        with self.inputDone:
          self.inputDone.wait()
        return
      # handle a request from xikij server
      else:
        attr = request['cmd']
        args = request.get('args', [])

        if isinstance(args, list):
          result = getattr(self, attr)(*args)
        else:
          result = getattr(self, attr)(**args)

        if isinstance(result, ProcessProvider):
          result.output(self, request)
          self.process = result

        elif isinstance(result, GeneratorType):
          for part in result:
            self.output({'res': request['req'], 'size': part.length, 'cnk': part})

          self.output({'res': request['req']})
        else:
          self.output({'res': request['req'], 'ret': result})
    except Exception as e:
      import traceback
      self.output({'res': request['req'], 'error': str(e), 'stack': traceback.format_exc()})

class ShellRequestThread(XikijRequestThread, Shell): pass

class XikijShellRequestThread(XikijRequestThread, XikijShell): pass

if __name__ == "__main__":
  while True:
    line = sys.stdin.readline()
    if not line: break
    request = json.loads(line)

    if 'res' in request:
      threads[request['res']].respond(request)
    else:
      if request['cmd'] == 'exit':
        for uuid in threads.keys():
          threads[uuid].join()

        output({'res': request['req'], 'ret': 'exited'})

        sys.exit(0)

      elif request['req'] in threads:
        assert 'input' in request
        threads[request['req']].input(request['input'])

      else:
        shellRequest(request)

    for uuid in threads.keys():
      if not threads[uuid].isAlive():
        del threads[uuid]

  # wait for threads to finish
  for uuid in threads.keys():
    threads[uuid].join()
