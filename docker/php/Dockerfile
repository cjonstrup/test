# -------------------------------------------------------------------------------------------------- #
FROM php:8.0.15-fpm-alpine3.15 AS foundation

# Install PHP along side needed extensions -postgresql-dev
RUN apk add --no-cache --update bash zip unzip curl postgresql13-client postgresql13-dev libpng-dev libzip-dev freetype-dev libjpeg-turbo-dev\
    php8-dom \
    php8-fileinfo \
    php8-json \
    php8-opcache \
    php8-openssl \
    php8-pdo \
    php8-gd \
    php8-zip \
    php8-bcmath \
    php8-pgsql \
    php8-pdo_pgsql \
    php8-phar \
    php8-session \
    php8-tokenizer \
    php8-xml \
    php8-simplexml \
    php8-xmlwriter \
    php8-curl \
    php8-mbstring \
    php8-pcntl && \
    docker-php-ext-configure gd --with-freetype --with-jpeg && \
    docker-php-ext-install bcmath pdo pdo_pgsql pgsql gd exif zip && \
    apk del --purge --no-cache postgresql13-dev freetype-dev libpng-dev libjpeg-turbo-dev

# -------------------------------------------------------------------------------------------------- #
FROM foundation AS project

# Copy project files to the container and set workdir
#COPY ./../../../project /project

# Ensure permissions and log files is in place
#RUN chmod 0755 /project/storage

WORKDIR /project

# -------------------------------------------------------------------------------------------------- #
FROM project AS dependencies-php

# Installing composer
RUN curl -sS https://getcomposer.org/installer -o composer-setup.php
RUN php composer-setup.php --install-dir=/usr/local/bin --filename=composer
RUN rm -rf composer-setup.php
RUN composer install --optimize-autoloader

# -------------------------------------------------------------------------------------------------- #

FROM project AS dependencies-npm

# Installing npm
RUN apk add --no-cache npm

# Install npm packages
RUN npm ci && npm run prod && rm -rf node_modules

# -------------------------------------------------------------------------------------------------- #
FROM caddy:2.4.6-builder AS webbuilder

#RUN xcaddy build --with github.com/caddyserver/ntlm-transport --output /hest
RUN xcaddy build --output /hest

# -------------------------------------------------------------------------------------------------- #

FROM project AS base

#COPY --from=dependencies-php /project/vendor /project/vendor
#COPY --from=dependencies-npm /project/public /project/public

# -------------------------------------------------------------------------------------------------- #
FROM base AS web

LABEL "company.name"="lenius"
LABEL "website.type"="website"

# Install nginx and supervisor
RUN apk add --update nginx supervisor

# Install caddy
COPY --from=webbuilder /hest /usr/local/bin/hest

# Copy needed files and configuration
COPY docker/php/config/nginx.conf /etc/nginx/nginx.conf

COPY docker/php/config/php-fpm.conf /usr/local/etc/php-fpm.conf
COPY docker/php/config/php.ini /etc/php8/conf.d/overrides.ini

COPY docker/php/config/entrypoint-web.sh /entrypoint-web.sh
COPY docker/php/config/index.php /project/index.php
COPY docker/php/config/Caddyfile /project/Caddyfile

#COPY docker/php/config/wait-for-it.sh /usr/bin/wait-for-it
#COPY docker/php/config/crontab /etc/crontabs/root
