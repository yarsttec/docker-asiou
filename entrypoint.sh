#!/bin/bash
set -e

init_work_dir() {
  mkdir -p "$RUN_DIR" "$LOG_DIR"
  touch "$LOG_DIR/cont_export.log"
  chown -R www-data: "$RUN_DIR" "$LOG_DIR"
  chmod -R g+w "$LOG_DIR"
}

init_nginx_dir() {
  mkdir -p /var/lib/nginx/{logs,body}
  chown -R www-data: /var/lib/nginx
  mkdir -p /var/run/nginx
  chown www-data: /var/run/nginx
}

export MYSQL_PWD="$DATABASE_PASSWORD"
get_mysql_cmd() {
  echo "/usr/bin/mysql -h $DATABASE_HOST -P $DATABASE_PORT -D $DATABASE_NAME \
        -u $DATABASE_USER -e"
}

get_db_version() {
  $(get_mysql_cmd) \
  'SELECT `version` FROM `asiou_db_version` ORDER BY `version` DESC LIMIT 1;' \
  --skip-column-names --vertical \
  | tail -n 1 | head -c 8
}

clear_expired_sessions() {
  $(get_mysql_cmd) \
  'DELETE FROM `django_session` WHERE `expire_date` < (DATE_SUB(NOW(), INTERVAL 1 DAY));'
}

prepare_asiou_db_configs() {
  get_db_version > "$WWW_HOME/asiou/db.version"
}

start_asiou() {
  prepare_asiou_db_configs
  clear_expired_sessions
  exec supervisord -c /etc/supervisord.conf
}

run_script() {
  local name="$1"
  "$WWW_HOME/scripts/${name}.sh"
}

run_database_update() {
  prepare_asiou_db_configs
  run_script "update"
}

run_backup() {
  "$WWW_HOME/scripts/backup.sh"
}

run_restore() {
  local file_name="$1"
  "$WWW_HOME/scripts/restore.sh" "$file_name"
}

#=========================
init_work_dir
init_nginx_dir
# Update ASIOU options
if [ ! -z "$ASIOU_OPTIONS" ]; then
  echo "$ASIOU_OPTIONS" | base64 -d > "$WWW_HOME/asiou/options.ini"
fi
# Update ASIOU db.ini with custon content
if [ ! -z "$ASIOU_DB_INI" ]; then
  echo "$ASIOU_DB_INI" | base64 -d > "$WWW_HOME/asiou/db.ini"
fi


case "$1" in
  "update")
    run_database_update
    ;;
  "gen-backup-keys")
    run_script "gen-backup-keys"
    ;;
  "backup")
    run_backup
    ;;
  "restore")
    run_restore "$2"
    ;;
  "rid-export")
    run_script "rid-export"
    ;;
  "cont-export")
    run_script "cont-export"
    ;;
  "cont-export-diff")
    run_script "cont-export-diff"
    ;;

  *)
    start_asiou
esac
