# ==============================================================================
# Cross-Platform Docker Compose Helper Makefile (Linux, macOS, Windows)
# NOTE: All paths are relative to this directory or come from .env.
# No host folder names are hardcoded, so renaming this directory is safe.
# ==============================================================================

.PHONY: up down stop restart rebuild logs logs-all status shell exec clear-cache cc grav-install deploy deploy-user deploy-pages deploy-user-all deploy-src deploy-all deploy-ftp test clean-test backup merge-main help

# Default target
.DEFAULT_GOAL := help

# Web root served by the container. SRC_PATH in .env may point outside this
# repository (e.g. an external app checkout); fall back to the ./src stub.
SRC_DIR := $(shell grep -E '^SRC_PATH=[^#]' .env 2>/dev/null | tail -n 1 | cut -d= -f2-)
ifeq ($(strip $(SRC_DIR)),)
SRC_DIR := ./src
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
	docker compose build --no-cache
	docker compose up -d

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

## 🧹 Clear Grav CMS cache on BOTH source container and target environment
## Target cache dir is derived from DEPLOY_DEST_DIR in .env (never hardcoded,
## so renaming this directory cannot recreate a stale folder).
clear-cache:
	docker compose exec webserver php bin/grav clearcache
	@if [ -f .env ]; then set -a; . ./.env; set +a; fi; \
	DEST="$${DEPLOY_DEST_DIR:-}"; DEST="$${DEST%/}"; \
	case "$$DEST" in \
		*/user) BASE="$${DEST%/user}";; \
		*/user/*) BASE="";; \
		*) BASE="";; \
	esac; \
	if [ -n "$$BASE" ] && [ -d "$$BASE/src/cache" ]; then \
		echo "Clearing target cache directory ($$BASE/src/cache)..."; \
		rm -rf "$$BASE/src/cache"/* 2>/dev/null || true; \
		echo "✅ Target cache cleared!"; \
	elif [ -n "$$DEST" ]; then \
		echo "Target cache dir not found under $$DEST - skipping (no folders created)."; \
	else \
		echo "DEPLOY_DEST_DIR not set - skipping target cache clear (no folders created)."; \
	fi

cc: clear-cache

## 📦 Install Grav CMS core dependencies & plugins inside container
grav-install:
	docker compose exec webserver php bin/grav install

## 🚀 Deploy src/user directory (plugins, themes, config) (default: pages excluded)
deploy: env
	./deploy.sh --target user

deploy-user: deploy

## 📄 Deploy ONLY src/user/pages directory
deploy-pages: env
	./deploy.sh --pages-only

## 📦 Deploy src/user directory INCLUDING pages
deploy-user-all: env
	./deploy.sh --target user --include-pages

## 🌐 Deploy the WHOLE src/ folder (Grav core, system, vendor, user, config)
deploy-src: env
	./deploy.sh --target src

## 🌐 Alias for deploy-src (deploy whole src/ folder)
deploy-all: deploy-src

## 📡 Deploy user plugins, themes, and configuration to target environment via FTP
deploy-ftp: env
	./deploy.sh --ftp

## 📝 Upload single article or select interactively from local to target environment
upload-article: env
	./upload-article.sh

## 📑 Upload ALL articles and pages from local to target environment
upload-pages: env
	./upload-article.sh --all

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
	@echo "  make logs-all         - Stream live logs from all services"
	@echo "  make status           - Display status of running containers"
	@echo "  make shell            - Open bash shell in webserver container"
	@echo "  make clear-cache      - Clear Grav CMS cache on source & target (alias: make cc)"
	@echo "  make grav-install     - Install Grav CMS dependencies & core plugins"
	@echo "  make deploy           - Deploy src/user directory (plugins, themes, config)"
	@echo "  make deploy-pages     - Deploy ONLY src/user/pages directory"
	@echo "  make deploy-user-all  - Deploy src/user directory INCLUDING pages"
	@echo "  make deploy-src       - Deploy WHOLE src/ folder (Grav core + plugins/themes)"
	@echo "  make deploy-all       - Alias for deploy-src (deploy whole src/ folder)"
	@echo "  make deploy-ftp       - Deploy user plugins, themes & config via FTP"
	@echo "  make upload-article   - Upload specific article/page interactively"
	@echo "  make upload-pages     - Upload ALL articles and pages to target environment"
	@echo "  make test             - Deploy diagnostic page (http://localhost/test.php)"
	@echo "  make clean-test       - Remove diagnostic page from src/"
	@echo "  make backup           - Interactive backup helper (WWW files, DB, or both)"
	@echo "  make merge-main       - Merge branch into main excluding src/user/pages"
	@echo "======================================================================"
