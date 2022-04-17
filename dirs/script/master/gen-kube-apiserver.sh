#!/bin/sh

source ./env.sh


:<<EOF
https://kubernetes.io/zh/docs/reference/command-line-tools-reference/kube-apiserver/
 --cert-dir=$ssl       如果提供了 --tls-cert-file 和 --tls-private-key-file 标志值，则将忽略此标志
endpoint轮询
--apiserver-count   默认值：1 必须为正数。 （在启用 --endpoint-reconciler-type=master-count 时使用。）

--runtime-config    api/all=true	  控制所有 API 版本

--token-auth-file=$config/token.csv

--audit-policy-file=xxx.yml 记录单个用户、管理员或系统其他组件影响系统的活动顺序
[auditing-level]。已知的审计级别有：
None -符合这条规则的日志将不会记录。
Metadata -记录请求的 metadata（请求的用户、timestamp、resource、verb 等等），但是不记录请求或者响应的消息体。
Request -记录事件的 metadata 和请求的消息体，但是不记录响应的消息体。这不适用于非资源类型的请求。
RequestResponse -记录事件的 metadata，请求和响应的消息体。这不适用于非资源类型的请求。

flanneld不支持 Network policy
  --alsologtostderr   \
 --audit-policy-file=$base/audit-policy.yaml   \
 	--audit-log-format=json    \
	--audit-log-path=/var/log/kubernetes/k8s-audit   \
	--audit-log-maxage=30 \
	--audit-log-maxbackup=3   \
	--audit-log-maxsize=100   \

 systemctl daemon-reload
 systemctl enable kube-apiserver
 systemctl start kube-apiserver
 systemctl status kube-apiserver

EOF

yaml(){
	cat>$1<<EOF
apiVersion: audit.k8s.io/v1beta1 # This is required.
kind: Policy
# Don't generate audit events for all requests in RequestReceived stage.
omitStages:
  - "RequestReceived"
rules:
  # Log pod changes at RequestResponse level
  - level: RequestResponse
    resources:
    - group: ""
      # Resource "pods" doesn't match requests to any subresource of pods,
      # which is consistent with the RBAC policy.
      resources: ["pods"]
  # Log "pods/log", "pods/status" at Metadata level
  - level: Metadata
    resources:
    - group: ""
      resources: ["pods/log", "pods/status"]

  # Don't log requests to a configmap called "controller-leader"
  - level: None
    resources:
    - group: ""
      resources: ["configmaps"]
      resourceNames: ["controller-leader"]

  # Don't log watch requests by the "system:kube-proxy" on endpoints or services
  - level: None
    users: ["system:kube-proxy"]
    verbs: ["watch"]
    resources:
    - group: "" # core API group
      resources: ["endpoints", "services"]

  # Don't log authenticated requests to certain non-resource URL paths.
  - level: None
    userGroups: ["system:authenticated"]
    nonResourceURLs:
    - "/api*" # Wildcard matching.
    - "/version"

  # Log the request body of configmap changes in kube-system.
  - level: Request
    resources:
    - group: "" # core API group
      resources: ["configmaps"]
    # This rule only applies to resources in the "kube-system" namespace.
    # The empty string "" can be used to select non-namespaced resources.
    namespaces: ["kube-system"]

  # Log configmap and secret changes in all other namespaces at the Metadata level.
  - level: Metadata
    resources:
    - group: "" # core API group
      resources: ["secrets", "configmaps"]

  # Log all other resources in core and extensions at the Request level.
  - level: Request
    resources:
    - group: "" # core API group
    - group: "extensions" # Version of group should NOT be included.

  # A catch-all rule to log all other requests at the Metadata level.
  - level: Metadata
    # Long-running requests like watches that fall under this rule will not
    # generate an audit event in RequestReceived.
    omitStages:
      - "RequestReceived"

EOF
}



env(){
	cat>$1<<EOF
KUBE_API_ARGS="--advertise-address=$localIp \
	--bind-address=$localIp \
	--storage-backend=etcd3  \
	--service-cluster-ip-range=$ipr \
	--service-node-port-range=1000-65535 \
	--enable-admission-plugins=$admission \
	--authorization-mode=Node,RBAC \
	--runtime-config=api/all=true \
	--enable-bootstrap-token-auth \
	--token-auth-file=$config/token.csv \
	--tls-cert-file=$ssl/kubernetes.pem \
	--tls-private-key-file=$ssl/kubernetes-key.pem \
	--client-ca-file=$ssl/ca.pem \
	--service-account-key-file=$ssl/ca-key.pem \
	  --kubelet-certificate-authority=$ssl/ca.pem \
	--kubelet-client-certificate=/$ssl/kubernetes.pem \
	--kubelet-client-key=$ssl/kubernetes-key.pem \
	--etcd-cafile=$ssl/ca.pem \
	--etcd-certfile=$ssl/kubernetes.pem \
	--etcd-keyfile=$ssl/kubernetes-key.pem \
	--etcd-servers=$etcdIps  \
	--allow-privileged=true \
	--log-dir=$logs   \
	--logtostderr=$stderr  \
	--v=$lv"
EOF
}




service(){
	cat>$1 <<EOF
[Unit]
Description=Kubernetes kube-apiserver Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=network.target
After=etcd.service
Requires=etcd.service

[Service]
EnvironmentFile=$base/$name.env
ExecStart=$exec  \$KUBE_API_ARGS
Restart=on-failure

[Install]
WantedBy=multi-user.target
WantedBy=multi-user.target
EOF
}





create(){
   for i in $@; do
    echo "开始生成:"$i    ${i##*.}   ${i%%.*}
     yml=$base/$i
     
     ${i##*.}  $yml
   
  done

}

arr=($yamlf $envf $servicef)

[ -d "$logs" ] || { echo "没有$logs目录,创建目录..." && mkdir -p $logs ; }

create ${arr[@]}
