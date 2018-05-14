# ################################################################
#!/bin/bash
# auter：Zaki
# 目的：基本功能函数脚本和基础变量
# 时间：2017年12月27日
# ################################################################

# 进入脚本所在工作目录
cd `dirname $0`

# 导入基础变量
PROJECT_NAME="dba-tools"
PROJECT_DIR=`pwd | awk -F "${PROJECT_NAME}" '{print $1}'`"${PROJECT_NAME}"
source "${PROJECT_DIR}/common/vars_conf.sh" 

# 基础工具
BIN_MYSQL_DIR="${MYSQL_DIR}/bin"
BIN_MONGO_DIR="${MONGO_DIR}/bin"
BIN_GREP="/bin/grep"
BIN_WHICH="/usr/bin/which"
BIN_PYTHON="${PYTHON_DIR}/bin/python"
PYTHON_LIB_DIR="${PYTHON_DIR}/lib"
# 本机实际ip
LOCAL_IP="127.0.0.1"
INSTANCE_IP=`/sbin/ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v 192.168.122.1|grep -v inet6|awk '{print $2}'|tr -d "addr:"|sort -n | head -n 1`
# 时间
DATE_TIME=`date "+%Y-%m-%d %H:%M:%S"`
DATE_TODAY=`date "+%Y%m%d"`
DATE_TIMESTAMP=`date "+%Y%m%d_%H%M%S"`
# 其他变量
SCRIPETS_NAME=`echo $0 | awk -F '.' '{print $1}' | awk -F '/' '{print $NF}'`
SCRIPETS_PATH=`cd "$(dirname $0)"; pwd`
RANDOM_STRING=`date +%s%N | md5sum | head -c 5`
# 日志存储
LOG_DIR="${SCRIPETS_PATH}/log"
COMMON_LOG_FILE="${LOG_DIR}/${SCRIPETS_NAME}_${DATE_TODAY}.log"
EXECUTE_LOG_FILE="`pwd`/log/execute${DATE_TODAY}.log"

# ################################################################
# mysql mongo 环境变量检测
# ################################################################
MYSQL_PROFILE=0
MONGO_PROFILE=0
if [ ! -d "${BIN_MYSQL_DIR}" ];then
    BIN_MYSQL=`${BIN_WHICH} mysql --skip-alias 2>/dev/null`
    if [ $? -ne 0 -o ! -n "${BIN_MYSQL}" ];then
        MYSQL_PROFILE=1
    else
    	BIN_MYSQL_DIR=`dirname ${BIN_MYSQL}`
    	if [ $? -ne 0 -o ! -n "${BIN_MYSQL_DIR}" ];then
            MYSQL_PROFILE=1
    	fi
    fi
fi

if [ ! -d "${BIN_MONGO_DIR}" ];then
    BIN_MONGO=`${BIN_WHICH} mongo --skip-alias 2>/dev/null`
    if [ $? -ne 0 -o ! -n "${BIN_MONGO}" ];then
        MONGO_PROFILE=1
    else
    	BIN_MONGO_DIR=`dirname ${BIN_MONGO}`
    	if [ $? -ne 0 -o ! -n "${BIN_MONGO_DIR}" ];then
            MONGO_PROFILE=1
    	fi
    fi
fi


if [ ${MYSQL_PROFILE} -eq 1 -a ${MONGO_PROFILE} -eq 1 ];then
   echo -e "\033[31m[ERROR] Please add mysql or mongo environment variable in the file: ~/.bash_profile.\033[0m" 
   exit 1
fi

BIN_MYSQL="${BIN_MYSQL_DIR}/mysql"
BIN_MYSQLDUMP="${BIN_MYSQL_DIR}/mysqldump"
BIN_MONGO="${BIN_MONGO_DIR}/mongo"
BIN_MONGOSTAT="${BIN_MONGO_DIR}/mongostat"

# ################################################################
# 函数功能：打印字体输出
# 调用方法：checkInstance variables
# ################################################################
printWhite(){
     print_data_length=$1
     print_data=$2
     printf "| %-${print_data_length}s " "${print_data}"
}

