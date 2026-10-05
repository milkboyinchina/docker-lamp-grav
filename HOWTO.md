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
3. **Copy Configuration Override Templates**:
   ```bash
   cp config/apache/000-default.conf.example config/apache/000-default.conf
   cp config/php/custom.ini.example config/php/custom.ini
   cp config/mysql/custom.cnf.example config/mysql/custom.cnf
   ```

*Note: Running `make up`, `./start.sh`, or `./rebuild.sh` automatically copies missing `.env`, `docker-compose.yml`, and `config/` override files from their `.example` templates.*

### Quick Guide: Customizing Configuration Files (`config/`)

All service configurations mounted into container runtimes are stored under the `config/` directory. Edit these files using any text editor (VS Code, Nano, Vim) to customize service behavior:

#### 1. Customizing PHP Settings (`config/php/custom.ini`)
Edit `config/php/custom.ini` to adjust PHP memory limits, file upload limits, or OPcache settings:
```ini
; Increase memory limit and file upload limits
memory_limit = 512M
upload_max_filesize = 64M
post_max_size = 64M
max_execution_time = 600
```
*Apply changes:* Run `make restart` (or `make up`).

#### 2. Customizing Apache VirtualHost (`config/apache/000-default.conf`)
Edit `config/apache/000-default.conf` to add custom Apache rewrite rules, headers, or domain aliases:
```apache
<VirtualHost *:80>
    ServerName example.com
    ServerAlias www.example.com
    DocumentRoot /var/www/html
    ...
</VirtualHost>
```
*Apply changes:* Run `docker compose exec webserver apache2ctl graceful` (or `make restart`).

#### 3. Customizing MariaDB Database Server (`config/mysql/custom.cnf`)
Edit `config/mysql/custom.cnf` to adjust database buffer pool sizes or maximum connections:
```ini
[mysqld]
max_connections = 200
innodb_buffer_pool_size = 512M
```
*Apply changes:* Run `make restart`.

---

### Key `.env` Variables & PHP Version Options:
```ini
# Base Image & PHP Version Selection
# Options: php:8.3-apache (default), php:8.2-apache, php:8.1-apache, php:8.0-apache, php:7.4-apache
PHP_IMAGE=php:8.3-apache

# Profiles (db,adminer,proxy)
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

### Changing PHP Version (`PHP_IMAGE`)

To switch your webserver container to a different PHP runtime version (e.g. PHP 8.3, 8.2, 8.1, 8.0, or legacy 7.4):

1. Open `.env` and set `PHP_IMAGE` to your desired PHP version tag:
   ```ini
   PHP_IMAGE=php:8.2-apache
   ```
2. Rebuild the container image to compile PHP extensions for the selected version:
   ```bash
   make rebuild
   # or on Linux/macOS: ./rebuild.sh
   # or on Windows: scripts\rebuild.bat
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

### Grav Scheduler & System Cron (`crontab`)
Grav CMS includes an internal job scheduler for automated cache purges, backups, and scheduled tasks. The `cron` daemon runs inside the `webserver` container with a crontab entry configured for the `www-data` user.

#### 1. How to Add `bin/grav scheduler` to Crontab
In this Docker stack, the container automatically adds the scheduler entry for `www-data` on boot. If you are configuring it manually or setting up a new server environment, use any of these methods:

- **Method A: Automated Grav CLI Setup (Recommended)**
  Run the Grav CLI install command inside the web container:
  ```bash
  docker compose exec webserver php bin/grav scheduler -i
  ```

- **Method B: One-Line Non-Interactive Command**
  Append the job directly to the `www-data` user crontab:
  ```bash
  docker compose exec webserver bash -c "(crontab -u www-data -l 2>/dev/null | grep -v 'bin/grav scheduler'; echo '* * * * * cd /var/www/html && /usr/local/bin/php bin/grav scheduler 1>> /dev/null 2>&1') | crontab -u www-data -"
  ```

- **Method C: Manual Interactive Crontab Editing (`crontab -e`)**
  Open the crontab editor for the `www-data` user:
  ```bash
  docker compose exec webserver crontab -u www-data -e
  ```
  Add the following line to the end of the file and save:
  ```crontab
  * * * * * cd /var/www/html && /usr/local/bin/php bin/grav scheduler 1>> /dev/null 2>&1
  ```

#### 2. Checking Scheduler & Cron Status
- **Grav Admin GUI**: Open `http://localhost/admin/tools#scheduler` (displays **Enabled for user: www-data**).
- **Inspect Container Crontab**:
  ```bash
  docker compose exec webserver crontab -u www-data -l
  ```
- **Check Cron Daemon Status**:
  ```bash
  docker compose exec webserver service cron status
  ```

#### 3. Executing Scheduled Jobs Manually
To trigger all pending scheduled jobs immediately via CLI:
```bash
docker compose exec webserver php bin/grav scheduler -r
```

### 🤖 Grav AI Chatbot Plugin Integration & Configuration
The pre-installed `ai-chatbot` plugin (`src/user/plugins/ai-chatbot`) provides an intelligent site assistant with multi-provider AI support, local FAQ pre-matching, and live analytics.

