# Clone MYSQL DB
## Usage
### Save as sql.gz only
```shell
./clone-mysql-db.sh src_host src_user src_password src_db_name /path/dump_file_prefix
```

### Save as sql.gz only and clone
```shell
./clone-mysql-db.sh src_host src_user src_password src_db_name /path/dump_file_prefix dst_host dst_user dst_password dst_db_name
```

### Crontab task example
```
00 09 * * * /home/proger4ever/projects/help-dev-scripts/clone-mysql-db/clone-mysql-db.sh 1>/home/proger4ever/tmp/src_host.output 2>&1 src_host src_user src_password src_db_name /home/proger4ever/tmp/src_host dst_host dst_user dst_password dst_db_name
```