printRed(){
     print_data_length=$1
     print_data=$2
     printf "| \033[31m%-${print_data_length}s\033[0m " "${print_data}"
}

printGreen(){
     print_data_length=$1
     print_data=$2
     printf "| \033[32m%-${print_data_length}s\033[0m " "${print_data}"
}

printYellow(){
     print_data_length=$1
     print_data=$2
     printf "| \033[33m%-${print_data_length}s\033[0m " "${print_data}"
}

echoRed(){
     ECHO_TEXT=$1
     echo -e "\033[31m${ECHO_TEXT}\033[0m"
}

echoGreen(){
     ECHO_TEXT=$1
     echo -e "\033[32m${ECHO_TEXT}\033[0m"
}

echoYellow(){
     ECHO_TEXT=$1
     echo -e "\033[33m${ECHO_TEXT}\033[0m"
}

# ################################################################
# 函数功能：输出框架
# 调用方法：framePrintf 4 5 6
# ################################################################
framePrintf(){
    while [ "$1" != "" ]
    do
	frameNum=$1
        printf "+"
        for ((framenum=1;framenum<=${frameNum};framenum++))
        do
             printf "-"
        done
	shift
    done
    if [ ! -n "$1" ];then
    	printf "+\n"
    fi
}

# ################################################################
# 函数功能：判断一个数组最长字符串的长度
# 调用方法：getArrayMaxLength "${name[*]}"  name是一个数组变量
# ################################################################
getArrayMaxLength(){
    array="$1"

    # 初始化最大长度
    max_length=0
    for var in ${array[*]}
    do
	string_length=${#var}
	if [ ${string_length} -gt ${max_length} ];then
	    max_length=${string_length}
	fi
    done
    echo ${max_length}
}

# ################################################################
# 函数功能：检测mysql密码的功能
# 调用方法：getArrayMaxLength socket全路径
# ################################################################
checkMysqlPasswd(){
    socket=$1
    password_file=$2
    # 文件位置
    if [ ! -n "${password_file}" ];then
    	basepath=$(cd `dirname $0`; pwd)
    	password_file="$basepath/common/mysql_pwd_list"
    fi
    while read password
    do
        user="root"
        test_row=`${BIN_MYSQL} -u${user} -p${password} --socket=${socket} -e "select 1" 2>/dev/null`
        if [ $? -eq 0 ];then
            echo ${password}
            return 0
        fi
    done < $password_file
    echo ""
}

# ################################################################
# 函数功能：检测mongo密码的功能
# 调用方法：checkMongoPasswd
# ################################################################
checkMongoPasswd(){
    mongo_port=$1
    password_file=$2
    # 文件位置
    if [ ! -n "${password_file}" ];then
    	basepath=$(cd `dirname $0`; pwd)
    	password_file="$basepath/common/mongo_pwd_list" 
    fi
    while read mongo_pwd
    do
	test_row=`${BIN_MONGO} -u${MONGO_USER} -p${mongo_pwd} --host ${INSTANCE_IP} --port ${mongo_port} admin --eval "1" 2>/dev/null`
	if [ $? -eq 0 ];then
            echo ${mongo_pwd}
            return 0
        fi
    done < $password_file
    echo ""
}

# ################################################################
# 函数功能：检测实例是否为空
# 调用方法：checkInstance "xxx" variables
# ################################################################
checkInstance(){
    print_log=$1
    check_variable=$2 
    if [ ! -n "${check_variable}" ];then
	echo -e "${print_log}"
	exit 1
    fi
}

checkFile(){
    print_log=$1
    check_variable=$2
    if [ ! -f "${check_variable}" ];then
	echoRed "${print_log}"
	exit 1
    fi
}

checkDir(){
    print_log=$1
    check_variable=$2
    if [ ! -d "${check_variable}" ];then
	echoRed "${print_log}"
	exit 1
    fi
}

# ################################################################
# 函数功能：操作crontab
# 调用方法：
# ################################################################
closeCrontabCheckSlave(){
     DATE_TIMESTAMP=`date "+%Y%m%d_%H%M%S"`
     TMP_FILE="/tmp/crontab${DATE_TIMESTAMP}"
     crontab -l > ${TMP_FILE}
     sed -i '/slave/s/^/#&/' ${TMP_FILE}
     crontab ${TMP_FILE}
     rm ${TMP_FILE}
}

openCrontabCheckSlave(){
     DATE_TIMESTAMP=`date "+%Y%m%d_%H%M%S"`
     TMP_FILE="/tmp/crontab${DATE_TIMESTAMP}"
     crontab -l > ${TMP_FILE}
     sed -i '/slave/s/^#//' ${TMP_FILE}
     crontab ${TMP_FILE}
     rm ${TMP_FILE}
}

###########################################################################
# 功能: 获取XML格式配置的某项值
# 使用示例：parsingXmlConfig "/home/ddb/DBClusterConf.xml" pid
# 输出: master-8888.pid
###########################################################################
parsingXmlConfig(){
    XML_CONFIG_FILE=$1
    XML_OPTIONS_NAME=$2
    echo `cat ${XML_CONFIG_FILE} | grep -w ${XML_OPTIONS_NAME} | sed -e "s/.*<${XML_OPTIONS_NAME}>\(.*\)<\/${XML_OPTIONS_NAME}>.*/\1/g"`
}

###########################################################################
# 功能: 打印日志
# 使用示例：printLog "printLog"
# 输出: 2018-01-11 11:23:03 printLog
###########################################################################
checkLogdir(){
   if [ ! -d "${LOG_DIR}" ];then
        mkdir "${LOG_DIR}"
   fi
}

printLog(){
   # 检查文件夹是否存在
   checkLogdir

   INFO_LOG_CONTENTS=$1
   echo -e "[INFO] ${DATE_TIME} ${INFO_LOG_CONTENTS}"
   echo -e "[INFO] ${DATE_TIME} ${INFO_LOG_CONTENTS}" >> ${COMMON_LOG_FILE}
}

printWarning(){
   # 检查文件夹是否存在
   checkLogdir

   WARNING_LOG_CONTENTS=$1
   echoYellow "[WARNING] ${DATE_TIME} ${WARNING_LOG_CONTENTS}"
   echo -e "[WARNING] ${DATE_TIME} ${WARNING_LOG_CONTENTS}" >> ${COMMON_LOG_FILE}
}

printError(){
   # 检查文件夹是否存在
   checkLogdir

   ERROR_LOG_CONTENTS=$1
   echoRed "[ERROR] ${DATE_TIME} ${ERROR_LOG_CONTENTS}"
   echoRed "[ERROR] ${DATE_TIME} Please check the log ${COMMON_LOG_FILE}."
   echo -e "[ERROR] ${DATE_TIME} ${ERROR_LOG_CONTENTS}" >> ${COMMON_LOG_FILE}
   echo -e "[ERROR] ${DATE_TIME} Please check the log ${COMMON_LOG_FILE}." >> ${COMMON_LOG_FILE}
}

###########################################################################
# 功能: 判断返回码是否有错误
# 使用示例:
# 返回：
###########################################################################
checkOk(){
    RETURN_CODE=$?
    if [ ${RETURN_CODE} -ne 0 ];then
	exit 1
    fi
}

checkReturnCode(){
     RETURN_CODE=$1
     if [ ${RETURN_CODE} -eq 0 ];then
        printLog "Success"
     else
        printError "Failed.Please check."
     fi
}

###########################################################################
# 功能: 换算单位,将多少b转换为相应的M/G/T
# 使用示例：
# 输出: 
###########################################################################
unitConversion(){
    CONVERSION=$1
    if [ -n "${CONVERSION}" ];then
        UNIT=0
        result=${CONVERSION}
        result_tmp=`expr ${CONVERSION} / 1024`
        while [ ${result_tmp} -ge 1 ]
        do
            result=${result_tmp}
            result_tmp=`expr ${result} / 1024`
            (( UNIT++ ))
        done
        case ${UNIT} in
            0)
	    result="${result}B"
            ;;
            1)
	    result="${result}K"
            ;;
            2)
	    result="${result}M"
            ;;
            3)
	    result="${result}G"
            ;;
            4)
	    result="${result}T"
            ;;
           # 其他单位报错
            *)
            exit 1
            ;;
        esac
    fi
}

