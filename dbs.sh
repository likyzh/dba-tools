#!/bin/bash
# auter：Zaki
# 目的：快速输出一个机器上面数据的实例

# 进入脚本所在工作目录
cd `dirname $0`

# 导入功能脚本
source ./common/basic_function.sh

# 设置基础变量
date=`date +"%Y%m%d_%H%M%S"`
instanctip=`/sbin/ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v 192.168.122.1|grep -v inet6|awk '{print $2}'|tr -d "addr:"`
pwd_list_file="`pwd`/common/pwd_list"
nums=0 
TIMEOUT_TIME="2s"

# 获取mysql socket cnf
mysql_sockets_cnfs=`ps -ef | grep "mysqld --defaults-file" | grep -vE 'grep|mysqld_safe|\-p |\-px |xtrabackup' | awk '{d=$3;if(match($0,".*defaults-file=([^; ]*)",a));if(match($0,".*socket=([^; ]*)",b));if(match($0,".*port=([^; ]*)",c));print d","a[1]","b[1]","c[1]}' |  sort -n -k 4 -t, | uniq`

# 帮助命令查询
usage(){
    echo "Usage: dbs use to get MySQL、DDB、Mongo server info" 1>&2
    echo "Options:
    -m | --more         Print details info.
    -d | --database     Print database info.
    -h | --help         Print the help page of scripts."
}

