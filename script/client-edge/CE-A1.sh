#!/bin/bash

sudo sysctl -w net.ipv4.ip_forward=1

sudo ip link set enp0s3 up
sudo ip addr add 100.2.22.1/30 dev enp0s3

sudo ip route add default via 100.2.22.2

# forwarding
# sudo echo 1 > /proc/sys/net/ipv4/ip_forward
sudo bash -c 'echo 1 > /proc/sys/net/ipv4/ip_forward'