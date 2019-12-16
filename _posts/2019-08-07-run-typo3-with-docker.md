---
permalink:	/:categories/:year/:month/:day/:title/
layout:     post
title:      Run TYPO3 with Docker
date:       2019-08-07 12:00:00
author:     Raimund Rittnauer
description:    How to run Typo3 with NGINX, PHP-FPM and MySQL inside Docker
categories: tech
comments: true
tags:
 - typo3
 - docker
 - nginx
---

In this post we will create Docker containers to run TYPO3 with NGINX, PHP-FPM and MySQL with an optional SQL dump import.
I will briefly explain each container with their corresponding Dockerfile and in the end we will have a look at the Docker compose file.

> When I wrote this post the current TYPO3 version was 9.5.8 LTS.

## web (NGINX)

This container runs NGINX and serves the content in _/var/www/html_ which is stored inside a volume.

_Dockerfile_

``` Dockerfile
FROM nginx:1.17.2-alpine
# ensure www-data user exists
RUN set -x ; \
  addgroup -g 82 -S www-data ; \
  adduser -u 82 -D -S -G www-data www-data && exit 0 ; exit 1
```

_nginx.conf_

``` conf
server {
    listen 80;
    index index.php index.html;
    server_name localhost;
    error_log  /var/log/nginx/error.log;
    access_log /var/log/nginx/access.log;
    root /var/www/html/public;

    location ~ \.php$ {
        try_files $uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass php:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
    }
}
```

## composer

This container just installs everything we defined in the _composer.json_ file.

_Dockerfile_

``` Dockerfile
FROM composer:latest
RUN apk add --no-cache freetype-dev libjpeg-turbo-dev libpng-dev mysql-client
RUN docker-php-ext-install mysqli gd
WORKDIR /site
CMD [ "composer", "install" ]
```

## php (PHP-FPM)

This container runs the PHP-FPM agent and installs all required dependencies for TYPO3.

_Dockerfile_

``` Dockerfile
FROM php:7.3.8-fpm-alpine
USER root
RUN apk add --update --no-cache \
    freetype-dev \
    libjpeg-turbo-dev \
    libpng-dev \
    libzip-dev \
    zlib-dev \
    icu-dev \
    g++ \
    icu
RUN docker-php-ext-install -j$(nproc) mysqli pdo_mysql zip
RUN docker-php-ext-configure gd --with-gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --with-png-dir=/usr/include/ && \
    docker-php-ext-install -j$(nproc) gd
RUN docker-php-ext-configure intl && \
    docker-php-ext-install -j$(nproc) intl
USER www-data
```

_php.ini_

``` ini
upload_max_filesize=120M
post_max_size=120M
always_populate_raw_post_data=1
max_execution_time=1200
max_input_vars=1500
memory_limit=512M
extension=gd.so
```

_log.conf_

This configuration file is only required if you want to see the logs from the PHP-FPM agent after running the container.

``` conf
php_admin_flag[log_errors] = on
php_flag[display_errors] = on
```

## docker-compose.yaml

In our _docker-compose.yaml_ file we define our volumes, map the required configuration files and volumes to the correct paths and
define our environment variables for the TYPO3 installation and MySQL database setup.

_docker-compose.yaml_

``` yaml
version: '3'
services:
  web:
    build: ./container/web/.
    depends_on: 
      - php
      - db
    ports:
      - '80:80'
    volumes:
      - ./site:/var/www/html
      - ./container/web/nginx.conf:/etc/nginx/conf.d/default.conf
  
  composer:
    build: ./container/composer/.
    depends_on:
        - db
    volumes:
        - ./site:/site
    environment: 
      TYPO3_INSTALL_DB_USER: ${DB_USER}
      TYPO3_INSTALL_DB_PASSWORD: ${DB_PASS}
      TYPO3_INSTALL_DB_HOST: ${DB_HOST}
      TYPO3_INSTALL_DB_PORT: ${DB_PORT}
      TYPO3_INSTALL_DB_USE_EXISTING: ${DB_USE_EXISTING}
      TYPO3_INSTALL_DB_DBNAME: ${DB_NAME}
      TYPO3_INSTALL_ADMIN_USER: ${TYPO3_USER}
      TYPO3_INSTALL_ADMIN_PASSWORD: ${TYPO3_PASS}
      TYPO3_INSTALL_SITE_NAME: ${TYPO3_SITE_NAME}
  
  php:
      build: ./container/php/.
      volumes:
        - ./site:/var/www/html
        - ./container/php/php.ini:/usr/local/etc/php/php.ini
        - ./container/php/log.conf:/usr/local/etc/php-fpm.d/zz-log.conf
      environment: 
        TYPO3_CONTEXT: Development

  db:
      image: mysql:8.0.17
      command: mysqld --default-authentication-plugin=mysql_native_password
      volumes:
          - db-data:/var/lib/mysql
      environment:
        MYSQL_USER: ${DB_USER}
        MYSQL_PASSWORD: ${DB_PASS}
        MYSQL_DATABASE: ${DB_NAME}
        MYSQL_ROOT_PASSWORD: ${DB_ROOT_PASS}

volumes:
  db-data:
```

Now after running _docker-compose up_ you should have a fresh installed and running TYPO3 web site with NGINX, PHP-FPM and MySQL.

Checkout the [github repo][1]{:target="_blank"} for the source.

[1]: https://github.com/raaaimund/typo3-docker
