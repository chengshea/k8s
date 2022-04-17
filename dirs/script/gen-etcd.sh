#!/bin/sh

source  ./env.sh

localName=$(hostname)

#本机名  本机ip
echo $localName:$localIp


env(){
	cat>$1<<EOF
ETCD_OPTIONS="--name=$localName   \
  --cert-file=$ssl/kubernetes.pem \
  --key-file=$ssl/kubernetes-key.pem \
  --peer-cert-file=$ssl/kubernetes.pem  \
  --peer-key-file=$ssl/kubernetes-key.pem  \
  --trusted-ca-file=$ssl/ca.pem \
  --peer-trusted-ca-file=$ssl/ca.pem \
  --initial-advertise-peer-urls https://$localIp:2380 \
  --listen-peer-urls https://$localIp:2380 \
  --listen-client-urls https://$localIp:2379,https://127.0.0.1:2379 \
  --advertise-client-urls https://$localIp:2379 \
  --initial-cluster-token etcd-cluster-0 \
   --initial-cluster $clusters  \
   --initial-cluster-state new  \
   --enable-v2=true   \
   --data-dir $base/data.etcd/   "
EOF
}


service(){
	cat>$1 <<EOF
[Unit]
Description=etcd
After=network.target
After=network-online.target
Wants=network-online.target
[Service]
Type=notify
EnvironmentFile=$base/etcd.env
ExecStart=$base/etcd  \$ETCD_OPTIONS
Restart=always
RestartSec=5
StartLimitInterval=0
[Install]
WantedBy=multi-user.target
EOF
}



ss(){
	cat>$1 <<EOF


EOF
}



create(){
   for i in $@; do
    echo "开始生成:"$i    ${i##*.}  
     yml=$base//$i
     ${i##*.}  $yml
   
  done

}

arr=($envf $servicef)

#[ -d "$base" ] || { echo "没有目录,创建目录..." && mkdir -p $base ; }

create ${arr[@]}

url="https://github.com/etcd-io/etcd/releases"
[ -f "$base/$name" ] || { echo "没有找到执行程序 $base/$name...." && echo "请前往下载:$url" ;}