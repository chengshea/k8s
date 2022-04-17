#!/bin/sh


source ./env.sh

echo "gen-flanneld... $name"

subnetf="subnet.env"







env(){
	cat>$1<<EOF
FLANNEL_OPTIONS="--etcd-endpoints=$etcdIps \
  --iface=$iface  \
  --etcd-prefix=/atomic.io/network   \
   -etcd-cafile=$ssl/ca.pem  \
   -etcd-certfile=$ssl/kubernetes.pem  \
   -etcd-keyfile=$ssl/kubernetes-key.pem "
EOF
}


subnet(){
  cat>$1 <<EOF
DOCKER_OPT_BIP="--bip=121.21.56.1/24"
DOCKER_OPT_IPMASQ="--ip-masq=true"
DOCKER_OPT_MTU="--mtu=1472"
DOCKER_NETWORK_OPTIONS=" --bip=121.21.56.1/24 --ip-masq=true --mtu=1472"

EOF
}


service(){
	cat>$1 <<EOF
[Unit]
Description=Flanneld overlay address etcd agent
After=network.target
After=network-online.target
Wants=network-online.target
After=etcd.service
Before=docker.service
[Service]
Type=notify
EnvironmentFile=$base/flanneld.env
ExecStart=$exec -ip-masq  \$FLANNEL_OPTIONS
ExecStartPost=$base/mk-docker-opts.sh -k DOCKER_NETWORK_OPTIONS -d $base/subnet.env
Restart=always
RestartSec=5
StartLimitInterval=0
[Install]
WantedBy=multi-user.target
EOF
}




create(){
   for i in $@; do
    echo "开始生成:"$i    ${i##*.}   ${i%%.*}
     yml=$base/$i
     
    [ "$i" != "subnet.env" ] || { ${i%%.*}  $yml && continue;}
     ${i##*.}  $yml
   
  done

}

arr=($envf $servicef $subnetf)

[ -d "$base" ] || { echo "没有目录,创建目录..." && mkdir -p $base ; }

create ${arr[@]}



url="https://github.com/flannel-io/flannel/releases"
[ -f "$exec" ] || { echo "没有找到执行程序 $exec...." && echo "请前往下载:$url" ;}

[ -f "$k8s/mk-docker-opts.sh" ] && { cp /opt/kubernetes/mk-docker-opts.sh /opt/kubernetes/flanneld && chmod +x /opt/kubernetes/flanneld/mk-docker-opts.sh ;}


mk="https://github.com/flannel-io/flannel/blob/24941444a861e7503d3e68722da9aa77c12db104/dist/mk-docker-opts.sh"
[ -f "$base/mk-docker-opts.sh" ] || { echo "没有找到脚本 mk-docker-opts...." && echo "请前往下载:$mk" ;}


:<<EOF
start  restart

sudo systemctl stop flanneld.service

systemctl status flanneld.service
设置开机自启动  systemctl enable flanneld.service
停止开机自启动 systemctl disable flanneld.service


systemctl is-enabled flanneld.service

查看开机启动的服务列表
systemctl list-unit-files|grep enabled | grep docker

查看启动失败的服务列表：systemctl --failed
EOF