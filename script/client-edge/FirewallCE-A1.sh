#!/bin/bash

export AS=enp0s3
export LAN=macsec0

sudo iptables -F # flush already present entries
sudo iptables -F -t nat

sudo iptables -P FORWARD DROP
sudo iptables -P INPUT DROP
sudo iptables -P OUTPUT ACCEPT

# Consentire il traffico tra LAN e rete esterna solo se avviato dalla LAN, 
sudo iptables -A FORWARD -i $LAN -o $AS -j ACCEPT
# con traduzione dinamica dell'indirizzo sorgente
sudo iptables -t nat -A POSTROUTING -o $AS -j MASQUERADE

# Nega tutto il traffico verso GW tranne 
# ssh e ICMP solo se avviato dalla LAN
sudo iptables -A INPUT -i $LAN -p tcp --dport 22 -j ACCEPT
sudo iptables -A INPUT -i $LAN -p icmp -j ACCEPT

# Autorizza il traffico da GW verso qualsiasi luogo 
# (e i relativi pacchetti di risposta)
sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
sudo iptables -A FORWARD -m state --state ESTABLISHED -j ACCEPT
sudo iptables -A INPUT -i $AS -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -i $AS -p tcp --dport 8080 -j ACCEPT
sudo iptables -A FORWARD -i $AS -o $LAN -p tcp --dport 80 -j ACCEPT
sudo iptables -A FORWARD -i $AS -o $LAN -p tcp --dport 8080 -j ACCEPT

# Consenti il port forwarding con DNAT a 
# hostA1 e hostA2 dalla rete esterna solo per il servizio HTTP
sudo iptables -t nat -A PREROUTING -i $AS -p tcp --dport 80 -j DNAT --to-destination 10.23.0.2
sudo iptables -t nat -A PREROUTING -i $AS -p tcp --dport 8080 -j DNAT --to-destination 10.23.0.3