# dbs -m显示
MysqlFullInfo(){
    # 检查是否有实例
    #checkInstance "The machine have no database available." ${mysql_sockets_cnfs}
    if [ ! -n "${mysql_sockets_cnfs}" ];then
	return 1
    fi

    # 获取打印的开头
    command_info[${nums}]="Command"
    port[${nums}]="Port" 
    read_only[${nums}]="Read_only"
    sql_safe_updates[${nums}]="Safe_updates"
    log_slave_updates[${nums}]="Slave_updates" 
    sync_binlog[${nums}]="sync_binlog"
    innodb_flush_log_at_trx_commit[${nums}]="trx_commit"
    innodb_buffer_pool_size[${nums}]="BP_Size"
    threads_all[${nums}]="run|con|max"
    command_status[${nums}]="Status"
    let nums++

    for mysql_socket_cnf in ${mysql_sockets_cnfs}
    do
	# 获取mysql socket
	mysql_socket[${nums}]=`echo ${mysql_socket_cnf} | awk -F ',' '{print $3}'`
	mysql_port[${nums}]=`echo ${mysql_socket_cnf} | awk -F ',' '{print $4}'`
	mysql_status[${nums}]=0
	# 确认正确的密码
	mysql_password=`checkMysqlPasswd ${mysql_socket[${nums}]}`
    	if [ ! -n "${mysql_password}" ];then
	    mysql_status[${nums}]=1
	    let nums++
	    continue
    	fi

	# 检查版本
        mysql_version=`${BIN_MYSQL} -u${MYSQL_USER} -p${mysql_password} --socket=${mysql_socket[${nums}]} -e "select version();" 2>/dev/null | grep -v version`
        if [[ ${mysql_version} =~ "5.7" ]];then
            system_db="performance_schema"
        else
            system_db="information_schema"
        fi
        # 获取相关信息
        processlist_info=`timeout ${TIMEOUT_TIME} ${BIN_MYSQL} -u${MYSQL_USER} -p${mysql_password} --socket=${mysql_socket[${nums}]} -e "use ${system_db};\
			select a.VARIABLE_VALUE,b.VARIABLE_VALUE,c.VARIABLE_VALUE,d.VARIABLE_VALUE,e.VARIABLE_VALUE,f.VARIABLE_VALUE,g.VARIABLE_VALUE,h.VARIABLE_VALUE,a1.VARIABLE_VALUE,b1.VARIABLE_VALUE from \
				global_variables a, \
				global_variables b, \
				global_variables c, \
				global_status d, \
				global_status e, \
				global_variables f, \
				global_variables g,  \
				global_variables h,   \
				global_variables a1,   \
				global_variables b1   \
			where \
				a.VARIABLE_NAME in ('port') \
				and b.VARIABLE_NAME in ('read_only') \
				and c.VARIABLE_NAME in ('sql_safe_updates') \
				and d.VARIABLE_NAME in ('Threads_connected') \
				and e.VARIABLE_NAME in ('Threads_running') \
				and f.VARIABLE_NAME in ('MAX_CONNECTIONS') \
				and g.VARIABLE_NAME in ('log_slave_updates') \
				and h.VARIABLE_NAME in ('innodb_buffer_pool_size') \
				and a1.VARIABLE_NAME in ('sync_binlog') \
				and b1.VARIABLE_NAME in ('innodb_flush_log_at_trx_commit') \
				;" 2>/dev/null | grep -v VARIABLE_VALUE`
	if [ ! -n "${processlist_info}" ];then
	    mysql_status[${nums}]=1
	    let nums++
	    continue
	fi
	
	# 获取需要展示的信息
        command_info[${nums}]="MySQL"
        port[${nums}]=`echo ${processlist_info} | awk '{print $1}'`
        read_only[${nums}]=`echo ${processlist_info} | awk '{print $2}'`
	sql_safe_updates[${nums}]=`echo ${processlist_info} | awk '{print $3}'`
	log_slave_updates[${nums}]=`echo ${processlist_info} | awk '{print $7}'`
	sync_binlog[${nums}]=`echo ${processlist_info} | awk '{print $9}'`
	innodb_flush_log_at_trx_commit[${nums}]=`echo ${processlist_info} | awk '{print $10}'`
	# innodb_buffer_pool_size
	innodb_buffer_pool_size_tmp[${nums}]=`echo ${processlist_info} | awk '{print $8}'`
	unitConversion ${innodb_buffer_pool_size_tmp[${nums}]}
	innodb_buffer_pool_size[${nums}]=${result}
	# threads run/con/max
        threads_connected=`echo ${processlist_info} | awk '{print $4}'`
        threads_running=`echo ${processlist_info} | awk '{print $5}'`
        max_connections=`echo ${processlist_info} | awk '{print $6}'`
	threads_all[${nums}]="${threads_running}|${threads_connected}|${max_connections}"
	command_status[${nums}]="running"
	let nums++
    done
    
    # 获取数组最长字段长度和每个字段frame长度
    # command
    command_max_length=`getArrayMaxLength "${command_info[*]}"`
    command_frame_num=`expr ${command_max_length} + 2`
    # port
    port_max_length=`getArrayMaxLength "${port[*]}"`
    port_frame_num=`expr ${port_max_length} + 2`
    # read_only
    read_only_max_length=`getArrayMaxLength "${read_only[*]}"` 
    read_only_frame_num=`expr ${read_only_max_length} + 2`
    # sql_safe_updates
    sql_safe_updates_max_length=`getArrayMaxLength "${sql_safe_updates[*]}"`
    sql_safe_updates_frame_num=`expr ${sql_safe_updates_max_length} + 2`
    # log_slave_updates
    log_slave_updates_max_length=`getArrayMaxLength "${log_slave_updates[*]}"`
    log_slave_updates_frame_num=`expr ${log_slave_updates_max_length} + 2`
    # innodb_buffer_pool_size
    innodb_buffer_pool_size_max_length=`getArrayMaxLength "${innodb_buffer_pool_size[*]}"`
    innodb_buffer_pool_size_frame_num=`expr ${innodb_buffer_pool_size_max_length} + 2`
    # threads_all
    threads_all_max_length=`getArrayMaxLength "${threads_all[*]}"`
    threads_all_frame_num=`expr ${threads_all_max_length} + 2`
    # command_status
    command_status_max_length=`getArrayMaxLength "${command_status[*]}"` 
    command_status_frame_num=`expr ${command_status_max_length} + 2`
    # sync_binlog
    sync_binlog_max_length=`getArrayMaxLength "${sync_binlog[*]}"`
    sync_binlog_frame_num=`expr ${sync_binlog_max_length} + 2`
    # innodb_flush_log_at_trx_commit
    innodb_flush_log_at_trx_commit_max_length=`getArrayMaxLength "${innodb_flush_log_at_trx_commit[*]}"`
    innodb_flush_log_at_trx_commit_frame_num=`expr ${innodb_flush_log_at_trx_commit_max_length} + 2`

    # 定义frame
    commandPrintfFrame="framePrintf ${port_frame_num} ${read_only_frame_num} ${sql_safe_updates_frame_num} ${log_slave_updates_frame_num} ${sync_binlog_frame_num} ${innodb_flush_log_at_trx_commit_frame_num} ${innodb_buffer_pool_size_frame_num} ${threads_all_frame_num} ${command_status_frame_num}"
    
    # 打印内容
    # 打印开始内容
    echo -e " \033[35mIP:\033[0m \033[33m${instanctip}\033[0m       \033[35mCommand:\033[0m \033[33mmysql\033[0m      \033[35mDate:\033[0m \033[33m${DATE_TIME}\033[0m"
    for((i=0;i<${nums};i++))
    do
	 # 打印输出
	if [[ ${mysql_status[$i]} -eq 0 ]];then
            if [[ ${i} -eq 0 ]];then
                ${commandPrintfFrame}
                printYellow ${port_max_length} ${port[$i]}
                printYellow ${read_only_max_length} ${read_only[$i]}
                printYellow ${sql_safe_updates_max_length} ${sql_safe_updates[$i]}
		printYellow ${log_slave_updates_max_length} ${log_slave_updates[$i]}
		printYellow ${sync_binlog_max_length} ${sync_binlog[$i]}
		printYellow ${innodb_flush_log_at_trx_commit_max_length} ${innodb_flush_log_at_trx_commit[$i]}
		printYellow ${innodb_buffer_pool_size_max_length} ${innodb_buffer_pool_size[$i]}
		printYellow ${threads_all_max_length} "${threads_all[$i]}"
                printYellow ${command_status_max_length} ${command_status[$i]}
    	        printf "|\n"
                ${commandPrintfFrame}
            else
    	        printWhite ${port_max_length} ${port[$i]}
    	        printWhite ${read_only_max_length} ${read_only[$i]}
    	        printWhite ${sql_safe_updates_max_length} ${sql_safe_updates[$i]}
		printWhite ${log_slave_updates_max_length} ${log_slave_updates[$i]}
		printWhite ${sync_binlog_max_length} ${sync_binlog[$i]}
		printWhite ${innodb_flush_log_at_trx_commit_max_length} ${innodb_flush_log_at_trx_commit[$i]}
		printWhite ${innodb_buffer_pool_size_max_length} ${innodb_buffer_pool_size[$i]}
		printWhite ${threads_all_max_length} "${threads_all[$i]}"
    	        printGreen ${command_status_max_length} ${command_status[$i]}
    	        printf "|\n"
            fi
	fi
    done
    # 输出结尾
    ${commandPrintfFrame}

    # 输出错误信息
    for((i=0;i<${nums};i++))
    do
	if [[ ${mysql_status[$i]} -eq 1 ]];then
	    echoRed "[ERROR] The MySQL's instance Without the correct password or in the Starting/Stopping or stuck. Can not connect! Socket:${mysql_socket[${i}]} Port:${mysql_port[${i}]}"
	fi
    done
}

