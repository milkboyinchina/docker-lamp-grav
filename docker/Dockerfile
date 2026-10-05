# Declare build argument with default fallback before FROM
ARG PHP_VERSION=php:8.4-apache
FROM ${PHP_VERSION}

# Install system dependencies & C-libraries for Grav CMS, WordPress, Laravel & CodeIgniter
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
    libmemcached-dev \
    libxml2-dev \
    libcurl4-openssl-dev \
    zip \
    unzip \
    git \
    cron \
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
        curl \
        sockets \
    && pecl install \
        imagick \
        redis \
        memcached \
        apcu \
        yaml \
    && docker-php-ext-enable \
        imagick \
        opcache \
        redis \
        memcached \
        apcu \
        yaml

# Enable Apache mod_rewrite (required by Grav, Laravel, CodeIgniter, WordPress)
RUN a2enmod rewrite

# Composer (required by Laravel & CodeIgniter, harmless for Grav/WordPress)
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Create PHP log directory
RUN mkdir -p /var/log/php && chown -R www-data:www-data /var/log/php

WORKDIR /var/www/html

# Copy entrypoint script
COPY docker/docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]