docker cp 67cd2b76de8d:/gns3volumes/openvpn/keys/ca.crt - | docker cp - e250147671ea:/gns3volumes/openvpn/keys/
docker cp 67cd2b76de8d:/gns3volumes/openvpn/keys/hostB2.crt - | docker cp - e250147671ea:/gns3volumes/openvpn/keys/
docker cp 67cd2b76de8d:/gns3volumes/openvpn/keys/hostB2.key - | docker cp - e250147671ea:/gns3volumes/openvpn/keys/
docker cp 67cd2b76de8d:/config/openssl.cnf - | docker cp - e250147671ea:/gns3volumes/openvpn/