#!/usr/bin/env sh

set -ex

# ENABLE ipv4 forward
sysctl -w net.ipv4.ip_forward=1

iptables -t nat -N clash
iptables -t nat -A clash -d 0.0.0.0/8 -j RETURN
iptables -t nat -A clash -d 10.0.0.0/8 -j RETURN
iptables -t nat -A clash -d 127.0.0.0/8 -j RETURN
iptables -t nat -A clash -d 169.254.0.0/16 -j RETURN
iptables -t nat -A clash -d 172.16.0.0/12 -j RETURN
iptables -t nat -A clash -d 192.168.0.0/16 -j RETURN
iptables -t nat -A clash -d 224.0.0.0/4 -j RETURN
iptables -t nat -A clash -d 240.0.0.0/4 -j RETURN
iptables -t nat -A clash -d ${POD_IP} -j RETURN
iptables -t nat -A clash -p tcp -j REDIRECT --to-port 
iptables -t nat -I PREROUTING -p tcp -d 8.8.8.8 -j REDIRECT --to-port 7893
iptables -t nat -I PREROUTING -p tcp -d 8.8.4.4 -j REDIRECT --to-port 7893
iptables -t nat -A PREROUTING -p tcp -j clash
iptables -t nat -A OUTPUT -p tcp -d 172.17.0.0/16 -j REDIRECT --to-port 7893
iptables -t nat -N CLASH_DNS
iptables -t nat -F CLASH_DNS 
iptables -t nat -A CLASH_DNS -p udp -j REDIRECT --to-port 1053
iptables -t nat -I OUTPUT -p udp --dport 53 -j CLASH_DNS
iptables -t nat -I PREROUTING -p udp --dport 53 -j REDIRECT --to 1053

/clash
