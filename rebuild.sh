#!/usr/bin/env bash
# Linux / macOS / WSL Docker Stack Rebuild Script
if [ ! -f .env ]; then
    echo "Creating .env configuration file from env.example..."
    cp env.example .env
fi
if [ ! -f docker-compose.yml ]; then
    echo "Creating docker-compose.yml configuration file from docker-compose.yml.example..."
    cp docker-compose.yml.example docker-compose.yml
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
echo "Rebuilding Docker LAMP Stack image..."
docker compose up -d --build --no-cache
echo ""
echo "✅ Rebuild complete! Access site at http://localhost"
