import json
from netaddr import IPAddress, IPNetwork

class Config:
  def __init__(self, configFile="config.js"):
    self.config = json.load(open(configFile))

  def getControlNetwork(self):
    return self.config["control_network"]

  def getControlIP(self):
    return self.config["control_ip"]

  def getMininetNetwork(self):
    return self.config["mininet_network"]

  def isInControlNetwork(self, ip):
    return IPAddress(ip) in IPNetwork(self.getControlNetwork())

  def isInMininetNetwork(self, ip):
    return IPAddress(ip) in IPNetwork(self.getMininetNetwork())
