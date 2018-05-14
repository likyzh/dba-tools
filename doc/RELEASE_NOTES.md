## Release notes
####  2018-05-11
- Functionality Added or Changed
  - 新增dbs显示mongo基础信息
  - 新增dba mysql 3306, 用于实时查看mysql状态值
  - 新增dba repair 3306, 快速修复Slave有问题的表, 目前只支持mysql5.5的版本
  - 新增dba status/stop/start/restart all操作, 可以一键重启所有实例
  - 新增dba killuser/killall 操作, 可以通过用户名判断快速kill mysql session
  - dbs显示mysql slave状态不为双Yes的时候显示红色
  - dbs加上log_slave_updates参数的显示
  - dbs -m 新增sync_binlog/innodb_flush_log_at_trx_commit的显示
- Bugs Fixed
  - 重大BUG: dba status/stop/start/restart 操作对端口不能精确匹配(已修复)
  - dbs显示mongo的优化
  - 危险操作加上了用户交互验证

####  2018-03-21
- Functionality Added or Changed
  - 新增go连接ddb功能
  - 新增go连接mongo功能
  - 新增日志模块
  - dba管理模块新增部分功能
- Bugs Fixed
  - dbs删除操作数据库的功能，迁移到dba管理工具下

#### 2018-02-08
- Functionality Added or Changed
  - 新增dba快捷方式，用于执行dba日常操作的工具
  - 新增功能一键打开或者关闭所有实例read-only
  - 新增启动和关闭实例脚本，可以通过端口进行判断
  - 新功能dbs -d 显示实例下的数据库
  - dbs添加变量sql_safe_updates的展示
- Bugs Fixed
  - dbs进行展示的时候，通过port进行排序
  - go脚本登陆时显示登陆的用户
  - 每个实例检测密码,解决同一个机器上数据库实例不同的问题
  - 没有实例的机器输出本机器没有实例
  - 兼容mysql5.7版本,表GLOBAL_VARIABLES迁移到了performance_schema

#### 2018-01-04
- Functionality Added or Changed
  - 密码验证功能拆分成独立功能
  - dbs -m 添加配置文件的显示
- Bugs Fixed
  - 合并Master_Host、Master_Port两个字段
  - 代码优化，所有字段变成动态
  - 缩减字段名字，解决显示问题
  - 修复dbs出现重复端口的bug

#### 2017-12-26
- Functionality Added or Changed
  - dbs脚本添加了功能：dbs m查看更多信息功能
  - go脚本添加了功能：优先使用端口进行登录
  - dbs增加了使用readlink获取准确的数据目录
- Bugs Fixed
  - 修复字段名称不规范问题
  - 修复dbs脚本部分查询Bug
