# syntax=docker/dockerfile:1

FROM php:8.2-apache

LABEL authors="scarab"
LABEL title="Docker image with Combodo iTop"
LABEL version="0.2"
LABEL url="https://github.com/scarab/itop-docker"

# BUILD_ARGUMENT_ENV = development | production
ARG BUILD_ARGUMENT_ENV=development

ARG USERNAME=www-data
ARG ITOP_DOWNLOAD_URL
ARG APP_DIR=/var/www/html
ENV APP_DIR=$APP_DIR
ARG ITOP_TMP=/tmp/itop
ARG ARTIFACTS_TMP=/tmp/artifacts
ENV ARTIFACTS_TMP=$ARTIFACTS_TMP

COPY artifacts ${ARTIFACTS_TMP:?}

RUN apt-get update \
    && apt-get install -y curl unzip graphviz default-mysql-client \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && mv "$PHP_INI_DIR/php.ini-$BUILD_ARGUMENT_ENV" "$PHP_INI_DIR/php.ini" \
    && mv $ARTIFACTS_TMP/php.ini $PHP_INI_DIR/conf.d/local.ini \
    && chmod -R u+x $ARTIFACTS_TMP/scripts \
    && mv $ARTIFACTS_TMP/scripts/*.sh /

ADD --chmod=0755 https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

RUN install-php-extensions ldap mysqli soap zip gd apcu imap \
    && /do_we_need_xdebug.sh

# Get iTop and fix rights
RUN mkdir -p ${APP_DIR} \
    && rm -rf ${APP_DIR}/* \
    && curl -SL -o /tmp/itop.zip ${ITOP_DOWNLOAD_URL:?} \
    && unzip /tmp/itop.zip -d ${ITOP_TMP}/ \
    && mv ${ITOP_TMP}/web/* ${APP_DIR} \
    && mkdir -p ${APP_DIR}/env-production ${APP_DIR}/env-toolkit \
    && chmod -R a=r ${APP_DIR} \
    && find ${APP_DIR} -type d -exec chmod a+x {} \; \
    && chmod u+w ${APP_DIR} \
    && chown ${USERNAME}:${USERNAME} ${APP_DIR} \
    && chown -R ${USERNAME} ${APP_DIR}/conf ${APP_DIR}/data ${APP_DIR}/log ${APP_DIR}/extensions ${APP_DIR}/env-production ${APP_DIR}/env-toolkit \
    && chmod -R ug+w ${APP_DIR}/conf ${APP_DIR}/data ${APP_DIR}/log ${APP_DIR}/extensions ${APP_DIR}/env-production ${APP_DIR}/env-toolkit

WORKDIR /var/www/html

VOLUME ["/var/www/html/conf", "/var/www/html/data", "/var/www/html/log", "/var/www/html/env-production", "/var/www/html/env-toolkit", "/var/www/html/extensions"]

EXPOSE 80

HEALTHCHECK --interval=5m --timeout=3s CMD curl -f http://localhost/ || exit 1
