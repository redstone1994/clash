#!/usr/bin/env sh

set -ex

# ENABLE ipv4 forward
sysctl -w net.ipv4.ip_forward=1

IPT=/sbin/iptables
lan_ipaddr=$(/sbin/ip route | awk '/default/ { print $3 }')
dns_port="1053"
proxy_port="7894"

# remove any existing rules
$IPT -F

# create new nat rule
$IPT -t nat -N CLASH_TCP_RULE
$IPT -t nat -F CLASH_TCP_RULE

# do not forward local address
$IPT -t nat -A CLASH_TCP_RULE -d 10.0.0.0/8 -j RETURN
$IPT -t nat -A CLASH_TCP_RULE -d 127.0.0.0/8 -j RETURN
$IPT -t nat -A CLASH_TCP_RULE -d 169.254.0.0/16 -j RETURN
$IPT -t nat -A CLASH_TCP_RULE -d 172.16.0.0/12 -j RETURN
$IPT -t nat -A CLASH_TCP_RULE -d 192.168.0.0/16 -j RETURN
$IPT -t nat -A CLASH_TCP_RULE -d 224.0.0.0/4 -j RETURN
$IPT -t nat -A CLASH_TCP_RULE -d 240.0.0.0/4 -j RETURN
$IPT -t nat -A CLASH_TCP_RULE -d ${lan_ipaddr}/16 -j RETURN

# do not forward ssh, clash http socks ports, transparent proxy port, clash web API port
$IPT -t nat -A CLASH_TCP_RULE -p tcp --dport 22 -j RETURN
$IPT -t nat -A CLASH_TCP_RULE -p tcp --dport 7890 -j RETURN
$IPT -t nat -A CLASH_TCP_RULE -p tcp --dport 7891 -j RETURN
$IPT -t nat -A CLASH_TCP_RULE -p tcp --dport 7892 -j RETURN
$IPT -t nat -A CLASH_TCP_RULE -p tcp --dport 9090 -j RETURN

# proxy_port take over HTTP/HTTPS request
$IPT -t nat -A CLASH_TCP_RULE  -p tcp -j REDIRECT --to-ports ${proxy_port}

# forward freedom DNS server address
$IPT -t nat -I PREROUTING -p tcp -d 8.8.8.8 -j REDIRECT --to-port "$proxy_port"
$IPT -t nat -I PREROUTING -p tcp -d 8.8.4.4 -j REDIRECT --to-port "$proxy_port"
$IPT -t nat -A PREROUTING -p tcp  -j CLASH_TCP_RULE
# Fake-IP rule
# $IPT -t nat -A OUTPUT -p tcp -d 198.18.0.0/16 -j REDIRECT --to-port ${proxy_port}

# forward DNS request to dns_port
$IPT -t nat -N CLASH_DNS_RULE
$IPT -t nat -F CLASH_DNS_RULE

$IPT -t nat -A PREROUTING -p udp -s ${lan_ipaddr}/16 --dport 53 -j CLASH_DNS_RULE
$IPT -t nat -A CLASH_DNS_RULE -p udp -s ${lan_ipaddr}/16 --dport 53 -j REDIRECT --to-ports $dns_port
$IPT -t nat -I OUTPUT -p udp --dport 53 -j CLASH_DNS_RULE

# this machine
$IPT -t nat -A OUTPUT -p tcp -m owner ! --uid-owner clash -j REDIRECT --to-port ${proxy_port}



