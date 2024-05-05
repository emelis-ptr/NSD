# Network and System Defence

Author: Melissa Petrolo

<img src=topology.png alt="">

In this project, there are 2 Autonomous Systems that provide network connectivity to five private networks. AS100
provides a BGP/MPLS VPN service for the three sites of VPN A. AS200 is a customer of AS100 and hosts an OpenVPN server
with a public IP address, used to provide an overlay VPN for the VPN client in LAN-B1.

## Table of contents

* [AS100](#as100)
    - [Router Configuration](#routers-configuration): [LSR](#lsr-router), [PE-A1](#router-pe1), PE-A2, PE-A3
* [AS200](#as200)
    - [Router Configuration](#router-configuration): RB1
    - [OpenVPN](#openvpn-configuration)
* [LAN-A1](#lan-a1)
    - [MACsec](#macsec)
    - [Firewall](#firewall-configuration): CE-A1
    - [Configuration client-edge](#ce-a1): CE-A1
    - [Configuration host](#hosta1-hosta2): HostA1, HostA2
* [LAN-A2](#lan-a2)
    - [EVPN/VCLAN](#evpnvxlan-configuration)
        - [spine](#spines)
        - [leaf](#leaves)
        - [tenants](#tenants)
    - [Configuration client-edge](#ce-a2):  CE-A2
    - [Firewall](#firewall-ce-a2): CE-A2
* [LAN-A3](#lan-a3)
    - [Configuration client-edge](#ce-a3): CE-A3
    - [Configuration host](#hosta3): HostA3
* [Test](#test-case)

## AS100

1. Setup the necessary iBGP and eBGP peerings between internal and external routers (AS 200)
2. Deploy MPLS with LDP in the AS100 core network
3. Setup BGP/MPLS VPN to realize an Intra-AS VPN that connects the three sites of VPNA
    - Site 2 is the HUB, Sites 1 and 3 are the SPOKES
    - Spoke-to-spoke connectivity is enabled through the HUB

### Routers configuration

#### [LSR Router](script/routers/LSR.cfg)

The IP interfaces were configured as follows:

* a loopback interface used for management purpose (i.e. iBGP interface)
  ```
   interface Loopback0
   ip address 1.255.0.4 255.255.0.0
  ```
* an interface used to link LSR to the PE1 router (same with pe2, pe3 router but changing ip address to GigabitEthernet
  interface) with the activation of the mpls protocol (used because packets between the two customers pass thought this
  interface):

  ```
    interface GigabitEthernet1/0
    mpls ip
    ip address 100.0.10.1 255.255.255.252
    no shutdown
   ```

* ospf configuration:
  ```
    router ospf 1
    router-id 1.255.0.4
    network 1.255.0.4 0.0.0.0 area 0
    network 100.0.10.0 0.0.0.3 area 0
    network 100.0.20.0 0.0.0.3 area 0
    network 100.0.30.0 0.0.0.3 area 0
  ```
* ldp configuration:
  ```
     mpls ldp autoconfig
  ```
* in order to make the correct advertisement of the prefix 1.0.0.0/8 a static route has also been added:
  ```
     ip route 1.0.0.0 255.0.0.0 Null0
  ```

#### [Router PE1](script/routers/PE1.cfg)

This is an example of the PE1 router, but [PE2](script/routers/PE2.cfg) and [PE3](script/routers/PE3.cfg) were also
configured the
same way by changing the ip addresses.

* a loopback interface used for management purpose (i.e. iBGP interface)
  ```
   interface Loopback0
   ip address 1.255.0.1 255.255.0.0
  ```
* the VRF for the `vpnA` VPN is defined by specifying route distinguisher and target:
   ```
     ip vrf vpnA
     rd 100:0
     route-target export 100:2
     route-target import 100:1
   ```
* an interface used to link PE1 router with others router but changing ip address to GigabitEthernet
  interface): one interface with the activation of the mpls protocol (used because packets between the two customers
  pass thought this
  interface) and one interface with vrf:
  ```
    interface GigabitEthernet1/0
    mpls ip
    ip address 100.0.10.2 255.255.255.252
    no shutdown
    !
    interface GigabitEthernet2/0
    ip address 100.0.12.2 255.255.255.252
    no shutdown
    !
    interface GigabitEthernet3/0
    ip vrf forwarding vpnA
    ip address 100.0.14.2 255.255.255.252
    no shutdown
   ```
* ospf configurations with mpls ldp:
   ```
      router ospf 1
      router-id 1.255.0.1
      network 1.255.0.1 0.0.0.0 area 0
      network 100.0.10.0 0.0.0.3 area 0
      mpls ldp autoconfig
  ```
* iBGP relationship with others routers inside the AS:
  ```
    router bgp 100
    network 1.0.0.0
    neighbor 1.255.0.2 remote-as 100
    neighbor 1.255.0.2 update-source Loopback0
    neighbor 1.255.0.2 next-hop-self
    neighbor 1.255.0.3 remote-as 100
    neighbor 1.255.0.3 update-source Loopback0
    neighbor 1.255.0.3 next-hop-self
    neighbor 100.0.12.1 remote-as 200
  ```
* the vpn4 peering:
   ``` 
      address-family vpnv4
      neighbor 1.255.0.2 activate
      neighbor 1.255.0.2 send-community extended
      neighbor 1.255.0.2 next-hop-self
      neighbor 1.255.0.3 activate
      neighbor 1.255.0.3 send-community extended
      neighbor 1.255.0.3 next-hop-self
      exit-address-family
  ```
* the BGP advertisements of vrf:
  ```
     address-family ipv4 vrf vpnA
     network 10.23.1.0 mask 255.255.255.0
     exit-address-family
  ```
* added a static route:
  ```
     ip route vrf vpnA 10.23.1.0 255.255.255.0 100.0.14.1
     ip route 1.0.0.0 255.0.0.0 Null0
  ```

## AS200

1. Setup eBGP peering with AS100
2. No need to setup OSPF between ovpn-server and RB1; static configuration is enough.

### Router configuration

#### [RB1 router](script/routers/RB1.cfg)

* a loopback interface used for management purpose (i.e. iBGP interface)
  ```
   interface Loopback0
   ip address 2.255.0.1 255.255.255.255
  ```
* an interface used to link router with others but changing ip address to GigabitEthernet
  interface):
   ```
    interface GigabitEthernet1/0
    ip address 100.0.12.1 255.255.255.252
    no shutdown
    !
    interface GigabitEthernet2/0
    ip address 2.0.0.2 255.255.255.252
    no shutdown
   ```
* iBGP relationship with others routers inside the AS:
  ```
     router bgp 200
     network 2.0.0.0
     neighbor 100.0.12.2 remote-as 100 
  ```
* added a static route:
  ```
     ip route 2.0.0.0 255.0.0.0 Null0
  ```

### OpenVPN

See configuration [here](#openvpn-configuration).

## LAN-A1

1. Setup MACsec in the LAN with MACsec Key Agreement protocol for all the devices in the LAN
2. Realize a Firewall (with iptables/NETFILTER) in CE-A1 with the following security policies:
    - Permit traffic between LAN and external network only if initiated from the LAN, with dynamic source address
      translation
    - Deny all traffic to GW except ssh and ICMP only if initiated from the LAN
    - Permit traffic from GW to anywhere (and related response packets)
    - Permit port forwarding with DNAT to hostA1 and hostA2 from the external network only for the HTTP service

### MACsec

Macsec configuration of  [CE-A1](script/client-edge/MACsecCE-A1.sh):

  ```
export MKA_CAK=00112233445566778899aabbccddeeff
export MKA_CKN=00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff

nmcli connection del test-mcsec

nmcli connection add type macsec \
con-name test-mcsec ifname macsec0 \
connection.autoconnect yes \
macsec.parent enp0s8 macsec.mode psk \
macsec.mka-cak $MKA_CAK \ 
macsec.mka-cak-flags 0 \
macsec.mka-ckn $MKA_CKN \
ipv4.method manual \
ipv4.addresses 10.23.0.1/24

nmcli connection up test-mcsec
  ```

The configuration of the
macsec [host A1](script/hosts/lanA/MacsecHostA1.sh), [host A2](script/hosts/lanA/MacsecHostA2.sh) are the
same of CE-A1.

### Firewall configuration

#### [Firewall CE-A1](script/client-edge/FirewallCE-A1.sh)

The firewall configuration is implemented in the host CE-A1 and it has the following content:

* the following line to flush the rules:
    ```
    iptables -F
    ```
* the following lines to set the default policies as DROP for INPUT, OUTPUT and FORWARD:
    ```
    iptables -P FORWARD DROP
    iptables -P INPUT DROP
    iptables -P OUTPUT DROP
  ```
* permit traffic between LAN and external network only if initiated from the LAN, with dynamic source address
  translation:
  ```
   iptables -A FORWARD -i $LAN -o $AS -j ACCEPT
   iptables -t nat -A POSTROUTING -o $AS -j MASQUERADE
  ```
* deny all traffic to GW except ssh and ICMP only if initiated from the LAN:
  ```
   iptables -A INPUT -i $LAN -p tcp --dport 22 -j ACCEPT
   iptables -A INPUT -i $LAN -p icmp -j ACCEPT
  ```
* permit traffic from GW to anywhere (and related response packets):

    ```
   iptables -A INPUT -m state --state ESTABLISHED -j ACCEPT
   iptables -A FORWARD -m state --state ESTABLISHED -j ACCEPT
   iptables -A INPUT -i $AS -p tcp --dport 80 -j ACCEPT
   iptables -A INPUT -i $AS -p tcp --dport 8080 -j ACCEPT
   iptables -A FORWARD -i $AS -o $LAN -p tcp --dport 80 -j ACCEPT
   iptables -A FORWARD -i $AS -o $LAN -p tcp --dport 8080 -j ACCEPT
    ```

* permit port forwarding with DNAT to hostA1 and hostA2 from the external network only for the HTTP service:

    ```
   iptables -t nat -A PREROUTING -i $AS -p tcp --dport 80 -j DNAT --to-destination 10.23.0.100
   iptables -t nat -A PREROUTING -i $AS -p tcp --dport 8080 -j DNAT --to-destination 10.23.0.101
    ```

### [CE-A1](script/client-edge/CE-A1.sh)

Configure the Client-Edge A1:

```
 sysctl -w net.ipv4.ip_forward=1
 ip link set enp0s3 up
 ip addr add 100.0.22.1/30 dev enp0s3
 
 ip route add default via 100.0.22.2
 ```

forwarding:

 ```
 echo 1 > /proc/sys/net/ipv4/ip_forward
 ```

### HostA1, HostA2

Same configuration of [CE-A1](#ce-a1).

## LAN-A2

LAN A2 is a leaf-spine Datacenter network with two leaves and two spines. There are 2 tenants in the cloud network, each
hosting two machines connected, one to leaf1 and the other to leaf2. The tenants are assigned with ONE broadcast domain
each; choose the broadcast domain network from the /16 private network provided in the Figure.

1. Realize VXLAN/EVPN forwarding in the DC network to provide L2VPNs between the tenants’ machines
2. In leaf1, realize an outbound connection to reach the external network and the other sites of the configured Intra-AS
   VPN.
3. Security policy (default DROP):
    - Permit traffic between LAN-A2 and the external network (including LAN-A1 and LAN-A3) only if initiated from LAN-A2
    - Permit forwarding between the spokes

### EVPN/VXLAN configuration

This section shows the _two-tier leaf-spine Clos topology_ configuration adopted within the datacenter in LAN-A2.

#### Spines

The configuration of the two spines is very similar, therefore only the one relating to
the [spine 1](script/vxlan-evpn/spines/Spine1.sh) is considered.

The following commands are used to configure the IP addresses:

```
net add interface swp1 ip add 10.10.1.2/30
net add interface swp2 ip add 10.20.1.2/30
net add loopback lo ip add 10.123.3.3/32
```

OSPF configuration:

```
net add ospf router-id 10.123.3.3
net add ospf network 0.0.0.0/0 area 0
```

BGP configuration ([spine 1](script/vxlan-evpn/spines/Spine1-vxlan-evpn.sh)):

```
net add bgp autonomous-system 65000
net add bgp router-id 10.123.3.3
net add bgp neighbor swp1 remote-as external
net add bgp neighbor swp2 remote-as external
```

Activation of the BGP EVPN extension:

```
net add bgp evpn neighbor swp1 activate
net add bgp evpn neighbor swp2 activate
```

Finally, EVPN was configured as a control plane for network virtualization with VXLAN, using the MP-eBGP mechanism in
which:

- the spines are placed in the private AS 65000;
- leaf 1 is placed in private AS 65001;
- leaf 2 is placed in private AS 65002.

#### Leaves

Below is the configuration of [leaf 1](script/vxlan-evpn/leaf/Leaf1.sh) because, except for the addresses, it is
also valid for
[leaf 2](script/vxlan-evpn/leaf/Leaf2.sh), with the difference
that the leaf 1 has additional configurations.

Creation of a VLAN-aware bridge:

```
net add bridge bridge ports swp1,swp2,swp5
net add interface swp1 bridge access 10
net add interface swp2 bridge access 20
```


Adding the point-to-point addresses and the loopback address:

```
net add interface swp3 ip add 10.10.1.1/30
net add interface swp4 ip add 10.10.2.1/30 
net add loopback lo ip add 10.123.1.1/32
```

OSPF configuration:

```
net add ospf router-id 10.123.1.1
net add ospf network 10.10.1.0/30 area 0
net add ospf network 10.10.2.0/30 area 0
net add ospf network 10.123.1.1/32 area 0
net add ospf passive-interface swp1
net add ospf passive-interface swp2
net add ospf passive-interface swp5
```

Local-tunnel IP specification (so the source IP in the outer header of the VXLANs) and bridge instruction to create a
mapping such that all packets tagged with a VLAN ID go into the corresponding VXLAN
tunnel:

```
net add vxlan vni10 vxlan id 10
net add vxlan vni10 vxlan local-tunnelip 10.123.1.1
net add vxlan vni10 bridge access 10

net add vxlan vni20 vxlan id 20
net add vxlan vni20 vxlan local-tunnelip 10.123.1.1
net add vxlan vni20 bridge access 20
```

In the EVPN configuration ([leaf 1](script/vxlan-evpn/leaf/Leaf1-vxlan-evpn.sh)).
BGP configuration:

```
net add bgp autonomous-system 65001
net add bgp router-id 10.123.1.1
net add bgp neighbor swp3 remote-as 65000
net add bgp neighbor swp4 remote-as 65000
```

Activation of the BGP EVPN extension and export of VNI routes:

```
net add bgp evpn neighbor swp3 activate
net add bgp evpn neighbor swp4 activate
net add bgp evpn advertise-all-vni
```

Add ip addresses in vteps:

```
net add vlan 10 ip address 10.123.0.254/24
net add vlan 20 ip address 10.123.20.254/24

net add vlan 100 ip address 10.123.100.254/16
net add vlan 100 ip gateway 10.123.100.1

net add vlan 200 ip address 10.123.100.254/16
net add vlan 200 ip gateway 10.123.100.1
```

Configure the switch virtual interfaces:

```
net add vlan 10 vrf TENA
net add vlan 20 vrf TENB
net add vlan 100 vrf TENA
net add vlan 200 vrf TENB

net add bgp vrf TENA autonomous-system 65001
net add bgp vrf TENA l2vpn evpn advertise ipv4 unicast
net add bgp vrf TENA l2vpn evpn default-originate ipv4

net add bgp vrf TENB autonomous-system 65001
net add bgp vrf TENB l2vpn evpn advertise ipv4 unicast
net add bgp vrf TENB l2vpn evpn default-originate ipv4
```

#### Tenants

There are 2 tenants in the cloud network, each hosting two machines connected, one to leaf1 and the other to leaf2. The
tenants are assigned with ONE broadcast domain each.

The VMs were emulated by creating namespaces and adding different VLAN interfaces for each namespace.

The configuration of the two tenants is very similar, therefore only the one relating to the machine is considered. You
can find the different tenant configurations here: [tenants](script/vxlan-evpn/end-hosts). But now let's consider only one
machine of one tenant [tAmv1](script/vxlan-evpn/end-hosts/tAvm1.sh).

```
ip addr add 10.123.0.1/24 dev eth1
ip route add default via 10.123.0.254
```

### CE-A2

The configuration of [CE-A2](script/client-edge/CE-A2.sh) is the same as [CE-A1](#ce-a1).

### [Firewall CE-A2](script/client-edge/FirewallCE-A2.sh)

* the following lines to set the default policies as DROP for INPUT, OUTPUT and FORWARD:
    ```
    iptables -P FORWARD DROP
    iptables -P INPUT DROP
    iptables -P OUTPUT DROP
   ```
* permit traffic between LAN-A2 and the external network (including LAN-A1 and LAN-A3) only if initiated from LAN-A2:

    ```
    iptables -t nat -A POSTROUTING -o eth1 -j MASQUERADE
    ```

* permit forwarding between the spokes:
  ```
   iptables -A FORWARD -s 10.123.3.3/24 -d 10.123.4.4/24 -j ACCEPT
   iptables -A FORWARD -s 10.123.4.4/24 -d 10.123.3.3/24 -j ACCEPT 
  ```

## LAN-A3

LAN-A3 is Site 3 of the BGP/MPLS VPN in which there is just a Customer Edge, facing AS200, and one device in the private
network. The device is sensitive, so it must be configured to use Mandatory Access Control.

### CE-A3

The configuration of [CE-A3](script/client-edge/CE-A3.sh) is the same as [CE-A1](#ce-a1).

### HostA3

Same configuration of [HostA1, HostA2](#hosta1-hosta2).

In this case the device is sensitive, so Mandatory Access Control with **AppArmor** was used and has been configured
through Docker.

AppArmor is an easy-to-use Linux Security Module implementation that restricts applications’ capabilities and
permissions with profiles. t uses profiles of an application to determine what files and permissions the application
requires.

To mount the system:

```
mount -tsecurityfs securityfs /sys/kernel/security
```

AppArmor profiles are simple text files located in /etc/apparmor.d/. In this case,
we have used an example like this:

- /etc/apparmor.d/bin.ping is the AppArmor profile for the /bin/ping command.

To create a new profile, create the bin.ping file inside the /etc/apparmor.d profile directory:

```
#include <tunables/global>
profile ping /{,usr}/bin/ping {
  #include <abstractions/base>
  #include <abstractions/consoles>
  #include <abstractions/nameservice>

  deny capability net_raw,
  capability setuid,
  network inet raw,
  network inet6 raw,

  /{,usr}/bin/ping mixr,
  /etc/modules.conf r,

}
```

To view the **current status** of AppArmor profiles:

```
apparmor_status
```

**aa-enforce** places a profile into enforce mode:

```
aa-enforce /etc/apparmor.d/bin.ping
```

**apparmor_parser** is used to load a profile into the kernel. It can also be used to reload a currently-loaded profile using the -r option after modifying it to have the changes take effect.
To reload a profile:

```
apparmor_parser -r /etc/apparmor.d/bin.ping
```

## OpenVPN Configuration

OpenVPN with one server and one client. The server is in AS200, with a public IP taken from the 2.0.0.0/8 network.
The client is host-B2, behind the private network in LANB2. The OpenVPN server provides access to LAN-B1 to which it
serves as the gateway.

### Certification managment

1. Download one of releases of EasyRSA (e.g., `v.3.1.0`):
   ```
   wget https://github.com/OpenVPN/easy-rsa/releases/download/v3.1.0/EasyRSA-3.1.0.tgz && tar xf EasyRSA-3.1.0.tgz && cd EasyRSA-3.1.0/
   ```
2. Initialize easy-rsa and create CA certificate:
    ```
    ./easyrsa init-pki && ./easyrsa build-ca
    ```

3. Generate a certificate and the private key of server:
    ```
    ./easyrsa build-server-full server
    ```
4. Generate certificates and keys for clients:
   ```
   ./easyrsa build-client-full client1 && ./easyrsa build-client-full client2
   ```

5. Generate Diffie-Hellman parameters for OpenVPN:
   ```
   ./easyrsa gen-dh
   ```

### Server Configuration

The network part of [server configuration](script/openvpn/ovpn-server.sh) is the following:

- the following lines to configure the network towards the WAN:
   ```
   ip link set eth0 up
   ip link set eth1 up
  
   ip addr add 2.0.0.1/24 dev eth1 2>/dev/null
   ip addr add 192.168.17.2/24 dev eth0 2>/dev/null   
   ip route add default via 2.0.0.2 2>/dev/null   
   
   iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
    ```
- since that the server receives packets not as end point, it must be able to forward packet:
    ```
    echo 1 > /proc/sys/net/ipv4/ip_forward
    ```

The OpenVPN part of [server configuration](script/openvpn/conf/server.ovpn) is the following:

- the following lines to set the listening port for the server is 1194, the encapsulation format is udp and the virtual
  interface is tun:
    ```
    port 1194
    proto udp
    dev tun
    ```
- the following lines to set the path of generated files in the phase of certification management:
    ```
    ca keys/ca.crt
    cert keys/server.crt
    key keys/server.key
    dh keys/dh2048.pem
    ```
- the following line to tell OpenVPN to run as a server instance and to allocate a 192.168.100.0/24 VPN address range
  and the servers' virtual adapter has ip 192.168.100.1 beacuse is the first valid ip address:
    ```
    server 192.168.100.0 255.255.255.0
    ```
- the following line tells each client that if they need to send a packet to the 2.0.0.0/11 network they must pass it to
  the OpenVPN process
    ```
    push "route 192.168.17.0 255.255.255.0"
    ```
- the following line has the same role of previous line, but it is for the server:
    ```
    route 192.168.16.0 255.255.255.0
    ```
- the following line to set the path to the per-client specific configuration directory:
    ```
    client-config-dir ccd
    ```
- the following line to tell that the ping every 10 seconds and assume that remote peer is down if no ping received
  during a 120 second time period:
    ```
    keepalive 10 120
    ```
- the cipher:
     ```
    cipher AES-256-CBC
    ```

### Client configuration

The network part of [client configuration](script/hosts/lanB/HostB2.sh) is the following:

```
ip link set eth0 up
ip addr add 192.168.16.1/24 dev eth0
ip route add default via 192.168.16.2
```
The OpenVPN part of [client configuration](docker/openvpn/config/ovpn/hostB2.ovpn) is composed by:

- the following lines to tell that it is a OpenVPN client, the encapsulation format is udp and the virtual interface is
  tun:
    ```
    client
    dev tun
    proto udp
    ```
- the following line to set 2.0.0.2 as server ip address and 1194 as server listening port:
    ```
    remote 2.0.0.1 1194
    resolv-retry infinite
   ```
- the following lines to set the path of generated files in the phase of certification management:
    ```
   ca keys/ca.crt
   cert keys/hostB2.crt
   key keys/hostB2.key
    ```
- the cipher:
   ```
    remote-cert-tls server
    cipher AES-256-CBC
   ```

## Test Case

### BGP/MPLS VPN

Examine MPLS forwarding table beetween routers with:

```
show mpls forwarding-table
```

Examine the routes associated with VPN:

```
show ip route vrf customers
```

### SPOKE -> SPOKE

With the following command check the correct route of the packet in a router:

```
show ip route vrf vpnA

show ip bgp vpnv4 vrf vpnA labels
```

### OverlayVPN

From HostB2:

- ping the server:
    ``` 
    ping 2.0.0.1
    ```

- ping HostB1:
    ``` 
    ping 192.168.17.1
    ```

### EVPN/VXLAN

Examine the number of remote VTEPs for each VNI from the leaves (_it should be different from 0 for VNI 10 and VNI 20_):

```
net show evpn vni
```

For each VNI, check the correct type (e.g. _L2 for VNI 10 and L3 for VNI 1020_).

Check the presence of the default type-5 route in the BGP RIB of the leves:

```
net show bgp evpn route
```

Check VLAN membership for that port:

```
net show bridge vlan
```

From tAvm1 ping tAvm2:

``` 
ping 10.123.0.2
```
