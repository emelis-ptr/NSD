# Per copiare le chiavi generate dal container del server al container del client
# docker container ls
docker cp 17ea6b42d5ba:/gns3volumes/openvpn/keys/ca.crt - | docker cp - 7762e66f720b:/gns3volumes/openvpn/keys/
docker cp 17ea6b42d5ba:/gns3volumes/openvpn/keys/hostB2.crt - | docker cp - 7762e66f720b:/gns3volumes/openvpn/keys/
docker cp 17ea6b42d5ba:/gns3volumes/openvpn/keys/hostB2.key - | docker cp - 7762e66f720b:/gns3volumes/openvpn/keys/