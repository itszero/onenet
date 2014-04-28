from mininet.net import Mininet
from ..util import findPyroObjectOrNone

def monkeypatch(cls):
  def decorator(func):
    setattr(cls, func.__name__, func)
    return func
  return decorator

def getOneNodeByName(net, name):
  if name in net.nameToNode:
    return net.nameToNode[name]
  else:
    return findPyroObjectOrNone(name)

@monkeypatch(Mininet)
def intakeNodes(self, networks):
  for netName in networks:
    net = findPyroObjectOrNone(netName)
    if self.name == net.getName():
      continue
    print "-- Intake nodes from %s" % net.getName()
    for h in net.getHosts():
      self.nameToNode[h.getName()] = h
      self.hosts.append(h)
    for s in net.getSwitches():
      self.nameToNode[s.getName()] = s
      self.hosts.append(s)

@monkeypatch(Mininet)
def remoteExecute(self, code):
  print "-- Executing: %s" % code
  exec(code, {'net': self})

