# Declare build argument with default fallback before FROM
ARG PHP_VERSION=php:8.3-apache
FROM ${PHP_VERSION}

# Install system dependencies & C-libraries for Grav CMS & WordPress extensions
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libwebp-dev \
    libzip-dev \
    libonig-dev \
    libicu-dev \
    libyaml-dev \
    libmagickwand-dev \
    libxml2-dev \
    libcurl4-openssl-dev \
    zip \
    unzip \
    git \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-configure intl \
    && docker-php-ext-install -j$(nproc) \
        mysqli \
        pdo \
        pdo_mysql \
        gd \
        zip \
        opcache \
        mbstring \
        exif \
        intl \
        bcmath \
        sockets \
    && pecl install \
        imagick \
        redis \
        memcache \
        apcu \
        yaml \
    && docker-php-ext-enable \
        imagick \
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
COPY docker/docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]