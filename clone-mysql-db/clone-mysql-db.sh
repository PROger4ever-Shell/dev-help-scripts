#!/bin/bash

# region Parameters
SRC_CONNECTION_CREDENTIALS="$1"
BACKUP_FILE_PREFIX_FULL="$2"
DST_CONNECTION_CREDENTIALS_LIST=("${@:3}")
# endregion Parameters

# region Var defaults
# NOTE: Vars can be overridden by env-files and env-variables!
UMASK_PATTERN=000
COMPRESSION_LEVEL=6
BACKUP_FILES_MAX_COUNT=3
CLONE_DATE="$(date +%Y-%m-%d_%H-%M-%S)"
CLONE_DATE_PATTERN='????-??-??_??-??-??'

MYSQLDUMP_PARAMETERS='--add-drop-table --add-locks --create-options --disable-keys --extended-insert --lock-tables=false --quick --set-charset --single-transaction --compress --dump-date'
MYSQL_PARAMETERS=''
# endregion Var defaults

# region Env
SCRIPT_FILE_PATH="${BASH_SOURCE[0]}"
SCRIPT_FILE_ABSOLUTE_PATH="$(realpath -s "$SCRIPT_FILE_PATH")"
SCRIPT_DIR_ABSOLUTE_PATH="$(dirname "$SCRIPT_FILE_ABSOLUTE_PATH")"

#SCRIPT_FILE_FULL_NAME="$(basename -- "$SCRIPT_FILE_ABSOLUTE_PATH")"
#SCRIPT_FILE_NAME="${SCRIPT_FILE_FULL_NAME%.*}"
#SCRIPT_FILE_EXTENSION="${SCRIPT_FILE_FULL_NAME##*.}"

ENV_FILE_PATHS=(
  "$SCRIPT_DIR_ABSOLUTE_PATH/.env"
  "$SCRIPT_DIR_ABSOLUTE_PATH/.local.env"
  "$BACKUP_FILE_PREFIX_FULL.env"
  "$BACKUP_FILE_PREFIX_FULL.local.env"
)

for ENV_FILE_PATH in "${ENV_FILE_PATHS[@]}"; do
  if [[ -f "$ENV_FILE_PATH" ]]; then
    # shellcheck source=clone-mysql-db.env
    source "$ENV_FILE_PATH"
  fi
done
# endregion Env

# region Vars
UMASK_PATTERN="${CLONE_MYSQL_DB_UMASK_PATTERN:-$UMASK_PATTERN}"
COMPRESSION_LEVEL="${CLONE_MYSQL_DB_COMPRESSION_LEVEL:-$COMPRESSION_LEVEL}"
BACKUP_FILES_MAX_COUNT="${CLONE_MYSQL_DB_BACKUP_FILES_MAX_COUNT:-$BACKUP_FILES_MAX_COUNT}"
CLONE_DATE="${CLONE_MYSQL_DB_CLONE_DATE:-$CLONE_DATE}"
CLONE_DATE_PATTERN="${CLONE_MYSQL_DB_CLONE_DATE_PATTERN:-$CLONE_DATE_PATTERN}"

MYSQLDUMP_PARAMETERS="${CLONE_MYSQL_DB_MYSQLDUMP_PARAMETERS:-$MYSQLDUMP_PARAMETERS}"
MYSQL_PARAMETERS="${CLONE_MYSQL_DB_MYSQL_PARAMETERS:-$MYSQL_PARAMETERS}"
# endregion Vars

# region Paths
BACKUP_FILE_PREFIX_DIR_PATH="$(dirname "$BACKUP_FILE_PREFIX_FULL")"
BACKUP_FILE_PREFIX_FILE_NAME="$(basename -- "$BACKUP_FILE_PREFIX_FULL")"

LOCK_FILE_FULL_PATH="$BACKUP_FILE_PREFIX_DIR_PATH/$BACKUP_FILE_PREFIX_FILE_NAME.lock"
LAST_START_FILE_FULL_PATH="$BACKUP_FILE_PREFIX_DIR_PATH/$BACKUP_FILE_PREFIX_FILE_NAME-last_start.txt"
LAST_SUCCESSFUL_BACKUP_FILE_FULL_PATH="$BACKUP_FILE_PREFIX_DIR_PATH/$BACKUP_FILE_PREFIX_FILE_NAME-last_successful_backup.txt"

