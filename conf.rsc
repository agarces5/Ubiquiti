# mar/31/2019 12:37:18 by RouterOS 6.44.1
# Configuracion inicial basica
# Creada desde laculpadesistemas.com
#
# model = RouterBOARD 962UiGS-5HacT2HnT
# 
/user set [find name=admin] password=1234
/interface bridge
add name=bridgeLAN
/interface ethernet
set [ find default-name=ether1 ] comment=WAN
/interface wireless security-profiles
set [ find default=yes ] supplicant-identity=MikroTik
add authentication-types=wpa-psk,wpa2-psk eap-methods="" group-ciphers=\
    tkip,aes-ccm management-protection=allowed mode=dynamic-keys name=\
    Seguridad-2.4 supplicant-identity="" unicast-ciphers=tkip,aes-ccm \
    wpa-pre-shared-key=clavewifi wpa2-pre-shared-key=clavewifi
add authentication-types=wpa-psk,wpa2-psk eap-methods="" group-ciphers=\
    tkip,aes-ccm management-protection=allowed mode=dynamic-keys name=\
    Seguridad-5 supplicant-identity="" unicast-ciphers=tkip,aes-ccm \
    wpa-pre-shared-key=clavewifi wpa2-pre-shared-key=clavewifi
/interface wireless
set [ find default-name=wlan1 ] antenna-gain=3 band=2ghz-b/g/n channel-width=\
    20/40mhz-XX country=spain disabled=no frequency=auto frequency-mode=\
    regulatory-domain mode=ap-bridge radio-name=MiMikroTik security-profile=\
    Seguridad-2.4 ssid=laculpadesistemas2.4 wireless-protocol=802.11 \
    wmm-support=enabled wps-mode=disabled
set [ find default-name=wlan2 ] antenna-gain=3 band=5ghz-a/n/ac \
    channel-width=20/40/80mhz-XXXX country=spain disabled=no frequency=auto \
    frequency-mode=regulatory-domain installation=indoor mode=ap-bridge \
    radio-name=MiMikroTik security-profile=Seguridad-5 ssid=\
    laculpadesistemas-5 wireless-protocol=802.11 wmm-support=enabled \
    wps-mode=disabled
/ip pool
add name=dhcp_pool0 ranges=192.168.111.2-192.168.111.254
/ip dhcp-server
add address-pool=dhcp_pool0 disabled=no interface=bridgeLAN name=dhcp1
/interface bridge port
add bridge=bridgeLAN interface=ether2
add bridge=bridgeLAN interface=ether3
add bridge=bridgeLAN interface=ether4
add bridge=bridgeLAN interface=ether5
add bridge=bridgeLAN interface=wlan1
add bridge=bridgeLAN interface=wlan2
/ip address
add address=192.168.111.1/24 interface=bridgeLAN network=192.168.111.0
/ip dhcp-client
add dhcp-options=hostname,clientid disabled=no interface=ether1
/ip dhcp-server network
add address=192.168.111.0/24 dns-server=8.8.8.8,1.1.1.1,8.8.4.4 gateway=\
    192.168.111.1
/ip dns
set allow-remote-requests=yes servers=9.9.9.9,8.8.4.4
/ip firewall filter
add action=drop chain=input connection-state=new in-interface=ether1
/ip firewall nat
add action=masquerade chain=srcnat out-interface=ether1
/system clock
set time-zone-name=Europe/Madrid
/system identity
set name=LCDS
/system ntp client
set enabled=yes server-dns-names=hora.roa.es
