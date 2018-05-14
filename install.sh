#!/bin/bash
# 目的：快速安装dbs、dba命令


basepath=$(cd `dirname $0`; pwd)
basedir=`cd ~; pwd`

bash_file="${basedir}/.bashrc"
dbs_test=`cat ${bash_file} | grep "dbs="`
dba_test=`cat ${bash_file} | grep "dba="`
go_test=`cat ${bash_file} | grep "go="`

dbs_scripts="${basepath}/dbs.sh"
dba_scripts="${basepath}/dba.sh"
go_scripts="${basepath}/go.sh"
mysql_pwd_list_file="${basepath}/common/mysql_pwd_list"
mongo_pwd_list_file="${basepath}/common/mongo_pwd_list"

echo "[INFO] Start to install dbs/dba/go tools."
echo "" >> ${bash_file}

if [ ! -n "${dbs_test}" ];then
    echo "[INFO] Execute: echo \"alias dbs=\"sh ${dbs_scripts}\"\" >> ${bash_file}"
    echo "alias dbs=\"sh ${dbs_scripts}\"" >> ${bash_file}
else
    echo "[Warning] alias dbs is exist.Skip install dbs."
fi
if [ ! -n "${go_test}" ];then
    echo "[INFO] Execute: echo \"alias go=\"sh ${go_scripts}\"\" >> ${bash_file}"
    echo "alias go=\"sh ${go_scripts}\"" >> ${bash_file}
else
    echo "[Warning] alias go is exist.Skip install go."
fi
if [ ! -n "${dba_test}" ];then
    echo "[INFO] Execute: echo \"alias dba=\"sh ${dba_scripts}\"\" >> ${bash_file}"
    echo "alias dba=\"sh ${dba_scripts}\"" >> ${bash_file}
else
    echo "[Warning] alias dba is exist.Skip install dba."
fi

if [ ! -f "${mysql_pwd_list_file}" ];then
    touch ${mysql_pwd_list_file}
fi
if [ ! -f "${mongo_pwd_list_file}" ];then
    touch ${mongo_pwd_list_file}
fi

echo "[INFO] The installation is complete."


