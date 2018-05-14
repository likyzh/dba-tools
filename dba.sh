#!/bin/bash
# auter：Zaki
# 目的：用于调用一些管理工具

# 进入脚本所在工作目录
cd `dirname $0`

# 导入功能脚本
source ./common/basic_function.sh

scripts=$1
shift
mysql_port=$1
shell_command_all="$@"
shift
shell_command="$@"

basepath=$(cd `dirname $0`; pwd)
tool_dir="${basepath}/tool"
script_db_admin="${tool_dir}/db_admin.sh"
script_mysql_session="${tool_dir}/mysql_session.sh"
script_exe_mysql="${tool_dir}/exe_mysql.sh"
script_mysql_status="${tool_dir}/mysql_status.sh"
script_mongo_status="${tool_dir}/mongo_status.sh"
script_mysql_repair="${tool_dir}/mysql_repair.sh"
script_orz="./lib/orz"

# 帮助
usage () {
    echo $"Usage: dba [Action] mysql_port or dba [Script] -h" 1>&2
    echo "Action:
    status		Check mysql status.(Support all)
    start		Start mysql by port.(Support all)
    stop		Stop mysql by port.(Support all)
    restart		Restart mysql by port.(Support all)
    slave		Show slave status by port.(Support all)
    session		Show processlist by port.(Support all)
    sql			Show Running SQL by port.(Support all)
    setro		Set global read_only = 1 by port.(Support all)
    setrw		Set global read_only = 0 by port.(Support all)
    opensqlsafe		Set global sql_safe_updates = 1 by port.(Support all)
    closesqlsafe	Set global sql_safe_updates = 0 by port.(Support all)
    mysql		Print orz -lazy -innodb_rows -innodb_data -mysql info
    mongo		Print mongostat info.
    repair		Repair slave error.(Only support mysql5.5)
    killuser		Kill the User's MySQL session by port.(Support all)
    killall		Kill all MySQL session by port.(Support all)"
    echo "Script:
    admin		Managing mysql instances.
    exe			Used to execute SQL.
    orz			MySQL Real-time monitoring"
}

# 检测scripts和mysql_port是否为空
if [ ! -n "${scripts}" -a ! -n "${mysql_port}" ];then
    usage
    exit 1
fi

# See how we were called.
case "$scripts" in
    admin )
	sh ${script_db_admin} "${shell_command_all}"
    	;;
    status )
	checkInstance "Sample: dba status 3306" "${mysql_port}"
	sh ${script_db_admin} -c status -p "${mysql_port}"
	;;
    start )
	checkInstance "Sample: dba start 3306 or dba start all" "${mysql_port}"
	sh ${script_db_admin} -c start -p "${mysql_port}"
	;;
    stop )
	checkInstance "Sample: dba stop 3306 or dba stop all" "${mysql_port}"
	sh ${script_db_admin} -c stop -p "${mysql_port}"
	;;    
    restart )
	checkInstance "Sample: dba restart 3306 or dba restart all" "${mysql_port}"
	sh ${script_db_admin} -c restart -p "${mysql_port}"
	;;
    killuser )
	checkInstance "Sample: dba killuser 3306 user_name" "${mysql_port}"
	checkInstance "Sample: dba killuser 3306 user_name" "${shell_command}"
	sh ${script_mysql_session} kill_user "${mysql_port}" "${shell_command}"
	;;
    killall )
	checkInstance "Sample: dba killall 3306" ${mysql_port}
	sh ${script_mysql_session} kill_all ${mysql_port}
	;;
    exe ) 
	sh ${script_exe_mysql} "${mysql_port}" "${shell_command}"
	;;
    setro )
	checkInstance "Sample: dba setro 3306" "${mysql_port}"
	sh ${script_exe_mysql} "${shell_command_all}" "set global read_only = 1;" 
	;;
    setrw )
	checkInstance "Sample: dba setrw 3306" "${mysql_port}"
	sh ${script_exe_mysql} "${shell_command_all}" "set global read_only = 0;" 
	;;
    opensqlsafe )
	checkInstance "Sample: dba opensqlsafe 3306" "${mysql_port}"
	sh ${script_exe_mysql} "${shell_command_all}" "set global sql_safe_updates = 1;"
	;;	
    closesqlsafe )
	checkInstance "Sample: dba closesqlsafe 3306" "${mysql_port}"
	sh ${script_exe_mysql} "${shell_command_all}" "set global sql_safe_updates = 0;"
	;;	
    slave )
	checkInstance "Sample: dba slave 3306" "${mysql_port}"
	sh  ${script_exe_mysql} "${shell_command_all}" "show slave status\G"
	;;
    session )
	checkInstance "Sample: dba session 3306" "${mysql_port}"
	sh  ${script_exe_mysql} "${shell_command_all}" "show processlist;"
	;;
    sql )
	checkInstance "Sample: dba sql 3306" "${mysql_port}"
	sh  ${script_exe_mysql} "${shell_command_all}" "select * from information_schema.processlist  where COMMAND not in ('sleep') and USER not in ('system user','repl','root')"
	;;
    mysql )
	checkInstance "Sample: dba mysql 3306" "${mysql_port}"
	sh ${script_mysql_status} "${mysql_port}"
	;;
    orz )
	perl ${script_orz} ${shell_command_all}	
	;;
    mongo )
	checkInstance "Sample: dba mongo 3306" "${mysql_port}"
	sh ${script_mongo_status} "${mysql_port}" 
	;;
    repair )
	checkInstance "Sample: dba repair 3306" "${mysql_port}"
	sh ${script_mysql_repair} "${mysql_port}"
	;;
  *)
    usage
    exit 2
esac
