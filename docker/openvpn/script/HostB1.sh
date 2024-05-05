#!/bin/bash

ip link set eth0 up
ip addr add 192.168.17.1/24 dev eth0 2>/dev/null
ip route add default via 192.168.17.2 2>/dev/null
