#!/bin/bash

net add hostname spine2

# spine - ip addresses
net add interface swp1 ip add 10.10.2.2/30
net add interface swp2 ip add 10.20.2.2/30
net add loopback lo ip add 10.123.4.4/32

# ospf
net add ospf router-id 10.123.4.4
net add ospf network 0.0.0.0/0 area 0

net pending
net commit