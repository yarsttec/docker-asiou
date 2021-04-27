#!/bin/sh
set -ex

cd "$WWW_HOME"

patch -p 1 -i patches/01_fix_log_filename.patch
patch -p 1 -i patches/03_enable_sql_cache.patch
cp patches/03_settings_cacheops.py asiou/settings_cacheops.py
patch -p 1 -i patches/05_disable_wintools.patch
patch -p 1 -i patches/06_db_from_environ.patch
patch -p 1 -i patches/08_tune_sessions.patch
patch -p 1 -i patches/09_add_db_connection_for_reports.patch
patch -p 1 -i patches/10_optimize_export_rhd.patch
patch -p 1 -i patches/11_secret_key_from_environ.patch
patch -p 1 -i patches/12_fix_index_page_performance.patch

#patch -p 1 -i patches/00_enable_debug.patch

find . -name \*.orig -delete
