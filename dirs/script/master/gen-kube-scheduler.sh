#!/bin/sh

source ./env.sh

:<<EOF
https://kubernetes.io/zh/docs/reference/command-line-tools-reference/kubelet/
cert-dir包括 -tls-cert-file 和 --tls-private-key-file

   --leader-elect=true   \
--master=$master_url   Kubernetes API 服务器的地址（覆盖 kubeconfig 中的任何值）



EOF


env(){
	cat>$1<<EOF
KUBE_SCH_ARGS=" --authentication-kubeconfig=$config/$name.kubeconfig \
    --authorization-kubeconfig=$config/$name.kubeconfig \
    --kubeconfig=$config/$name.kubeconfig \
    --client-ca-file=$ssl/ca.pem \
    --requestheader-client-ca-file=$ssl/ca.pem \
    --tls-cert-file=$ssl/$name.pem \
    --tls-private-key-file=$ssl/$name-key.pem \
    --log-dir=$logs   \
    --logtostderr=$stderr  \
    --v=$lv"
EOF
}




service(){
	cat>$1 <<EOF
[Unit]
Description=Kubernetes kube-scheduler Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=docker.service
Requires=docker.service

[Service]
EnvironmentFile=$base/$name.env
ExecStart=$exec  \$KUBE_SCH_ARGS
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
