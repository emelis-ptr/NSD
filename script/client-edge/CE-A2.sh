#!/bin/sh

ip addr add 100.0.32.1/30 dev eth1
ip route add default via 100.0.32.2

sysctl -w net.ipv4.ip_forward=1

# Interface setup for VLAN 100 & VLAN 200
#ip link set eth0 up
ip link add link eth0 name eth0.100 type vlan id 100
ip link add link eth0 name eth0.200 type vlan id 200

ip addr add 10.123.0.1/16 dev eth0.100
ip addr add 10.123.0.1/16 dev eth0.200

ip link set eth0.100 up
ip link set eth0.200 up

# setup for VLAN
ip route add 10.123.10.0/24 via 10.123.0.254 dev eth0.100
ip route add 10.123.20.0/24 via 10.123.0.254 dev eth0.200

#echo 1 > /proc/sys/net/ipv4/ip_forward