#!/bin/sh


source ./env.sh




:<<EOF
https://kubernetes.io/zh/docs/reference/command-line-tools-reference/kubelet/
cert-dir包括 -tls-cert-file 和 --tls-private-key-file


--cni-bin-dir 指定cni插件二进制目录，默认为/opt/cni/bin
--cni-conf-dir 指定cni插件配置目录，默认为/etc/cni/net.d
如果设置了 --hostname-override 选项，则 kube-proxy 也需要设置该选项，否则会出现找不到 Node 的情况
cgroupDriver: "systemd"

已弃用用如下方式配置
--config
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
address: "192.168.56.1",
serializeImagePulls: false,
evictionHard:
    memory.available:  "200Mi"
    nodefs.available: "10%" 
    nodefs.inodesFree: "5%" 
cgroupDriver: systemd    
failSwapOn: false    # --ignore-preflight-errors=Swap
maxPods: 210


--hostname-override=$localIp
hostname-override:设置node在集群中的主机名，默认使用主机hostname；
如果设置了此项参数，kube-proxy服务也需要设置此项参数


https://kubernetes.io/docs/reference/config-api/kubelet-config.v1beta1/
EOF


yaml(){
  cat > $1<<EOF
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
address: "$localIp"
port: 10250
healthzBindAddress: "$localIp"
healthzPort: 10248
readOnlyPort: 0
cgroupDriver: "cgroupfs"
clusterDomain: "cluster.local"
clusterDNS: ["121.21.0.0"]
failSwapOn: false
tlsCertFile: "$ssl/kubelet.pem"
tlsPrivateKeyFile: "$ssl/kubelet-key.pem"
authentication:
    x509:
        clientCAFile: "$ssl/ca.pem"
    webhook:
        enabled: true
        cacheTTL: "2m0s"
    anonymous:
        enabled: false
authorization:
    mode: Webhook
    webhook:
        cacheAuthorizedTTL: "5m0s"
        cacheUnauthorizedTTL: "30s"
hairpinMode: "promiscuous-bridge"
serializeImagePulls: false
featureGates:
    RotateKubeletClientCertificate: true
    RotateKubeletServerCertificate: true
EOF
}


env(){
	cat>$1<<EOF
KUBELET_OPTIONS=" --pod-infra-container-image=$pause_image \
  --bootstrap-kubeconfig=$config/bootstrap.kubeconfig \
  --kubeconfig=$config/$name.kubeconfig \
  --config=$base/$kubelf  \
  --cni-bin-dir=$cni/bin  \
  --cni-conf-dir=$cni/net.d  \
  --network-plugin=cni  \
  --runtime-cgroups=/systemd/system.slice  \
  --log-dir=$logs   \
  --logtostderr=$stderr  \
  --v=$lv"
EOF
}




service(){
	cat>$1 <<EOF
[Unit]
Description=Kubernetes Kubelet Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=docker.service
Requires=docker.service

[Service]
WorkingDirectory=/var/lib/$name
EnvironmentFile=$base/$name.env
ExecStart=$exec  \$KUBELET_OPTIONS
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
}



conf(){
  cat>$1 <<EOF
error_log stderr notice;

worker_processes auto;
events {
      multi_accept on;
      use epoll;
      worker_connections 1024;
}

stream {
    upstream kube_apiserver {
        least_conn;
        server ${master01Ip##*/}:6443;
        server ${master02Ip##*/}:6443;
        server ${master03Ip##*/}:6443;
    }

    server {
        listen        0.0.0.0:6443;
        proxy_pass    kube_apiserver;
        proxy_timeout 10m;
        proxy_connect_timeout 1s;
    }
}

EOF
}


nginxs(){
  cat>$1 <<EOF
[Unit]
Description=K8S apiserver docker  nginx-proxy
Wants=docker.socket
After=docker.service

[Service]
User=root
PermissionsStartOnly=true
ExecStart=/usr/bin/docker run -p 127.0.0.1:6443:6443 \
                              -v $base/$nginxf:/etc/nginx/$nginxf \
                              --name nginx-proxy \
                              --net=host \
                              --restart=on-failure:5 \
                              --memory=512M \
                             $nginx_image
ExecStartPre=-/usr/bin/docker rm -f nginx-proxy
ExecStop=/usr/bin/docker stop nginx-proxy
Restart=always
RestartSec=15s
TimeoutStartSec=30s

[Install]
WantedBy=multi-user.target
EOF
}



nginxf="nginx.conf"



create(){
   for i in $@; do
    echo "开始生成:"$i    ${i##*.}   ${i%%.*}
     yml=$base/$i
     
     ${i##*.}  $yml
   
  done

}

arr=($kubelf $envf $servicef $nginxf)

[ -d "$logs" ] || { echo "没有目录,创建目录..." && mkdir -p $logs ; }
[ -d "/var/lib/$name" ] || { echo "没有目录/var/lib/$name,创建目录..." && mkdir -p /var/lib/$name ; }

create ${arr[@]}


localname=
status=
pid(){
  status=$(systemctl status $1 | grep Active: | sed 's/.*(\([a-z]*\)).*/\1/g')
}


prepare(){
  [ -n "$(command -v $1)" ] || { echo "需要使用到$1,请下载并配置好使用环境..." && exit 1 ;}
  [ -f "/etc/docker/daemon.json" ] || { echo "私库配置有问题..." && exit 1; }
}


ss='{print$1":"$2}'

getim(){
     str=${1%%:*}
    localname=$(docker images | grep $str | awk $ss )
    echo ">>>>>str:$str  $ss "
}

check(){
  [ "$1" = "$localname" ] || { echo "docker pull $1" && docker pull $1  && getim $1; }
  echo "localname:$localname"
  [ "$1" = "$localname" ] || {  echo "拉取镜像,检查私库是否可以请求,镜像名称$1是否正确..." &&  exit 1; }
}

pull(){
    getim $1
    check $1
}

ens(){
  cp -r $1 /usr/lib/systemd/system
   systemctl daemon-reload
   systemctl enable $2
   systemctl start $2
}


judge(){
  pid kube-apiserver
  #docker stop nginx-proxy && docker rm $(docker ps -a -q)
  [ "$status" = "running" ] && { echo "master 不安装代理..." && return ; }  

  [ -f "$base/nginx-proxy.service" ] || { nginxs $base/nginx-proxy.service ;} 

  pid nginx-proxy
  [ "$status" = "running" ] || { echo "nginx-proxy获取状态为:$status ,重安装..."  && ens  $base/nginx-proxy.service  nginx-proxy ; }

}



insp(){
  prepare docker
  pid docker
  [ "$status" = "running" ] || { echo "docker获取状态为:$status ,请检查..."  && exit 1 ; }
  pull $pause_image
  
  pull $nginx_image
  
  judge
}

insp

#kubelet请求apiserver通过会生成client-certificate: /var/lib/kubelet/pki/kubelet-client-current.pem
#--kubeconfig=/opt/kubernetes/config/kubelet.kubeconfig
[  -f "$config/$name.kubeconfig" ] && { cat $config/$name.kubeconfig  | grep "pki\/kubelet-client-current.pem" | wc -l | xargs  -I var [ var -ne 2 ] && rm $config/$name.kubeconfig  ;}

tokenid=$(cat /opt/kubernetes/config/token.csv | awk -F ',' '{print $1}')
sed -i  "s#token.*#token: $tokenid#g" $config/bootstrap.kubeconfig