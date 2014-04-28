from onenet.util import dumpNetConnections
from mininet.cli import CLI

print "-- dump connections"
dumpNetConnections(net)
print "-- h1: ping h2"
net.get('h1').cmd("ping -c1 10.0.1.2")
print "-- h2: ping h1"
net.get('h2').cmd("ping -c1 10.0.1.1")
