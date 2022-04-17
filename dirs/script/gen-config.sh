#!/bin/bash

source  ./env.sh


:<<FI

token(){
#生成token 变量    api和kubelet要一致
export BOOTSTRAP_TOKEN=$(head -c 16 /dev/urandom | od -An -t x | tr -d ' ')

cat > $base/token.csv <<EOF
${BOOTSTRAP_TOKEN},kubelet-bootstrap,10001,"system:kubelet-bootstrap"
EOF

}


FI





#[ -z "$(find $ssl  -iname  *.pem -print -quit)" ] || { echo "查找到如下pem..." && find $ssl  -iname  *.pem ; }



[ -f "$k8s/token.csv" ] || { echo "请在宿主机先生成该文件" && exit 1 ;}
#cat ./config/token.csv |  awk -F ',' '{print$1}'
[ -f "$base/token.csv" ] || { mv $k8s/token.csv  $base/token.csv ;}

BOOTSTRAP_TOKEN=$( cat $base/token.csv |  cut -d ',' -f 1 )
echo "token:$BOOTSTRAP_TOKEN"

genconf(){
    echo "开始生成$1.kubeconfig   ip:$KUBE_APISERVER"
    echo "设置集群参数--server为master节点ip"
    [ -f "$ssl/ca.pem" ] || { echo "没有$ssl/ca.pem..." && exit 1 ;}
    /opt/kubernetes/amd64/kubectl config set-cluster kubernetes \
      --certificate-authority=$ssl/ca.pem \
      --embed-certs=true \
      --server=$KUBE_APISERVER \
      --kubeconfig=$base/$1.kubeconfig



      echo "设置客户端认证参数...$1"  
    if [ $1 == "bootstrap" ];then
        /opt/kubernetes/amd64/kubectl config set-credentials $2 \
          --token=${BOOTSTRAP_TOKEN} \
          --kubeconfig=$base/$1.kubeconfig
    else

        [ -f "$ssl/$3.pem" ] || { echo "没有$ssl/$3.pem..." && exit 1 ;}   
        /opt/kubernetes/amd64/kubectl config set-credentials $2 \
          --client-certificate=$ssl/$3.pem \
          --client-key=$ssl/$3-key.pem \
          --embed-certs=true \
          --kubeconfig=$base/$1.kubeconfig
    fi
   

      echo "设置上下文参数"
    /opt/kubernetes/amd64/kubectl config set-context ${4:-"default"} \
      --cluster=kubernetes \
      --user=$2 \
      --kubeconfig=$base/$1.kubeconfig
 
    echo "设置默认上下文"
    /opt/kubernetes/amd64/kubectl config use-context ${4:-"default"} --kubeconfig=$base/$1.kubeconfig

  
  echo "=======ls -l $1"
  ls -l  $base/$1.kubeconfig
}

create(){
    for i in $@; do
    echo "===============开始:$i======================="
    ##1.程序名  2.对应user   3.pem密钥名   4.对应name current-context
      #/opt/kubernetes/amd64/kubectl和api通信
       # cp -r $base/$1.kubeconfig  ~/.kube/config
       [ $i != "kubectl" ] || {  genconf $i  admin admin  admin@kubernetes; }    
      #  [ $i != "bootstrap" ] || {   genconf $i  kubelet-bootstrap ; }  
     
      # [ $i != "kube-proxy" ] || { genconf $i  system:$i  $i  system:$i@kubernetes; }
      # [ $i != "kube-controller-manager" ] || { genconf $i  system:$i  $i  system:$i@kubernetes; }
      # [ $i != "kube-scheduler" ] || { genconf $i  system:$i  $i  system:$i@kubernetes; }
  done
}


arr=("kubectl" "bootstrap" "kube-proxy" "kube-controller-manager" "kube-scheduler")
create ${arr[@]}
