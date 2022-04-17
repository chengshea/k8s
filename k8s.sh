
#!/bin/sh


# cs@nfs:/opt/data/k8s/centos$ tree -L 1
# .
# ├── amd64
# ├── cni
# ├── docker
# ├── docker-18.09.3.tgz
# ├── env.sh
# ├── etcd
# ├── gen-etcd.sh




mount 192.168.56.107:/opt/data/k8s/centos  /mnt

SYSTEMDDIR=/usr/lib/systemd/system
SERVICEFILE=docker.service
SRC=/mnt/docker-18.09.3.tgz

BASE=/opt/kubernetes

[ -f "$SRC" ] || { echo "没有docker二进制包,无法执行安装,退出" && exit 1;}
 
LOCAL=/mnt 

echo "##unzip : tar -zxvf  ${SRC}"
tar -zxvf  ${SRC}  -C /opt
cp -p /opt/docker/*  /usr/bin  
#其他目录无法启动成功,估计是环境变量依赖问题
[ -f "/usr/bin/dockerd" ] && { echo "docker二进制安装/usr/bin/dockerd成功" && rm -rf  /opt/docker;}
 
echo "##systemd service: ${SERVICEFILE}"
cat >${SYSTEMDDIR}/${SERVICEFILE} <<EOF
[Unit]
Description=Docker Application Container Engine
Documentation=http://docs.docker.com
After=network.target docker.socket
[Service]
Type=notify
EnvironmentFile=$BASE/flanneld/subnet.env
WorkingDirectory=/usr/local/bin
ExecStart=/usr/bin/dockerd \
                \$DOCKER_NETWORK_OPTIONS \
                -H unix:///var/run/docker.sock 
ExecReload=/bin/kill -s HUP $MAINPID
# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
TimeoutStartSec=0
# set delegate yes so that systemd does not reset the cgroups of docker containers
Delegate=yes
# kill only the docker process, not all processes in the cgroup
KillMode=process
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF
 
echo "配置私库密钥"
 
cp -R $LOCAL/docker /etc
groupadd docker
#添加当前用户到组
gpasswd -a vagrant docker 

echo "## docker version"
docker -v

echo "复制k8s文件-----"
mkdir -p $BASE/flanneld
cp -r $LOCAL/subnet.env   $BASE/flanneld

cd $BASE

cp -R $LOCAL/{amd64,cni,pem,etcd} $BASE
cp -r $LOCAL/env.sh   $BASE


ser(){
  systemctl daemon-reload
  systemctl enable $1
  systemctl start $1
}

if [[ `hostname` == *"master"* ]];then
  cp -R $LOCAL/etcd   $BASE
  cp  $LOCAL/gen-etcd.sh  $BASE
  bash $BASE/gen-etcd.sh
  echo " cp -r $BASE/etcd/etcd.service  /usr/lib/systemd/system/ "
  cp -r $BASE/etcd/etcd.service  /usr/lib/systemd/system/
   ser etcd
fi

ls -l $BASE
echo "结束复制-----" 




swapoff -a
sed -i 's/^\/swapfile/#\/swapfile/' /etc/fstab
sed  -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
systemctl stop firewalld.service && systemctl disable firewalld.service 

ser docker


#设置时间
rm -rf /etc/localtime
ln -sv /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

echo "安装完成"
