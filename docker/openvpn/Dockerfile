FROM weibeld/ubuntu-networking:latest
RUN mkdir /openvpn   
RUN apt update
RUN apt install -y openvpn easy-rsa telnet nano traceroute wget
VOLUME /openvpn
ADD script/ovpn-server.sh /script/ovpn-server.sh
ADD script/HostB1.sh /script/HostB1.sh
ADD script/HostB2.sh /script/HostB2.sh

ADD config/openssl.cnf /usr/share/easy-rsa/openssl.cnf
ADD config/cred/server_cred /config/cred/cred/server_cred
ADD config/cred/hostB2_cred /config/cred/hostB2_cred
ADD config/cred/ca_cred /config/cred/ca_cred

ADD config/ovpn/hostB2.ovpn /config/ovpn/hostB2.ovpn
ADD config/ovpn/server.ovpn /config/ovpn/server.ovpn

ADD config/ccd/hostB2 /config/ccd/hostB2