#!/bin/bash
# 目的: 用于实时监控mysql的相关操作

# 进入脚本所在工作目录
cd `dirname $0`

# 导入功能脚本
source ../common/basic_function.sh

# 基本参数
PWD_LIST_FILE="../common/mysql_pwd_list"
SCRIPT_ORZ="../lib/orz"

# 传入参数
MYSQL_PORT=$1

# 获取socket
MYSQL_SOCKET=`ps -ef | grep -w "port=${MYSQL_PORT}" | grep -v grep | awk '{if(match($0,".*socket=([^; ]*)",a))print a[1]}' | head -1`
# 检测该端口是否启动
checkInstance "Port: ${MYSQL_PORT} Instance is not online." ${MYSQL_SOCKET}
# 确认正确的密码
MYSQL_PASSWORD=`checkMysqlPasswd ${MYSQL_SOCKET} ${PWD_LIST_FILE}`
checkInstance "Socket:${MYSQL_SOCKET},Without the correct password, add the available password in the ${PWD_LIST_FILE}!" ${MYSQL_PASSWORD}

# 执行orz命令
perl ${SCRIPT_ORZ} -u ${MYSQL_USER} -p ${MYSQL_PASSWORD} -S ${MYSQL_SOCKET} -lazy -innodb_rows -innodb_data -mysql 
