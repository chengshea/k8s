#!/bin/bash
:<<EOF
###https://kubernetes.io/docs/tasks/administer-cluster/certificates/
cfssl print-defaults config > config.json
cfssl print-defaults csr > csr.json

EOF

source ./env.sh



[ -n "$(command -v cfssl)" ] || { echo "该脚本需要使用到cfssl,请下载配置好环境变量..." && exit 1 ;}





[ -d "$base" ] || { echo "没有目录,创建目录...$base" && mkdir -p $base ;}
cd $base



usage(){
  echo "使用方法: 必须要参数(kube-proxy|kubernetes|admin|kube-controller-manager|kube-scheduler)"
  echo "例如: ./gencert.sh kubernetes "
  echo ""
}



if [ ! -f "$conf" ]; then
echo "没有ca-config.json文件,生成文件==="
cat >$conf<<EOF
{
    "signing":{
        "default":{
            "expiry":"87600h"
        },
        "profiles":{
            "kubernetes":{
                "expiry":"87600h",
                "usages":[
                    "signing",
                    "key encipherment",
                    "server auth",
                    "client auth"
                ]
            }
        }
    }
}
EOF
fi

if [ ! -f "$csr" ]; then
echo "没有ca-csr.json文件,生成文件==="
cat >$csr<<EOF
{
	"CN": "kubernetes",
	"key": {
		"algo": "rsa",
		"size": 2048
	},
	"names": [{
		"C": "CN",
		"ST": "GuangDong",
		"L": "Shenzhen",
		"O": "k8s",
		"OU": "cs"
	}]
}
EOF
fi

geninit(){
  #根据ca-csr.json生成 CA 密钥 ( ca-key.pem) 和证书 ( ca.pem)
  if [ ! -f "$base/ca.pem" ] && [ ! -f "$base/ca-key.pem" ]; then
  echo "没有ca.pem,ca-key.pem文件,生成文件 ==="
  cfssl gencert -initca $csr | cfssljson -bare ca
  echo "-------------gencert ca----------------$PWD"
  ls -l  ./
  fi

}



generate(){
  geninit
  cj=$base/$1-csr.json
  [ -f "$cj" ] || { echo "没有匹配的json,$cj不存在" && return; }
  echo "===开始为$1 生成 key.pem文件=="
  cfssl gencert \
         -ca=$base/ca.pem \
         -ca-key=$base/ca-key.pem \
         -config=$conf \
         -profile=kubernetes $cj | cfssljson -bare $1  
  echo "-------------gencert kube----------------$PWD"
   ls -l  ./
}


#apiserver-csr.json
gen_kubernetes(){
  url=$base/$1-csr.json
  echo "----开始生成$url-----"
 cat >$url<<EOF
{
    "CN":"kubernetes",
    "hosts": [
    "127.0.0.1",
    "192.168.56.1",
    "192.168.56.101",
    "192.168.56.102",
    "192.168.56.103",
    "192.168.56.104",
    "192.168.56.105",
    "192.168.56.106",
    "192.168.56.107",
    "192.168.56.108",
    "192.168.56.109",
    "192.168.56.111",
    "192.168.56.112",
    "192.168.56.113",
    "192.168.56.114",
    "192.168.56.115",
    "192.168.56.116",
    "121.21.0.1",
    "master01",
    "master02",
    "master03",
    "node04",
    "node05",
    "node06",
    "kubernetes",
    "kubernetes.default",
    "kubernetes.default.svc",
    "kubernetes.default.svc.cluster",
    "kubernetes.default.svc.cluster.local"
  ],
    "key":{
        "algo":"rsa",
        "size":2048
    },
   "names": [{
    "C": "CN",
    "ST": "GuangDong",
    "L": "Shenzhen",
    "O": "k8s",
    "OU": "System"
  }]
}
EOF

}

#kube-controller-manager-csr.json
#kube-scheduler-csr.json  
gen_kube(){
   url=$base/$1-csr.json
   echo "----开始生成$url-----"
cat > $url<<EOF
{
    "CN": "system:$1",
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "hosts": [
    "127.0.0.1",
    "192.168.56.1",
    "192.168.56.101",
    "192.168.56.102",
    "192.168.56.103",
    "192.168.56.104",
    "192.168.56.105",
    "192.168.56.106",
    "192.168.56.107",
    "192.168.56.108",
    "192.168.56.109",
    "192.168.56.116",
    "121.21.0.1",
    "master01",
    "master02",
    "master03",
    "node04",
    "node05",
    "node06"
    ],
    "names": [
      {
            "C": "CN",
           "ST": "GuangDong",
           "L": "Shenzhen",
           "O":"system:$1",
           "OU":"System"
      }
    ]
}
EOF
}




gen_admin(){
  url=$base/$1-csr.json
   echo "----开始生成$url-----"
 cat >$url<<EOF
{
  "CN": "admin",
  "hosts": [],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "BeiJing",
      "L": "BeiJing",
      "O": "system:masters",
      "OU": "System"
    }
  ]
}

EOF

}


genjson(){

 case $1 in
  "kubernetes")     
      gen_kubernetes $1
  ;;
  "kubelet"|"kube-proxy"|"kube-scheduler"|"kube-controller-manager")
         gen_kube $1
  ;;
  "admin")
         gen_admin $1
  ;;
  *)
       usage
        echo "--没有匹配的json,退出"
        exit 1;
  ;;
  esac
}

create(){
    for i in $@; do

      if [ ! -f "$base/$i-key.pem" ]; then
         [ -f "$base/$i-csr.json" ] || {  echo "没有$i-csr.json文件生成" && genjson $i ;}
         generate $i
      fi

  done
}

arr=("admin" "kubelet" "kubernetes" "kube-proxy" "kube-controller-manager" "kube-scheduler")
create ${arr[@]}
