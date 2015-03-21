#!/bin/bash
#Script from: http://niczsoft.com/2010/06/linux-simple-router/ 

#configuration
IF_LOC=eth1
IP_LOC=192.168.67
IF_NET=wlan1
 
#script
IF_NET=$(ifconfig $IF_NET | awk '/inet/ {print $2}' | grep -o '[0-9]*\.[0-9]*\.[0-9]*')

 
#connect
iptables-save > /dev/shm/old_routes
ifconfig $IF_LOC inet $IP_LOC.1
ip route add $IP_LOC.0/24 dev $IF_LOC src $IP_LOC.1
iptables -t nat -A POSTROUTING -s $IF_NET.0/24 -j MASQUERADE
sudo sysctl -w net.ipv4.ip_forward=1
 
if ip route | grep $IP_LOC.1 >/dev/null
then
  #message
  clear
  echo "Enter this information in connected machines:"
  echo "IP address : $IP_LOC.2-254"
  echo "Netmask    : 255.255.255.0"
  echo "Gateway    : $IP_LOC.1"
  echo "DNS        : $(echo -n $(awk '/^nameserver/ {print $2}' /etc/resolv.conf))"
  echo ""
  echo "Press ENTER to continue."
  read
 
  #monitor connection
  iftop -i $IF_LOC
 
else
  echo "Error setting up network"
fi
 
#disconnect
ip route del $IP_LOC.0/24 dev $IF_LOC
ifconfig $IF_LOC down
iptables-restore < /dev/shm/old_routes
rm /dev/shm/old_routes
 
#end
