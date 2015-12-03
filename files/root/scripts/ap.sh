#!/bin/bash

CONFIG=/www/config

# Derive a unique ESSID from wifi NIC's MAC on first boot
if [ ! -f $CONFIG/since ]; then
        SSID=unplug_$(cat $CONFIG/wlanmac | cut -d ':' -f 5-8 | sed 's/://g')
        echo $SSID > $CONFIG/ssid # Needed for UI later
	MAC=$(cat $CONFIG/wlanmac)
	
	# Pseudo-randomly generate a channel for our AP
	RANGE=13
	CHAN=$RANDOM
	let "CHAN %= $RANGE"
	uci set wireless.@wifi-iface[0].ssid=$SSID
	uci set wireless.@wifi-iface[0].macaddr=$MAC
	uci set wireless.@wifi-iface[0].channel=$CHAN
fi
# Bring up Access Point
wifi down
SSID=$(cat $CONFIG/ssid)
#ifconfig wlan0 hw ether $(cat $CONFIG/wlanmac)
uci set wireless.@wifi-iface[0].disabled=0
uci set wireless.@wifi-iface[0].mode="ap"

uci commit wireless
echo "Bringing up AP..."
wifi

# Wait for hostapd to come up before exiting
while true;
    do
	HAPD=$(ps | grep [ho]st | awk '{ print $1 }')
        if [ ! $HAPD ]; then
	    sleep 1
	else
	    echo "AP should be up with name: " $SSID
	    # Restart dnsmasq (DHCP)
	    /etc/init.d/dnsmasq restart
	    exit
	fi
    done
