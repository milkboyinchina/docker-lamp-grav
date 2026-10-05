#!/bin/bash
set -e

# Export environment variables with fallbacks
export SERVER_NAME="${SERVER_NAME:-localhost}"
export SERVER_ADMIN="${SERVER_ADMIN:-webmaster@localhost}"

# Update global ServerName in main apache2.conf
sed -i '/ServerName/d' /etc/apache2/apache2.conf
echo "ServerName ${SERVER_NAME}" >> /etc/apache2/apache2.conf

# Automatically fix permissions for Grav writable directories on startup
mkdir -p /var/www/html/cache \
         /var/www/html/logs \
         /var/www/html/images \
         /var/www/html/assets \
         /var/www/html/tmp \
         /var/www/html/backup

chown -R www-data:www-data /var/www/html/cache \
                           /var/www/html/logs \
                           /var/www/html/images \
                           /var/www/html/assets \
                           /var/www/html/tmp \
                           /var/www/html/backup \
                           /var/www/html/user 2>/dev/null || true

chmod -R 777 /var/www/html/cache \
             /var/www/html/logs \
             /var/www/html/images \
             /var/www/html/assets \
             /var/www/html/tmp \
             /var/www/html/backup \
             /var/www/html/user 2>/dev/null || true

# Setup Grav Scheduler crontab for www-data
if command -v crontab >/dev/null 2>&1; then
    (crontab -u www-data -l 2>/dev/null | grep -v 'bin/grav scheduler'; echo "* * * * * cd /var/www/html && /usr/local/bin/php bin/grav scheduler 1>> /dev/null 2>&1") | crontab -u www-data - 2>/dev/null || true
fi

# Start cron daemon
if command -v service >/dev/null 2>&1; then
    service cron start 2>/dev/null || true
fi

# Execute Apache
exec "$@"