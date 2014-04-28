from mininet.net import Mininet
from mininet.log import setLogLevel
from mininet.link import Intf
from mininet.cli import CLI
from mininet.node import RemoteController
from mininet.node import CPULimitedHost
from mininet.link import TCLink
from onenet import util
from config import Config
from onenet.inject import expose
import sys
import Pyro4
import json

Pyro4.config.SERIALIZERS_ACCEPTED = set(['pickle'])
Pyro4.config.SERIALIZER = 'pickle'

def findRootSwitch(net, data):
  l = filter(lambda l: l['source'] == 'backbone' or l['target'] == 'backbone', data['links'])[0]
  return net.get(l['target'] if l['source'] == 'backbone' else l['source'])

def startLocalMininet(data, infect=False):
  config = Config()
  ip = filter(lambda ip: config.isInControlNetwork(ip[1]), util.getIPs())[0][1]
  setLogLevel('debug')
  net = Mininet(topo=None, build=False, host=CPULimitedHost, link=TCLink)
  net.addController(RemoteController('c0', ip=config.getControlIP()))

  for h in data['nodes']:
    print "-- add host: %s (%s)" % (h['name'], h['ip'])
    net.addHost(h['name'], ip=h['ip'])

  for s in data['switches']:
    print "-- add switch: %s (%s)" % (s['name'], h['ip'])
    net.addSwitch(s['name'], ip=h['ip'])

  for l in data['links']:
    if l['source'] == 'backbone' or l['target'] == 'backbone':
      continue
    opts = { k: l[k] for k in ['bw', 'delay', 'loss'] if k in l }
    if 'bw' in opts:
      opts['bw'] = int(opts['bw'])
    if 'loss' in opts:
      opts['loss'] = int(opts['loss'])
    print "-- add link: %s <-> %s %s" % (l['source'], l['target'], repr(opts))
    net.addLink(net.get(l['source']), net.get(l['target']), **opts)

  rootSwitch = findRootSwitch(net, data)
  iface = filter(lambda ip: config.isInMininetNetwork(ip[1]), util.getIPs())[0][0]
  Intf(iface, node=rootSwitch)

  net.start()
  rootSwitch.cmd("ovs-vsctl add-port %s %s" % (rootSwitch.name, iface))

  # This allows infected Mininet instances to lookup nodes via Pyro4.
  if infect:
    from onenet.inject import infect

  print "** Publishing network"
  net.publishNet(ip, data['nodes'][0]['pno'])

if __name__ == '__main__':
  pno = int(sys.argv[1])
  if sys.argv.count >= 2:
    data = json.load(open(sys.argv[2]))
    data['nodes'] = filter(lambda n: n['pno'] == pno, data['nodes'])
    data['switches'] = filter(lambda n: n['pno'] == pno, data['switches'])
    known_names = map(lambda n: n['name'], data['nodes'] + data['switches'])
    data['links'] = filter(lambda n: n['source'] in known_names or n['target'] in known_names, data['links'])
  else:
    data = {
      'nodes': [{
        'name': "h%d" % pno,
        'ip': "10.0.1.%d" % (pno + 1),
        'pno': pno
      }],
      'switches': [{
        'name': "s%d" % pno,
        'pno': pno
      }],
      'links': [{
        'source': "s%d" % pno,
        'target': 'backbone'
      }, {
        'source': "s%d" % pno,
        'target': "h%d" % pno
      }]
    }
  startLocalMininet(data, pno == 0)
