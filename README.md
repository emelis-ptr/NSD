# Network and System Defence

Author: Melissa Petrolo

<img src=topology.png alt="">

> In this project, there are 2 Autonomous Systems that provide network connectivity to five private networks. AS100
> provides a BGP/MPLS VPN service for the three sites of VPN A. AS200 is a customer of AS100 and hosts an OpenVPN server
> with a public IP address, used to provide an overlay VPN for the VPN client in LAN-B1.

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

> 1. Setup the necessary iBGP and eBGP peerings between internal and external routers (AS 200)
>2. Deploy MPLS with LDP in the AS100 core network
>3. Setup BGP/MPLS VPN to realize an Intra-AS VPN that connects the three sites of VPNA
> - Site 2 is the HUB, Sites 1 and 3 are the SPOKES
> - Spoke-to-spoke connectivity is enabled through the HUB

### Routers configuration

#### [LSR Router](script/routers/LSR.cfg)

Le interfacce IP sono state configurate come segue:

* Un'interfaccia di loopback utilizzata per scopi di gestione (ovvero interfaccia iBGP):
  ```shell
   interface Loopback0
   ip address 1.255.0.4 255.255.0.0
  ```
* Un'interfaccia utilizzata per collegare LSR al router PE1 (lo stesso vale per i router PE2, PE3 ma cambiando
  l'indirizzo IP sull'interfaccia GigabitEthernet) con l'attivazione del protocollo mpls (utilizzata perché i pacchetti
  tra i due clienti passano attraverso questa interfaccia).

  ```shell
   interface GigabitEthernet1/0
   mpls ip
   ip address 100.0.10.1 255.255.255.252
   no shutdown
  ```

> > **mpls-ip**: abilita l’uso di MPLS su una precisa interfaccia.
>>
>> **MPLS** è una tecnologia di trasporto dati utilizzata nelle reti di telecomunicazioni per velocizzare e dirigere il
> > traffico di rete.
>> - Aggiunge un'etichetta (label) ai pacchetti di dati, che è utilizzata per prendere decisioni di instradamento
     > rapide all'interno della rete.
>> - Il router di ingresso riceve un pacchetto IP, aggiunge un'etichetta MPLS e inoltra il pacchetto nella rete MPLS.
>> - I router di transito esaminano l'etichetta MPLS e utilizzano tabelle di inoltro basate su etichette (Label
     > Forwarding Information Base, LFIB) per instradare il pacchetto.
>> - Il router di uscita rimuove l'etichetta MPLS e inoltra il pacchetto IP alla destinazione finale.

* Configurazione OSPF:
  ```shell
    router ospf 1
    router-id 1.255.0.4
    network 1.255.0.4 0.0.0.0 area 0
    network 100.0.10.0 0.0.0.3 area 0
    network 100.0.20.0 0.0.0.3 area 0
    network 100.0.30.0 0.0.0.3 area 0
  ```
  **OSPF** permette ai PE di apprendere le rotte per l’instradamento interno ad AS100 utilizzando le interfacce
  di loopback (stabili), rimanendo UP a prescindere dallo stato dei link fisici.

  > >
  >> **OSPF** è un protocollo IGP (Interior gateway protocols) utilizzato per instradare i pacchetti IP all'interno di
  un
  singolo sistema autonomo (AS).
  >>
  >> E’ un protocollo di routing di tipo link state su reti IP.
  >>
  >> Utilizza il flooding (inondazione) di informazioni riguardo allo stato dei collegamenti e utilizza l'algoritmo di
  Dijkstra per la determinazione del percorso più breve a costo minimo INTRA-AS (cioè all'interno di uno stesso sistema
  autonomo).


* Configurazione LDP:
  ```shell
     mpls ldp autoconfig
  ```
  > > **LDP** è un protocollo utilizzato nelle reti MPLS per distribuire etichette (labels) tra router.
  >>
  >> I router LDP scoprono automaticamente i loro peer LDP adiacenti sulla stessa rete fisica. Questo processo avviene
  tramite pacchetti di scoperta inviati a un indirizzo multicast riservato.
  >>
  >> Una volta scoperti i peer, i router stabiliscono una sessione TCP per lo scambio delle informazioni LDP. Questa
  sessione viene utilizzata per distribuire le etichette e altre informazioni di controllo.
  >>
  >> I router utilizzano LDP per assegnare etichette a prefissi di rete IP e scambiare queste informazioni con i peer.
  Le
  etichette vengono utilizzate per creare una Label Switched Path (LSP) attraverso la rete MPLS.


