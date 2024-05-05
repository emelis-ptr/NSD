#!/bin/sh

net del vxlan vni100 vxlan remoteip 10.123.1.1
net del vxlan vni200 vxlan remoteip 10.123.1.1

# ebgp
net add bgp autonomous-system 65002
net add bgp router-id 10.123.2.2
net add bgp neighbor swp3 remote-as 65000
net add bgp neighbor swp4 remote-as 65000
net add bgp evpn neighbor swp3 activate
net add bgp evpn neighbor swp4 activate
net add bgp evpn advertise-all-vni

# default route end-host
net add vlan 10 ip address 10.123.0.254/24
net add vlan 20 ip address 10.123.20.254/24

net add vlan 100
net add vlan 200

# tenant vrf
net add vlan 100 vrf TENA
net add vlan 10 vrf TENA

net add vlan 200 vrf TENB
net add vlan 20 vrf TENB

# Bridge VIDs and VNIs and create tenant VRF
net add vlan 10 vrf TENA
net add vlan 20 vrf TENB
net add vlan 100 vrf TENA
net add vlan 200 vrf TENB

net commit