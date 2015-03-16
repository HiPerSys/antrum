from netaddr import IPNetwork, IPAddress
import socket

def inNetwork(addr, network):
    if IPAddress(addr) in IPNetwork(network):
        return True
    return False

def isValidIP(addr):
    try:
        socket.inet_aton(addr)
        return True
    except socket.error:
        return False

def getIPsInNetwork(iprange):
    for ipaddr in IPNetwork(iprange):
        print ipaddr

def getNoIPsInNetwork(iprange):
    return len(IPNetwork(iprange))
