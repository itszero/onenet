import Pyro4
import sys
import subprocess
import thread
from onenet.util import waitForOnenetManager

Pyro4.config.SERIALIZERS_ACCEPTED = set(['pickle'])
Pyro4.config.SERIALIZER = 'pickle'

print "** Waiting for the manager"
waitForOnenetManager()

manager = Pyro4.Proxy("PYRONAME:onenet-manager")
cmd = ' '.join(sys.argv[2:])

print "** Sending log: %s" % cmd
proc = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

def send_log(manager, io):
  while True:
    line = io.readline()
    if not line:
      break
    line = line.strip()
    manager.putLog(sys.argv[1], line)
    sys.stdout.write(line + "\n")

thread.start_new_thread(send_log, (manager, proc.stderr))
send_log(manager, proc.stdout)
