#!/bin/bash
set -e

. $HOME/asiou/scripts/utils.sh

prepare_asiou_db_configs() {
  get_db_version > "$WWW_HOME/asiou/db.version"
}

prepare_rid_export_cron() {
  if [ ! -z "$ASIOU_RID_EXPORT_CRON" ]; then
    echo "$ASIOU_RID_EXPORT_CRON www-data $WWW_HOME/scripts/rid-export.sh" > /etc/cron.d/asiou-rid-export
  fi
}

start_asiou() {
  prepare_rid_export_cron
  prepare_asiou_db_configs
  clear_expired_sessions
  exec supervisord -c /etc/supervisord.conf
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

run_shell() {
  prepare_asiou_db_configs
  exec /bin/bash
}

#=========================
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
  "shell")
    run_shell
    ;;

  *)
    start_asiou
esac
