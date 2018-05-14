@author Zaki-Zhou

# dba-tools工具集
### 安装部署
```shell
cd dba-tools
sh install.sh
source ~/.bashrc
```
### 配置文件说明

#### common/vars_conf.sh

可以修改的变量配置，变量详细介绍如下: 

- MYSQL_CONFIG_DIR : 存放MySQL配置文件的目录
- MYSQL_DIR : MySQL的bin目录
- MONGO_DIR : Mongo的bin目录
- PYTHON_DIR : Python包的目录
- MYSQL_USER: MySQL使用的用户名，最好有所有权限
- MONGO_USER： Mongo使用的用户名，最好有所有权限
- DDB_USER: 连接DDB的用户名
- DDB_PASSWORD: 连接DDB的密码


#### common/mysql_pwd_list

mysql可用的密码，可配置多个，每个密码占一行

#### common/mongo_pwd_list

mongo可用的密码，可配置多个，每个密码占一行

### 工具介绍

​	本工具包一共包含3个小工具，dbs/dba/go，dbs用于数据库日常的显示，dba用于数据库日常的操作，go用于数据库日常的连接，具体内容请往下看。

#### dbs

**使用方法:** dbs

**作用:** 快速显示一个机器上面的所有mysql、mongo、ddb实例和相关信息

**效果展示:** 更多参数可以通过 dbs --help进行获取，详细如下: 

```mysql
[dba@db-dg150-198 dba-tools]$ dbs --help
Usage: dbs use to get MySQL、DDB、Mongo server info
Options:
    -m | --more         Print details info.				   # 打印更多详细信息
    -d | --database     Print database info.			   # 打印数据库的信息
    -h | --help         Print the help page of scripts.    # 查看帮助文档
```

执行dbs获取MySQL、Mongo的基础信息，详细如下: 

```mysql
[dba@db-dg150-198 dba-tools]$ dbs
 IP: 127.0.0.1       Command: mysql      Date: 2018-05-11 12:51:23
+------+--------------------+-----------------------------+------------------+---------------------+--------------+
| Port | Vesion             | Defaults_File               | Datadir          | Master_Host_Port    | IO|SQL|Dealy |
+------+--------------------+-----------------------------+------------------+---------------------+--------------+
| 3306 | 5.5.23-rel25.3-log | /home/dba/mysqlnode/my1.cnf | /data1/nodedata1 |                     |              |
| 4306 | 5.7.21-log         | /home/dba/mysqlnode/my2.cnf | /data2/nodedata2 | 127.0.0.2:8306 | Yes|Yes|0    |
| 5306 | 5.7.21-log         | /home/dba/mysqlnode/my3.cnf | /data2/nodedata3 |                     |              |
| 6306 | 5.7.21-log         | /home/dba/mysqlnode/my4.cnf | /data3/nodedata4 | 127.0.0.2:8306 | Yes|Yes|0    |
| 8306 | 5.7.21-log         | /home/dba/mysqlnode/my5.cnf | /data2/nodedata5 |                     |              |
+------+--------------------+-----------------------------+------------------+---------------------+--------------+
 IP: 127.0.0.1       Command: mongo      Date: 2018-05-11 12:51:23
+-------+--------+-------------------------------------------------------+
| Port  | Server | Config_file                                           |
+-------+--------+-------------------------------------------------------+
| 20000 | mongod | /home/dba/sysbench-data/mongo/20000/mongod_20000.conf |
| 20001 | mongod | /home/dba/sysbench-data/mongo/20001/mongod_20001.conf |
| 32001 | mongod | /home/dba/config/shard.conf                           |
| 32003 | mongod | /home/dba/config/shard2.conf                          |
| 32004 | mongod | /home/dba/config/shard3.conf                          |
+-------+--------+-------------------------------------------------------+
```

#### go

**使用方法:** go port

**作用:** 通过端口快速连接一个mysql、mongo、ddb

**效果展示:** 连接mysql详细如下: 

```mysql
[dba@db-dg150-198 dba-tools]$ go 4306
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 38109
Server version: 5.7.21-log MySQL Community Server (GPL)

Copyright (c) 2000, 2018, Oracle and/or its affiliates. All rights reserved.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

(root@127.0.0.1:4306) [(none)]>
```

连接mongo详细如下: 

