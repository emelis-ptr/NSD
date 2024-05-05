#!/bin/sh

ip addr add 100.0.32.1/30 dev eth1
ip route add default via 100.0.32.2

sysctl -w net.ipv4.ip_forward=1

# Interface setup for VLAN 100 & VLAN 200
ip link set eth2 up
ip link add link eth2 name eth2.100 type vlan id 100
ip link add link eth2 name eth2.200 type vlan id 200

ip addr add 10.123.100.1/16 dev eth2.100
ip addr add 10.123.100.1/16 dev eth2.200

ip link set eth2.100 up
ip link set eth2.200 up

# setup for VLAN
ip route add 10.123.0.0/24 via 10.123.0.254 dev eth2.100
ip route add 10.123.20.0/24 via 10.123.20.254 dev eth2.200

echo 1 > /proc/sys/net/ipv4/ip_forward