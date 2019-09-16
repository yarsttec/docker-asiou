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
      less \
      zip \
      unzip \
      nano \
      cron \
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
    python -m pip install --upgrade "pip~=19.1"; \
    pip2 install --no-cache-dir "setuptools~=41.0.1"; \
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
    pip2 install --no-cache-dir -r /tmp/requirements.txt; \
    pip2 install --upgrade --no-cache-dir \
      https://github.com/sokolovs/django-piston/archive/master.tar.gz; \
    # Additional packages
    pip2 install --no-cache-dir \
      "supervisor~=3.0" \
      "django-cacheops~=4.1" \
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


ENV HOME=/srv \
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
