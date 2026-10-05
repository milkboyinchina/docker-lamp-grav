#!/usr/bin/env bash
# Linux / macOS / WSL Docker Stack Start Script
if [ ! -f .env ]; then
    echo "Creating .env configuration file from env.example..."
    cp env.example .env
fi
if [ ! -f docker-compose.yml ]; then
    echo "Creating docker-compose.yml configuration file from docker-compose.yml.example..."
    cp docker-compose.yml.example docker-compose.yml
fi
if [ ! -f docker-compose.direct.yml ]; then
    echo "Creating docker-compose.direct.yml configuration file from docker-compose.direct.yml.example..."
    cp docker-compose.direct.yml.example docker-compose.direct.yml
fi
if [ ! -f config/apache/000-default.conf ] && [ -f config/apache/000-default.conf.example ]; then
    echo "Creating config/apache/000-default.conf from example..."
    cp config/apache/000-default.conf.example config/apache/000-default.conf
fi
if [ ! -f config/php/custom.ini ] && [ -f config/php/custom.ini.example ]; then
    echo "Creating config/php/custom.ini from example..."
    cp config/php/custom.ini.example config/php/custom.ini
fi
if [ ! -f config/mysql/custom.cnf ] && [ -f config/mysql/custom.cnf.example ]; then
    echo "Creating config/mysql/custom.cnf from example..."
    cp config/mysql/custom.cnf.example config/mysql/custom.cnf
fi
# Validate PHP_VERSION selector (number only - image is derived in compose)
PHP_VERSION_VAL="$(grep -E '^PHP_VERSION=' .env 2>/dev/null | tail -n 1 | cut -d= -f2-)"
PHP_VERSION_VAL="${PHP_VERSION_VAL:-8.4}"
case " 8.3 8.4 8.5 " in
    *" ${PHP_VERSION_VAL} "*) ;;
    *)
        echo "ERROR: unsupported PHP_VERSION '${PHP_VERSION_VAL}'. Choose: 8.3, 8.4, 8.5"
        exit 1
        ;;
esac
echo "Starting Docker LAMP Stack..."
docker compose up -d
echo ""
echo "✅ Stack running! Access site at http://localhost"
