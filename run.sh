#!/bin/bash

EXTIFACE=${EXTIFACE:-eth0}
INTIFACE=${INTIFACE:-172.17.42.1}
INTNET=${INTNET:-172.17.0.0/16}

grep -e '^START_DAEMON=' /etc/default/miniupnpd || \
  echo "START_DAEMON=1" >> /etc/default/miniupnpd
	
grep -e '^MiniUPnPd_EXTERNAL_INTERFACE=' /etc/default/miniupnpd || \
  echo "MiniUPnPd_EXTERNAL_INTERFACE=${EXTIFACE}" >> /etc/default/miniupnpd

grep -e "^MiniUPnPd_LISTENING_IP=" /etc/default/miniupnpd || \
  echo "MiniUPnPd_LISTENING_IP=${INTIFACE}" >> /etc/default/miniupnpd
	
sed -i -e "s/^iniUPnPd_ip6tables_enable=.*\$/iniUPnPd_ip6tables_enable=yes/" \
       -e "s/^MiniUPnPd_EXTERNAL_INTERFACE=.*\$/MiniUPnPd_EXTERNAL_INTERFACE=${EXTIFACE}/" \
       -e "s/^MiniUPnPd_LISTENING_IP=.*\$/MiniUPnPd_LISTENING_IP=${INTIFACE}/" \
       -e "s/^START_DAEMON=.*\$/START_DAEMON=1/" \
       /etc/default/miniupnpd

. /etc/default/miniupnpd

IP="/bin/ip"

EXTIP="$(LC_ALL=C ${IP} addr show ${MiniUPnPd_EXTERNAL_INTERFACE} | grep "inet " | awk '{ print $2 }' | cut -d"/" -f1)"

sed -i -e "s/^ext_ifname=.*\$/ext_ifname=${EXTIFACE}/" \
       -e "s/^listening_ip=.*\$/listening_ip=${INTIFACE}/" \
       -e "s/^enable_natpmp=.*\$/enable_natpmp=yes/" \
       -e "s/^enable_upnp=.*\$/enable_upnp=yes/" \
       -e "s%192.168.0.0/24%${$IP}/32%" \
       -e "s%192\.168\.1\.0/24%${INTNET}%" \
       /etc/miniupnpd/miniupnpd.conf

# This is needed to keep running in the foreground in debug mode
exec /usr/sbin/miniupnpd -i ${EXTIFACE} -o ${EXTIP} -a ${INTIFACE} -d

