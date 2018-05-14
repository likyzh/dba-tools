#!/bin/bash
# auter：Zaki
# 目的：通过端口快速登录mysql、mongo、ddb

# 进入脚本所在工作目录
cd `dirname $0`

# 导入功能脚本
source ./common/basic_function.sh

# mysql登陆功能
login_mysql(){
    # 获取port
    mysql_port=$1
    # 获取相关信息
    mysql_socket=`ps -ef | grep -w "port=${mysql_port}" | grep -v grep | awk '{if(match($0,".*socket=([^; ]*)",a))print a[1]}'`
    mysql_prompt="(${MYSQL_USER}@${INSTANCE_IP}:${mysql_port}) [\d]>"
    # 确认登陆密码
    mysql_password=`checkMysqlPasswd ${mysql_socket}`
    if [ ! -n "${mysql_password}" ];then
        echo "没有正确的密码,请在pwd_list中添加可用的密码!"
        exit
    fi 

    # 使用socket进行登陆
    ${BIN_MYSQL} -u${MYSQL_USER} -p${mysql_password} --socket=${mysql_socket} --prompt="${mysql_prompt}"
}

login_mongo(){
     # 获取port
     MONGO_PORT=$1
     # 确认登陆密码
     MONGO_PASSWORD=`checkMongoPasswd ${MONGO_PORT}`
     if [ ! -n "${MONGO_PASSWORD}" ];then
	test_row=`${mongo} --host ${INSTANCE_IP} --port ${MONGO_PORT} admin --eval "show dbs" 2>/dev/null`
	if [ $? -eq 0 ];then
	    # 不使用账号密码登陆
	    ${BIN_MONGO} --host ${INSTANCE_IP} --port ${MONGO_PORT} admin
	else
	    ${BIN_MONGO} --host ${LOCAL_IP} --port ${MONGO_PORT} --eval "1" >/dev/null 2>&1
	    if [ $? -eq 0 ];then
		${BIN_MONGO} --host ${LOCAL_IP} --port ${MONGO_PORT}
	    else
            	echo "没有正确的密码,请在pwd_list中添加可用的密码!"
            	exit 1
	    fi
	fi
     else
     	# 使用port进行登陆
     	${BIN_MONGO} -u${MONGO_USER} -p${MONGO_PASSWORD} --host ${INSTANCE_IP} --port ${MONGO_PORT} admin
     fi
}

login_ddb(){
    # 传入参数
    DDB_PORT=$1
    DDB_PID=$2
    # 其他参数
    DDB_SCRIPTS_DIR_PWDX=`pwdx ${DDB_PID}| awk -F ':' '{print $NF}'`
    # 兼容全路径启动ddb的情况
    if [[ "${DDB_SCRIPTS_DIR_PWDX}" =~ "scripts" ]];then
	DDB_SCRIPTS_DIR=${DDB_SCRIPTS_DIR_PWDX}
    else
	DDB_SCRIPTS_DIR_PS=`ps -ef | grep " ${DDB_PID} " | grep -v grep | awk '{print $10}' | awk -F '=' '{print $2}' | awk -F '\\\.\\\.' '{print $1}'`
	if [[ "${DDB_SCRIPTS_DIR_PS}" =~ "./" ]];then
	    DDB_SCRIPTS_DIR_TEMP=`echo ${DDB_SCRIPTS_DIR_PS} | awk -F '\\\./' '{print $2}'` 
	    DDB_SCRIPTS_DIR="${DDB_SCRIPTS_DIR_PWDX}/${DDB_SCRIPTS_DIR_TEMP}"
	else
	    DDB_SCRIPTS_DIR=${DDB_SCRIPTS_DIR_PS}
	fi
    fi

    # 检查dir是否存在
    checkDir "The DDB scripts dir is not exist.DDB_SCRIPTS_DIR: ${DDB_SCRIPTS_DIR}" ${DDB_SCRIPTS_DIR} 
    
    # ddb的相关参数
    DDB_DIR=`dirname ${DDB_SCRIPTS_DIR}`
    DDB_CONFIG_FILE="${DDB_DIR}/conf/DBClusterConf.xml"
    DDB_DBA_PORT=`parsingXmlConfig ${DDB_CONFIG_FILE} dba_port`
    DDB_DBI_PORT=`parsingXmlConfig ${DDB_CONFIG_FILE} port`
    DDB_IP=`parsingXmlConfig ${DDB_CONFIG_FILE} ip`
    DDB_LOG_DIR="isqllog"

    # 检查是否有配置文件
    # 登陆ddb
    printLog "cd ${DDB_SCRIPTS_DIR} && ./isql.sh -U${DDB_USER} -P${DDB_PASSWORD} -h${DDB_IP} -O${DDB_DBA_PORT} -o${DDB_DBI_PORT} -l${DDB_LOG_DIR}"
    cd ${DDB_SCRIPTS_DIR} && ./isql.sh -U${DDB_USER} -P${DDB_PASSWORD} -h${DDB_IP} -O${DDB_DBA_PORT} -o${DDB_DBI_PORT} -l${DDB_LOG_DIR}
}

# 连接数据库函数主函数
connection_database(){
    # 传入port
    PORT=$1
    # 判断port是否为空是否为空
    if [ ! -n "${PORT}" ];then
	echo "请输入端口号，例如go 3306"
	exit
    fi

    # 判断这个port是什么服务
    #name=`netstat -ntlp 2>/dev/null | grep ":${port} " | awk '{print $7}' | awk -F'/' '{print $NF}' | uniq`
    PID_NAME=`netstat -ntlp 2>/dev/null | grep ":${PORT} " | awk '{print $7}'`
    NAME=`echo ${PID_NAME} | awk -F '/' '{print $NF}'`
    PID=`echo ${PID_NAME} | awk -F '/' '{print $1}'`

    if [ ! -n "${NAME}" ];then
	echo "端口${PORT}不存在,请检查!"
    elif [[ "${NAME}" =~ "mysql" ]];then
	# 登陆mysql
	login_mysql ${PORT}
	exit
    elif [[ "${NAME}" =~ "mongo" ]];then
        #echo "mongo"
	login_mongo ${PORT}
	exit
    elif [[ "${NAME}" =~ "java" ]];then
	login_ddb ${PORT} ${PID}
    else
        echo "该端口服务不支持快捷登陆！"
    fi
}

# 连接
connection_database $1