```mysql
[dba@db-dg150-198 dba-tools]$ go 32001
MongoDB shell version: 3.2.5
connecting to: 127.0.0.1:32001/admin
Server has startup warnings:
2018-04-08T10:38:29.308+0800 I CONTROL  [initandlisten]
2018-04-08T10:38:29.308+0800 I CONTROL  [initandlisten] ** WARNING: You are running on a NUMA machine.
2018-04-08T10:38:29.308+0800 I CONTROL  [initandlisten] **          We suggest launching mongod like this to avoid performance problems:
2018-04-08T10:38:29.308+0800 I CONTROL  [initandlisten] **              numactl --interleave=all mongod [other options]
2018-04-08T10:38:29.308+0800 I CONTROL  [initandlisten]
2018-04-08T10:38:29.308+0800 I CONTROL  [initandlisten] ** WARNING: soft rlimits too low. rlimits set to 65536 processes, 1000000 files. Number of processes should be at least 500000 : 0.5 times number of files.
2018-04-08T10:38:29.308+0800 I CONTROL  [initandlisten]
>
```

连接ddb详细如下: 

```mysql
[dba@db-39 ~]$ go 8888
User/password of administrator is given and user/password of normal user is omitted,
we will use user/password of administrator for normal user.
isql@dba>>
```

#### dba

**使用方法:** dba command port

**作用:** 用于管理数据库，将日常手动的操作简化

**效果展示:** 执行dba来查看帮助文档，详细如下: 

```mysql
[dba@db-dg150-198 dba-tools]$ dba
Usage: dba [Action] mysql_port or dba [Script] -h
Action:
    status		Check mysql status.(Support all)		# 查看mysql状态
    start		Start mysql by port.(Support all)		# 启动mysql实例
    stop		Stop mysql by port.(Support all)		# 关闭mysql实例
    restart		Restart mysql by port.(Support all)		# 重启mysql实例
    slave		Show slave status by port.(Support all) # 打印slave信息
    session		Show processlist by port.(Support all)  # 打印processlist信息
    sql			Show Running SQL by port.(Support all)  # 打印正在运行的SQL信息
    setro		Set global read_only = 1 by port.(Support all) # 执行Set global read_only=1
    setrw		Set global read_only = 0 by port.(Support all) # 执行Set global read_only=0
    opensqlsafe		Set global sql_safe_updates = 1 by port.(Support all) # 执行Set global sql_safe_updates = 1
    closesqlsafe	Set global sql_safe_updates = 0 by port.(Support all) # 执行Set global sql_safe_updates = 0
    mysql		Print orz -lazy -innodb_rows -innodb_data -mysql info  # 展示mysql实时信息
    mongo		Print mongostat info.								   # 展示mongo实时信息
    repair		Repair slave error.(Only support mysql5.5)	# 自动修复Slave的错误，只支持5.5
    killuser	Kill the User's MySQL session by port.(Support all) # 杀掉某用户的全部连接
    killall		Kill all MySQL session by port.(Support all)  # 杀掉除了系统连接外的所有连接
Script:
    admin		Managing mysql instances.				# status/start/stop/restart MySQL
    exe			Used to execute SQL.					# 可用于批量支持SQL
    orz			MySQL Real-time monitoring				# 监控mysql的脚本调用
```

**举个例子:** 

你想查看改机器上所有实例的binlog_format，执行`dba exe all 'show variables like "binlog_format"'`

```mysql
[dba@db-dg150-198 dba-tools]$ dba exe all 'show variables like "binlog_format"'
+---------------+-------+
| Variable_name | Value |
+---------------+-------+
| binlog_format | ROW   |
+---------------+-------+
Port: 3306 execute: show variables like "binlog_format"
+---------------+-------+
| Variable_name | Value |
+---------------+-------+
| binlog_format | ROW   |
+---------------+-------+
Port: 4306 execute: show variables like "binlog_format"
+---------------+-------+
| Variable_name | Value |
+---------------+-------+
| binlog_format | ROW   |
+---------------+-------+
Port: 5306 execute: show variables like "binlog_format"
+---------------+-------+
| Variable_name | Value |
+---------------+-------+
| binlog_format | ROW   |
+---------------+-------+
Port: 6306 execute: show variables like "binlog_format"
+---------------+-------+
| Variable_name | Value |
+---------------+-------+
| binlog_format | ROW   |
+---------------+-------+
Port: 8306 execute: show variables like "binlog_format"
```

### Release notes

[release notes](./doc/RELEASE_NOTES.md)
