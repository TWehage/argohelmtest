FROM php:8.3-apache

MAINTAINER Thorsten Wehage <t.wehage@prediger.de>

COPY .docker/php/php.ini /usr/local/etc/php/conf.d/php.ini

RUN apt-get update && \
    apt-get install -y software-properties-common && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get update && \
    apt-get install -y git zip

# Copy app's source code to the /app directory
COPY app/ /var/www/html

# The application's directory will be the working directory
WORKDIR /var/www/html

COPY --from=composer /usr/bin/composer /usr/bin/composer
RUN composer install

EXPOSE 80