# dbs显示
mysql_info(){
    # 检查是否有实例
    #checkInstance "The machine have no database available." ${mysql_sockets_cnfs}
    if [ ! -n "${mysql_sockets_cnfs}" ];then
        return 1
    fi

    # 获取列表头
    command_info[${nums}]="Command"
    port[${nums}]="Port"
    version[${nums}]="Vesion"
    mysql_cnf[${nums}]="Defaults_File"
    datadir[${nums}]="Datadir"
    master_host_port[${nums}]="Master_Host_Port"
    slave_slave_all[${nums}]="IO|SQL|Dealy"
    #slave_io_running[${nums}]="Slave_IO" 
    #slave_sql_running[${nums}]="Slave_SQL" 
    #seconds_behind_master[${nums}]="Delay" 
    let nums++

    # 获取数据
    for mysql_socket_cnf in ${mysql_sockets_cnfs}
    do
        # 获取socket和cnf
	mysql_safe_pid[${nums}]=`echo ${mysql_socket_cnf} | awk -F ',' '{print $1}'`
        mysql_cnf_tmp[${nums}]=`echo ${mysql_socket_cnf} | awk -F ',' '{print $2}'`
	mysql_socket[${nums}]=`echo ${mysql_socket_cnf} | awk -F ',' '{print $3}'`
	mysql_port[${nums}]=`echo ${mysql_socket_cnf} | awk -F ',' '{print $4}'`
	mysql_start_dir[${nums}]=`pwdx ${mysql_safe_pid[${nums}]} | awk -F ':' '{print $2}' | sed 's/^[ \t]*//g'`
	# 获取配置文件的绝对路径
	if [[ "${mysql_cnf_tmp[${nums}]}" =~ "./" ]];then
            mysql_cnf_tmp[${nums}]=`echo ${mysql_cnf_tmp[${nums}]} | sed 's/^.\///g'`
            mysql_cnf[${nums}]="${mysql_start_dir[${nums}]}/${mysql_cnf_tmp[${nums}]}"
            #echo "${mysql_cnf[${nums}]}"
        else
            mysql_cnf[${nums}]="${mysql_cnf_tmp[${nums}]}"
            #echo "${mysql_cnf[${nums}]}"
        fi
	mysql_status[${nums}]=0
	# 确认正确的密码
	mysql_password=`checkMysqlPasswd ${mysql_socket[${nums}]}`
    	if [ ! -n "${mysql_password}" ];then
	    mysql_status[${nums}]=1
	    let nums++
	    continue
    	fi
	# 检查版本
	mysql_version=`${BIN_MYSQL} -u${MYSQL_USER} -p${mysql_password} --socket=${mysql_socket[${nums}]} -e "select version()\G" 2>/dev/null | grep version | awk '{print $2}'`
        if [[ ${mysql_version} =~ "5.7" ]];then
            system_db="performance_schema"
        else
            system_db="information_schema"
        fi
        # 获取slave相关信息、版本信息
        more_info[${nums}]=`timeout ${TIMEOUT_TIME} ${BIN_MYSQL} -u${MYSQL_USER} -p${mysql_password} --socket=${mysql_socket[${nums}]} -e "use ${system_db};\
			select a.VARIABLE_VALUE,b.VARIABLE_VALUE,c.VARIABLE_VALUE from \
				 global_variables a, \
				 global_variables b, \
				 global_variables c \
			where \
				 a.VARIABLE_NAME = 'port' \
				and b.VARIABLE_NAME = 'datadir' \
				and c.VARIABLE_NAME = 'version'\G;\
				show slave status\G" 2>/dev/null | grep -vE "VARIABLE_NAME|row" | grep -wE "Master_Host|Master_Port|Slave_IO_Running|Slave_SQL_Running|Seconds_Behind_Master|VARIABLE_VALUE" | awk '{print $2}'`
	if [ ! -n "${more_info[$nums]}" ];then
	    mysql_status[${nums}]=1
	    let nums++
	    continue
	fi
	# 获取mysql相关信息
        command_info[${nums}]="MySQL"
	port[${nums}]=`echo ${more_info[$nums]} | awk '{print $1}'`
	# 获取data目录
        datadir_tmp=`echo ${more_info[$nums]} | awk '{print $2}'`
        datadir[${nums}]=`getMysqlDatadir "${datadir_tmp}"`
	# 获取版本信息
	version[${nums}]=`echo ${more_info[${nums}]} | awk '{print $3}'`
	# 获取master_host and master_port
        master_host_port[${nums}]=`echo ${more_info[${nums}]} | awk -F ' ' '{if($5>0){print $4":"$5}}'`
	# 获取slave相关信息
        slave_io_running[${nums}]=`echo ${more_info[${nums}]} | awk '{print $6}'`
        slave_sql_running[${nums}]=`echo ${more_info[${nums}]} | awk '{print $7}'`
        seconds_behind_master[${nums}]=`echo ${more_info[${nums}]} | awk '{print $8}'`
	if [ -n "${slave_io_running[${nums}]}" -a -n "${slave_sql_running[${nums}]}" ];then
	    slave_slave_all[${nums}]="${slave_io_running[${nums}]}|${slave_sql_running[${nums}]}|${seconds_behind_master[${nums}]}"
	else
	    slave_slave_all[${nums}]=""
	fi
	let nums++
    done
    
    # 获取数组最长字段长度和每个字段frame长度
    # command
    command_max_length=`getArrayMaxLength "${command_info[*]}"`
    command_frame_num=`expr ${command_max_length} + 2`
    # port
    port_max_length=`getArrayMaxLength "${port[*]}"`
    port_frame_num=`expr ${port_max_length} + 2`
    # version
    version_max_length=`getArrayMaxLength "${version[*]}"`
    version_frame_num=`expr ${version_max_length} + 2`
    # mysql_cnf
    mysql_cnf_max_length=`getArrayMaxLength "${mysql_cnf[*]}"`
    mysql_cnf_frame_num=`expr ${mysql_cnf_max_length} + 2`
    # datadir
    datadir_max_length=`getArrayMaxLength "${datadir[*]}"`
    datadir_frame_num=`expr ${datadir_max_length} + 2`
    # master_host and master_port
    master_host_port_max_length=`getArrayMaxLength "${master_host_port[*]}"`
    master_host_port_frame_num=`expr ${master_host_port_max_length} + 2`
    # slave_slave_all
    slave_slave_all_max_length=`getArrayMaxLength "${slave_slave_all[*]}"`
    slave_slave_all_frame_num=`expr ${slave_slave_all_max_length} + 2`

    # 定义frame
    #commandPrintfFrame="framePrintf ${port_frame_num} ${version_frame_num} ${mysql_cnf_frame_num} ${datadir_frame_num} ${master_host_port_frame_num} ${slave_io_frame_num} ${slave_sql_frame_num} ${delay_frame_num}"
    commandPrintfFrame="framePrintf ${port_frame_num} ${version_frame_num} ${mysql_cnf_frame_num} ${datadir_frame_num} ${master_host_port_frame_num} ${slave_slave_all_frame_num}"

    # 打印内容
    # 打印开始内容
    echo -e " \033[35mIP:\033[0m \033[33m${instanctip}\033[0m       \033[35mCommand:\033[0m \033[33mmysql\033[0m      \033[35mDate:\033[0m \033[33m${DATE_TIME}\033[0m"
    for((i=0;i<${nums};i++))
    do
	# 打印输出
	if [[ ${mysql_status[$i]} -eq 0 ]];then
	    if [[ ${i} -eq 0 ]];then
	        ${commandPrintfFrame}
                printYellow ${port_max_length} "${port[$i]}"
                printYellow ${version_max_length} "${version[$i]}"
                printYellow ${mysql_cnf_max_length} "${mysql_cnf[$i]}"
                printYellow ${datadir_max_length} ${datadir[$i]}
                printYellow ${master_host_port_max_length} ${master_host_port[${i}]}
		printYellow ${slave_slave_all_max_length} ${slave_slave_all[${i}]}
    	        printf "|\n"
	        ${commandPrintfFrame}
	    else
                printWhite ${port_max_length} ${port[$i]}
                printWhite ${version_max_length} ${version[$i]}
                printWhite ${mysql_cnf_max_length} ${mysql_cnf[$i]}
                printWhite ${datadir_max_length} ${datadir[$i]}
                printWhite ${master_host_port_max_length} ${master_host_port[${i}]}
                if [ ! -n "${slave_io_running[$i]}" -a ! -n "${slave_sql_running[$i]}" ];then
                    printGreen ${slave_slave_all_max_length} ${slave_slave_all[${i}]}
		elif [ "${seconds_behind_master[$i]}" = "NULL" ];then
		    printRed ${slave_slave_all_max_length} ${slave_slave_all[${i}]}
		elif [ "${slave_io_running[$i]}" = "No" -o "${slave_sql_running[$i]}" = "No" -o "${seconds_behind_master[$i]}" -gt 3600 ];then
		    printRed ${slave_slave_all_max_length} ${slave_slave_all[${i}]}
		else
		    printGreen ${slave_slave_all_max_length} ${slave_slave_all[${i}]}
		fi
    	        printf "|\n"
	    fi
	fi
    done
    # 输出结尾
    ${commandPrintfFrame}

    # 输出错误信息
    for((i=0;i<${nums};i++))
    do
	if [[ ${mysql_status[$i]} -eq 1 ]];then
	    echoRed "[ERROR] The MySQL's instance Without the correct password or in the Starting/Stopping or stuck. Can not connect! Socket:${mysql_socket[${i}]} Port:${mysql_port[${i}]}"
	fi
    done
}

