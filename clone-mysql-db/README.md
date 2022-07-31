# Clone MYSQL DB
## Usage
### Save as sql.gz only
```shell
./clone-mysql-db.sh \
  "--protocol tcp --host src_host --port 3306 --user src_user --password=src_password src_db_name" \
  /path/dump_file_prefix
```

### Save as sql.gz only and clone
```shell
./clone-mysql-db.sh \
  "--protocol tcp --host src_host --port 3306 --user src_user --password=src_password src_db_name" \
  /path/dump_file_prefix \
  "--protocol tcp --host dst_host --port 3306 --user dst_user --password=dst_password dst_db_name"
```

### Crontab task example
```
00 09 * * * /home/proger4ever/projects/help-dev-scripts/clone-mysql-db/clone-mysql-db.sh 1>/home/proger4ever/tmp/src_host.output 2>&1 "--protocol tcp --host src_host --port src_user --password=src_password src_db_name" /home/proger4ever/tmp/src_host "--protocol tcp --host dst_host --port dst_user --password=dst_password dst_db_name"
```