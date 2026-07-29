# Comprehensive User Manual & Usage Guide

Welcome to the **Dockerized LAMP Stack (PHP 8.3 + Apache + MariaDB)** user manual. This guide covers installation, local development, database management, automated backups, deployments, and branch workflows.

---

## Table of Contents

1. [System Overview & Prerequisites](#1-system-overview--prerequisites)
2. [Environment Setup](#2-environment-setup)
3. [Local Development Commands](#3-local-development-commands)
4. [Grav CMS Operations](#4-grav-cms-operations)
5. [Automated Deployments (RSYNC & FTP)](#5-automated-deployments-rsync--ftp)
6. [Automated Backups](#6-automated-backups)
7. [Git Branch Merging & Page Exclusion](#7-git-branch-merging--page-exclusion)
8. [Database & Reverse Proxy Configuration](#8-database--reverse-proxy-configuration)
9. [Troubleshooting & Diagnostics](#9-troubleshooting--diagnostics)

---

## 1. System Overview & Prerequisites

### Overview
This stack provides a containerized PHP 8.3 environment on Apache 2.4, optimized for **Grav CMS**, **WordPress**, and custom PHP web applications.

### Requirements
- **Docker Engine**: 20.10+
- **Docker Compose**: v2+
- **Make** (Optional): For 1-word Makefile command shortcuts
- **rsync** & **python3**: Pre-installed on Linux/macOS for deployment automation

---

## 2. Environment Setup

Before starting the containers, set up your local configuration files:

1. **Copy the Environment Configuration Template**:
   ```bash
   cp env.example .env
   ```
2. **Copy the Docker Compose Configuration Template**:
   ```bash
   cp docker-compose.yml.example docker-compose.yml
   ```

*Note: Running `make up`, `./start.sh`, or `./rebuild.sh` automatically creates `.env` and `docker-compose.yml` if missing.*

### Key `.env` Variables:
```ini
# Base Image Selection
PHP_IMAGE=php:8.3-apache

# Profiles (db,adminer)
COMPOSE_PROFILES=db,adminer

# Ports
HTTP_PORT=80
ADMINER_PORT=8080

# Deployment Configuration
DEPLOY_MODE=rsync
DEPLOY_SRC_DIR=./src/user
DEPLOY_DEST_DIR=/mnt/1.milkboy/docker/docker-lamp-grav/src/user
DEPLOY_LOG_DIR=./logs/deployments

# FTP Settings
FTP_HOST=ftp.example.com
FTP_PORT=21
FTP_USER=ftp_username
FTP_PASS=ftp_password
FTP_REMOTE_DIR=/public_html/user
FTP_SSL=false
```

---

## 3. Local Development Commands

Use Makefile targets or shell/batch scripts depending on your operating system:

| Task | Makefile Command | Linux / macOS / WSL | Windows CMD |
| :--- | :--- | :--- | :--- |
| **Start Stack** | `make up` | `./start.sh` | `scripts\start.bat` |
| **Stop Stack** | `make stop` | `./stop.sh` | `scripts\stop.bat` |
| **Down (Remove)** | `make down` | `docker compose down` | `docker compose down` |
| **Rebuild Stack** | `make rebuild` | `./rebuild.sh` | `scripts\rebuild.bat` |
| **Container Shell**| `make shell` | `./shell.sh` | `scripts\shell.bat` |
| **View Logs** | `make logs` | `docker compose logs -f` | `docker compose logs -f` |
| **Stack Status** | `make status` | `docker compose ps` | `docker compose ps` |

### Entering & Running Commands inside Containers (`docker compose exec`)

#### 1. Interactive Container Shell Access
To open an interactive Bash terminal session inside the running webserver container:
```bash
# Makefile shortcut
make shell     # or: make exec

# Linux / macOS script shortcut
./shell.sh

# Windows batch script shortcut
scripts\shell.bat

# Direct Docker Compose command (using service name)
docker compose exec webserver bash

# Direct Docker command (using container name)
docker exec -it grav-lamp-web bash
```
Once inside the container, your working directory is set to `/var/www/html` where you can inspect logs, check file permissions, or execute CLI commands. Type `exit` to exit the container shell.

#### 2. Running One-Off Commands (`docker compose exec`)
To run a command inside the container from your host terminal without opening an interactive shell session:

```bash
# General Syntax: docker compose exec <service_name> <command>

# Clear Grav CMS application cache
docker compose exec webserver php bin/grav clearcache

# Install Grav CMS dependencies and core plugins
docker compose exec webserver php bin/grav install

# Check PHP runtime version and active extensions
docker compose exec webserver php -v
docker compose exec webserver php -m

# Check web root file permissions and directory contents
docker compose exec webserver ls -la /var/www/html/user/

# Execute Composer commands inside container
docker compose exec webserver composer status
```

---

## 4. Grav CMS Operations

### Clear Application Cache
Invalidate Twig templates, compiled PHP, and asset cache inside the container:
```bash
make clear-cache  # alias: make cc
# Or via CLI directly:
docker compose exec webserver php bin/grav clearcache
```

### Install Dependencies & Plugins
Install core Grav dependencies and missing plugins:
```bash
make grav-install
```

### Diagnostic Test Page
Deploy a PHP diagnostic test script to `http://localhost/test.php`:
```bash
make test        # Deploys test page
make clean-test  # Removes test page
```

---

## 5. Automated Deployments (RSYNC & FTP)

The deployment tool (`deploy.sh`, `make deploy`, `make deploy-ftp`) synchronizes `src/user/` (plugins, themes, configuration) to a target live environment while preserving production pages and runtime data.

### Per-Run Log File Generation
Every deployment automatically creates a detailed execution log in `logs/deployments/deploy_YYYYMMDD_HHMMSS.log`.

### Command Examples:
```bash
# 1. Standard RSYNC Deployment (Reads .env variables)
make deploy
# or:
./deploy.sh

# 2. FTP / FTPS Transport Deployment
make deploy-ftp
# or:
./deploy.sh --ftp

# 3. Dry-Run Mode (Preview changes without modifying files)
./deploy.sh --dry-run

# 4. Include src/user/pages/ in deployment
./deploy.sh --include-pages

# 5. Deploy to a custom destination path
./deploy.sh /path/to/target/src/user
```

---

## 6. Automated Backups

Run the interactive backup tool to create compressed archives of site files, database dumps, or both:

```bash
# Launch backup script
make backup
# or:
./backup.sh
```

### Generated Output:
- Archives are saved to `./backups/` (e.g. `grav_lamp_www_20260729_233000.tar.gz`).
- Execution logs and warnings are appended to `./logs/backup.log`.

---

## 7. Git Branch Merging & Page Exclusion

When working on feature branches, merge changes into `main` while excluding `src/user/pages/`:

```bash
# Merge current branch into main (excluding src/user/pages)
make merge-main
# or:
./merge-to-main.sh [feature-branch-name]
```

---

## 8. Database & Reverse Proxy Configuration

### Enabling MariaDB & Adminer
Set `COMPOSE_PROFILES=db,adminer` in `.env` and restart the stack (`make up`).
- **MariaDB Host**: `db`
- **Adminer URL**: [http://localhost:8080](http://localhost:8080)

> **⚠️ Security Note**: Disable Adminer in production by setting `COMPOSE_PROFILES=` in `.env`.

### Traefik Reverse Proxy Integration
Uncomment Traefik labels in `docker-compose.yml` to route domains through an external Traefik network with automatic Let's Encrypt TLS certificates.

---

## 9. Troubleshooting & Diagnostics

- **Permission Issues**: The webserver container runs `docker-entrypoint.sh` to automatically grant write permissions to `user/config`, `user/data`, and `cache/`.
- **View Container Logs**: Run `make logs` or `docker compose logs -f webserver`.
- **HTTP Health Check**: Run `curl -I http://localhost/` to verify Apache and PHP response.
