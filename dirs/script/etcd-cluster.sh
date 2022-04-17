#!/bin/bash
baseFile=/opt/kubernetes/pem

ips="https://192.168.56.101:2379,https://192.168.56.102:2379,https://192.168.56.103:2379"

prefix=${2:-"/atomic.io/network/config"}

h=" endpoint health"
s=" endpoint status"

temp="{\"Network\":\"121.21.0.0/16\",\"Backend\":{\"Type\":\"vxlan\"}}"
exec(){
    arr=$@
    cd /opt/kubernetes/etcd

	ETCDCTL_API=2  ./etcdctl --ca-file=$baseFile/ca.pem \
	  --cert-file=$baseFile/kubernetes.pem \
	  --key-file=$baseFile/kubernetes-key.pem \
	  --endpoints=$ips \
	  $arr
}


exec3(){
    arr=$@
    cd /opt/kubernetes/etcd

  ETCDCTL_API=3  ./etcdctl  --write-out=table \
     --cacert=$baseFile/ca.pem \
     --cert=$baseFile/kubernetes.pem \
     --key=$baseFile/kubernetes-key.pem \
     --endpoints=$ips \
    $arr
}
 

usege(){
  echo "---------------------------:"
  echo " default  endpoint health "
  echo "Usage: $0 {get|add|del|list|l|status|s}"
}


#启动 flanneld 需要先设置数据
exec set $prefix  $temp

case $1 in
	  get)
       #查询值
		exec get $prefix
    ;;
    add)
        #  etcd 证书要包括 节点
       #exec member add node04  $node04Ip
    ;;
    del)
       #  key del val 
       exec rmdir $prefix

       #etcdctl member remove d94f291ab88a467c
	   ;;
	 status|s)
       exec3  $s
	   ;;
      list|l)
         exec   member list
     ;;
	  *)
      exec3  $h
     
	;;
esac



:<<EOF
Couldn't fetch network config: client: response is invalid json. The endpoint is probably not valid etcd cluster endpoint.
v0.12.0 not support etcd3

ETCDCTL_API=2
--enable-v2=true 


EOF