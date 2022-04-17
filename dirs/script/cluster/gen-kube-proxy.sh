#!/bin/sh


source ./env.sh



:<<EOF
https://kubernetes.io/zh/docs/reference/command-line-tools-reference/kube-proxy/

WARNING: all flags other than --config, --write-config-to, and --cleanup are deprecated. Please begin using a config file ASAP

  --cleanup=true  \


 --config, --write-config-to, and --cleanup


  --hostname-override=$localIp \
    --masquerade-all=true \  如果使用纯 iptables 代理，则对通过服务集群 IP 发送的所有流量 进行 SNAT（通常不需要）。
https://kubernetes.io/docs/reference/config-api/kube-proxy-config.v1alpha1/
EOF



yaml(){
  cat > $1<<EOF
apiVersion: kubeproxy.config.k8s.io/v1alpha1
bindAddress: $localIp
clientConnection:
  kubeconfig: $config/$name.kubeconfig
clusterCIDR: "$ipr"
healthzBindAddress: "$localIp:10256"
ipvs:
  minSyncPeriod: 6s
  scheduler: "nq"
  syncPeriod: 6s
kind: KubeProxyConfiguration
metricsBindAddress: "$localIp:10249"
mode: "ipvs"
EOF
}




env(){
	cat>$1<<EOF
PROXY_OPTIONS="  --alsologtostderr=true  \
   --config=$base/$kubepf  \
  --log-dir=$logs   \
  --logtostderr=$stderr  \
  --v=$lv"
EOF
}



#Before=kubelet.service
service(){
	cat>$1 <<EOF
[Unit]
Description=Kubernetes kube-proxy Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=docker.service
Requires=docker.service

[Service]
EnvironmentFile=$base/$name.env
ExecStart=$exec  \$PROXY_OPTIONS
Restart=on-failure

[Install]
WantedBy=multi-user.target
WantedBy=multi-user.target
EOF
}





create(){
   for i in $@; do
    echo "开始生成:"$i    ${i##*.}   ${i%%.*}
     yml=$base//$i
     
     ${i##*.}  $yml
   
  done

}

arr=($kubepf $envf $servicef)

[ -d "$logs" ] || { echo "没有$logs目录,创建目录..." && mkdir -p $logs ; }

create ${arr[@]}
