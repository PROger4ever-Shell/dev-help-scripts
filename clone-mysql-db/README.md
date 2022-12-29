# Clone MYSQL DB
## Usage
### Save as sql.gz only
```shell
./clone-mysql-db.sh \
  "--protocol tcp --host src_host --port 3306 --user src_user --password=src_password src_db_name" \
  /path/dump_file_prefix
```

### Save as sql.gz only and clone to several destination databases
```shell
CLONE_MYSQL_DB_MYSQLDUMP_FILE_BEGIN=~/bkp/clone-mysql-script.dump-file-begin.sql \
  ./clone-mysql-db.sh \
    "--protocol tcp --host src_host --port 3306 --user src_user --password=src_password src_db_name" \
    /path/dump_file_prefix \
    "--protocol tcp --host dst_host1 --port 3306 --user dst_user1 --password=dst_password1 dst_db_name1" \
    "--protocol tcp --host dst_host2 --port 3306 --user dst_user2 --password=dst_password2 dst_db_name2"
```

### Crontab task example
```
00 09 * * * /home/proger4ever/projects/help-dev-scripts/clone-mysql-db/clone-mysql-db.sh 1>/home/proger4ever/tmp/src_host.output 2>&1 "--protocol tcp --host src_host --port src_user --password=src_password src_db_name" /home/proger4ever/tmp/src_host "--protocol tcp --host dst_host --port dst_user --password=dst_password dst_db_name"
```