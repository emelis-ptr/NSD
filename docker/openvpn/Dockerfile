FROM weibeld/ubuntu-networking:latest
RUN mkdir /openvpn
RUN mkdir /.ovpn_tmp
RUN apt update
RUN apt install -y openvpn easy-rsa telnet nano traceroute wget
VOLUME /openvpn
ADD script/ovpn-server.sh /script/ovpn-server.sh
ADD script/HostB1.sh /script/HostB1.sh
ADD script/HostB2.sh /script/HostB2.sh

ADD config/openssl.cnf /usr/share/easy-rsa/openssl.cnf
ADD config/cred/server_cred /.ovpn_tmp/config/cred/server_cred
ADD config/cred/hostB2_cred /.ovpn_tmp/config/cred/hostB2_cred
ADD config/cred/ca_cred /.ovpn_tmp/config/cred/ca_cred

ADD config/ovpn/hostB2.ovpn /.ovpn_tmp/config/ovpn/hostB2.ovpn
ADD config/ovpn/server.ovpn /.ovpn_tmp/config/ovpn/server.ovpn

ADD config/ccd/hostB2 /.ovpn_tmp/config/ccd/hostB2