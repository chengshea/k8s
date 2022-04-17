#!/bin/sh

#目录
k8s=/opt/kubernetes
ssl=$k8s/pem
[ -f "$sll" ] || { echo "本地调试..." && ssl=/home/cs/data/VM/k8s/dirs/script/pem/ ; }
cni=$k8s/cni
config=$k8s/config
logf=/var/log/kubernetes


KUBE_APISERVER=

#etcd
master01Ip=https://192.168.56.101
master02Ip=https://192.168.56.102
master03Ip=https://192.168.56.103
etcdIps=$master01Ip:2379,$master02Ip:2379,$master03Ip:2379
clusters="master01=$master01Ip:2380,master02=$master02Ip:2380,master03=$master03Ip:2380"



DIR="$(cd "$(dirname "$0")" && pwd)"
#截取脚本名称
name=$(echo $0 | sed 's/.*gen-\(.*\)\..*/\1/g')
#文件执行生成的目录
base=$DIR/$name

[ -d "$base" ] || { echo "没有$base,创建目录..." && mkdir -p $base ; }

#pem
csr=$base/ca-csr.json
conf=$base/ca-config.json


exec=$k8s/amd64/$name
[ "$DIR" == "/opt/kubernetes" ] || { echo "这是dev...." && logf=$DIR/logs ; }

logs=$logf/$name
stderr=false
lv=2

yamlf="audit-policy.yaml"
kubelf="kubelet-config.yaml"
kubepf="kube-proxy-config.yaml"
envf="$name.env"
servicef="$name.service"


addr=192.168.56

ipr=121.21.0.0/16

#获取网卡名匹配行最后一列
iface=$(ip add | grep $addr | awk '{print $NF}')

#本机ip
localIp=$(ip a | grep $addr  | sed -e "s/\(.*\)\(${addr}\..*\)\/\(.*\)/\2/g")


case $localIp in
	"192.168.56.101"|"192.168.56.102"|"192.168.56.103")
	     KUBE_APISERVER="https://$localIp:6443"
	;;
	*)
	      KUBE_APISERVER=https://127.0.0.1:6443
	;;
esac


echo $KUBE_APISERVER

#cm
master_url=http://127.0.0.1:8080


#,ServiceAccount  SecurityContextDeny
admission=NamespaceLifecycle,NamespaceExists,LimitRanger,DefaultStorageClass,ResourceQuota,ServiceAccount

#sch
pause_image="k8s.org/k8s/pause:3.2"
nginx_image="k8s.org/cs/nginx:stable-alpine"
