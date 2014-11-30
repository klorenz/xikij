"""
Print hostname of machine running xikij
"""

def menu():
  import socket
  return socket.gethostbyname()
