#!/bin/sh


src=/home/cs/data/VM/k8s/dirs/script
exit
dest=/home/cs/
path=/home/cs/data/VM/k8s/roles/k8s/vars



rep(){

	echo "grep $1 -rl --include=\*.{yaml,sh} $3"
	echo "变更结果预览 $format"
	sed -n "s#$1#$2#g"p `grep $1 -rl --include=\*.{yaml,sh} $3`
}

exec(){
	[ -n "$1" ] || { echo "原文本$1为空,无法进行操作" && return; }
	[ -n "$2" ] || { echo "替换文本$2为空" && return ; }
	[ -n "$3" ] || { echo "搜索路径$4为空,默认当前目录" && path={3:-"./"} ; }
	sed -i "s#$1#$2#g" `grep $1 -rl --include=\*.{yaml,sh} $3`
}


rep $src $dest $path


# read -t 10
# read  -p "确认是否执行替换(ok|no) > " var
# echo "$var"
# case $var in 
#    ok)
#     echo "开始替换..."
#    # exec $src $dest $path
#     ;;
#    *)
#     echo "退出操作"
#     exit
# esac


!
exit




:<<EOF
扫描path路径对应格式的文件,把src替换成dest,



sed

-n p 结合打印改变内容,不执行变更

grep
-r 表示查找当前目录以及所有子目录
-l 表示仅列出符合条件的文件名
--include="*.[ch]" 表示仅查找.c、.h文件
上面不适用大多数情况,推荐下面
--include=\*.{yaml,sh}
EOF