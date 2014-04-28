import Pyro4
from mininet.net import Mininet
from mininet.node import Node
from mininet.util import quietRun
from mininet.log import info, error, debug, output
from time import sleep
from ..util import waitForOnenetManager
import signal

def monkeypatch(cls):
  def decorator(func):
    setattr(cls, func.__name__, func)
    return func
  return decorator

@monkeypatch(Node)
def getName(self):
  return self.name

@monkeypatch(Node)
def getLastPid(self):
  return self.lastPid

@monkeypatch(Mininet)
def getHosts(self):
  return self.hosts

@monkeypatch(Mininet)
def getSwitches(self):
  return self.switches

@monkeypatch(Mininet)
def getName(self):
  return self.name

@monkeypatch(Mininet)
def getNodeByNameTable(self):
  return self.nameToNode

@monkeypatch(Mininet)
def iperf( self, hosts=None, l4Type='TCP', udpBw='10M' ):
  if not quietRun( 'which telnet' ):
    error( 'Cannot find telnet in $PATH - required for iperf test' )
    return
  if not hosts:
    hosts = [ self.hosts[ 0 ], self.hosts[ -1 ] ]
  else:
    assert len( hosts ) == 2
  client, server = hosts
  output( '*** Iperf: testing ' + l4Type + ' bandwidth between ' )
  output( "%s and %s\n" % ( client.name, server.name ) )
  server.cmd( 'killall -9 iperf' )
  iperfArgs = 'iperf '
  bwArgs = ''
  if l4Type == 'UDP':
    iperfArgs += '-u '
    bwArgs = '-b ' + udpBw + ' '
  elif l4Type != 'TCP':
    raise Exception( 'Unexpected l4 type: %s' % l4Type )
  server.sendCmd( iperfArgs + '-s', printPid=True )
  servout = ''
  while server.getLastPid() is None:
    servout += server.monitor()
  if l4Type == 'TCP':
    while 'Connected' not in client.cmd(
            'sh -c "echo A | telnet -e A %s 5001"' % server.IP()):
      output('waiting for iperf to start up...')
      sleep(.5)
  cliout = client.cmd( iperfArgs + '-t 5 -c ' + server.IP() + ' ' +
                       bwArgs )
  debug( 'Client output: %s\n' % cliout )
  server.sendInt()
  servout += server.waitOutput()
  debug( 'Server output: %s\n' % servout )
  result = [ self._parseIperf( servout ), self._parseIperf( cliout ) ]
  if l4Type == 'UDP':
    result.insert( 0, udpBw )
  output( '*** Results: %s\n' % result )
  return result

@monkeypatch(Mininet)
def publishNet(self, host, pno):
  self.name = "net-%d" % pno

  print "** Waiting for the manager"
  waitForOnenetManager()
  daemon = Pyro4.Daemon(host=host)
  ns = Pyro4.locateNS()

  for node in (self.hosts + self.switches):
    uri = daemon.register(node)
    ns.register(node.name, uri)
    for intf in node.intfList():
      uri = daemon.register(intf)
      ns.register("%s-intf-%s" % (node.name, intf.name), uri)
    print "** %s published at %s" % (node.name, uri)

  uri = daemon.register(self)
  ns.register(self.name, uri)
  print "** net-%d published at %s" % (pno, uri)

  manager = Pyro4.Proxy("PYRONAME:onenet-manager")
  manager.notifyNetUp(pno, "net-%d" % pno)

  print "** Entering Pyro loop"
  daemon.requestLoop()
