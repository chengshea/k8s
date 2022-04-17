#!/bin/sh

source ./env.sh


:<<EOF
https://kubernetes.io/zh/docs/reference/command-line-tools-reference/kube-controller-manager/
  -kubeconfig=$config/  \
  --leader-elect=true  启动领导选举（Leader Election）客户端，并尝试获得领导者身份
use-service-account-credentials=true  来为其包含的每个控制器使用单独的 ServiceAccount
--cluster-cidr 用于给pod分配ip的cidr段，整个集群生效  对应的flannel Network  ip段
--service-cluster-ip-range 用于给service分配ip的cidr段，整个集群生效

--kubeconfig
--authentication-kubeconfig
--authorization-kubeconfig

EOF



env(){
	cat>$1<<EOF
KUBE_CM_ARGS="--cluster-name=kubernetes \
  --allocate-node-cidrs =true \
  --authentication-kubeconfig=$config/$name.kubeconfig \
   --authorization-kubeconfig=$config/$name.kubeconfig \
   --kubeconfig=$config/$name.kubeconfig \
  --cluster-cidr=$ipr \
  --cluster-signing-cert-file=$ssl/ca.pem \
  --cluster-signing-key-file=$ssl/ca-key.pem \
  --root-ca-file=$ssl/ca.pem  \
  --service-account-private-key-file=$ssl/ca-key.pem \
  --tls-cert-file=$ssl/$name.pem \
  --tls-private-key-file=$ssl/$name-key.pem \
  --requestheader-client-ca-file=$ssl/ca.pem \
  --use-service-account-credentials=true \
  --log-dir=$logs   \
  --logtostderr=$stderr  \
  --v=$lv"
EOF
}




service(){
	cat>$1 <<EOF
[Unit]
Description=Kubernetes controller-manager Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=docker.service
#Requires=docker.service

[Service]
EnvironmentFile=$base/$name.env
ExecStart=$exec  \$KUBE_CM_ARGS
Restart=on-failure

[Install]
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

arr=($envf $servicef)

[ -d "$logs" ] || { echo "没有$logs目录,创建目录..." && mkdir -p $logs ; }

create ${arr[@]}
