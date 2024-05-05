#!/bin/sh

# net del all
net add hostname leaf1

net add bridge bridge ports swp1,swp2,swp5
net add interface swp1 bridge access 10
net add interface swp2 bridge access 20
net add bridge bridge pvid 1
net add bridge bridge vids 10,20,100,200

# leaves - ip addresses
net add interface swp3 ip add 10.10.1.1/30
net add interface swp4 ip add 10.10.2.1/30
net add loopback lo ip add 10.123.1.1/32

# ospf
net add ospf router-id 10.123.1.1
net add ospf network 10.10.1.0/30 area 0
net add ospf network 10.10.2.0/30 area 0
net add ospf network 10.123.1.1/32 area 0
net add ospf passive-interface swp1
net add ospf passive-interface swp2

# vxlan
net add vxlan vni10 vxlan id 10
net add vxlan vni10 vxlan remoteip 10.123.2.2
net add vxlan vni10 vxlan local-tunnelip 10.123.1.1
net add vxlan vni10 bridge access 10

net add vxlan vni20 vxlan id 20
net add vxlan vni20 vxlan remoteip 10.123.2.2
net add vxlan vni20 vxlan local-tunnelip 10.123.1.1
net add vxlan vni20 bridge access 20

net commit