#!/bin/sh
#
#This shell script takes care of starting and stopping

# 进入脚本所在工作目录
cd `dirname $0`

# 导入功能脚本
source ../common/basic_function.sh

# Source function library.
. /etc/rc.d/init.d/functions

# Source networking configuration.
#. /etc/sysconfig/network

# Set timeouts here so they can be overridden from /etc/sysconfig/mysqld
STARTTIMEOUT=120
STOPTIMEOUT=600

# Echo Usage
usage () {
    #echo $"Usage: sh $0 -c {start|stop|restart|status} --defaults-file ${MYSQL_CONFIG_DIR}/my1.cnf OR sh $0 -c status -p 3306" 1>&2
    echo "Options:
    -c  | --command           {start|stop|restart|status}
    -p  | --port 	      Set mysql port
    -df | --defaults-file     Set mysql defaults-file
    -h  | --help"
}

# Get args
get_args () {
    while [ "$1" != "" ]; do
        case $1 in
            -c | --command )           
                shift
                command=$1
                ;;
            -df | --defaults-file )
		shift
                mysql_config=$1
                ;;
	    -p | --port )
		shift
		mysql_port=$1
		;;
            -h | --help )                
                usage
                exit
                ;;
            * )   
                echo "Unknown option specified!" 
                usage
                exit 1
        esac
        shift
    done
}

# Get command line options 
get_args $*

# 获取配置文件的参数
get_mysql_option () {
    # 传入参数
    default_file=$1
    option=$2
    #default=$3
    shift 2
    # 判断是否mysql_config是否有值
    if [ ! -e ${default_file} ];then
	echo "defaults_file:${default_file} is not exists." 
	exit 5
    fi
    result=$(${bin_my_print_defaults} -c ${default_file} "$@" | sed -n "s/^--${option}=//p" | tail -n 1)
    if [ -z "$result" ]; then
	# not found, use default
	echo "${option} is null in the ${default_file}.Please check."
	exit 1
	#result="${default}"
    fi
}

# 通过port获取defaults_file
get_defaults_file(){
    if [ ! -n "${mysql_config}" -a ! -n "${mysql_port}" ];then
        echo "[ERROR] Defaults-file and Port is null.Please read help info."
	exit 1
    elif [ ! -n "${mysql_config}" -a -n "${mysql_port}" ];then
	mysql_config_test=`${BIN_GREP} -irw "port " ${MYSQL_CONFIG_DIR}/my*.cnf | ${BIN_GREP} -w "${mysql_port}"`

	if [ -n "${mysql_config_test}" ];then
	    mysql_config_test=`echo ${mysql_config_test} | grep ':'`
	    if [ ! -n "${mysql_config_test}" ];then
		mysql_config=`ls ${MYSQL_CONFIG_DIR}/my*.cnf`
		checkOk $?	
	    else
		mysql_config=`${BIN_GREP} -irw "port " ${MYSQL_CONFIG_DIR}/my*.cnf | ${BIN_GREP} -w "${mysql_port}" | awk -F: '{print $1}' | uniq`
		mysql_config_row=`${BIN_GREP} -irw "port " ${MYSQL_CONFIG_DIR}/my*.cnf | ${BIN_GREP} -w "${mysql_port}" | awk -F: '{print $1}' | uniq | wc -l`
		if [ ${mysql_config_row} -gt 1 ];then
             	    echo "[ERROR] Too much defaults file have port: ${mysql_port}. defaults-file:"
	     	    echo "${mysql_config}"
	     	    echo "Please set defaults-file. Example: dba admin -c status --defaults-file ${MYSQL_CONFIG_DIR}/my1.cnf"
             	    exit 1
		elif [ ${mysql_config_row} -eq 0 ];then
	     	    echo "[ERROR] There is no defaults file have port: ${mysql_port}."
	     	    exit 1
		fi
	    fi
	else
	    echo "[ERROR] There is no defaults file have port: ${mysql_port}."
	    exit 1
	fi
    fi
}

