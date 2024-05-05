#!/bin/bash

export MKA_CAK=00112233445566778899aabbccddeeff
export MKA_CKN=00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff

nmcli connection del macsec-conn

nmcli connection add type macsec \
con-name macsec-conn \
ifname macsec0 \
connection.autoconnect yes \
macsec.parent enp0s3 \
macsec.mode psk \
macsec.mka-cak $MKA_CAK \
macsec.mka-cak-flags 0 \
macsec.mka-ckn $MKA_CKN \
ipv4.method manual \
ipv4.addresses 10.23.0.3/24

nmcli connection up macsec-conn