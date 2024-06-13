#!/bin/sh

iptables -F
iptables -t nat -F
iptables -X

iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

export LAN=eth0
export NET=eth1

# Permetti il traffico in uscita dalla LAN-A2 verso la rete esterna
iptables -A FORWARD -i $LAN -o $NET -j ACCEPT
iptables -A FORWARD -s 10.123.0.0/16 -o $NET -j ACCEPT
# Permetti il traffico di risposta alle connessioni stabilite
iptables -A FORWARD -m state --state ESTABLISHED -j ACCEPT

# Configura il MASQUERADE per il traffico in uscita su eth1 (rete esterna)
iptables -A POSTROUTING -t nat -o eth1 -j MASQUERADE

# Permetti il traffico di forward tra gli spoke (LAN-A1 e LAN-A3)
iptables -A FORWARD -s 10.23.0.0/24 -d 10.23.1.0/24 -j ACCEPT
iptables -A FORWARD -s 10.23.1.0/24 -d 10.23.0.0/24 -j ACCEPT

