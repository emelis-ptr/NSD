#!/bin/sh

# net del all
net add hostname leaf2

net add bridge bridge ports swp1,swp2
net add interface swp1 bridge access 10
net add interface swp2 bridge access 20

# ip address leaf
net add interface swp4 ip add 10.20.1.1/30
net add interface swp3 ip add 10.20.2.1/30
net add loopback lo ip add 10.123.2.2/32

# ospf
net add ospf router-id 10.123.2.2
net add ospf network 10.20.1.0/30 area 0
net add ospf network 10.20.2.0/30 area 0
net add ospf network 10.123.2.2/32 area 0
net add ospf passive-interface swp1
net add ospf passive-interface swp2

# vxlan
net add vxlan vni10 vxlan id 10
net add vxlan vni10 vxlan local-tunnelip 10.123.2.2
net add vxlan vni10 bridge access 10

net add vxlan vni20 vxlan id 20
net add vxlan vni20 vxlan local-tunnelip 10.123.2.2
net add vxlan vni20 bridge access 20

net commit
