#!/bin/bash

#目录
DIR="$(cd "$(dirname "$0")" && pwd)"
#文件执行生成的目录
base=$DIR/config
[ -d "$base" ] || { echo "没有$base,创建目录..." && mkdir -p $base ; }

#生成token 变量    api和kubelet要一致
export BOOTSTRAP_TOKEN=$(head -c 16 /dev/urandom | od -An -t x | tr -d ' ')

cat > $base/token.csv <<EOF
${BOOTSTRAP_TOKEN},kubelet-bootstrap,10001,"system:kubelet-bootstrap"
EOF






