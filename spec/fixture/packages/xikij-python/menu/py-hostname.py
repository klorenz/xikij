"""
Print hostname of machine running xikij
"""

def run():
  import socket
  return socket.gethostname()
