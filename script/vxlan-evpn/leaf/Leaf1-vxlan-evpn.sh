#!/bin/sh

# ebgp
net add bgp autonomous-system 65001
net add bgp router-id 10.123.1.1
net add bgp neighbor swp3 remote-as 65000
net add bgp neighbor swp4 remote-as 65000
net add bgp evpn neighbor swp3 activate
net add bgp evpn neighbor swp4 activate
net add bgp evpn advertise-all-vni

# add ip address in vteps
net add vlan 10 ip address 10.123.10.254/24
net add vlan 20 ip address 10.123.20.254/24

net add vlan 100 ip address 10.123.0.254/16
net add vlan 100 ip gateway 10.123.0.1

net add vlan 200 ip address 10.123.0.254/16
net add vlan 200 ip gateway 10.123.0.1

# Finally, to actually configure the L3VNI it is necessary to add another VLAN used only to bridge packets that enter an
# L2VNI and must exit through the L3VNI, so it is only a binding between a VLAN ID and an L3VNI:
# VXLAN interface for L3VNI
net add vxlan vni50 vxlan id 50
net add vxlan vni50 vxlan local-tunnelip 10.123.1.1
net add vxlan vni50 bridge access 50
net add vxlan vni60 vxlan id 60
net add vxlan vni60 vxlan local-tunnelip 10.123.1.1
net add vxlan vni60 bridge access 60

# Bridge VIDs and VNIs and create tenant VRF
# Configure the VRF to L3VNI mapping
net add vrf TENA vni 50
net add vlan 50 vrf TENA
net add vlan 10 vrf TENA
net add vlan 100 vrf TENA

net add vrf TENB vni 60
net add vlan 60 vrf TENB
net add vlan 20 vrf TENB
net add vlan 200 vrf TENB

net add bgp vrf TENA autonomous-system 65001
net add bgp vrf TENA l2vpn evpn advertise ipv4 unicast
net add bgp vrf TENA l2vpn evpn default-originate ipv4

net add bgp vrf TENB autonomous-system 65001
net add bgp vrf TENB l2vpn evpn advertise ipv4 unicast
net add bgp vrf TENB l2vpn evpn default-originate ipv4

net commit