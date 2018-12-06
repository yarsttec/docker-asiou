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
      memcached \
      telnet \
      optipng \
    ; \
    # Prepare Python
    python -m pip install --upgrade pip; \
    pip2 install --no-cache-dir setuptools; \
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
      "python-memcached~=1.59" \
      "johnny-cache==1.4" \
    ; \
    pip2 install --no-cache-dir -r /tmp/requirements.txt; \
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


# Install ASIOU distribution
ENV ASIOU_VERSION=7.5.9
RUN set -ex; \
    # Download and install
    $WWW_HOME/scripts/install-asiou.sh; \
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

EXPOSE 8080
ENTRYPOINT ["/entrypoint.sh"]
