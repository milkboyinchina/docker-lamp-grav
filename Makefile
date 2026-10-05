# ==============================================================================
# Cross-Platform Docker Compose Helper Makefile (Linux, macOS, Windows)
# NOTE: All paths are relative to this directory or come from .env.
# No host folder names are hardcoded, so renaming this directory is safe.
# ==============================================================================

.PHONY: up down stop restart rebuild logs logs-tunnel logs-all status shell exec clear-cache cc grav-install test clean-test backup merge-main check-php help

# Default target
.DEFAULT_GOAL := help

# Web root served by the container. SRC_PATH in .env may point outside this
# repository (e.g. an external app checkout); fall back to the ./src stub.
SRC_DIR := $(shell grep -E '^SRC_PATH=[^#]' .env 2>/dev/null | tail -n 1 | cut -d= -f2-)
ifeq ($(strip $(SRC_DIR)),)
SRC_DIR := ./src
endif

# PHP runtime selector (number only - image is derived in compose).
PHPV := $(shell grep -E '^PHP_VERSION=[^#]' .env 2>/dev/null | tail -n 1 | cut -d= -f2-)
ifeq ($(strip $(PHPV)),)
PHPV := 8.4
endif

# Auto-copy .env, docker-compose.yml, and config templates if missing
env:
	@if [ ! -f .env ]; then \
		echo "Creating .env configuration file from env.example..."; \
		cp env.example .env; \
	fi
	@if [ ! -f docker-compose.yml ]; then \
		echo "Creating docker-compose.yml configuration file from docker-compose.yml.example..."; \
		cp docker-compose.yml.example docker-compose.yml; \
	fi
	@if [ ! -f docker-compose.direct.yml ]; then \
		echo "Creating docker-compose.direct.yml configuration file from docker-compose.direct.yml.example..."; \
		cp docker-compose.direct.yml.example docker-compose.direct.yml; \
	fi
	@if [ ! -f config/apache/000-default.conf ] && [ -f config/apache/000-default.conf.example ]; then \
		echo "Creating config/apache/000-default.conf from example..."; \
		cp config/apache/000-default.conf.example config/apache/000-default.conf; \
	fi
	@if [ ! -f config/php/custom.ini ] && [ -f config/php/custom.ini.example ]; then \
		echo "Creating config/php/custom.ini from example..."; \
		cp config/php/custom.ini.example config/php/custom.ini; \
	fi
	@if [ ! -f config/mysql/custom.cnf ] && [ -f config/mysql/custom.cnf.example ]; then \
		echo "Creating config/mysql/custom.cnf from example..."; \
		cp config/mysql/custom.cnf.example config/mysql/custom.cnf; \
	fi

## 🚀 Start containers in background (Detached)
up: env check-php
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
rebuild: env check-php
	docker compose build --no-cache
	docker compose up -d

## 📋 Stream live container logs for webserver
logs:
	docker compose logs -f webserver

## 📋 Stream live container logs for Cloudflare Tunnel
logs-tunnel:
	docker compose logs -f tunnel

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

## 🧹 Clear Grav CMS cache inside the webserver container
## (Target-environment cache is handled by the app repo deploy flow.)
clear-cache:
	docker compose exec webserver php bin/grav clearcache

cc: clear-cache

## 📦 Install Grav CMS core dependencies & plugins inside container
grav-install:
	docker compose exec webserver php bin/grav install

## 🧪 Deploy diagnostic test page to the served web root ($SRC_PATH or ./src)
test:
	cp test-scripts/test.php.example "$(SRC_DIR)/test.php"
	@echo "✅ Diagnostic test script deployed! Open http://localhost/test.php"

## 🧹 Clean up diagnostic test page from the served web root
clean-test:
	rm -f "$(SRC_DIR)/test.php" "$(SRC_DIR)/diagnostics.php" "$(SRC_DIR)/wp-diagnostics.php"
	@echo "✅ Diagnostic test page removed from $(SRC_DIR)/"

## 💾 Backup WWW site files and MariaDB database
backup: env
	./backup.sh

## 🔍 Validate PHP_VERSION selector against supported versions
check-php:
	@case " 8.3 8.4 8.5 " in \
		*" $(PHPV) "*) ;; \
		*) echo "ERROR: unsupported PHP_VERSION '$(PHPV)'. Choose: 8.3, 8.4, 8.5"; exit 1;; \
	esac

## 🔀 Merge current branch into main excluding src/user/pages
merge-main:
	./merge-to-main.sh

## ❓ Show available commands
help:
	@echo "======================================================================"
	@echo "   Docker LAMP Stack - Cross-Platform Command Helper"
	@echo "======================================================================"
	@echo "  make up               - Start stack in background (auto-creates .env)"
	@echo "  make stop             - Stop running containers"
	@echo "  make down             - Stop & remove containers and networks"
	@echo "  make restart          - Restart all stack containers"
	@echo "  make rebuild          - Rebuild PHP image without cache & restart"
	@echo "  make logs             - Stream live webserver logs"
	@echo "  make logs-tunnel      - Stream live Cloudflare Tunnel logs"
	@echo "  make logs-all         - Stream live logs from all services"
	@echo "  make status           - Display status of running containers"
	@echo "  make shell            - Open bash shell in webserver container"
	@echo "  make clear-cache      - Clear app cache in container (alias: make cc)"
	@echo "  make grav-install     - Install Grav CMS dependencies & core plugins"
	@echo "  make test             - Deploy diagnostic page (http://localhost/test.php)"
	@echo "  make clean-test       - Remove diagnostic page from src/"
	@echo "  make backup           - Interactive backup helper (WWW files, DB, or both)"
	@echo "  make merge-main       - Merge branch into main excluding src/user/pages"
	@echo "======================================================================"