#### Key Features & Settings (`/admin/plugins/ai-chatbot`):
1. **AI Provider Engines**:
   - **Ollama**: Connects to local or remote Ollama instances (e.g. `http://host.docker.internal:11434/v1` or `http://100.100.75.77:11434/v1`). Hostnames like `localhost` or `127.0.0.1` inside Docker containers are automatically mapped to `host.docker.internal`.
   - **Groq, Google Gemini, OpenRouter, OpenAI, and Custom API Endpoints**.
2. **Customizable Chatbot Header Title (`bot_title`)**:
   - Change the widget top header box title directly from Grav Admin (default: `"Website Assistant"`).
3. **Model Context Window Limit (`context_window_tokens`)**:
   - Configures model context capacity (e.g. `1024`, `8192`, `16384`, `128000`). Automatically calculates available context prompt length and truncates site summaries so model context limits are strictly honored.
   - Automatically passes `num_ctx` and `num_predict` options to Ollama API requests.
4. **Input/Output Token Limits**:
   - **Max Input Tokens (`max_input_tokens`)**: Default `500` tokens (~2,000 characters). Preserves typed user input for easy shortening if exceeded.
   - **Max Output Tokens (`max_tokens`)**: Default `800` tokens.
5. **Optional AI Server Response Logging (`log_ai_responses`)**:
   - Disabled by default. When enabled, records full response payloads, tokens, questions, answers, and errors to `user/data/ai-chatbot/ai_responses.log`.

---

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

## 5. Automated Deployments & Article Uploading (RSYNC & FTP)

### 🚀 Targeted Deployments (`deploy.sh` & `Makefile`)
Synchronize code, plugins, themes, pages, or the entire application codebase to a target live environment with precise target scope control:

#### 1. Deploy `src/user/` Directory (Plugins, Themes, Config)
Deploys plugins, themes, and configuration files while preserving production pages by default:
```bash
make deploy            # or: make deploy-user
./deploy.sh --target user
```

#### 2. Deploy ONLY `src/user/pages/` Directory
Deploys ONLY markdown pages and article content without modifying plugins or system settings:
```bash
make deploy-pages
./deploy.sh --pages-only
```

#### 3. Deploy `src/user/` INCLUDING Pages
Deploys user plugins, themes, configuration, **AND** all markdown pages together:
```bash
make deploy-user-all
./deploy.sh --target user --include-pages
```

#### 4. Deploy the WHOLE `src/` Folder (Full Site Codebase)
Deploys the entire application document root including Grav core, vendor, system, plugins, themes, and configuration:
```bash
make deploy-src        # or: make deploy-all
./deploy.sh --target src
```

#### 5. FTP Transport Deployment
Deploys user files using FTP credentials defined in `.env`:
```bash
make deploy-ftp        # or: ./deploy.sh --ftp
```

#### 6. Dry-Run Mode (Preview Changes)
Preview file transfers without modifying any live files:
```bash
./deploy.sh --dry-run
./deploy.sh --target src --dry-run
```

#### 7. Automatic Cache Exclusion & Dual Invalidation Policy
- **Cache Exclusion**: All deployment commands strictly exclude `cache/`, `user/cache/`, and `.cache/` directories from transfer.
- **Dual Cache Invalidation**: Upon completion of any deployment run, cache is automatically cleared on **BOTH**:
  1. **Source Development Environment**: Runs `php bin/grav clearcache` inside `grav-lamp-web` container and purges `./src/cache/*`.
  2. **Target Production Environment**: Purges target cache directory (`/mnt/1.milkboy/.../src/cache/*`) and touches `system.yaml` to force Grav to rebuild page and system caches instantly.

---

### 📝 Article & Page Uploading (`upload-article.sh`)
Upload specific articles, blog posts, or page folders from local `src/user/pages/` to production without running a full stack deployment.

```bash
# 1. Interactive selection mode (lists available local page folders)
make upload-article  # or: ./upload-article.sh

# 2. Upload a specific article or subfolder directly
./upload-article.sh 05.faq
./upload-article.sh blog/my-new-post

# 3. Upload ALL articles and pages to production
make upload-pages    # or: ./upload-article.sh --all

# 4. Dry-run mode for article upload
./upload-article.sh --dry-run 05.faq
```

### Per-Run Log File Generation
Every deployment and article upload automatically creates a detailed execution log in `logs/deployments/` (e.g. `deploy_user_YYYYMMDD_HHMMSS.log`, `deploy_pages_YYYYMMDD_HHMMSS.log`, or `deploy_src_YYYYMMDD_HHMMSS.log`).

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

---

### Nginx Proxy Manager (GUI Reverse Proxy & SSL Manager)

