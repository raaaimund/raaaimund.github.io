---
layout:     post
title:      Run TYPO3 with Docker
date:       2019-08-07 12:00:00
author:     Raimund Rittnauer
summary:    How to run Typo3 with NGINX, PHP-FPM and MySQL inside Docker
categories: tech
comments: true
tags:
 - typo3
 - docker
 - nginx
---

In this post we will create the required Docker containers to host TYPO3 with NGINX, PHP-FPM and MySQL.
I will briefly explain each container with their corresponding Dockerfile and in the end we will have a look at the Docker compose file.
When I wrote this post the current TYPO3 version was 9.5.8 LTS.

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

Here we download the latest TYPO3 version, copy it to our volume and run the installation with the typo3-console.

_Dockerfile_

``` Dockerfile
FROM composer:latest AS build
WORKDIR /src
RUN composer create-project typo3/cms-base-distribution site
WORKDIR /src/site
RUN composer require helhum/typo3-console typo3-ter/introduction:4.0.1

FROM php:7.3.8-fpm-alpine
USER root
RUN docker-php-ext-install mysqli
WORKDIR /site
COPY --from=build --chown=82:82 /src/site .
COPY entrypoint.sh .
RUN chmod +x vendor/bin/typo3cms && \
    chmod +x entrypoint.sh
CMD [ "./entrypoint.sh" ]
```

_entrypoint.sh_

I use sleep to wait until the MySQL server is up and running.

``` sh
sleep 10 && ./vendor/bin/typo3cms install:setup --no-interaction && ./vendor/bin/typo3cms cache:flush
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
RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ && \
    docker-php-ext-install -j$(nproc) gd
RUN docker-php-ext-configure intl && \
    docker-php-ext-install -j$(nproc) intl
USER www-data
ENV TYPO3_CONTEXT Development
```

_php.ini_

``` ini
upload_max_filesize=120M
post_max_size=120M
always_populate_raw_post_data=1
max_execution_time=1200
max_input_vars=1500
memory_limit=512M
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
    build: ./config/web/.
    depends_on: 
      - php
      - db
    ports:
      - '80:80'
    volumes:
      - html:/var/www/html
      - ./config/web/nginx.conf:/etc/nginx/conf.d/default.conf
      - ./config/web/AdditionalConfiguration.php:/var/www/html/public/typo3conf/AdditionalConfiguration.php
  
  composer:
    build: ./config/composer/.
    depends_on:
        - db
    volumes:
        - html:/site
    environment: 
      TYPO3_INSTALL_DB_USER: typo3
      TYPO3_INSTALL_DB_PASSWORD: abcdefghi
      TYPO3_INSTALL_DB_HOST: db
      TYPO3_INSTALL_DB_PORT: 3306
      TYPO3_INSTALL_DB_USE_EXISTING: 1
      TYPO3_INSTALL_DB_DBNAME: typo3
      TYPO3_INSTALL_ADMIN_USER: admin
      TYPO3_INSTALL_ADMIN_PASSWORD: abcdefghi
      TYPO3_INSTALL_SITE_NAME: 'My Site'
  
  php:
      build: ./config/php/.
      volumes:
        - html:/var/www/html
        - ./config/php/php.ini:/usr/local/etc/php/php.ini
        - ./config/php/log.conf:/usr/local/etc/php-fpm.d/zz-log.conf

  db:
      image: mysql:8.0.17
      command: mysqld --default-authentication-plugin=mysql_native_password
      volumes:
          - db-data:/var/lib/mysql
      environment:
        MYSQL_USER: typo3
        MYSQL_PASSWORD: abcdefghi
        MYSQL_DATABASE: typo3
        MYSQL_ROOT_PASSWORD: abcdefghi

volumes:
  html:
  db-data:
```

Now you are good to go and after _docker-compose up_ you should have a fresh installed and running TYPO3 web site with NGINX, PHP-FPM and MySQL.