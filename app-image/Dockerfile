FROM yarsttec/asiou:7.6-base

# Prepare
COPY home/ ${WWW_HOME}/
COPY entrypoint.sh /entrypoint.sh
# hadolint ignore=SC2086
RUN set -ex; \
    chmod +x $WWW_HOME/scripts/*.sh \
             $WWW_HOME/patches/*.sh \
             /entrypoint.sh \
    ; \
    # Prepare directories
    mkdir -p "$RUN_DIR" "$LOG_DIR" "$TEMP_DIR"; \
    touch "$LOG_DIR/cont_export.log"; \
    chown -R www-data: "$RUN_DIR" "$LOG_DIR" "$TEMP_DIR"; \
    chmod -R g+w "$LOG_DIR"

ENV ASIOU_DOMAIN="" \
    ASIOU_HTTPS_ONLY=false \
    DEBUG_ASIOU=false \
    DEBUG_SQL=false \
    TMPDIR=$TEMP_DIR

HEALTHCHECK --interval=1m --timeout=10s \
    CMD [ $(wget -O/dev/null --max-redirect=0 http://127.0.0.1:8080/ 2>&1 | grep -i '302 Found' | wc -l) -eq 1 ] || exit 1

VOLUME /srv/asiou/log \
       /srv/asiou/temp \
       /srv/backup \
       /srv/cache/nginx

EXPOSE 8080
ENTRYPOINT ["/entrypoint.sh"]

#
# Install ASIOU distribution
#
ENV ASIOU_VERSION=7.6.2
RUN set -ex; \
    # Download and install
    "$WWW_HOME/scripts/install-asiou.sh"; \
    ln -s asiou/wsgi.py "$WWW_HOME/wsgi.py"; \
    # Apply patches
    "$WWW_HOME/patches/00_patch.sh"; \
    ln -s /usr/local/lib/python2.7/dist-packages/debug_toolbar/static/debug_toolbar \
          "$WWW_HOME/static_new/debug_toolbar"; \
    # Optimize distribution
    "$WWW_HOME/scripts/optimize-dist.sh"

ARG BUILD_DATE
LABEL asiou.version=${ASIOU_VERSION} \
      asiou.build-date=${BUILD_DATE}
