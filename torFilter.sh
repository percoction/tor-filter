#!/bin/bash

EXIT_NODES_URL="https://www.dan.me.uk/torlist/?exit"
EXIT_NODES_FILE="torExitNodes.txt"

# create chains
iptables -t filter -N TORFILTER > /dev/null 2>&1
iptables -t filter -N TORLOG > /dev/null 2>&1

# forward incoming packets to TORFILTER chain
iptables -t filter -C INPUT -j TORFILTER
if [ $? -ne 0 ]; then
    iptables -t filter -A INPUT -j TORFILTER
fi
iptables -t filter -C FORWARD -j TORFILTER
if [ $? -ne 0 ]; then
    iptables -t filter -A FORWARD -j TORFILTER
fi

# configure TORLOG chain to log and drop
iptables -t filter -C TORLOG -m limit --limit 10/min --limit-burst 1 -j LOG --log-prefix "Tor Node Packet: " --log-level 7
if [ $? -ne 0 ]; then
    iptables -t filter -A TORLOG -m limit --limit 10/min --limit-burst 1 -j LOG --log-prefix "Tor Node Packet: " --log-level 7
fi
iptables -t filter -C TORLOG -j DROP
if [ $? -ne 0 ]; then
    iptables -t filter -A TORLOG -j DROP
fi

# grab current list of tor nodes
curl -k $EXIT_NODES_URL > $EXIT_NODES_FILE

# flush previous TORFILTER chain
iptables -t filter -F TORFILTER

# add rules for each node in list
while read line; do
   iptables -t filter -A TORFILTER -s $line/32 -j TORLOG 
done < $EXIT_NODES_FILE

iptables -t filter -A TORFILTER -j RETURN
