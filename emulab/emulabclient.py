#! /usr/bin/env python
#
# EMULAB-COPYRIGHT
# Copyright (c) 2004 University of Utah and the Flux Group.
# All rights reserved.
#
# Permission to use, copy, modify and distribute this software is hereby
# granted provided that (1) source code retains these copyright, permission,
# and disclaimer notices, and (2) redistributions including binaries
# reproduce the notices in supporting documentation.
#
# THE UNIVERSITY OF UTAH ALLOWS FREE USE OF THIS SOFTWARE IN ITS "AS IS"
# CONDITION.  THE UNIVERSITY OF UTAH DISCLAIMS ANY LIABILITY OF ANY KIND
# FOR ANY DAMAGES WHATSOEVER RESULTING FROM THE USE OF THIS SOFTWARE.
#
import re
import sys
import socket
import os
import popen2
import getopt
import string
import xmlrpclib
from M2Crypto.m2xmlrpclib import SSL_Transport
from M2Crypto import SSL

# Maximum size of an NS file that the server will accept. 
MAXNSFILESIZE = (1024 * 512)

#
# This class defines a simple structure to return back to the caller.
# It includes a basic response code (success, failure, badargs, etc),
# as well as a return "value" which can be any valid datatype that can
# be represented in XML (int, string, hash, float, etc). You can also
# send back some output (a string with embedded newlines) to print out
# to the user.
#
# Note that XMLRPC does not actually return a "class" to the caller; It gets
# converted to a hashed array (Python Dictionary), but using a class gives
# us a ready made constructor.
#
# WARNING: If you change this stuff, also change libxmlrpc.pm in this dir.
#
RESPONSE_SUCCESS        = 0
RESPONSE_BADARGS        = 1
RESPONSE_ERROR          = 2
RESPONSE_FORBIDDEN      = 3
RESPONSE_BADVERSION     = 4
RESPONSE_SERVERERROR    = 5
RESPONSE_TOOBIG         = 6
RESPONSE_REFUSED        = 7  # Emulab is down, try again later.
RESPONSE_TIMEDOUT       = 8

class EmulabResponse:
    def __init__(self, code, value=0, output=""):
        self.code     = code            # A RESPONSE code
        self.value    = value           # A return value; any valid XML type.
        self.output   = re.sub(         # Pithy output to print
            r'[^' + re.escape(string.printable) + ']', "", output)
        return

#
# Read an nsfile and return a single string.
#
def readnsfile(nsfilename, debug):
    nsfilestr  = ""
    try:
        fp = os.open(nsfilename, os.O_RDONLY)

        while True:
            str = os.read(fp, 1024)

            if not str:
                break
            nsfilestr = nsfilestr + str
            pass

        os.close(fp)

    except:
        if debug:
            print "%s:%s" % (sys.exc_type, sys.exc_value)
            pass

        print "batchexp: Cannot read NS file '" + nsfilename + "'"
        return None
        pass

    return nsfilestr

#
# Process a single command line
#
def do_method(module, method, params, password):

  def passwordCallback(*args, **kwds):
    return password

  cert = './emulab.pem'
  server = 'boss.emulab.net'
  port = 3069

  URI = "https://%s:%d%s" % (server, port, '/usr/testbed')

  ctx = SSL.Context("sslv23")
  ctx.load_cert(cert, cert, callback=passwordCallback)
  ctx.set_verify(SSL.verify_none, 16)
  ctx.set_allow_unknown_ca(0)

  # Get a handle on the server,
  server = xmlrpclib.ServerProxy(URI, SSL_Transport(ctx))

  # Get a pointer to the function we want to invoke.
  meth      = getattr(server, module + "." + method)
  meth_args = [ 0.1, params ]

  #
  # Make the call.
  #
  try:
    response = apply(meth, meth_args)
    pass
  except xmlrpclib.Fault, e:
    print e.faultString
    return (-1, None)

  #
  # Parse the Response, which is a Dictionary. See EmulabResponse in the
  # emulabclient.py module. The XML standard converts classes to a plain
  # Dictionary, hence the code below.
  rval = response["code"]

  print "-- %s" % URI
  print "-- %s" % response

  #
  # If the code indicates failure, look for a "value". Use that as the
  # return value instead of the code.
  #
  if rval != RESPONSE_SUCCESS:
    if response["value"]:
      rval = response["value"]
      pass
    pass
  return (rval, response)

def getstate(pid, eid, password):
  info = getinfo(pid, eid, password)
  if info.strip() == 'No information available.':
    return 'activating'
  else:
    return info.split('\n')[1].split(' ')[1]

def getinfo(pid, eid, password):
  show = ["nodeinfo"]
  params = {
    'proj': pid,
    'exp':  eid,
    'show': 'nodeinfo'
  }
  rval, resp = do_method("experiment", "expinfo", params, password)
  return resp['output']

def swapin(pid, eid, password):
  swapexp(pid, eid, "in", password)

def swapout(pid, eid, password):
  swapexp(pid, eid, "out", password)

def swapexp(pid, eid, direction, password):
  params = {
    'proj': pid,
    'exp':  eid,
    'direction': direction
  }
  do_method("experiment", "swapexp", params, password)

def node_avail(node_type):
  params = { 'type': node_type }
  rval, resp = do_method("node", "available", params)
  if resp['output']:
    return int(resp['output'])
  else:
    return 0

def startexp(desc, pid, eid, maxdur, ns, password):
  params = { 'proj': pid, 'exp': eid, 'description': desc, 'max_duration': maxdur, 'nsfilestr': ns, 'wait': True, 'batch': False }
  rval, resp = do_method("experiment", "startexp", params, password)
  return rval

def endexp(pid, eid, password):
  params = { 'proj': pid, 'exp': eid, 'wait': True }
  rval, resp = do_method("experiment", "endexp", params, password)
  return rval
