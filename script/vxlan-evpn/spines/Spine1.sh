#!/bin/sh

net add hostname spine1

# spine - ip addresses
net add interface swp1 ip add 10.10.1.2/30
net add interface swp2 ip add 10.20.1.2/30
net add loopback lo ip add 10.123.3.3/32

# ospf
net add ospf router-id 10.123.3.3
net add ospf network 10.123.3.3/32 area 0
net add ospf network 10.10.1.0/30 area 0
net add ospf network 10.20.1.0/30 area 0
net add ospf network 0.0.0.0/0 area 0

net pending
net commit