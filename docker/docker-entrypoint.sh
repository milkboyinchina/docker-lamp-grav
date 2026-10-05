#!/bin/bash
set -e

# Export environment variables with fallbacks
export SERVER_NAME="${SERVER_NAME:-localhost}"
export SERVER_ADMIN="${SERVER_ADMIN:-webmaster@localhost}"
export APP_TYPE="${APP_TYPE:-grav}"
export APACHE_DOCROOT="${APACHE_DOCROOT:-/var/www/html}"

# Update global ServerName in main apache2.conf
sed -i '/ServerName/d' /etc/apache2/apache2.conf
echo "ServerName ${SERVER_NAME}" >> /etc/apache2/apache2.conf

# Apply the configured document root to the vhost when it differs from the
# default (e.g. Laravel serves from <root>/public). The vhost file is a
# bind-mounted host file; edits are idempotent and persist across restarts.
VHOST_CONF="/etc/apache2/sites-available/000-default.conf"
if [ "${APACHE_DOCROOT}" != "/var/www/html" ] && [ -f "${VHOST_CONF}" ]; then
    sed -i "s|^\(\s*\)DocumentRoot .*|\1DocumentRoot ${APACHE_DOCROOT}|" "${VHOST_CONF}"
    sed -i "s|^\(\s*\)<Directory /var/www/html>|\1<Directory ${APACHE_DOCROOT}>|" "${VHOST_CONF}"
fi

# Per-application writable directories, ownership fix mode, and scheduler line.
# Grav keeps its historical 777 behavior; other apps use 775 + www-data ownership.
APP_DIRS=""
APP_SCHEDULER=""
case "${APP_TYPE}" in
    grav)
        APP_DIRS="/var/www/html/cache /var/www/html/logs /var/www/html/images /var/www/html/assets /var/www/html/tmp /var/www/html/backup /var/www/html/user"
        APP_SCHEDULER="* * * * * cd /var/www/html && /usr/local/bin/php bin/grav scheduler 1>> /dev/null 2>&1"
        ;;
    laravel)
        APP_DIRS="/var/www/html/storage /var/www/html/bootstrap/cache"
        APP_SCHEDULER="* * * * * cd /var/www/html && /usr/local/bin/php artisan schedule:run >> /dev/null 2>&1"
        ;;
    codeigniter)
        APP_DIRS="/var/www/html/writable"
        ;;
    wordpress)
        APP_DIRS="/var/www/html/wp-content"
        ;;
    custom)
        # No managed directories or scheduler; app handles its own layout.
        ;;
    *)
        echo "ERROR: unsupported APP_TYPE '${APP_TYPE}'. Choose: grav, laravel, codeigniter, wordpress, custom." >&2
        exit 1
        ;;
esac

# shellcheck disable=SC2086
if [ -n "${APP_DIRS}" ]; then
    mkdir -p ${APP_DIRS}
    chown -R www-data:www-data ${APP_DIRS} 2>/dev/null || true
    if [ "${APP_TYPE}" = "grav" ]; then
        chmod -R 777 ${APP_DIRS} 2>/dev/null || true
    else
        chmod -R 775 ${APP_DIRS} 2>/dev/null || true
    fi
fi

# Warn (do not fail) when the document root looks empty - usually a wrong
# SRC_PATH / volume mount rather than a fresh app.
if [ -z "$(ls -A "${APACHE_DOCROOT}" 2>/dev/null)" ]; then
    echo "WARNING: document root '${APACHE_DOCROOT}' is empty. Check SRC_PATH / volume mounts." >&2
fi

# Setup application scheduler crontab for www-data (clears stale entries from
# a previous APP_TYPE first so switching apps cannot double-schedule).
if [ -n "${APP_SCHEDULER}" ] && command -v crontab >/dev/null 2>&1; then
    (crontab -u www-data -l 2>/dev/null | grep -v 'bin/grav scheduler' | grep -v 'artisan schedule:run'; echo "${APP_SCHEDULER}") | crontab -u www-data - 2>/dev/null || true
fi

# Start cron daemon
if command -v service >/dev/null 2>&1; then
    service cron start 2>/dev/null || true
fi

# Execute Apache
exec "$@"
