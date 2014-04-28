from onenet.manager import Manager
from onenet import util
import Pyro4
import thread
import time
import json
import sys
from mininet.net import Mininet

Pyro4.config.SERIALIZERS_ACCEPTED = set(['pickle'])
Pyro4.config.SERIALIZER = 'pickle'

data = json.load(open(sys.argv[1]))
nets = len(set(map(lambda l: l['pno'], data['nodes'])))

manager = Manager()
daemon = Pyro4.Daemon(host="10.0.50.50")
ns = Pyro4.locateNS()
uri = daemon.register(manager)
ns.register("onenet-manager", uri)

thread.start_new_thread(lambda name, d: d.requestLoop(), ("thd-pyro", daemon))
sys.stdout.write("** manager is available on the network\n")

sys.stdout.write("** waiting for mininets (%d)\n" % nets)
while len(manager.getNetworks()) < nets:
  time.sleep(1)

sys.stdout.write("** start running the experiment\n")
try:
  net = util.findRootNet()
  net.intakeNodes(manager.getNetworks())
  # __import__('IPython').core.debugger.Pdb(color_scheme='Linux').set_trace()

  net.remoteExecute(open("experiment.py").read())
except Exception:
  sys.stdout.write("Pyro Traceback:\n")
  sys.stdout.write("".join(Pyro4.util.getPyroTraceback()) + "\n")

sys.stdout.write("** Experiment Completed\n")
sys.stdout.write("** Waiting for all logs\n")
time.sleep(5)
sys.stdout.write("** Standing down\n")
sys.exit()
