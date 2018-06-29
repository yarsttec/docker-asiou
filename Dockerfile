FROM alpine:3.7
LABEL maintainer="Sergey Yarkin <sega.yarkin@gmail.com>"

# Install required software
COPY python_requirements.txt /tmp/requirements.txt
RUN set -ex; \
    # Create user and group
    addgroup -g 82 -S www-data; \
    adduser -u 82 -D -S -G www-data www-data; \
    apk update; \
    # Install required libraries
    apk add \
            curl \
            jpeg \
            libxml2 \
            libxslt \
            mysql-client \
            openssl \
            patch \
            supervisor \
            zlib \
    ; \
    # Install packages for building
    apk add --virtual .build-deps \
            build-base \
            jpeg-dev \
            libffi-dev \
            libxml2-dev \
            libxslt-dev \
            linux-headers \
            musl-dev \
            openssl-dev \
            python2-dev \
            zlib-dev \
    ; \
    # Prepare Python
    apk add python2 \
            py2-pip \
            py-mysqldb \
    ; \
    pip install --upgrade pip; \
    # Install python packages required by ASIOU
    pip install -r /tmp/requirements.txt ;\
    # Install additional python packages
    pip install johnny-cache==1.4; \
    # Install nginx
    apk add nginx; \
    rm -r /etc/nginx/conf.d/; \
    # Clear
    apk del .build-deps; \
    rm /var/cache/apk/*; \
    rm -rf /root/.cache; \
    rm -f /root/.ash_history; \
    rm -rf /tmp/*


ENV HOME=/srv \
    WWW_HOME=/srv/asiou \
    RUN_DIR=/srv/asiou/run \
    LOG_DIR=/srv/asiou/log

# Prepare
RUN set -ex; \
    mkdir -p ${HOME} ${WWW_HOME}; \
    ln -s /usr/lib/python2.7/site-packages/django/contrib/admin/media \
          ${WWW_HOME}/media

# Download ASIOU distribution
ENV ASIOU_VERSION=7.5.8
RUN set -ex; \
    # Download and extract files
    wget -qO/tmp/asiou.zip "http://asiou.coikko.ru/static/update_version/www${ASIOU_VERSION}.zip"; \
    unzip /tmp/asiou.zip -d /tmp/ \
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
    rm -f /tmp/www*/asiou/common/r_functions1.py; \
    rm -f /tmp/www*/asiou/management/commands/edit_pe_docum_member1.py; \
    rm -f /tmp/www*/asiou/reports_stats/function_662.py; \
    rm -f /tmp/www*/asiou/rhd_settings.py; \
    rm -f /tmp/www*/asiou/settings_s.py; \
    rm -rf /tmp/www*/asiou/tmp/*; \
    rm -f /tmp/www*/static/images/psy_questions/*; \
    find /tmp/www*/static/ -name "*1.xml" -delete; \
    rm -f /tmp/www*/tpls/douq_small_add.html.new; \
    rm -f /tmp/www*/tpls/ed_programm1.html; \
    rm -f /tmp/www*/tpls/*.zip; \
    rm -f /tmp/www*/tpls/marks/marks1.html; \
    rm -f /tmp/www*/tpls/psy/marks1.html; \
    rm -f /tmp/www*/tpls/select_otype1.html; \
    # Move to right place
    mv /tmp/www*/* ${WWW_HOME}/; \
    rm -rf /tmp/*; \
    # Update files
    find "$WWW_HOME/asiou" -type f -name *.py -exec dos2unix '{}' \;; \
    chown -R www-data: "$WWW_HOME"

# Applying patches
COPY patches/* ${WWW_HOME}/patches/
RUN ${WWW_HOME}/patches/00_patch.sh

COPY scripts ${WWW_HOME}/scripts/
COPY asiou ${WWW_HOME}/asiou/
COPY nginx /etc/nginx/
COPY supervisord.conf /etc/supervisord.conf
COPY entrypoint.sh /entrypoint.sh
RUN set -ex; \
    chmod +x $WWW_HOME/scripts/*.sh \
             /entrypoint.sh

ENV DATABASE_HOST=127.0.0.1 \
    DATABASE_PORT=3306 \
    DATABASE_NAME=asiou \
    DATABASE_USER=asiou \
    DATABASE_PASSWORD=""

ARG BUILD_DATE
LABEL asiou.version=${ASIOU_VERSION} \
      asiou.build-date=${BUILD_DATE}

HEALTHCHECK --interval=1m --timeout=10s \
    CMD [ $(curl -sI http://127.0.0.1:8080/|head -1|cut -d' ' -f2) -eq 302 ] || exit 1

EXPOSE 8080
ENTRYPOINT ["/entrypoint.sh"]
