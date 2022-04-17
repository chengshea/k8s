#!/bin/sh

addr=192.168.56
#本机ip
localIp=$(ip a | grep $addr  | sed -e "s/\(.*\)\(${addr}\..*\)\/\(.*\)/\2/g")
echo "localIp:$localIp"
name=$(cat /etc/hosts | sed -n "s/^\(${localIp}\)\([[:space:]]*\)\(.*\)/\3/g"p)  
echo "name:$name"

hostnamectl set-hostname  $name

sed -i "s#setHostname#$name#g"  /etc/hosts 