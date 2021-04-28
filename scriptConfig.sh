cat /tmp/system.cfg > /tmp/prueba.cfg
(grep -v "netconf.3.ip" /tmp/prueba.cfg && echo "netconf.3.ip=192.168.1.30") | sort > /tmp/system.cfg
cfgmtd -f /tmp/system.cfg -w
/usr/etc/rc.d/rc.softrestart save
