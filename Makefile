# ==============================================================================
# Cross-Platform Docker Compose Helper Makefile (Linux, macOS, Windows)
# ==============================================================================

.PHONY: up down stop restart rebuild logs status test clean-test help

# Default target
.DEFAULT_GOAL := help

# Auto-copy .env if missing
env:
	@if [ ! -f .env ]; then \
		echo "Creating .env configuration file from env.example..."; \
		cp env.example .env; \
	fi

## 🚀 Start containers in background (Detached)
up: env
	docker compose up -d
	@echo "\n✅ Stack running! Access site at http://localhost"

## ⏹️ Stop containers (keep state)
stop:
	docker compose stop

## 🛑 Stop and remove containers & networks
down:
	docker compose down

## 🔄 Restart all running containers
restart:
	docker compose restart

## 🛠️ Rebuild image without cache & restart containers
rebuild: env
	docker compose up -d --build --no-cache

## 📋 Stream live container logs
logs:
	docker compose logs -f webserver

## 📊 View status of running containers
status:
	docker compose ps

## 🧪 Deploy diagnostic test page to src/test.php
test:
	cp test-scripts/test.php.example src/test.php
	@echo "✅ Diagnostic test script deployed! Open http://localhost/test.php"

## 🧹 Clean up diagnostic test page from src/
clean-test:
	rm -f src/test.php src/diagnostics.php src/wp-diagnostics.php
	@echo "✅ Diagnostic test page removed from src/"

## ❓ Show available commands
help:
	@echo "======================================================================"
	@echo "   Docker LAMP Stack - Cross-Platform Command Helper"
	@echo "======================================================================"
	@echo "  make up          - Start stack in background (auto-creates .env)"
	@echo "  make stop        - Stop running containers"
	@echo "  make down        - Stop & remove containers and networks"
	@echo "  make restart     - Restart all stack containers"
	@echo "  make rebuild     - Rebuild PHP image without cache & restart"
	@echo "  make logs        - Stream live webserver logs"
	@echo "  make status      - Display status of running containers"
	@echo "  make test        - Deploy diagnostic page (http://localhost/test.php)"
	@echo "  make clean-test  - Remove diagnostic page from src/"
	@echo "======================================================================"
