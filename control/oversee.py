import sys
import json
import paramiko
import time
from threading import Thread, Lock
stdout_lock = Lock()

def suckPipe(chan):
  while not chan.exit_status_ready() or chan.recv_ready():
    if chan.recv_ready():
      data = chan.recv(1024)
      stdout_lock.acquire()
      sys.stdout.write(data)
      stdout_lock.release()

def shellquote(s):
  return "'" + s.replace("'", "'\\''") + "'"

def getSSHCmd(host, cmd):
  return "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no %s %s" % (host, shellquote(cmd))

def activatePhysicalNode(client, pnos):

  def eachPhysicalNode(pno):
    host = "node%d.onenet.infosphere" % pno
    cmd  = "cd onenet; sh start_node.sh %d" % pno
    _, pout, _ = client.exec_command(getSSHCmd(host, cmd))
    return pout

  return map(eachPhysicalNode, pnos)

data = json.load(sys.stdin)
pnos = set(map(lambda n: n['pno'], data['nodes']))
sys.stdout.write("** Summary:\n")
sys.stdout.write("**   %d nodes, %d switches, %d links\n" % (len(data['nodes']), len(data['switches']), len(data['links'])))
sys.stdout.write("**   %d physical machines %s\n" % (len(pnos), list(pnos)))
sys.stdout.write("\n")

sys.stdout.write("** Connecting to EMULab\n")
client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect('ops.emulab.net', username='mininet')

sftp = client.open_sftp()

sys.stdout.write("** Uploading topology\n")
with sftp.open('onenet/topo.js', 'w') as f:
  f.write(json.dumps(data))

sys.stdout.write("** Uploading experiment code\n")
with sftp.open('onenet/experiment.py', 'w') as f:
  f.write(data['code']['experiment'])

sys.stdout.write("** Uploading controller code\n")
with sftp.open('pox/pox/controller.py', 'w') as f:
  f.write(data['code']['controller'])

sys.stdout.write("** Activating physical nodes\n")
pipes = activatePhysicalNode(client, pnos)

sys.stdout.write("** Activating the control node\n")
chan = client.get_transport().open_session()
chan.exec_command(getSSHCmd("c.onenet.infosphere", "sh onenet/start_control.sh"))
thd_control = Thread(target=suckPipe, args=(chan,))
thd_control.start()
thd_control.join()
