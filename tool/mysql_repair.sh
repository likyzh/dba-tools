#!/bin/bash
# 目的: 用于执行repair.py脚本

# 进入脚本所在工作目录
cd `dirname $0`

# 导入功能脚本
source ../common/basic_function.sh

# 导入mysql包
export LD_LIBRARY_PATH=${PYTHON_LIB_DIR}

# 传入参数
MYSQL_PORT=$1
shift
MYSQL_EXE_COMMAND="$@"

# 基础变量
PWD_LIST_FILE="../common/mysql_pwd_list"
SCRIPTS_MYSQL_REPL_REPAIR="../lib/mysql_repl_repair.py"

# 获取socket
MYSQL_SOCKET=`ps -ef | grep -w "port=${MYSQL_PORT}" | grep -v grep | awk '{if(match($0,".*socket=([^; ]*)",a))print a[1]}' | head -1`
# 检测该端口是否启动
checkInstance "Port: ${MYSQL_PORT} Instance is not online." ${MYSQL_SOCKET} 
# 确认正确的密码
MYSQL_PASSWORD=`checkMysqlPasswd ${MYSQL_SOCKET} ${PWD_LIST_FILE}`
checkInstance "Socket:${MYSQL_SOCKET},Without the correct password, add the available password in the ${PWD_LIST_FILE}!" ${MYSQL_PASSWORD}

# 进行恢复
echoGreen "Execute: ${BIN_PYTHON} ${SCRIPTS_MYSQL_REPL_REPAIR} -u ${MYSQL_USER} -p ${MYSQL_PASSWORD} -S ${MYSQL_SOCKET}"
${BIN_PYTHON} ${SCRIPTS_MYSQL_REPL_REPAIR} -u ${MYSQL_USER} -p ${MYSQL_PASSWORD} -S ${MYSQL_SOCKET}