# 展示简单的mongo信息
mongoInfo(){
    # mongo信息
    MONGO_INFOS=`netstat -nltp  2>/dev/null | grep mongo | awk '{print $4":"$7}' | awk -F ':' '{print $2"/"$3}' | sort -n | uniq`
    nums=0
    if [ ! -n "${MONGO_INFOS}" ];then
        return 1
    fi
    
    MONGO_PORT[${nums}]="Port"
    MONGO_SERVER_NAME[${nums}]="Server"
    MONGO_CONF[${nums}]="Config_file"
    let nums++

#    echo $(($(date +%s%N)/1000000))
    for MONGO_INFO in ${MONGO_INFOS}
    do
	STATUS[${nums}]=0
	MONGO_PORT[${nums}]=`echo ${MONGO_INFO} | awk -F '/' '{print $1}'`
	MONGO_PID=`echo ${MONGO_INFO} | awk -F '/' '{print $2}'`
        MONGO_SERVER_NAME[${nums}]=`echo ${MONGO_INFO} | awk -F '/' '{print $3}'`
        MONGO_CONF[${nums}]=`ps -ef | grep ${MONGO_PID} | grep -v grep | awk '{print $NF}'`
	let nums++
    done

    # 获取数组最长字段长度和每个字段frame长度
    # MONGO_SERVER_NAME_MAX_LENGTH
    MONGO_SERVER_NAME_MAX_LENGTH=`getArrayMaxLength "${MONGO_SERVER_NAME[*]}"`
    MONGO_SERVER_NAME_FRAME_NUM=`expr ${MONGO_SERVER_NAME_MAX_LENGTH} + 2`

    # MONGO_CONF
    MONGO_CONF_MAX_LENGTH=`getArrayMaxLength "${MONGO_CONF[*]}"`
    MONGO_CONF_FRAME_NUM=`expr ${MONGO_CONF_MAX_LENGTH} + 2`

    # MONGO_PORT
    MONGO_PORT_MAX_LENGTH=`getArrayMaxLength "${MONGO_PORT[*]}"`
    MONGO_PORT_FRAME_NUM=`expr ${MONGO_PORT_MAX_LENGTH} + 2`

    # 定义frame
    PRINTF_FRAME="framePrintf ${MONGO_PORT_FRAME_NUM} ${MONGO_SERVER_NAME_FRAME_NUM} ${MONGO_CONF_FRAME_NUM}"

    # 打印开始内容
    echo -e " \033[35mIP:\033[0m \033[33m${instanctip}\033[0m       \033[35mCommand:\033[0m \033[33mmongo\033[0m      \033[35mDate:\033[0m \033[33m${DATE_TIME}\033[0m"
    for((i=0;i<${nums};i++))
    do
        if [[ ${STATUS[$i]} -eq 0 ]];then
            if [[ ${i} -eq 0 ]];then
                    ${PRINTF_FRAME}
                    printYellow ${MONGO_PORT_MAX_LENGTH} ${MONGO_PORT[$i]}
                    printYellow ${MONGO_SERVER_NAME_MAX_LENGTH} ${MONGO_SERVER_NAME[$i]}
                    printYellow ${MONGO_CONF_MAX_LENGTH} ${MONGO_CONF[$i]}
                    printf "|\n"
                    ${PRINTF_FRAME}
            else
                if [ "${MONGO_SERVER_NAME[$i]}" = "mongos" ];then
                        printGreen ${MONGO_PORT_MAX_LENGTH} ${MONGO_PORT[$i]}
                        printGreen ${MONGO_SERVER_NAME_MAX_LENGTH} ${MONGO_SERVER_NAME[$i]}
                        printGreen ${MONGO_CONF_MAX_LENGTH} ${MONGO_CONF[$i]}
                else
                        printWhite ${MONGO_PORT_MAX_LENGTH} ${MONGO_PORT[$i]}
                        printWhite ${MONGO_SERVER_NAME_MAX_LENGTH} ${MONGO_SERVER_NAME[$i]}
                        printWhite ${MONGO_CONF_MAX_LENGTH} ${MONGO_CONF[$i]}
                fi
                printf "|\n"
            fi
        fi
    done
    ${PRINTF_FRAME}

    # 输出错误信息
    for((i=0;i<${nums};i++))
    do
        if [[ ${STATUS[$i]} -eq 1 ]];then
            echoRed "[ERROR] The Mongo's instance Without the correct password or it's a arbiter. Can not connect! Port: ${MONGO_PORT[$i]}"
        fi
    done
}

