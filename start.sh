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
echo "Starting Docker LAMP Stack..."
docker compose up -d
echo ""
echo "✅ Stack running! Access site at http://localhost"
