#!/bin/sh

ip addr add 10.123.20.1/24 dev eth1
ip route add default via 10.123.20.254