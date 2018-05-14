#!/bin/bash
# 目的: 用于批量kill mysql 连接

# 进入脚本所在工作目录
cd `dirname $0`

# 导入功能脚本
source ../common/basic_function.sh

# 基本参数
PWD_LIST_FILE="../common/mysql_pwd_list"

# 传入参数
COMMAND=$1
shift
MYSQL_PORT=$1
shift
PARAMETER="$@"

kill_user(){
    MYSQL_PORT=$1
    USER_NAEM=$2

    checkInstance "dba killuser 4306 username" ${MYSQL_PORT}
    checkInstance "dba killuser 4306 username" ${USER_NAEM}
    echoGreen "Start to Kill.Port:${MYSQL_PORT} User: ${USER_NAEM}"
    # 获取socket
    MYSQL_SOCKET=`ps -ef | grep -w "port=${MYSQL_PORT}" | grep -v grep | awk '{if(match($0,".*socket=([^; ]*)",a))print a[1]}' | head -1`
    #checkInstance "Port: ${MYSQL_PORT} Instance is not online." ${MYSQL_SOCKET}
    if [ ! -n "${MYSQL_SOCKET}" ];then
	echoRed "Port: ${MYSQL_PORT} Instance is not online."
	return 1
    fi

    # 确认正确的密码
    MYSQL_PASSWORD=`checkMysqlPasswd ${MYSQL_SOCKET} ${PWD_LIST_FILE}`
    #checkInstance "Socket:${MYSQL_SOCKET},Without the correct password, add the available password in the ${PWD_LIST_FILE}!" ${MYSQL_PASSWORD}
    if [ ! -n "${MYSQL_PASSWORD}" ];then
	echoRed "Socket:${MYSQL_SOCKET},Without the correct password, add the available password in the ${PWD_LIST_FILE}!"
	return 1
    fi
    
    # 获取该用户的连接 
    KILL_SQL=`${BIN_MYSQL} -u${MYSQL_USER} -p${MYSQL_PASSWORD} -S ${MYSQL_SOCKET} -e "select concat('kill ',id,';') from information_schema.processlist where USER = '${USER_NAEM}';" 2>/dev/null | grep -v concat`
    #checkInstance "The Instance is no user:${USER_NAEM}" ${KILL_SQL}
    if [ ! -n "${KILL_SQL}" ];then
	echoRed "The Instance is no user:${USER_NAEM}."
	return 1
    fi
    
    # kill 连接
    ${BIN_MYSQL} -u${MYSQL_USER} -p${MYSQL_PASSWORD} -S ${MYSQL_SOCKET} -e "${KILL_SQL}" 2>/dev/null
    checkReturnCode $?
}

# kill all session
kill_all(){
    MYSQL_PORT=$1
    
    checkInstance "dba killall 4306" ${MYSQL_PORT}

    # 开始kill
    echoGreen "Start to Kill all session.Port:${MYSQL_PORT}"
    # 获取socket
    MYSQL_SOCKET=`ps -ef | grep -w "port=${MYSQL_PORT}" | grep -v grep | awk '{if(match($0,".*socket=([^; ]*)",a))print a[1]}' | head -1`
    if [ ! -n "${MYSQL_SOCKET}" ];then
	echoRed "Port: ${MYSQL_PORT} Instance is not online."
	return 1
    fi

    # 确认正确的密码
    MYSQL_PASSWORD=`checkMysqlPasswd ${MYSQL_SOCKET} ${PWD_LIST_FILE}`
    if [ ! -n "${MYSQL_PASSWORD}" ];then
	echoRed "Socket:${MYSQL_SOCKET},Without the correct password, add the available password in the ${PWD_LIST_FILE}!"
	return 1
    fi

    # 获取该用户的连接
    KILL_SQL=`${BIN_MYSQL} -u${MYSQL_USER} -p${MYSQL_PASSWORD} -S ${MYSQL_SOCKET} -e "select concat('kill ',id,';') from information_schema.processlist where USER not in ('dbagent','system user','repl','root','sys','db_backup','pxb','mysqlbeat');" 2>/dev/null | grep -v concat`
    if [ ! -n "${KILL_SQL}" ];then
	echoRed "The Instance is no user."
	return 1
    fi
    
    # kill all session
    ${BIN_MYSQL} -u${MYSQL_USER} -p${MYSQL_PASSWORD} -S ${MYSQL_SOCKET} -e "${KILL_SQL}" 2>/dev/null
    checkReturnCode $?
}

# execute all port
execute_all_port(){
    COMMAND=$1
    shift
    PARAMETER=$@
    
    # 进行危险警告
    dangerWarning "Kill all MySQL's session is a dangerous operation"
    
    # 获取mysql socket cnf
    MYSQL_SOCKETS_CNFS_PORTS=`ps -ef | grep "mysqld --defaults-file" | grep -vE 'grep|mysqld_safe|\-p |\-px |xtrabackup' | awk '{if(match($0,".*defaults-file=([^; ]*)",a));if(match($0,".*socket=([^; ]*)",b));if(match($0,".*port=([^; ]*)",c));print a[1]","b[1]","c[1]}' | sort -t"," -k 3 -n | uniq`
    # 批量执行
    for MYSQL_SOCKET_CNF_PORT in ${MYSQL_SOCKETS_CNFS_PORTS}
    do
	MYSQL_PORT=`echo ${MYSQL_SOCKET_CNF_PORT} | awk -F ',' '{print $3}'`
	${COMMAND} ${MYSQL_PORT} ${PARAMETER}
    done
}

# 执行脚本
if [ "${MYSQL_PORT}" = "all" ];then
    execute_all_port ${COMMAND} ${PARAMETER}
else
    ${COMMAND} ${MYSQL_PORT} ${PARAMETER}
fi
