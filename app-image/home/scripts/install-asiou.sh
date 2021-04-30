#!/bin/bash
set -ex

ASIOU_SOURCE_PREFIX="${ASIOU_SOURCE_PREFIX:-"http://asiou.coikko.ru"}"
URL="${ASIOU_SOURCE_PREFIX}/static/upd_vers/www${ASIOU_VERSION}.zip"

download() {
  wget --progress=bar:force --tries=3 -O"$2" "$1"
}

if [ "$CACHE_DISTR_FILE" = "yes" ]; then
  DISTR_FILE=/tmp/asiou.zip
  [ ! -f "$DISTR_FILE" ] && download "$URL" "$DISTR_FILE"
else
  DISTR_FILE=$(mktemp --suffix .zip)
  download "$URL" "$DISTR_FILE"
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