###########################################################################
# 功能: 获取配置文件的绝对路径
# 使用示例：getTrueConfig ./my1.cnf 12345
# 返回参数:result
###########################################################################
getTrueConfig(){
    # 传入参数
    CONFIG_FILE_TMP=$1
    SERVER_PID=$2 
    
    # 判断传入参数是否为空
    if [ ! -n "${CONFIG_FILE_TMP}" -o ! -n "${SERVER_PID}" ];then
	return 1
    fi

    # 获取绝对路径
    if [[ "${CONFIG_FILE_TMP}" =~ "./" ]];then
	CONFIG_FILE_TMP=`echo ${CONFIG_FILE_TMP} | sed 's/^.\///g'`
	SERVER_START_DIR=`pwdx ${SERVER_PID} | awk -F ':' '{print $2}' | sed 's/^[ \t]*//g'`
	CONFIG_FILE=${SERVER_START_DIR}/${CONFIG_FILE_TMP}
    else
	CONFIG_FILE="${CONFIG_FILE_TMP}"
    fi
    
    # 返回
    result=${CONFIG_FILE}
    return 0
}

###########################################################################
# 功能: 解析json字符串
# 使用示例：resolveJson "string" "关键字"
# 返回参数: 关键字的值
###########################################################################
resolveJson(){
    JSON_STRING="$1"
    RESOLVE_NAME="$2"
    # 判断传入参数是否为空
    if [ ! -n "${JSON_STRING}" -o ! -n "${RESOLVE_NAME}" ];then
        return 1
    fi
    
    # 开始解析
    RESOLVE_VALUE=`echo "${JSON_STRING}" | awk -F "\"${RESOLVE_NAME}\" : " '{print $2}' | awk -F',' '{print $1}'`
    if [ $? -ne 0 ];then
	return 1
    fi

    # 返回
    result="${RESOLVE_VALUE}"
    return 0
}

