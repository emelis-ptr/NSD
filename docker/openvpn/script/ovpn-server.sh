#!/bin/bash

# Configura chiavi e certificati openvpn sul Server
cd /usr/share/easy-rsa
cp openssl-1.0.0.cnf openssl.cnf
. ./vars
source ./vars
./clean-all
./build-ca #< /config/cred/ca_cred
./build-key-server server #< /config/cred/server_cred
./build-dh
./build-key hostB2 #< /config/cred/hostB2_cred
 ..
cp openscdsl.cnf /config/
# Configura le cartelle utilizzate per OpenVPN
cd /
#mkdir /gns3volumes/openvpn/ccd
cp -r /usr/share/easy-rsa/keys/ /gns3volumes/openvpn/
cp /config/ovpn/server.ovpn /gns3volumes/openvpn/server.ovpn
cp /config/ccd/hostB2 /gns3volumes/openvpn/ccd/hostB2

#rm -drf /script /script/openvpn-server.sh




