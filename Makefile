# ==============================================================================
# Cross-Platform Docker Compose Helper Makefile (Linux, macOS, Windows)
# Directory: /home/milkboy/Documents/grav-lamp-docker
# ==============================================================================

.PHONY: up down stop restart rebuild logs logs-all status shell exec clear-cache cc grav-install test clean-test backup merge-main help

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
	@echo ""
	@echo "✅ Stack running! Access site at http://localhost"

## ⏹️ Stop containers (keep container state)
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

## 📋 Stream live container logs for webserver
logs:
	docker compose logs -f webserver

## 📋 Stream live container logs for all services
logs-all:
	docker compose logs -f

## 📊 View status of running containers
status:
	docker compose ps

## 🐚 Interactive bash shell inside webserver container
shell:
	docker compose exec webserver bash

exec: shell

## 🧹 Clear Grav CMS cache inside webserver container
clear-cache:
	docker compose exec webserver bin/grav clear-cache

cc: clear-cache

## 📦 Install Grav CMS core dependencies & plugins inside container
grav-install:
	docker compose exec webserver bin/grav install

## 🧪 Deploy diagnostic test page to src/test.php
test:
	cp test-scripts/test.php.example src/test.php
	@echo "✅ Diagnostic test script deployed! Open http://localhost/test.php"

## 🧹 Clean up diagnostic test page from src/
clean-test:
	rm -f src/test.php src/diagnostics.php src/wp-diagnostics.php
	@echo "✅ Diagnostic test page removed from src/"

## 💾 Backup WWW site files and MariaDB database
backup: env
	./backup.sh

## 🔀 Merge current branch into main excluding src/user/pages
merge-main:
	./merge-to-main.sh

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
	@echo "  make logs-all    - Stream live logs from all services"
	@echo "  make status      - Display status of running containers"
	@echo "  make shell       - Open bash shell in webserver container"
	@echo "  make clear-cache - Clear Grav CMS cache (alias: make cc)"
	@echo "  make grav-install - Install Grav CMS dependencies & core plugins"
	@echo "  make test        - Deploy diagnostic page (http://localhost/test.php)"
	@echo "  make clean-test  - Remove diagnostic page from src/"
	@echo "  make backup      - Interactive backup helper (WWW files, DB, or both)"
	@echo "  make merge-main  - Merge branch into main excluding src/user/pages"
	@echo "======================================================================"