* Per fare la corretta pubblicizzazione del prefisso 1.0.0.0/8 è stata aggiunta anche una rotta statica:
  ```shell
     ip route 1.0.0.0 255.0.0.0 Null0
  ```

#### [Router PE1](script/routers/PE1.cfg)

Questo è un esempio del router PE1, ma [PE2](script/routers/PE2.cfg) e [PE3](script/routers/PE3.cfg) sono stati
configurati allo stesso modo modificando gli indirizzi IP.

* un'interfaccia di loopback utilizzata per scopi di gestione (cioè interfaccia iBGP)
  ```shell
   interface Loopback0
   ip address 1.255.0.1 255.255.0.0
  ```shell
* la VRF per la VPN **vpnA** è definita specificando il route distinguisher e il target:
   ```
     ip vrf vpnA
     rd 100:0
     route-target export 100:2
     route-target import 100:1
   ```

  Il **LSR** non è configurato con BGP e realizza il forwarding tramite etichette. Questo consente di mantenere una
  rete logica full-mesh tra i PE, facilitando lo scambio corretto dei messaggi MP-iBGP e la sincronizzazione delle VRF.

  L’Hub importa le entry VRF ricevute dagli Spoke utilizzando il route-target 2 associato al RD. Ogni Spoke importa le
  entry VRF ricevute solo dall'Hub e non dagli altri Spoke, utilizzando il route-target 1 associato al RD.


* un'interfaccia utilizzata per collegare il router PE1 con altri router, ma cambiando l'indirizzo IP su un'interfaccia
  GigabitEthernet: un'interfaccia con l'attivazione del protocollo MPLS (usato perché i pacchetti tra i due clienti
  passano attraverso questa interfaccia) e un'interfaccia con VRF:
  ```shell
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
* configurazioni OSPF con MPLS LDP:
   ```shell
      router ospf 1
      router-id 1.255.0.1
      network 1.255.0.1 0.0.0.0 area 0
      network 100.0.10.0 0.0.0.3 area 0
      mpls ldp autoconfig
  ```
* relazione iBGP con altri router all'interno dell'AS:
  ```shell
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

  Il protocollo **BGP** utilizza l'interfaccia fisica PE1->RB1 per il peering eBGP con l'AS200 e le interfacce di
  loopback per i peering iBGP.

    - eBGP è attivato su RB1 e PE1 per scambiare rotte tra AS100 e AS200.
    - iBGP è attivato su tutti i PE per propagare le rotte verso AS200 all'interno della rete.

> > **BGP** è un protocollo di routing vettoriale di distanza (più specificamente un protocollo di routing vettoriale di
> > percorso).
>>
>> Si basa sui vicini per passare lungo i percorsi dalla loro tabella di routing. Il nodo effettua i calcoli del
> > percorso in base ai percorsi pubblicizzati e passa i risultati ai vicini.
>>
>> BGP utilizza un elenco di numeri AS attraverso i quali un pacchetto deve passare per raggiungere una destinazione
> > come _metrica di distanza da minimizzare_.

Utilizziamo l'interfaccia di loopback come sorgente degli aggiornamenti BGP perché le rotte in AS100 sono conosciute
tramite questi indirizzi, appresi con OSPF.

* il peering vpn4:
   ``` shell
      address-family vpnv4
      neighbor 1.255.0.2 activate
      neighbor 1.255.0.2 send-community extended
      neighbor 1.255.0.2 next-hop-self
      neighbor 1.255.0.3 activate
      neighbor 1.255.0.3 send-community extended
      neighbor 1.255.0.3 next-hop-self
      exit-address-family
  ```
  Configurazione di BGP per gli indirizzi VPNv4 che consente di stabilire nuove relazioni di peering tra tutti i PE
  connessi a una VPN.

  Utilizza l'attributo extended community per trasportare sia il RD che il RT negli annunci MP-iBGP.
  In questo modo, possiamo scambiare messaggi MP-iBGP tra i PE e filtrarli per creare una topologia hub-and-spoke.