# start mysql
start(){
    mysql_config=$1

    # 判断是否存在该配置文件
    if [ ! -f "${mysql_config}" ];then
        echoRed "The config don't exist.File: ${mysql_config}"
        return 1
    fi
    # 基础变量获取
    mysql_dir=`cat ${mysql_config} | ${BIN_GREP} -v '^#' | ${BIN_GREP} basedir | awk -F= '{print $2}' | sed 's/^[ \t]*//g'`
    checkInstance "${mysql_config} don't have basedir,Please add." ${mysql_dir}
    checkDir "${mysql_dir} don't exist." ${mysql_dir} 
    bin_mysqld_safe="${mysql_dir}/bin/mysqld_safe"
    bin_mysqladmin="${mysql_dir}/bin/mysqladmin"
    bin_my_print_defaults="${mysql_dir}/bin/my_print_defaults"

    # 获取参数
    get_mysql_option ${mysql_config} socket mysqld
    mysql_socket=${result}
    get_mysql_option ${mysql_config} datadir mysqld
    datadir=${result}
    get_mysql_option ${mysql_config} pid-file mysqld
    mypidfile=${result}
    prog="mysqld [${mysql_config}] "	
	
    [ -x ${bin_mysqld_safe} ] || exit 5
    # check to see if it's already running
    RESPONSE=$(${bin_mysqladmin} --no-defaults --socket="${mysql_socket}" --user=UNKNOWN_MYSQL_USER ping 2>&1)
    if [ $? = 0 ]; then
	# already running, do nothing
	status -p "$mypidfile" "mysqld"
	ret=0
    elif echo "$RESPONSE" | ${BIN_GREP} -q "Access denied for user"
    then
	# already running, do nothing
	status -p "$mypidfile" "mysqld"
	ret=0
    else
	# 进行启动
	printf "Starting $prog:"
	${bin_mysqld_safe} --defaults-file=${mysql_config} >/dev/null & 
	safe_pid=$!
	# 验证是否启动成功
	ret=0
	TIMEOUT="$STARTTIMEOUT"
	while [ $TIMEOUT -gt 0 ]; do
	    printf "."
	    RESPONSE=$(${bin_mysqladmin} --no-defaults --socket="${mysql_socket}" --user=UNKNOWN_MYSQL_USER ping 2>&1) && break
	    echo "$RESPONSE" | ${BIN_GREP} -q "Access denied for user" && break
	    if ! /bin/kill -0 $safe_pid 2>/dev/null; then
		echo "MySQL Daemon failed to start."
		ret=1
		break
	    fi
	    sleep 1
	    let TIMEOUT=${TIMEOUT}-1
	done
	if [ $TIMEOUT -eq 0 ]; then
	    echo "Timeout error occurred trying to start MySQL Daemon."
	    ret=1
	fi
	if [ $ret -eq 0 ]; then
	    action "" /bin/true
	    #action $"Starting $prog: " /bin/true
	    #touch $lockfile
	else
	    #action $"Starting $prog: " /bin/false
	    action "" /bin/false
	fi
    fi
    return $ret
}

# stop mysql
stop(){
    mysql_config=$1
        
    # 判断是否存在该配置文件
    if [ ! -f "${mysql_config}" ];then
	echoRed "The config don't exist.File: ${mysql_config}"
	return 1
    fi 
    # 基础变量获取
    mysql_dir=`cat ${mysql_config} | ${BIN_GREP} -v '^#' | ${BIN_GREP} basedir | awk -F= '{print $2}' | sed 's/^[ \t]*//g'`
    checkInstance "${mysql_config} don't have basedir,Please add." ${mysql_dir}
    checkDir "${mysql_dir} don't exist." ${mysql_dir} 
    bin_mysqld_safe="${mysql_dir}/bin/mysqld_safe"
    bin_mysqladmin="${mysql_dir}/bin/mysqladmin"
    bin_my_print_defaults="${mysql_dir}/bin/my_print_defaults"
	
    # 获取变量
    get_mysql_option ${mysql_config} pid-file mysqld	
    mypidfile=${result}
    get_mysql_option ${mysql_config} socket mysqld
    mysql_socket=${result}
    prog="mysqld [${mysql_config}] "	

    if [ ! -f "$mypidfile" ]; then
	# not running; per LSB standards this is "ok"
	action "Stopping $prog: " /bin/true
	return 0
    fi
    MYSQLPID=$(cat "$mypidfile")
    if [ -n "$MYSQLPID" ]; then
	printf "Stopping $prog:"
	/bin/kill "$MYSQLPID" >/dev/null 2>&1
	ret=$?
	if [ $ret -eq 0 ]; then
	    TIMEOUT="$STOPTIMEOUT"
	    while [ $TIMEOUT -gt 0 ]
	    do
		printf "."
		/bin/kill -0 "$MYSQLPID" >/dev/null 2>&1 || break
		sleep 1
		let TIMEOUT=${TIMEOUT}-1
	    done
	    if [ $TIMEOUT -eq 0 ]; then
		echo "Timeout error occurred trying to stop MySQL Daemon."
		ret=1
		action "" /bin/false
	    else
		rm -f "$socketfile"
		action "" /bin/true
	    fi
	else
	    action "" /bin/false
	fi
    else
	action "" /bin/false
	ret=4
    fi
    return $ret
}

restart(){
    mysql_config=$1

    stop ${mysql_config}
    start ${mysql_config}
}

mysqlStatus(){
    mysql_config=$1
    # 判断是否存在该配置文件
    if [ ! -f "${mysql_config}" ];then
	echoRed "The config don't exist.File: ${mysql_config}"	
	return 1
    fi

    # 基础变量获取
    mysql_dir=`cat ${mysql_config} | ${BIN_GREP} -v '^#' | ${BIN_GREP} basedir | awk -F= '{print $2}' | sed 's/^[ \t]*//g'`
    checkInstance "${mysql_config} don't have basedir,Please add." ${mysql_dir}
    checkDir "${mysql_dir} don't exist." ${mysql_dir} 
    bin_my_print_defaults="${mysql_dir}/bin/my_print_defaults"
   
    get_mysql_option ${mysql_config} pid-file mysqld
    mypidfile=${result}
    status -p "$mypidfile" "mysqld" 
}

