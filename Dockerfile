FROM alpine:3.8
LABEL maintainer="Sergey Yarkin <sega.yarkin@gmail.com>"

# Install required software
COPY python_requirements.txt /tmp/requirements.txt
RUN set -ex; \
    # Create user and group
    addgroup -g 82 -S www-data; \
    adduser -u 82 -D -S -G www-data www-data; \
    # Install required libraries
    apk add --no-cache \
            wget \
            jpeg \
            libxml2 \
            libxslt \
            mysql-client \
            mariadb-connector-c \
            libressl \
            patch \
            supervisor \
            zlib \
            python2 \
            py2-pip \
    ; \
    # Install packages for building
    apk add --virtual .build-deps --no-cache \
            build-base \
            jpeg-dev \
            libffi-dev \
            libxml2-dev \
            libxslt-dev \
            linux-headers \
            musl-dev \
            python2-dev \
            zlib-dev \
            libressl-dev \
            mariadb-connector-c-dev \
    ; \
    # Prepare Python
    python -m pip install --no-cache-dir --upgrade pip; \
    # Install python packages required by ASIOU
    pip install --no-cache-dir -r /tmp/requirements.txt ;\
    # Install additional python packages
    pip install --no-cache-dir "johnny-cache==1.4"; \
    # Install nginx
    apk add --no-cache nginx; \
    rm -r /etc/nginx/conf.d/; \
    # Clear
    apk del .build-deps; \
    rm -rf /root/.cache; \
    rm -f /root/.ash_history; \
    rm -rf /tmp/*


ENV HOME=/srv \
    WWW_HOME=/srv/asiou \
    RUN_DIR=/srv/asiou/run \
    LOG_DIR=/srv/asiou/log

ENV DATABASE_HOST=127.0.0.1 \
    DATABASE_PORT=3306 \
    DATABASE_NAME=asiou \
    DATABASE_USER=asiou \
    DATABASE_PASSWORD=""

# Prepare
RUN set -ex; \
    mkdir -p ${HOME} ${WWW_HOME}; \
    ln -s /usr/lib/python2.7/site-packages/django/contrib/admin/media \
          ${WWW_HOME}/media

COPY scripts ${WWW_HOME}/scripts/
COPY asiou ${WWW_HOME}/asiou/
COPY patches ${WWW_HOME}/patches/
COPY nginx /etc/nginx/
COPY supervisord.conf /etc/supervisord.conf
COPY entrypoint.sh /entrypoint.sh
RUN set -ex; \
    chmod +x $WWW_HOME/scripts/*.sh \
             $WWW_HOME/patches/*.sh \
             /entrypoint.sh

ARG BUILD_DATE
LABEL asiou.version=${ASIOU_VERSION} \
      asiou.build-date=${BUILD_DATE}

# Install ASIOU distribution
ENV ASIOU_VERSION=7.5.9
RUN set -ex; \
    # Download and extract files
    wget -qO/tmp/asiou.zip "http://asiou.coikko.ru/static/update_version/www${ASIOU_VERSION}.zip"; \
    unzip -q /tmp/asiou.zip -d /tmp/ \
            '*/asiou/**.py' \
            '*/asiou/soap_api/cert/*' \
            '*/static/*' \
            '*/sql/updatedb/2018*' \
            '*/tpls/*' \
            '*/asiou.ico'; \
    # Remove trash
    find /tmp/www*/ -name "Thumbs.db" -delete; \
    find /tmp/www*/ -name "views?*.py" -delete; \
    find /tmp/www*/ ! -name "utils.py" -a  -name "util?*.py" -delete; \
    find /tmp/www*/ -name "urls?*.py" -delete; \
    find /tmp/www*/ -name "models?*.py" -delete; \
    rm -rf \
      /tmp/www*/asiou/common/r_functions{1,2}.py \
      /tmp/www*/asiou/management/commands/edit_pe_docum_member1.py \
      /tmp/www*/asiou/reports_stats/function_662.py \
      /tmp/www*/asiou/rhd_settings.py \
      /tmp/www*/asiou/settings_s.py \
      /tmp/www*/asiou/tmp/*; \
    find /tmp/www*/static/ -name "*1.xml" -delete; \
    rm -rf \
      /tmp/www*/static/images/psy_questions/* \
      /tmp/www*/tpls/douq_small_add.html.new \
      /tmp/www*/tpls/ed_programm1.html \
      /tmp/www*/tpls/*.zip \
      /tmp/www*/tpls/marks/marks1.html \
      /tmp/www*/tpls/psy/marks1.html \
      /tmp/www*/tpls/select_otype1.html; \
    # Move to right place
    cp -r /tmp/www*/* ${WWW_HOME}/; \
    rm -rf /tmp/*; \
    # Update files
    find "$WWW_HOME/asiou" -type f -name *.py -exec dos2unix '{}' \;; \
    chown -R www-data: "$WWW_HOME"; \
    # Applying patches
    ${WWW_HOME}/patches/00_patch.sh

HEALTHCHECK --interval=1m --timeout=10s \
    CMD [ $(wget -O/dev/null --max-redirect=0 http://127.0.0.1:8080/ 2>&1 | grep '302 FOUND' | wc -l) -eq 1 ] || exit 1

EXPOSE 8080
ENTRYPOINT ["/entrypoint.sh"]