* le pubblicità BGP della VRF:
  ```shell
     address-family ipv4 vrf vpnA
     network 10.23.1.0 mask 255.255.255.0
     exit-address-family
  ```
  Configurazione specifica di BGP per definire le rotte verso i siti della VPN gestiti da un PE, che devono essere
  esportate negli annunci MP-iBGP.

  Poiché non esiste un protocollo di routing sul link PE-CE, le rotte nella VRF devono
  essere inserite manualmente per specificare come raggiungere il sito della VPN. L’hub esporta anche la rotta per
  10.23.0.0/16 per abilitare la comunicazione tra gli spokes.


* aggiunta di una route statica:
  ```shell
     ip route vrf vpnA 10.23.1.0 255.255.255.0 100.0.14.1
     ip route 1.0.0.0 255.0.0.0 Null0
  ```
  > **ip vrf forwarding vpnA**: abilita il forwarding dei pacchetti per la BGP/MPLS VPN sull’interfaccia del PE connessa
  al CE.

## AS200

> 1. Setup eBGP peering with AS100
>2. No need to setup OSPF between ovpn-server and RB1; static configuration is enough.

### Router configuration

#### [RB1 router](script/routers/RB1.cfg)

* Un'interfaccia di loopback utilizzata per scopi di gestione (cioè interfaccia iBGP)
  ```shell
   interface Loopback0
   ip address 2.255.0.1 255.255.255.255
  ```
* Un'interfaccia utilizzata per collegare il router con altri router, ma cambiando l'indirizzo IP su un'interfaccia
  GigabitEthernet:
   ```shell
    interface GigabitEthernet1/0
    ip address 100.0.12.1 255.255.255.252
    no shutdown
    !
    interface GigabitEthernet2/0
    ip address 2.0.0.2 255.255.255.252
    no shutdown
   ```
* Relazione iBGP con altri router all'interno dell'AS:
  ```shell
     router bgp 200
     network 2.0.0.0
     neighbor 100.0.12.2 remote-as 100 
  ```
* Aggiunta di una route statica:
  ```shell
     ip route 2.0.0.0 255.0.0.0 Null0
  ```

### OpenVPN