# 展示详细的mongo信息
mongoFullInfo(){
    # mongo信息
    MONGO_INFOS=`netstat -nltp  2>/dev/null | grep mongo | awk '{print $4":"$7}' | awk -F ':' '{print $2"/"$3}' | sort -n | uniq`
    nums=0
    if [ ! -n "${MONGO_INFOS}" ];then
	return 1
    fi

    MONGO_PORT[${nums}]="Port"
    MONGO_SERVER_NAME[${nums}]="Server"
    MONGO_VERSION[${nums}]="Version"
    MONGO_CONF[${nums}]="Config_file"
    MONGO_CONN[${nums}]="run|idle"
    let nums++

    for MONGO_INFO in ${MONGO_INFOS}
    do
	STATUS[${nums}]=0
	MONGO_PORT[${nums}]=`echo ${MONGO_INFO} | awk -F '/' '{print $1}'`
	MONGO_PID=`echo ${MONGO_INFO} | awk -F '/' '{print $2}'`
	MONGO_SERVER_NAME[${nums}]=`echo ${MONGO_INFO} | awk -F '/' '{print $3}'`
	MONGO_CONF[${nums}]=`ps -ef | grep ${MONGO_PID} | grep -v grep | awk '{print $NF}'`
	
        # 确认登陆密码
	MONGO_PASSWORD=`checkMongoPasswd ${MONGO_PORT[${nums}]}`
        if [ ! -n "${MONGO_PASSWORD}" ];then
            # 不使用账号密码登陆
            TEST_ROW=`${BIN_MONGO} --host ${INSTANCE_IP} --port ${MONGO_PORT[${nums}]} admin --eval "show dbs;" 2>/dev/null`
	    if [ $? -eq 0 ];then
            	MONGO_MORE_INFO=`${BIN_MONGO} --host ${INSTANCE_IP} --port ${MONGO_PORT[${nums}]} admin --eval "db.serverStatus().connections" | grep -v "connecting to"`
	    else
		TEST_ROW=`${BIN_MONGO} --host ${LOCAL_IP} --port ${MONGO_PORT[${nums}]} admin --eval "1" 2>/dev/null`
	        if [ $? -eq 0 ];then
	    	    MONGO_MORE_INFO=`${BIN_MONGO} --host ${LOCAL_IP} --port ${MONGO_PORT[${nums}]} admin --eval "db.serverStatus().connections" | grep -v "connecting to"`
		else
               	    STATUS[${nums}]=1
		    let nums++
               	    continue
		fi
	    fi
        else
           # 使用port进行登陆
           MONGO_MORE_INFO=`${BIN_MONGO} -u${MONGO_USER} -p${MONGO_PASSWORD} --host ${INSTANCE_IP} --port ${MONGO_PORT[${nums}]} admin --eval "db.serverStatus().connections" | grep -v "connecting to"`
        fi
	
	# 获取mongo版本信息 连接数信息
	MONGO_VERSION[${nums}]=`echo "${MONGO_MORE_INFO}" | awk -F '{' '{print $1}' | awk -F':' '{print $2}' | sed 's/^[ \t]*//g'`
	resolveJson "${MONGO_MORE_INFO}" "current"
	MONGO_CURRENT=`echo ${result}`
	resolveJson "${MONGO_MORE_INFO}" "available"
	MONGO_AVAILABLE=`echo ${result}`
	if [ -n "${MONGO_CURRENT}" -o -n "${MONGO_AVAILABLE}" ];then
	    MONGO_CONN[${nums}]="${MONGO_CURRENT}|${MONGO_AVAILABLE}"
	fi
	let nums++
    done

    # 获取数组最长字段长度和每个字段frame长度
    # MONGO_SERVER_NAME_MAX_LENGTH
    MONGO_SERVER_NAME_MAX_LENGTH=`getArrayMaxLength "${MONGO_SERVER_NAME[*]}"`
    MONGO_SERVER_NAME_FRAME_NUM=`expr ${MONGO_SERVER_NAME_MAX_LENGTH} + 2`

    # MONGO_CONF
    MONGO_CONF_MAX_LENGTH=`getArrayMaxLength "${MONGO_CONF[*]}"`
    MONGO_CONF_FRAME_NUM=`expr ${MONGO_CONF_MAX_LENGTH} + 2`

    # MONGO_PORT
    MONGO_PORT_MAX_LENGTH=`getArrayMaxLength "${MONGO_PORT[*]}"`
    MONGO_PORT_FRAME_NUM=`expr ${MONGO_PORT_MAX_LENGTH} + 2`
    
    # MONGO_VERSION
    MONGO_VERSION_MAX_LENGTH=`getArrayMaxLength "${MONGO_VERSION[*]}"`
    MONGO_VERSION_FRAME_NUM=`expr ${MONGO_VERSION_MAX_LENGTH} + 2`

    # MONGO_CONN
    MONGO_CONN_MAX_LENGTH=`getArrayMaxLength "${MONGO_CONN[*]}"`
    MONGO_CONN_FRAME_NUM=`expr ${MONGO_CONN_MAX_LENGTH} + 2`

    # 定义frame
    PRINTF_FRAME="framePrintf ${MONGO_PORT_FRAME_NUM} ${MONGO_SERVER_NAME_FRAME_NUM} ${MONGO_VERSION_FRAME_NUM} ${MONGO_CONF_FRAME_NUM} ${MONGO_CONN_FRAME_NUM}"

    # 打印开始内容
    echo -e " \033[35mIP:\033[0m \033[33m${instanctip}\033[0m       \033[35mCommand:\033[0m \033[33mmongo\033[0m      \033[35mDate:\033[0m \033[33m${DATE_TIME}\033[0m"		
    for((i=0;i<${nums};i++))
    do
	if [[ ${STATUS[$i]} -eq 0 ]];then
       	    if [[ ${i} -eq 0 ]];then
                    ${PRINTF_FRAME}
                    printYellow ${MONGO_PORT_MAX_LENGTH} ${MONGO_PORT[$i]}
                    printYellow ${MONGO_SERVER_NAME_MAX_LENGTH} ${MONGO_SERVER_NAME[$i]}
	    	    printYellow ${MONGO_VERSION_MAX_LENGTH} ${MONGO_VERSION[$i]}
                    printYellow ${MONGO_CONF_MAX_LENGTH} ${MONGO_CONF[$i]}
	    	    printYellow ${MONGO_CONN_MAX_LENGTH} ${MONGO_CONN[$i]}
                    printf "|\n"
                    ${PRINTF_FRAME}
            else
	    	if [ "${MONGO_SERVER_NAME[$i]}" = "mongos" ];then
                        printGreen ${MONGO_PORT_MAX_LENGTH} ${MONGO_PORT[$i]}
                        printGreen ${MONGO_SERVER_NAME_MAX_LENGTH} ${MONGO_SERVER_NAME[$i]}
	    	    	printGreen ${MONGO_VERSION_MAX_LENGTH} ${MONGO_VERSION[$i]}
                        printGreen ${MONGO_CONF_MAX_LENGTH} ${MONGO_CONF[$i]}
	    	    	printGreen ${MONGO_CONN_MAX_LENGTH} ${MONGO_CONN[$i]}
	    	else
                        printWhite ${MONGO_PORT_MAX_LENGTH} ${MONGO_PORT[$i]}
                        printWhite ${MONGO_SERVER_NAME_MAX_LENGTH} ${MONGO_SERVER_NAME[$i]}
	    	    	printWhite ${MONGO_VERSION_MAX_LENGTH} ${MONGO_VERSION[$i]}
                        printWhite ${MONGO_CONF_MAX_LENGTH} ${MONGO_CONF[$i]}
	    	    	printWhite ${MONGO_CONN_MAX_LENGTH} ${MONGO_CONN[$i]}
	    	fi
    	        printf "|\n"
	    fi
	fi
    done
    ${PRINTF_FRAME}

    # 输出错误信息
    for((i=0;i<${nums};i++))
    do
        if [[ ${STATUS[$i]} -eq 1 ]];then
            echoRed "[ERROR] The Mongo's instance Without the correct password or it's a arbiter. Can not connect! Port: ${MONGO_PORT[$i]}"
        fi
    done
   
}

