#!/bin/sh

ip link set eth0 up
ip addr add 192.168.16.1/24 dev eth0
ip route add default via 192.168.16.2

# Creazione Directory OpenVPN
cd /
mkdir /gns3volumes/openvpn/keys
cp /.ovpn_tmp/config/ovpn/hostB2.ovpn /gns3volumes/openvpn/hostB2.ovpn

# rm -drf /.ovpn_tmp /script/HostB2.sh