Nginx Proxy Manager provides a web UI to easily manage reverse proxies, SSL/TLS certificates (Let's Encrypt), and domain forwarding.

#### 1. Enabling the Proxy Profile
Enable `proxy` in `COMPOSE_PROFILES` inside `.env`:
```ini
# Enable Nginx Proxy Manager along with MariaDB and Adminer:
COMPOSE_PROFILES=db,adminer,proxy

# Or enable Nginx Proxy Manager only:
COMPOSE_PROFILES=proxy
```

#### 2. Environment Variables (`.env`)
Configure ports and data storage paths in `.env`:
```ini
# Nginx Proxy Manager Ports
NPM_HTTP_PORT=8000
NPM_ADMIN_PORT=81
NPM_HTTPS_PORT=8443

# Persistent Volume Storage Paths
NPM_DATA_PATH=./data/npm
NPM_LETSENCRYPT_PATH=./etc/letsencrypt
```

#### 3. Access & Initial Setup
1. Start the stack: `make up`
2. Open the Admin UI at **[http://localhost:81](http://localhost:81)**
3. Default credentials:
   - **Email**: `admin@example.com`
   - **Password**: `changeme`
4. Promptly change the default admin email and password upon first login.
5. Create Proxy Hosts pointing your domain (e.g. `example.com`) to container `webserver:80`.

---

### Network Configuration (Internal Bridge vs External Network)

By default, the Docker stack uses an isolated internal bridge network (`grav-network`) for container-to-container communication.

#### Switching to an External Network (`external-net`)
If your containers need to connect to an external Docker network (e.g., Traefik, NetBird, or a shared proxy network):

1. Edit the `networks:` block at the bottom of `docker-compose.yml`:
   ```yaml
   networks:
     grav-network:
       driver: bridge

     external-net:
       external: true
       name: nb_netbird  # Replace with your external Docker network name if different
   ```
2. Under your service (e.g. `webserver` or `adminer`), switch the network mapping:
   ```yaml
       networks:
         # - grav-network
         - external-net
   ```

---

### Traefik Reverse Proxy & SSL/TLS Configuration Guide

When deploying behind Traefik or Nginx Proxy Manager (with automatic Let's Encrypt TLS certificates or an external proxy network), configure your `docker-compose.yml` as follows:

#### Step 1: Comment out Direct Host Port Mapping
By default, Docker Compose maps host ports (`ports: - "${HTTP_PORT:-80}:80"`). When using Traefik or Nginx Proxy Manager as your primary front-end proxy, comment out the `ports:` block under `webserver` (and `adminer`):

```yaml
    # Direct host ports (uncomment for standalone access; comment out if using Traefik or Nginx Proxy Manager)
    #ports:
    #  - "${HTTP_PORT:-80}:80"
```

#### Step 2: Connect Container to External Network
Attach `webserver` to your external proxy network (`external-net`):

```yaml
services:
  webserver:
    ...
    networks:
      - external-net

networks:
  external-net:
    external: true
    name: nb_netbird  # Replace with your external network name
```

#### Step 3: Configure Traefik Labels (Apex & WWW Redirect Example)
Add Traefik labels under `webserver` to configure SSL/TLS certificates and automatic `www` to non-`www` HTTPS redirection using `example.com`:

```yaml
    labels:
      - "traefik.enable=true"
      - "traefik.docker.network=traefik_network"

      # 1. Main Router for Apex Domain (example.com -> HTTPS)
      - "traefik.http.routers.webserver.rule=Host(`${SERVER_NAME:-example.com}`)"
      - "traefik.http.routers.webserver.entrypoints=websecure"
      - "traefik.http.routers.webserver.tls=true"
      - "traefik.http.routers.webserver.tls.certresolver=letsencrypt"
      - "traefik.http.routers.webserver.priority=10"
      - "traefik.http.services.webserver.loadbalancer.server.port=80"

      # 2. Redirect Router for WWW Domain (www.example.com -> HTTPS)
      - "traefik.http.routers.webserver-www.rule=Host(`www.${SERVER_NAME:-example.com}`)"
      - "traefik.http.routers.webserver-www.entrypoints=websecure"
      - "traefik.http.routers.webserver-www.tls=true"
      - "traefik.http.routers.webserver-www.tls.certresolver=letsencrypt"
      - "traefik.http.routers.webserver-www.priority=10"
      - "traefik.http.routers.webserver-www.middlewares=redirect-to-non-www"

      # 3. Middleware for Redirecting www.example.com -> example.com (301 Permanent)
      - "traefik.http.middlewares.redirect-to-non-www.redirectregex.permanent=true"
      - "traefik.http.middlewares.redirect-to-non-www.redirectregex.regex=^https://www\\.(.*)"
      - "traefik.http.middlewares.redirect-to-non-www.redirectregex.replacement=https://$${1}"
```

#### Step 4: Apply Changes
Apply changes and start containers:
```bash
make up
```

---

## 9. Troubleshooting & Diagnostics

- **Permission Issues**: The webserver container runs `docker-entrypoint.sh` to automatically grant write permissions to `user/config`, `user/data`, and `cache/`.
- **View Container Logs**: Run `make logs` or `docker compose logs -f webserver`.
- **HTTP Health Check**: Run `curl -I http://localhost/` to verify Apache and PHP response.