# 打印出数据库函数
showDatabaseInfo(){
    # 检查是否有实例
    checkInstance "The machine have no database available." ${mysql_sockets_cnfs}
    
    # 获取数据
    for mysql_socket_cnf in ${mysql_sockets_cnfs}
    do
        # 获取socket和cnf
        mysql_socket[${nums}]=`echo ${mysql_socket_cnf} | awk -F ',' '{print $3}'`
	mysql_port[${nums}]=`echo ${mysql_socket_cnf} | awk -F ',' '{print $4}'`
	mysql_status[${nums}]=0
	# 获取正确的密码
	mysql_password=`checkMysqlPasswd ${mysql_socket[${nums}]}`
    	if [ ! -n "${mysql_password}" ];then
	    mysql_status[${nums}]=1
	    let nums++
	    continue
    	fi
        if [[ ${mysql_status[$nums]} -eq 0 ]];then
            more_info[${nums}]=`${BIN_MYSQL} -u${MYSQL_USER} -p${mysql_password} --socket=${mysql_socket[${nums}]} -e "show databases;" 2>/dev/null  | grep -vwE "information_schema|performance_schema|sys|mysql|Database"`
	    echo "----------------------------------------------------------------------------------------------------------------------------"
            echo -e "\033[32m${instanctip}:${mysql_port[${nums}]} 实例下的数据库:\033[0m "
	    echo "${more_info[${nums}]}"
	fi
    done
	echo "-----------------------------------------------------------------------------------------------------------------------------"

    # 输出错误信息
    for((i=0;i<${nums};i++))
    do
	if [[ ${mysql_status[$i]} -eq 1 ]];then
	    echoRed "[ERROR] The MySQL's instance Without the correct password or in the Starting/Stopping. Can not connect! Socket:${mysql_socket[${i}]} Port:${mysql_port[${i}]}"
	fi
    done
}

# 参数检测函数
get_args()
{
# Get the parameters form the command line
while [ "$1" != "" ]; do
  case $1 in
    -m | --more )
    MysqlFullInfo
    mongoFullInfo
    exit
    ;;
    -d | --database )
    showDatabaseInfo
    exit
    ;;
    -h | --help )
    usage
    exit
    ;;
    * )
    usage
    exit 1
  esac
  shift
done

if [ ! -n "$1" ];then
    # 查看该机器数据库实例
    mysql_info
    mongoInfo
fi
}

# 对输入的命令进行判断
get_args $*
