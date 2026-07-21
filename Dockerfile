# Declare build argument with default fallback before FROM
ARG PHP_VERSION=8.3-apache
FROM php:${PHP_VERSION}

# Install system dependencies & C-libraries for extensions
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libzip-dev \
    libonig-dev \
    libicu-dev \
    libyaml-dev \
    zip \
    unzip \
    git \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-configure intl \
    && docker-php-ext-install -j$(nproc) \
        gd \
        zip \
        opcache \
        pdo \
        pdo_mysql \
        mbstring \
        exif \
        intl \
    && pecl install \
        redis \
        memcache \
        apcu \
        yaml \
    && docker-php-ext-enable \
        opcache \
        redis \
        memcache \
        apcu \
        yaml

# Enable Apache mod_rewrite
RUN a2enmod rewrite

# Create PHP log directory
RUN mkdir -p /var/log/php && chown -R www-data:www-data /var/log/php

WORKDIR /var/www/html

# Copy entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]