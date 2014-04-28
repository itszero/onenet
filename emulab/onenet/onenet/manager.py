import Pyro4
import json
from threading import Lock
import sys

class Manager:
  def __init__(self):
    self.networks = set()
    self.logs = []
    self.next_log_id = 0
    self.log_lock = Lock()

  def notifyNetUp(self, pno, net_name):
    self.networks.add(net_name)
    sys.stdout.write(">> network: %s is up (%d)\n" % (net_name, len(self.networks)))

  def getNetworks(self):
    return self.networks

  def getLogs(self, since=-1):
    if since >= 0:
      return filter(lambda l: l['id'] > since, self.logs)
    else:
      return self.logs

  def putLog(self, host, log):
    self.log_lock.acquire()
    l = {'id': self.next_log_id, 'host': host, 'log': log}
    self.next_log_id = self.next_log_id + 1
    sys.stdout.write(">> log: %s\n" % json.dumps(l))
    self.logs.append(l)
    self.log_lock.release()
