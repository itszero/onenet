#!/usr/bin/env python
from emulabclient import *
import os
import json
import sys

EMULAB_SERVER="boss.emulab.net"
EMULAB_PORT=3069
EMULAB_USER="<your user>"
EMULAB_PASSWORD="<your password>"
PID="<Your Project ID>"
EID="onenet"
MAXDUR=48
EXP_INFO="onenet"
NODETYPE="pc3000"
CERTIFICATE=os.path.join(os.path.dirname(__file__), 'emulab.pem')

def createexp(max_pno):
  if not getinfo(PID, EID, EMULAB_PASSWORD).startswith('No such experiment'):
    print "** Experiment existed. Stopping..."
    endexp(PID, EID, EMULAB_PASSWORD)
  ns = createns(max_pno)
  print "** Start experiment"
  startexp("onenet experiment", PID, EID, 48, ns, EMULAB_PASSWORD)

def createns(max_pno):
  nodes = ' '.join(['$c'] + map(lambda n: "$node%d" % n, range(0, max_pno + 1)))
  ns = "set ns [new Simulator]\nsource tb_compat.tcl\n"
  ns += "set c [$ns node]\n"
  ns += "tb-set-node-os c mininet\n"
  ns += "tb-set-hardware c pc3000\n"
  for i in range(0, max_pno + 1):
    ns += "set node%d [$ns node]\n" % i
    ns += "tb-set-node-os node%d mininet\n" % i
    ns += "tb-set-hardware node%d pc3000\n" % i
  ns += "set lan1 [$ns make-lan \" %s \" 1000Mb 0ms]\n" % nodes
  ns += "set lan2 [$ns make-lan \" %s \" 1000Mb 0ms]\n" % nodes

  ns += "tb-set-netmask $lan1 \"255.255.255.0\"\n"
  ns += "tb-set-ip-lan $c $lan1 10.0.1.254\n"
  for i in range(0, max_pno + 1):
    ns += "tb-set-ip-lan $node%d $lan1 10.0.51.%d\n" % (i, i + 1)

  ns += "tb-set-netmask $lan2 \"255.255.255.0\"\n"
  ns += "tb-set-ip-lan $c $lan2 10.0.50.50\n"
  for i in range(0, max_pno + 1):
    ns += "tb-set-ip-lan $node%d $lan2 10.0.50.%d\n" % (i, i + 1)
  ns += "$ns rtproto Static\n"
  ns += "$ns run\n"
  print ns
  return ns

createexp(int(sys.argv[1]))
