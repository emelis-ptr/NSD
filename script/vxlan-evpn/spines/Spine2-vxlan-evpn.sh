#!/bin/bash

# ebgp
net add bgp autonomous-system 65000
net add bgp router-id 10.123.4.4
net add bgp neighbor swp1 remote-as external
net add bgp neighbor swp2 remote-as external
net add bgp evpn neighbor swp1 activate
net add bgp evpn neighbor swp2 activate

net commit