FROM php:8-apache

ENV APP_DIR=/var/www/html \
    TMP_DIR=/tmp
ARG BINARY=https://pkp.sfu.ca/ojs/download/ojs-3.5.0-1.tar.gz

ENV PHP_POST_MAX_SIZE=16M \
    PHP_UPLOAD_MAX_FILESIZE=10M

ADD ${BINARY} ${TMP_DIR}
WORKDIR ${APP_DIR}
RUN tar xf ${TMP_DIR}/ojs*.tar.gz --strip 1 \
    && chown -R www-data:www-data ${APP_DIR}/* \
    && rm -Rf ${TMP_DIR}/ojs*

COPY files/* ${TMP_DIR}/

RUN apt-get update \
    && apt-get dist-upgrade -y \
    && apt-get install -y --no-install-recommends libxml2-dev libzip-dev libpng-dev zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

RUN mv ${TMP_DIR}/config-creator.php /bin/config-creator \
    && mv ${TMP_DIR}/pkp.sh /bin/pkp \
    && mv ${TMP_DIR}/entrypoint.sh /entrypoint.sh \
    && mv ${TMP_DIR}/ojs.config.env /etc/ojs.config.env \
    && chmod +x /bin/config-creator \
    && chmod +x /bin/pkp \
    && chmod +x /entrypoint.sh \
    && docker-php-ext-install mysqli pdo pdo_mysql gettext xml intl bcmath ftp gd zip \
    && echo "error_log=/dev/stderr" > $PHP_INI_DIR/conf.d/error.ini \
    && echo "post_max_size=$PHP_POST_MAX_SIZE" > $PHP_INI_DIR/conf.d/ojs-settings.ini \
    && echo "upload_max_filesize=$PHP_UPLOAD_MAX_FILESIZE" >> $PHP_INI_DIR/conf.d/ojs-settings.ini \
    && rm ${APP_DIR}/config.inc.php

ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "apache2ctl", "-DFOREGROUND" ]
