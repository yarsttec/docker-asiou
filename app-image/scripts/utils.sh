#!/bin/bash

export MYSQL_PWD="$DATABASE_PASSWORD"
get_mysql_cmd() {
  echo "/usr/bin/mysql -h $DATABASE_HOST -P $DATABASE_PORT -D $DATABASE_NAME \
        -u $DATABASE_USER"
}

get_db_version() {
  $(get_mysql_cmd) -e \
  'SELECT `version` FROM `asiou_db_version` ORDER BY `version` DESC LIMIT 1;' \
  --skip-column-names --vertical \
  | tail -n 1 | head -c 8
}

clear_expired_sessions() {
  $(get_mysql_cmd) -e \
  'DELETE FROM `django_session` WHERE `expire_date` < (DATE_SUB(NOW(), INTERVAL 1 DAY));'
}

run_script() {
  local name="$1"; shift;
  "$WWW_HOME/scripts/${name}.sh" "$@"
}