startAll(){
    checkDir "${MYSQL_CONFIG_DIR} don't exist." ${MYSQL_CONFIG_DIR}
    MYSQL_CONFIGS=`ls -ll ${MYSQL_CONFIG_DIR}/my*.cnf | awk '{print $9}'`
    checkInstance "${MYSQL_CONFIG_DIR} There is no mysql config." ${MYSQL_CONFIGS}
    for MYSQL_CONFIG in ${MYSQL_CONFIGS}
    do
	echoGreen "Begin to start mysql. [defaults-file: ${MYSQL_CONFIG}]"
	start ${MYSQL_CONFIG}
    done 
}

stopAll(){
    # 进行危险警告
    dangerWarning "Stop all MySQL's instance is a dangerous operation"
    
    # 开始进行批量关闭
    MYSQL_CONFIGS_PIDS=`ps -ef | grep "mysqld --defaults-file" | grep -vE 'grep|mysqld_safe|\-p |\-px |xtrabackup' | awk '{b=$3;if(match($0,".*defaults-file=([^; ]*)",a));print a[1]","b}' | sort -t"," -k 3 -n | uniq`
    for MYSQL_CONFIG_PID in ${MYSQL_CONFIGS_PIDS}
    do
	# 获取需要使用的参数
        MYSQL_CONFIG_TMP=`echo ${MYSQL_CONFIG_PID} | awk -F ',' '{print $1}'`
        MYSQL_PID=`echo ${MYSQL_CONFIG_PID} | awk -F ',' '{print $2}'`
        getTrueConfig ${MYSQL_CONFIG_TMP} ${MYSQL_PID}
        checkOk
        MYSQL_CONFIG="${result}"

	echoGreen "Begin to stop mysql. [defaults-file: ${MYSQL_CONFIG}]"
	stop ${MYSQL_CONFIG}
    done
}

restartAll(){
    # 进行危险警告
    dangerWarning "Restart all MySQL's instance is a dangerous operation"
    
    # 开始进行批量启动
    MYSQL_CONFIGS_PIDS=`ps -ef | grep "mysqld --defaults-file" | grep -vE 'grep|mysqld_safe|\-p |\-px |xtrabackup' | awk '{b=$3;if(match($0,".*defaults-file=([^; ]*)",a));print a[1]","b}' | sort -t"," -k 3 -n | uniq`
    for MYSQL_CONFIG_PID in ${MYSQL_CONFIGS_PIDS}
    do
	# 获取需要使用的参数
        MYSQL_CONFIG_TMP=`echo ${MYSQL_CONFIG_PID} | awk -F ',' '{print $1}'`
        MYSQL_PID=`echo ${MYSQL_CONFIG_PID} | awk -F ',' '{print $2}'`
        getTrueConfig ${MYSQL_CONFIG_TMP} ${MYSQL_PID}
        checkOk
        MYSQL_CONFIG="${result}"

        echoGreen "Begin to restart mysql. [defaults-file: ${MYSQL_CONFIG}]"
        restart ${MYSQL_CONFIG}
    done
}

statusAll(){
    MYSQL_CONFIGS_PIDS=`ps -ef | grep "mysqld --defaults-file" | grep -vE 'grep|mysqld_safe|\-p |\-px |xtrabackup' | awk '{b=$3;if(match($0,".*defaults-file=([^; ]*)",a));print a[1]","b}' | sort -t"," -k 3 -n | uniq`
    for MYSQL_CONFIG_PID in ${MYSQL_CONFIGS_PIDS}
    do
	# 获取需要使用的参数
	MYSQL_CONFIG_TMP=`echo ${MYSQL_CONFIG_PID} | awk -F ',' '{print $1}'`
	MYSQL_PID=`echo ${MYSQL_CONFIG_PID} | awk -F ',' '{print $2}'`
	getTrueConfig ${MYSQL_CONFIG_TMP} ${MYSQL_PID}
	checkOk
	MYSQL_CONFIG="${result}"

	echoGreen "Begin to check mysql status. [defaults-file: ${MYSQL_CONFIG}]"
	mysqlStatus ${MYSQL_CONFIG}
    done 
}


# See how we were called.
case "$command" in
    start )
	if [ "${mysql_port}" = "all" ];then
	    startAll
	else
    	    get_defaults_file
    	    start ${mysql_config}
	fi
    	;;
    stop )
	if [ "${mysql_port}" = "all" ];then
	    stopAll
	else
    	    get_defaults_file
    	    stop ${mysql_config}
	fi
    	;;
    status )
	if [ "${mysql_port}" = "all" ];then
	    statusAll
	else
    	    get_defaults_file
    	    mysqlStatus ${mysql_config}
	fi
    	;;
    restart )
	if [ "${mysql_port}" = "all" ];then
	    restartAll
	else
    	    get_defaults_file
    	    restart ${mysql_config}
	fi
    	;;
    *)
    usage
    exit 2
esac

exit $?
