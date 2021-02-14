#!/bin/bash
set -ex

URL="http://asiou.coikko.ru/static/upd_vers/www${ASIOU_VERSION}.zip"

if [ "$CACHE_DISTR_FILE" = "yes" ]; then
  DISTR_FILE=/tmp/asiou.zip
  [ ! -f "$DISTR_FILE" ] && wget -qO"$DISTR_FILE" "$URL"
else
  DISTR_FILE=$(mktemp --suffix .zip)
  wget -qO"$DISTR_FILE" "$URL"
fi

DISTR_DIR=$(mktemp -d)
unzip -q "$DISTR_FILE" -d "$DISTR_DIR" \
  '*/manage.py' \
  '*/asiou/**.py' \
  '*/asiou/soap_api/cert/*' \
  '*/asiou/claim/*' \
  '*/asiou/**.zip' \
  '*/static/*' \
  '*/static_new/*' \
  '*/sql/django_migrations.sql' \
  '*/sql/init_structure.sql' \
  '*/tpls/*'

pushd $DISTR_DIR/www*

# Clean garbage
find ./ -name "Thumbs.db" -delete
rm -rf \
  ./asiou/common/r_functions{1,2}.py \
  ./asiou/management/commands/edit_pe_docum_member1.py \
  ./asiou/rhd_settings.py \
  ./asiou/settings_s.py \
  ./asiou/tmp/*
find ./static/ -name "*1.xml" -delete
rm -rf \
  ./tpls/douq_small_add.html.new \
  ./tpls/ed_programm1.html \
  ./tpls/*.zip \
  ./tpls/marks/marks1.html \
  ./tpls/psy/marks1.html \
  ./tpls/select_otype1.html

find ./asiou -type f -name '*.py' -exec dos2unix -q -k '{}' \;

# Move to right place
cp -r ./* "${WWW_HOME}/"

# Clean temporary files
popd
[ "$CACHE_DISTR_FILE" = "yes" ] || rm -f "$DISTR_FILE"
rm -rf "$DISTR_DIR"
