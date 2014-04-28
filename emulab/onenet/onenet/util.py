import Pyro4
import time
import subprocess
from mininet.log import output

def getIPs():
  cmd = "ip -o -4 addr list | egrep -i -Eo '.+ inet [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | awk '{print $2 \" \" $4;}'"
  ps = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
  ips = map(lambda line: line.split(" "), ps.communicate()[0].strip().split("\n"))
  return ips

def findRootNet():
  return findPyroObjectOrNone("net-0")

def findPyroObjectOrNone(name):
  ns = Pyro4.locateNS()
  try:
    obj = ns.lookup(name)
    return Pyro4.Proxy(obj)
  except:
    return None

def pyroGetAttribute(obj, attr):
  if isinstance(obj, Pyro4.Proxy):
    return obj.__getattr__('__getattribute__')(attr)
  else:
    return obj.__getattribute__(attr)

def waitForOnenetManager():
  while True:
    time.sleep(0.5)
    try:
      ns = Pyro4.locateNS()
      if not 'onenet-manager' in ns.list():
        continue
    except Pyro4.naming.NamingError:
      continue
    else:
      break

# provides mininet functions that works with Pyro
def dumpNodeConnections( nodes ):
  "Dump connections to/from nodes."

  def dumpConnections( node ):
    "Helper function: dump connections to node"
    for intf in node.intfList():
      output( ' %s:' % pyroGetAttribute(intf, 'name') )
      link = pyroGetAttribute(intf, 'link')
      if link:
        intf1 = pyroGetAttribute(link, 'intf1')
        intf2 = pyroGetAttribute(link, 'intf2')
        intfs = [ intf1, intf2 ]
        intfs.remove( intf )
        output( pyroGetAttribute(intfs[ 0 ], 'name') )
      else:
        output( ' ' )

  for node in nodes:
    output( pyroGetAttribute(node, 'name') )
    dumpConnections( node )
    output( '\n' )

def dumpNetConnections( net ):
  "Dump connections in network"
  nodes = net.controllers + net.switches + net.hosts
  dumpNodeConnections( nodes )
