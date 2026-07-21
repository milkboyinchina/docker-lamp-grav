#!/usr/bin/env bash
# Linux / macOS / WSL Docker Stack Stop Script
echo "Stopping Docker LAMP Stack containers..."
docker compose stop
echo "✅ Containers stopped."
