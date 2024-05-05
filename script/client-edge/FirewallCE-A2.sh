#!/bin/sh

#export AS=enp0s3
#export LAN=macsec0

iptables -F

# Set default policy to DROP
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

# Permette il traffico avviato da LAN-A2 a reti esterne (incluse LAN-A1 e LAN-A3)
iptables -t nat -A POSTROUTING -o eth1 -j MASQUERADE
#iptables -A FORWARD -i 10.123.0.0 -o 1.0.0.0 -j ACCEPT
#iptables -A FORWARD -i $LAN -o $AS -j ACCEPT
#iptables -A FORWARD -s 10.123.0.0/24 -d 10.23.0.0/24 --j ACCEPT
#iptables -A FORWARD -s 10.123.0.0/24 -d 10.23.1.0/24 --j ACCEPT

# Permette il traffico di forwarding tra gli spoke
iptables -A FORWARD -s 10.23.0.0/24 -d 10.23.1.0/24 -j ACCEPT
iptables -A FORWARD -s 10.23.1.0/24 -d 10.23.0.0/24 -j ACCEPT