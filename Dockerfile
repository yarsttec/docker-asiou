FROM ubuntu:18.04
LABEL maintainer="Sergey Yarkin <sega.yarkin@gmail.com>"

# Install required libraries
RUN set -ex; \
    export DEBIAN_FRONTEND=noninteractive; \
    apt-get update; \
    apt-get install --no-install-recommends -y \
      openssl \
      ca-certificates \
      wget \
      zip \
      unzip \
      dos2unix \
      patch \
      libmysqlclient20 \
      mysql-client \
      python2.7 \
      python-pip \
      libxml2 \
      libxslt1.1 \
      nginx-light \
      redis \
      telnet \
      optipng \
      # NOTE: try Nginx Unit instead of Apache
      # https://unit.nginx.org/howto/django/
      apache2 \
      libapache2-mod-wsgi \
    ; \
    # Nginx directories
    mkdir -p /var/lib/nginx/logs \
             /var/run/nginx; \
    chown -R www-data: /var/lib/nginx \
                       /var/run/nginx; \
    # Prepare Apache
    rm -rf /etc/apache2/sites-enabled/* \
           /etc/apache2/sites-available/* \
           /var/log/apache2/*; \
    chown -R www-data: /var/log/apache2 \
                       /var/run/apache2 \
                       /var/lock/apache2; \
    # Prepare Python
    python -m pip install --upgrade "pip~=18.1"; \
    pip2 install --no-cache-dir "setuptools~=40.6.3"; \
    # Clean
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*; \
    rm -rf /root/.cache; \
    rm -rf /tmp/*

# Install python packages required by ASIOU
COPY python_requirements.txt /tmp/requirements.txt
RUN set -ex; \
    export DEBIAN_FRONTEND=noninteractive; \
    apt-get update; \
    # Install packages for building
    apt-get install --no-install-recommends -y \
      build-essential \
      libmysqlclient-dev \
      python2.7-dev \
      libssl-dev \
    ; \
    #
    pip2 install --no-cache-dir \
      "supervisor~=3.0" \
      "django-cacheops~=4.1" \
    ; \
    pip2 install --no-cache-dir -r /tmp/requirements.txt; \
    pip2 install --upgrade --no-cache-dir \
      https://github.com/sokolovs/django-piston/archive/master.tar.gz; \
    # Clean
    apt-get remove --purge -y \
      build-essential \
      libmysqlclient-dev \
      python2.7-dev \
      libssl-dev \
    ; \
    apt-get autoremove --purge -y; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*; \
    rm -rf /root/.cache; \
    rm -rf /tmp/*


ENV HOME=/srv \
    WWW_HOME=/srv/asiou \
    RUN_DIR=/srv/asiou/run \
    LOG_DIR=/srv/asiou/log \
    TEMP_DIR=/srv/asiou/temp

ENV DATABASE_HOST=127.0.0.1 \
    DATABASE_PORT=3306 \
    DATABASE_NAME=asiou \
    DATABASE_USER=asiou \
    DATABASE_PASSWORD=""

# Prepare
RUN set -ex; \
    mkdir -p ${HOME} ${WWW_HOME}; \
    ln -s /usr/local/lib/python2.7/dist-packages/django/contrib/admin/static/admin \
          ${WWW_HOME}/media

COPY scripts ${WWW_HOME}/scripts/
COPY asiou ${WWW_HOME}/asiou/
COPY patches ${WWW_HOME}/patches/
COPY nginx /etc/nginx/
COPY apache2 /etc/apache2/
COPY redis /etc/redis/
COPY supervisord.conf /etc/supervisord.conf
COPY entrypoint.sh /entrypoint.sh
RUN set -ex; \
    ln -s ../sites-available/django-asiou.conf \
          /etc/apache2/sites-enabled/django-asiou.conf; \
    chmod +x $WWW_HOME/scripts/*.sh \
             $WWW_HOME/patches/*.sh \
             /entrypoint.sh


# Install ASIOU distribution
ENV ASIOU_VERSION=7.6
RUN set -ex; \
    # Download and install
    $WWW_HOME/scripts/install-asiou.sh; \
    ln -s asiou/wsgi.py $WWW_HOME/wsgi.py; \
    # Applying patches
    $WWW_HOME/patches/00_patch.sh; \
    # Compile source code
    python -W ignore -m compileall -f -qq $WWW_HOME/asiou; \
    # Prepare compressed static files
    find $WWW_HOME/static \
        -type f \
        -regextype posix-extended \
        -iregex '.*\.(css|js|html?|ttf)' \
        -exec gzip -9 -k -q '{}' \;; \
    # Optimize images
    find $WWW_HOME/static \
        -type f \
        -regextype posix-extended \
        -iregex '.*\.(png|gif)' \
        -exec optipng -o3 -q '{}' \;

ENV ASIOU_DOMAIN= \
    ASIOU_HTTPS_ONLY=false \
    DEBUG_ASIOU=false \
    DEBUG_SQL=false

ARG BUILD_DATE
LABEL asiou.version=${ASIOU_VERSION} \
      asiou.build-date=${BUILD_DATE}

HEALTHCHECK --interval=1m --timeout=10s \
    CMD [ $(wget -O/dev/null --max-redirect=0 http://127.0.0.1:8080/ 2>&1 | grep '302 FOUND' | wc -l) -eq 1 ] || exit 1

# Prepare directories
RUN set -ex; \
    mkdir -p "$RUN_DIR" "$LOG_DIR" "$TEMP_DIR"; \
    touch "$LOG_DIR/cont_export.log"; \
    chown -R www-data: "$RUN_DIR" "$LOG_DIR" "$TEMP_DIR"; \
    chmod -R g+w "$LOG_DIR"


VOLUME /srv/asiou/log
VOLUME /srv/asiou/temp
VOLUME /srv/backup

EXPOSE 8080
ENTRYPOINT ["/entrypoint.sh"]
