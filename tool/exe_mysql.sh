#!/bin/bash
# function: 获取基础的mysql基础的信息

# 进入脚本所在工作目录
cd `dirname $0`

# 导入功能脚本
source ../common/basic_function.sh

# 基本参数
PWD_LIST_FILE="../common/mysql_pwd_list"

# 传入参数
MYSQL_PORT=$1
shift
MYSQL_EXE_COMMAND="$@"

# 帮助文档
usage() {
    echo "dba exe 4306 \"show slave status\G\" or dba exe all \"show master status\G\""
}

# 执行单个端口
exeCommand(){
    # 获取socket
    MYSQL_SOCKET=`ps -ef | grep -w "port=${MYSQL_PORT}" | grep -v grep | awk '{if(match($0,".*socket=([^; ]*)",a))print a[1]}' | head -1`
    # 检测该端口是否启动
    checkInstance "Port: ${MYSQL_PORT} Instance is not online." ${MYSQL_SOCKET}
    # 确认正确的密码
    MYSQL_PASSWORD=`checkMysqlPasswd ${MYSQL_SOCKET} ${PWD_LIST_FILE}`
    checkInstance "Socket:${MYSQL_SOCKET},Without the correct password, add the available password in the ${PWD_LIST_FILE}!" ${MYSQL_PASSWORD}
	
    MYSQL="${BIN_MYSQL} -u${MYSQL_USER} -p${MYSQL_PASSWORD} -S ${MYSQL_SOCKET}"
    ${MYSQL} -e "${MYSQL_EXE_COMMAND}" 2>/dev/null
    if [ $? -eq 0 ];then
        echoGreen "Port: ${MYSQL_PORT} execute: ${MYSQL_EXE_COMMAND}"
    else
        echoRed "Port: ${MYSQL_PORT} Socket: ${MYSQL_SOCKET} execute: ${MYSQL_EXE_COMMAND} is bad. Please check."
	return 1
    fi
}

# 批量执行命令
executeAllSql(){
    # 获取mysql socket cnf
    MYSQL_SOCKETS_CNFS_PORTS=`ps -ef | grep "mysqld --defaults-file" | grep -vE 'grep|mysqld_safe|\-p |\-px |xtrabackup' | awk '{if(match($0,".*defaults-file=([^; ]*)",a));if(match($0,".*socket=([^; ]*)",b));if(match($0,".*port=([^; ]*)",c));print a[1]","b[1]","c[1]}' | sort -t"," -k 3 -n | uniq`
    # 检查是否有实例
    checkInstance "The machine have no database available." ${MYSQL_SOCKETS_CNFS_PORTS}

    # 批量执行
    for MYSQL_SOCKET_CNF_PORT in ${MYSQL_SOCKETS_CNFS_PORTS}
    do
	MYSQL_SOCKET=`echo ${MYSQL_SOCKET_CNF_PORT} | awk -F ',' '{print $2}'`
	MYSQL_PORT=`echo ${MYSQL_SOCKET_CNF_PORT} | awk -F ',' '{print $3}'`
        # 确认正确的密码
        MYSQL_PASSWORD=`checkMysqlPasswd ${MYSQL_SOCKET} ${PWD_LIST_FILE}`
	checkInstance "Socket:${MYSQL_SOCKET},Without the correct password, add the available password in the ${PWD_LIST_FILE}!" ${MYSQL_PASSWORD}
	
	MYSQL="${BIN_MYSQL} -u${MYSQL_USER} -p${MYSQL_PASSWORD} -S ${MYSQL_SOCKET}"
	${MYSQL} -e "${MYSQL_EXE_COMMAND}" 2>/dev/null
        if [ $? -eq 0 ];then
             echoGreen "Port: ${MYSQL_PORT} execute: ${MYSQL_EXE_COMMAND}"
        else
             echoRed "Port: ${MYSQL_PORT} Socket: ${MYSQL_SOCKET} execute: ${MYSQL_EXE_COMMAND} is bad. Please check."
        fi
    done
}

# 参数判断
if [ ! -n "${MYSQL_PORT}" -o ! -n "${MYSQL_EXE_COMMAND}" ];then
    usage
elif [ "${MYSQL_PORT}" = "all" ];then
    executeAllSql
else
    exeCommand 
fi