See configuration [here](#openvpn-configuration).

## LAN-A1

> 1. Setup MACsec in the LAN with MACsec Key Agreement protocol for all the devices in the LAN
>2. Realize a Firewall (with iptables/NETFILTER) in CE-A1 with the following security policies:
>- Permit traffic between LAN and external network only if initiated from the LAN, with dynamic source address
   translation
>- Deny all traffic to GW except ssh and ICMP only if initiated from the LAN
>- Permit traffic from GW to anywhere (and related response packets)
>- Permit port forwarding with DNAT to hostA1 and hostA2 from the external network only for the HTTP service

### MACsec

Configurazione MACsec di [CE-A1](script/client-edge/MACsecCE-A1.sh):

```shell
export MKA_CAK=00112233445566778899aabbccddeeff
export MKA_CKN=00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff
```

> > **Connectivity Association Key** e **Connectivity Key Name** per la realizzazione del Key Agreement in CAK Static
> > Mode

```shell
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

Le configurazione MACsec di [host A1](script/hosts/lanA/MacsecHostA1.sh), [host A2](script/hosts/lanA/MacsecHostA2.sh)
sono gli stessi di CE-A1.

### Firewall configuration

#### [Firewall CE-A1](script/client-edge/FirewallCE-A1.sh)

> > Un **firewall** è un componente essenziale della sicurezza informatica che protegge una rete o un sistema
> > informatico
> > controllando il traffico di rete in entrata e in uscita:
>> - filtra il traffico di rete basandosi su regole predefinite. Può permettere o bloccare il traffico in base a criteri
     > come indirizzo IP, porta, protocollo e altro.
>> - protegge la rete da varie minacce, inclusi attacchi informatici, malware, spyware e intrusioni.
>> - possono monitorare il traffico di rete e registrare gli eventi di sicurezza per l'analisi successiva e per il
     > rilevamento di eventuali attività sospette.
>> - consentono di suddividere la rete in segmenti separati, noti come zone di sicurezza, per limitare l'accesso a
     > risorse
     > > sensibili solo agli utenti autorizzati.
>>
>> Le politiche di sicurezza configurate all'interno del firewall determinano come il traffico di rete viene gestito.

L’implementazione richiesta per il firewall sul GW di LAN-A1 è la seguente:

1. Permettere il traffico tra la LAN e l'esterno solo se iniziato dalla LAN con SNAT.
2. Negare tutto il traffico verso il GW tranne per SSH e ICMP solo se iniziato dalla LAN.
3. Permettere tutto il traffico dal GW verso ovunque (ed i relativi pacchetti di risposta).
4. Permettere il port-forwarding con DNAT verso hostA1 e hostA2 dall’esterno soltanto per il servizio HTTP.

La configurazione del firewall è implementata nell'host CE-A1 e ha il seguente contenuto:

* la seguente riga per pulire le regole:
    ```shell
    iptables -F
    ```
* le seguenti righe per impostare le politiche predefinite su DROP per INPUT, OUTPUT e FORWARD:
    ```shell
    iptables -P FORWARD DROP
    iptables -P INPUT DROP
    iptables -P OUTPUT DROP
  ```
* permette il traffico tra la LAN e la rete esterna solo se avviato dalla LAN, con traduzione dinamica dell'indirizzo
  sorgente:
  ```shell
   iptables -A FORWARD -i $LAN -o $AS -j ACCEPT
   iptables -t nat -A POSTROUTING -o $AS -j MASQUERADE
  ```
* nega tutto il traffico verso il GW eccetto SSH e ICMP solo se avviato dalla LAN:
  ```shell
   iptables -A INPUT -i $LAN -p tcp --dport 22 -j ACCEPT
   iptables -A INPUT -i $LAN -p icmp -j ACCEPT
  ```
* permette il traffico dal GW verso qualsiasi destinazione (e i pacchetti di risposta correlati):

    ```shell
   iptables -A INPUT -m state --state ESTABLISHED -j ACCEPT
   iptables -A FORWARD -m state --state ESTABLISHED -j ACCEPT
   iptables -A INPUT -i $AS -p tcp --dport 80 -j ACCEPT
   iptables -A INPUT -i $AS -p tcp --dport 8080 -j ACCEPT
   iptables -A FORWARD -i $AS -o $LAN -p tcp --dport 80 -j ACCEPT
   iptables -A FORWARD -i $AS -o $LAN -p tcp --dport 8080 -j ACCEPT
    ```

* permette il port forwarding con DNAT verso hostA1 e hostA2 dalla rete esterna solo per il servizio HTTP:

    ```shell
   iptables -t nat -A PREROUTING -i $AS -p tcp --dport 80 -j DNAT --to-destination 10.23.0.100
   iptables -t nat -A PREROUTING -i $AS -p tcp --dport 8080 -j DNAT --to-destination 10.23.0.101
    ```

### [CE-A1](script/client-edge/CE-A1.sh)

Configurazione del Client-Edge A1:

```shell
 sysctl -w net.ipv4.ip_forward=1
 ip link set enp0s3 up
 ip addr add 100.0.22.1/30 dev enp0s3
 
 ip route add default via 100.0.22.2
 ```

Permette il forwarding:

 ```shell
 echo 1 > /proc/sys/net/ipv4/ip_forward
 ```

### HostA1, HostA2

Stessa configurazione di [CE-A1](#ce-a1).

## LAN-A2

> LAN A2 is a leaf-spine Datacenter network with two leaves and two spines. There are 2 tenants in the cloud network,
> each
> hosting two machines connected, one to leaf1 and the other to leaf2. The tenants are assigned with ONE broadcast
> domain
> each; choose the broadcast domain network from the /16 private network provided in the Figure.
>
>1. Realize VXLAN/EVPN forwarding in the DC network to provide L2VPNs between the tenants’ machines
>2. In leaf1, realize an outbound connection to reach the external network and the other sites of the configured
    Intra-AS
    > VPN.
>3. Security policy (default DROP):
>- Permit traffic between LAN-A2 and the external network (including LAN-A1 and LAN-A3) only if initiated from LAN-A2
>- Permit forwarding between the spokes

### EVPN/VXLAN configuration

Questa sezione mostra la configurazione della topologia Clos a due livelli leaf-spine adottata all'interno del
datacenter in LAN-A2.

#### Spines

La configurazione dei due spine è molto simile, quindi viene considerata solo quella relativa
a [spine 1](script/vxlan-evpn/spines/Spine1.sh) is considered.

I seguenti comandi vengono utilizzati per configurare gli indirizzi IP:

```shell
net add interface swp1 ip add 10.10.1.2/30
net add interface swp2 ip add 10.20.1.2/30
net add loopback lo ip add 10.123.3.3/32
```

Configurazione OSPF:

```shell
net add ospf router-id 10.123.3.3
net add ospf network 0.0.0.0/0 area 0
```

Configurazione BGP ([spine 1](script/vxlan-evpn/spines/Spine1-vxlan-evpn.sh)):

```shell
net add bgp autonomous-system 65000
net add bgp router-id 10.123.3.3
net add bgp neighbor swp1 remote-as external
net add bgp neighbor swp2 remote-as external
```

Attivazione dell'estensione BGP EVPN:

```shell
net add bgp evpn neighbor swp1 activate
net add bgp evpn neighbor swp2 activate
```

Infine, EVPN è stato configurato come piano di controllo per la virtualizzazione della rete con VXLAN, utilizzando il
meccanismo MP-eBGP in cui:

- gli spine sono posizionati nel AS privato 65000
- il leaf 1 è posizionato nel AS privato 65001
- il leaf 2 è posizionato nel AS privato 65002

#### Leaves

Di seguito è riportata la configurazione di [leaf 1](script/vxlan-evpn/leaf/Leaf1.sh) b perché, ad eccezione degli
indirizzi, è valida anche per [leaf 2](script/vxlan-evpn/leaf/Leaf2.sh), con la differenza che il leaf 1 ha
configurazioni aggiuntive.

Creazione di un bridge VLAN-aware con le porte specificate e assegnando le porte alle VLAN appropriate:

```shell
net add bridge bridge ports swp1,swp2,swp5
net add interface swp1 bridge access 10
net add interface swp2 bridge access 20
```

Aggiunta degli indirizzi point-to-point e dell'indirizzo di loopback:

```shell
net add interface swp3 ip add 10.10.1.1/30
net add interface swp4 ip add 10.10.2.1/30 
net add loopback lo ip add 10.123.1.1/32
```

Configura OSPF con l'ID del router e le reti specificate, e imposta le interfacce come passive:

```shell
net add ospf router-id 10.123.1.1
net add ospf network 10.10.1.0/30 area 0
net add ospf network 10.10.2.0/30 area 0
net add ospf network 10.123.1.1/32 area 0
net add ospf passive-interface swp1
net add ospf passive-interface swp2
net add ospf passive-interface swp5
```

Configura il tunnel VXLAN e il bridge per mappare i pacchetti con un ID VLAN al tunnel VXLAN corrispondente:

```shell
net add vxlan vni10 vxlan id 10
net add vxlan vni10 vxlan local-tunnelip 10.123.1.1
net add vxlan vni10 bridge access 10

net add vxlan vni20 vxlan id 20
net add vxlan vni20 vxlan local-tunnelip 10.123.1.1
net add vxlan vni20 bridge access 20
```

Configurazione EVPN (BGP) su ([leaf 1](script/vxlan-evpn/leaf/Leaf1-vxlan-evpn.sh)):

```shell
net add bgp autonomous-system 65001
net add bgp router-id 10.123.1.1
net add bgp neighbor swp3 remote-as 65000
net add bgp neighbor swp4 remote-as 65000
```

Abilita l'estensione EVPN per i vicini e pubblica tutte le rotte VNI:

```shell
net add bgp evpn neighbor swp3 activate
net add bgp evpn neighbor swp4 activate
net add bgp evpn advertise-all-vni
```

Configura gli indirizzi IP per le VLAN sui VTEP:

```shell
net add vlan 10 ip address 10.123.0.254/24
net add vlan 20 ip address 10.123.20.254/24

net add vlan 100 ip address 10.123.100.254/16
net add vlan 100 ip gateway 10.123.100.1

net add vlan 200 ip address 10.123.100.254/16
net add vlan 200 ip gateway 10.123.100.1
```

Configura le interfacce di switch virtuali associando le VLAN alle VRF e configurando BGP per queste VRF:

```shell
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

Ci sono 2 tenant nella rete cloud, ciascuno ospita due macchine connesse, una a leaf1 e l'altra a leaf2. Ogni tenant è
assegnato a un dominio di broadcast.

Le VM sono state emulate creando namespace e aggiungendo diverse interfacce VLAN per ciascun namespace.

La configurazione dei due tenant è molto simile, quindi viene considerata solo quella relativa a una macchina. Puoi
trovare le diverse configurazioni dei tenant qui: [tenants](script/vxlan-evpn/end-hosts).
Ma ora consideriamo solo una macchina di un tenant [tAmv1](script/vxlan-evpn/end-hosts/tAvm1.sh).

```shell
ip addr add 10.123.0.1/24 dev eth1
ip route add default via 10.123.0.254
```

### CE-A2

La configurazione di [CE-A2](script/client-edge/CE-A2.sh) la stessa di [CE-A1](#ce-a1).

### [Firewall CE-A2](script/client-edge/FirewallCE-A2.sh)

* Ecco la traduzione delle righe per impostare le politiche predefinite su DROP per INPUT, OUTPUT e FORWARD:
    ```shell
    iptables -P FORWARD DROP
    iptables -P INPUT DROP
    iptables -P OUTPUT DROP
   ```
* permette il traffico tra LAN-A2 e la rete esterna (incluse LAN-A1 e LAN-A3) solo se avviato da LAN-A2:
    ```shell
    iptables -A FORWARD -i $LAN -o $NET -j ACCEPT
    iptables -A FORWARD -s 10.123.0.0/16 -o $NET -j ACCEPT
  ```
* permette il traffico di risposta alle connessioni stabilite
    ```shell
    iptables -A FORWARD -m state --state ESTABLISHED -j ACCEPT
    ```
* configura il MASQUERADE per il traffico in uscita su eth1 rete esterna)
    ```shell
    iptables -A POSTROUTING -t nat -o eth1 -j MASQUERADE
    ```
* permette il forwarding tra gli spoke:
  ```shell
   iptables -A FORWARD -s 10.123.3.3/24 -d 10.123.4.4/24 -j ACCEPT
   iptables -A FORWARD -s 10.123.4.4/24 -d 10.123.3.3/24 -j ACCEPT 
  ```

## LAN-A3

> LAN-A3 is Site 3 of the BGP/MPLS VPN in which there is just a Customer Edge, facing AS200, and one device in the
> private network. The device is sensitive, so it must be configured to use Mandatory Access Control.

### CE-A3

La configurazione di [CE-A3](script/client-edge/CE-A3.sh) è la stessa di [CE-A1](#ce-a1).

### HostA3

Stessa configurazione di [HostA1, HostA2](#hosta1-hosta2).

In questo caso, il dispositivo è sensibile, quindi è stato utilizzato il Controllo di Accesso Obbligatorio con AppArmor
ed è stato configurato tramite Docker.

**AppArmor** è un modulo di sicurezza Linux facile da usare che limita le capacità e i permessi delle applicazioni
attraverso profili. Utilizza i profili di un'applicazione per determinare quali file e permessi sono necessari all'
applicazione.

Per montare il sistema:

```shell
mount -tsecurityfs securityfs /sys/kernel/security
```

I **profili** di AppArmor sono semplici file di testo situati in /etc/apparmor.d/. In questo caso, abbiamo utilizzato un
esempio come questo:

- /etc/apparmor.d/bin.ping è il profilo AppArmor per il comando /bin/ping.

Per creare un nuovo profilo, crea il file bin.ping all'interno della directory dei profili /etc/apparmor.d:

```shell
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

Per visualizzare lo **stato corrente** dei profili AppArmor:

```shell
apparmor_status
```

**aa-enforce** mette un profilo in modalità enforce:

```shell
aa-enforce /etc/apparmor.d/bin.ping
```

Per ricaricare un profilo:

```shell
apparmor_parser -r /etc/apparmor.d/bin.ping
```

> > **apparmor_parser** viene utilizzato per caricare un profilo nel kernel. Può essere utilizzato anche per ricaricare
> > un
> > profilo attualmente caricato usando l'opzione -r dopo averlo modificato per rendere effettive le modifiche.

## OpenVPN Configuration

> OpenVPN with one server and one client. The server is in AS200, with a public IP taken from the 2.0.0.0/8 network.
> The client is host-B2, behind the private network in LANB2. The OpenVPN server provides access to LAN-B1 to which it
> serves as the gateway.

### Certification managment

1. Scarica una delle release di EasyRSA (ad esempio, v.3.1.0):
   ```shell
   wget https://github.com/OpenVPN/easy-rsa/releases/download/v3.1.0/EasyRSA-3.1.0.tgz && tar xf EasyRSA-3.1.0.tgz && cd EasyRSA-3.1.0/
   ```
2. Inizializza easy-rsa e crea il certificato CA:
    ```shell
    ./easyrsa init-pki && ./easyrsa build-ca
    ```
3. Genera un certificato e la chiave privata del server:
    ```shell
    ./easyrsa build-server-full server
    ```
4. Genera i certificati e le chiavi per i client:
   ```shell
   ./easyrsa build-client-full client1 && ./easyrsa build-client-full client2
   ```
5. Genera i parametri Diffie-Hellman per OpenVPN:
   ```shell
   ./easyrsa gen-dh
   ```

### Server Configuration

La parte di configurazione di rete del [server](script/openvpn/ovpn-server.sh) è la seguente:

- le seguenti righe per configurare la rete verso la WAN:
   ```shell
   ip link set eth0 up
   ip link set eth1 up
  
   ip addr add 2.0.0.1/24 dev eth1 2>/dev/null
   ip addr add 192.168.17.2/24 dev eth0 2>/dev/null   
   ip route add default via 2.0.0.2 2>/dev/null   
   
   iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
    ```
- dato che il server riceve pacchetti non come punto finale, deve essere in grado di inoltrare i pacchetti:
    ```shell
    echo 1 > /proc/sys/net/ipv4/ip_forward
    ```

La parte di configurazione OpenVPN del[server](script/openvpn/conf/server.ovpn) è la seguente:

- le seguenti righe per impostare la porta di ascolto del server su 1194, il formato di incapsulamento su UDP e
  l'interfaccia virtuale su tun:
    ```
    port 1194
    proto udp
    dev tun
    ```
- le seguenti righe per impostare il percorso dei file generati nella fase di gestione della certificazione:
    ```
    ca keys/ca.crt
    cert keys/server.crt
    key keys/server.key
    dh keys/dh2048.pem
    ```
- la seguente riga per indicare a OpenVPN di funzionare come un'istanza server e di allocare un intervallo di indirizzi
  VPN 192.168.100.0/24, dove l'adattatore virtuale del server ha l'IP 192.168.100.1 perché è il primo indirizzo IP
  valido:
    ```
    server 192.168.100.0 255.255.255.0
    ```
- la seguente riga indica a ciascun client che, se devono inviare un pacchetto alla rete 2.0.0.0/11, devono passarlo al
  processo OpenVPN:
    ```
    push "route 192.168.17.0 255.255.255.0"
    ```
- la seguente riga ha lo stesso ruolo della riga precedente, ma è per il server:
    ```
    route 192.168.16.0 255.255.255.0
    ```
- la seguente riga per impostare il percorso alla directory di configurazione specifica per ogni client:
    ```
    client-config-dir ccd
    ```
- la seguente riga per indicare di inviare un ping ogni 10 secondi e assumere che il peer remoto sia inattivo se non si
  ricevono ping per un periodo di 120 secondi:
    ```
    keepalive 10 120
    ```
- il cifrario:
     ```
    cipher AES-256-CBC
    ```

### Client configuration

La parte di configurazione di rete del [client configuration](script/hosts/lanB/HostB2.sh) è la seguente:

```shell
ip link set eth0 up
ip addr add 192.168.16.1/24 dev eth0
ip route add default via 192.168.16.2
```

La parte di configurazione OpenVPN del [client configuration](docker/openvpn/config/ovpn/hostB2.ovpn) è composta da:

- le seguenti righe per indicare che è un client OpenVPN, il formato di incapsulamento è udp e l'interfaccia virtuale è
  tun:
    ```
    client
    dev tun
    proto udp
    ```
- la seguente riga per impostare 2.0.0.2 come indirizzo IP del server e 1194 come porta di ascolto del server:
    ```
    remote 2.0.0.1 1194
    resolv-retry infinite
   ```
- le seguenti righe per impostare il percorso dei file generati nella fase di gestione della certificazione:
    ```
   ca keys/ca.crt
   cert keys/hostB2.crt
   key keys/hostB2.key
    ```
- il cifrario:
   ```
    remote-cert-tls server
    cipher AES-256-CBC
   ```

## Test Case

### BGP/MPLS VPN

Per esaminare la tabella di forwarding MPLS tra i router:

```shell
show mpls forwarding-table
```

Esamina le rotte associate alla VPN:

```shell
show ip route vrf customers
```

### Spoke -> Spoke

Per poter eseguire correttamente MACsec, prima avviare lo script: **sh run-mac.sh** e poi **sh CE-A1.sh**.

Con il seguente comando verifica la corretta rotta del pacchetto in un router:

```shell
show ip route vrf vpnA
```

Questo comando visualizza la tabella di routing per il VRF (Virtual Routing and Forwarding) specificato, in questo caso
vpnA. Mostra tutte le rotte conosciute e le loro destinazioni, comprese le rotte statiche e dinamiche apprese tramite
protocolli di routing

```shell
show ip bgp vpnv4 vrf vpnA labels
```

Questo comando mostra le rotte BGP per gli indirizzi VPNv4 associate al VRF vpnA, insieme alle etichette MPLS (
Multiprotocol Label Switching). Fornisce informazioni sulle rotte VPNv4 apprese tramite BGP, comprese le etichette MPLS
utilizzate per il forwarding dei pacchetti.

### LAN-A1

Per testare la configurazione MACsec sono stati effettuati i seguenti test:

- HostA2 -> HostA1:
    - Verifica ICMP verso ```ping 10.23.0.3```
    - Verifica incapsulamento in MACsec Frame in HostA2 tramite: ```tcpdump -i macsec0``` e ```tcpdump -i enp0s3```

### OverlayVPN

Dopo aver configurato il server e il client, eseguire dal server:

```shell
openvpn /gns3volumes/openvpn/server.ovpn
```

Da HostB2:

```shell
openvpn /gns3volumes/openvpn/HostB2.ovpn
```

Per testare la configurazione OpenVPN sono stati effettuati i seguenti test:

- Handshake HostB1 -> ovpn-server
- HostB2 -> ovpn-server:
    - Verifica ICMP verso ```ping 2.0.0.1```
    - Verifica OpenVPN verso ```ping 192.158.100.1```
- HostB1 -> HostB2:
    - Verifica ICMP verso ```ping 192.168.17.1```

### EVPN/VXLAN

Esamina il numero di VTEPs per ogni VNI dai leaves (_dovrebbe essere differente da 0 per VNI 10 e VNI 20_):

```shell
net show evpn vni
```

Controlla la presenza della route di default type-5 in BGP dei leaves:

```shell
net show bgp evpn route
```

Controlla la VLAN membership per quella porta:

```shell
net show bridge vlan
```

Per testare la configurazione EVPN/VXLAN sono stati effettuati i seguenti test:

  ``` shell
  ip link show vlan100
  sudo ip link set vlan100 up
  ip route show vrf TENA
  ```

- tAvm1 -> tAvm2: ```ping 10.123.10.2```

### Firewall

Per testare la configurazione del Firewall su CE-A2 sono stati effettuati i seguenti test:

- leaf 1 -> PE3: ip vrf exec TENA ```ping 100.0.32.2```
- CE-A2 -> leaf1 ```ping 10.123.0.254```

