#!/bin/csh -f

set wgconf = /usr/local/etc/wireguard/wg0.conf
set wgkey = /home/vpn/wg0.key

if ( $#argv != 2 ) then

 clear
 echo "Syntax: newwg.sh <usuario> <ip>"
 exit 0

endif

if ( -e $argv[1].key ) then

 echo "Usuario ja existe, usar outro"
 exit 0

endif

grep -q $argv[2] ${wgconf}
echo $? > /tmp/verificaip
if ( `cat /tmp/verificaip` == 0 ) then

 echo "Usar outro endereco IP"
 exit 0
 rm /tmp/verificaip

endif

echo "Usuario: $argv[1], IP: $argv[2]"

umask 077
wg genkey > $argv[1].key
wg pubkey < $argv[1].key > $argv[1].pub
wg genpsk > $argv[1].psk

set pubkey = `cat $argv[1].pub`
set privkey = `cat $argv[1].key`
set psk = `cat $argv[1].psk`
set spubkey = `wg pubkey < ${wgkey}`
set ip = $argv[2]

# criando configuracao para cliente

printf "[Interface]\n PrivateKey = $privkey\n Address = $ip\n\n" > $argv[1].conf
printf "[Peer]\n PublicKey = $spubkey\n PresharedKey = $psk\n Endpoint = SERVERADDRESS:51820\n AllowedIPs = 172.16.34.0/24\n\n" >> $argv[1].conf
zip $argv[1].zip $argv[1].conf

# Criando configuracao para o servidor
printf "# $argv[1]\n[Peer]\n PublicKey = $pubkey\n PresharedKey = $psk\n AllowedIPs = $ip/32\n\n" >> ${wgconf}

/usr/local/etc/rc.d/wireguard restart
