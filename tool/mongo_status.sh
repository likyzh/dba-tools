#!/bin/bash
# 目的: 用于mongo监控的相关快捷功能

# 进入脚本所在工作目录
cd `dirname $0`

# 导入功能脚本
source ../common/basic_function.sh

# 基本参数
PWD_LIST_FILE="../common/mongo_pwd_list"

# 传入参数
MONGO_PORT=$1

# 帮助文档
usage(){
    echo "dba mongo 3306"
}

mongoStat(){
    # 获取port
    MONGO_PORT=$1
    # 确认登陆密码
    MONGO_PASSWORD=`checkMongoPasswd ${MONGO_PORT} ${PWD_LIST_FILE}`
    # 连接查看 
    if [ ! -n "${MONGO_PASSWORD}" ];then
       test_row=`${BIN_MONGO} --host ${INSTANCE_IP} --port ${MONGO_PORT} admin --eval "1" 2>/dev/null`
       if [ $? -eq 0 ];then
           # 不使用账号密码登陆
           echo -e " \033[35mIP:\033[0m \033[33m${INSTANCE_IP}\033[0m       \033[35mPort:\033[0m \033[33m${MONGO_PORT}\033[0m"
           ${BIN_MONGOSTAT} --host ${INSTANCE_IP}:${MONGO_PORT} --authenticationDatabase=admin
       else
           echo "没有正确的密码,请在mongo_pwd_list中添加可用的密码!"
           exit
       fi
    else
       	# 使用port进行登陆
        echo -e " \033[35mIP:\033[0m \033[33m${INSTANCE_IP}\033[0m       \033[35mPort:\033[0m \033[33m${MONGO_PORT}\033[0m"
       	${BIN_MONGOSTAT} -u${MONGO_USER} -p${MONGO_PASSWORD} --host ${INSTANCE_IP}:${MONGO_PORT} --authenticationDatabase=admin
    fi
}

if [ ! -n "${MONGO_PORT}" ];then
    usage
else    
    mongoStat ${MONGO_PORT}
fi
