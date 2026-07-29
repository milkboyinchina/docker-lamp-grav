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
echo "Rebuilding Docker LAMP Stack image..."
docker compose up -d --build --no-cache
echo ""
echo "✅ Rebuild complete! Access site at http://localhost"
