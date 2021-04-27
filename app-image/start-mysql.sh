#!/bin/sh

docker container run -d --name mysql --restart=unless-stopped \
  -e MYSQL_ROOT_PASSWORD=PaSwOrD \
  -e MYSQL_DATABASE=asiou \
  -e MYSQL_USER=asiou \
  -e MYSQL_PASSWORD=AsiouPassword \
  -p 3306:3306 \
  mysql:5.7.24 \
  --sql-mode='STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION'