###########################################################################
# 功能: 用于危险操作警告
# 使用示例：输入yes跳过
# 返回参数: 
###########################################################################
dangerWarning(){
    # 传入需要输出的文字
    DANGER_TEXT="$1"
    
    # 进行输入
    printf "\033[31m[Warning]%s. Are You Sure? [Y/n]\033[0m" "${DANGER_TEXT}"
    read -r -p "" input
    
    # 进行确认是否为yes
    case $input in
        [yY][eE][sS]|[yY])
                    return
                    ;;
    
        [nN][oO]|[nN])
                    exit 1
                    ;;
    
        *)
            exit 1
            ;;
    esac
}

# ################################################################
# 函数功能：通过端口获取mysql datadir
# 使用方法：getMysqlDatadir datadir
# ################################################################
getMysqlDatadir(){
    mysql_datadir=$1
    if [ -n "${mysql_datadir}" ];then
        mysql_real_datadir=`readlink ${mysql_datadir%?}`
        if [ ! -n "$mysql_real_datadir" ];then
            echo "${mysql_datadir}" | sed 's/[/]*$//g'
        else
            echo "${mysql_real_datadir}" | sed 's/[/]*$//g'
        fi
    fi
}

# ################################################################
# 函数功能：通过端口获取mysql socket
# 使用方法：getMysqlSocket 3306
# ################################################################
getMysqlSocket(){
    mysql_port=$1
    mysql_socket=`ps -ef | grep -w "port=${mysql_port}" | grep -v grep | awk '{if(match($0,".*socket=([^; ]*)",a))print a[1]}'`
    echo "${mysql_socket}"
}
