FROM ubuntu:18.04
LABEL maintainer="Sergey Yarkin <sega.yarkin@gmail.com>"

# Install required libraries
RUN set -ex; \
    export DEBIAN_FRONTEND=noninteractive; \
    apt-get update; \
    apt-get install --no-install-recommends -y \
      openssl=1.1.1* \
      ca-certificates=* \
      wget=1.19.4* \
      less=* \
      zip=3.0* \
      unzip=6.0* \
      nano=* \
      cron=3.0pl1* \
      dos2unix=7.3.4* \
      patch=2.7.6* \
      libmysqlclient20=5.7.* \
      mysql-client=5.7.* \
      python2.7=2.7.* \
      python-pip=9.0.1-2.3* \
      libxml2=2.9.4* \
      libxslt1.1=1.1.29* \
      nginx-light=1.14.0* \
      redis=5:4.0.9* \
      telnet=0.17* \
      optipng=0.7.6* \
      # NOTE: try Nginx Unit instead of Apache
      # https://unit.nginx.org/howto/django/
      apache2=2.4.29* \
      libapache2-mod-wsgi=4.5.17* \
    ; \
    rm -f /etc/crontab; \
    # Nginx directories
    mkdir -p /var/lib/nginx/body \
             /var/lib/nginx/logs \
             /var/lib/nginx/proxy \
             /var/run/nginx \
             /srv/cache/nginx; \
    chown -R www-data: /var/lib/nginx \
                       /var/run/nginx \
                       /srv/cache/nginx; \
    # Prepare Apache
    rm -rf /etc/apache2/sites-enabled/* \
           /etc/apache2/sites-available/* \
           /etc/apache2/conf-enabled/* \
           /var/log/apache2/*; \
    chown -R www-data: /var/log/apache2 \
                       /var/run/apache2 \
                       /var/lock/apache2; \
    a2dismod -f autoindex deflate dir filter status; \
    # Prepare Python
    python -m pip install --upgrade "pip==19.3.1"; \
    pip2 install --no-cache-dir "setuptools==42.0.2"; \
    # Clean
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*; \
    rm -rf /root/.cache; \
    rm -rf /tmp/*

# Install python packages required by ASIOU
COPY python_requirements.txt /tmp/requirements.txt
# hadolint ignore=DL3013
RUN set -ex; \
    export DEBIAN_FRONTEND=noninteractive; \
    apt-get update; \
    # Install packages for building
    apt-get install --no-install-recommends -y \
      build-essential=* \
      libmysqlclient-dev=5.7.* \
      python2.7-dev=2.7.* \
      libssl-dev=1.1.1* \
    ; \
    pip2 install --no-cache-dir -r /tmp/requirements.txt; \
    pip2 install --upgrade --no-cache-dir \
      https://github.com/sokolovs/django-piston/archive/master.tar.gz; \
    # Additional packages
    pip2 install --no-cache-dir \
      "supervisor==4.1.0" \
      "django-cacheops~=4.2" \
      "django-debug-toolbar~=1.11" \
    ; \
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


ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    HOME=/srv \
    WWW_HOME=/srv/asiou \
    RUN_DIR=/srv/asiou/run \
    LOG_DIR=/srv/asiou/log \
    TEMP_DIR=/srv/asiou/temp \
    DATABASE_HOST=127.0.0.1 \
    DATABASE_PORT=3306 \
    DATABASE_NAME=asiou \
    DATABASE_USER=asiou \
    DATABASE_PASSWORD=""

# Prepare

COPY etc/ /etc/

RUN set -ex; \
    mkdir -p ${HOME} ${WWW_HOME}; \
    ln -s /usr/local/lib/python2.7/dist-packages/django/contrib/admin/static/admin \
          ${WWW_HOME}/media; \
    ln -s ../sites-available/django-asiou.conf \
          /etc/apache2/sites-enabled/django-asiou.conf; \
    echo "export APACHE_LOG_DIR=${LOG_DIR}" >> /etc/apache2/envvars

ARG BUILD_DATE
LABEL asiou.base-build-date=${BUILD_DATE}