BACKUP_PARTIAL_FILE_FULL_PATH="$BACKUP_FILE_PREFIX_DIR_PATH/$BACKUP_FILE_PREFIX_FILE_NAME-backup-partial-$CLONE_DATE.sql.gz.tmp"
BACKUP_COMPLETED_FILE_FULL_PATH="$BACKUP_FILE_PREFIX_DIR_PATH/$BACKUP_FILE_PREFIX_FILE_NAME-backup-full-$CLONE_DATE.sql.gz"
# endregion Paths

# region Functions
function lock() {
  if [ -e "$LOCK_FILE_FULL_PATH" ]; then
    echo "Lock-file already exists" >&2
    return 1
  fi

  echo -n "$$ $CLONE_DATE" >"$LOCK_FILE_FULL_PATH"
}

function unlock() {
  rm -f "$LOCK_FILE_FULL_PATH"
}

function remove_partial_files() {
  echo -e "\n- Remove partial files" >&2
  find "$BACKUP_FILE_PREFIX_DIR_PATH" -name "$BACKUP_FILE_PREFIX_FILE_NAME-backup-partial-$CLONE_DATE_PATTERN.sql.gz.tmp" -delete
}

function remove_extra_backups() {
  echo -e "\n- Remove all backups except last $BACKUP_FILES_MAX_COUNT" >&2
  # shellcheck disable=SC2012
  find "$BACKUP_FILE_PREFIX_DIR_PATH" -name "$BACKUP_FILE_PREFIX_FILE_NAME-backup-full-$CLONE_DATE_PATTERN.sql.gz" -exec ls -r1 {} \+ |
    tail -n "+$((BACKUP_FILES_MAX_COUNT + 1))" |
    xargs -r rm
}

function dump_db() {
  echo -e "\n- mysqldump to file" >&2
  # shellcheck disable=SC2086
  mysqldump $MYSQLDUMP_PARAMETERS $SRC_CONNECTION_CREDENTIALS |
    dd status=progress bs=8M |
    pigz -c "-$COMPRESSION_LEVEL" \
      >"$BACKUP_PARTIAL_FILE_FULL_PATH" &&
    mv "$BACKUP_PARTIAL_FILE_FULL_PATH" "$BACKUP_COMPLETED_FILE_FULL_PATH"
}

function restore_db() {
  if (( ${#DST_CONNECTION_CREDENTIALS_LIST[@]} == 0 )); then
    return 0
  fi

  for DST_CONNECTION_CREDENTIALS in "${DST_CONNECTION_CREDENTIALS_LIST[@]}"
  do
  	  echo -e "\n- Restore db from file to '$DST_CONNECTION_CREDENTIALS'"
      # shellcheck disable=SC2086
      pigz -cd "$BACKUP_COMPLETED_FILE_FULL_PATH" |
        dd status=progress bs=8M |
        mysql $MYSQL_PARAMETERS $DST_CONNECTION_CREDENTIALS
  done
}

function check_return_code() {
  local CODE="$1"
  local DO_FAIL_FAST="$2"

  if [ "$CODE" -eq "0" ]; then
    return 0
  fi

  if [ -z "$DO_FAIL_FAST" ]; then
      finish
  fi

  exit 1
}

function start() {
  umask "$UMASK_PATTERN"

  echo -n "$CLONE_DATE" >"$LAST_START_FILE_FULL_PATH"
  lock
}

function finish() {
  remove_partial_files
  unlock
}

function finish_successfully() {
  finish
  echo -n "$BACKUP_COMPLETED_FILE_FULL_PATH" >"$LAST_SUCCESSFUL_BACKUP_FILE_FULL_PATH"
}
# endregion Functions

# region Start
start
check_return_code $? 1
# endregion Start

# region Preparing
remove_partial_files
remove_extra_backups
# endregion Preparing

# region Dump DB
dump_db
check_return_code $?
# endregion Dump DB

# region Restore DB
restore_db
check_return_code $?
# endregion Restore DB

# region Remove extra backups again
remove_extra_backups
# endregion Remove extra backups again

# region Finish successfully
finish_successfully
# endregion Finish successfully
