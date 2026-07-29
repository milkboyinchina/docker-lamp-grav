# Dockerized LAMP Stack (PHP 8.3 + Apache + MariaDB)

A lightweight, high-performance, and developer-friendly Docker environment running Apache and PHP 8.3, pre-configured for **Grav CMS**, **WordPress**, or any custom PHP web application.

> [!NOTE]
> **📖 Full User Manual & Advanced Usage Guide**  
> For complete step-by-step instructions, deployment details (RSYNC & FTP), backup operations, database management, and branch workflows, please read the **[HOWTO User Manual](file:///home/milkboy/Documents/docker-stacks-dev/docker-lamp-grav/HOWTO.md)** (`HOWTO.md`).

---

## 🚀 Quick Start (3 Steps)

### 1. Start the Stack
Run the start command (automatically creates `.env` and `docker-compose.yml` if missing):
```bash
make up
# or on Linux/macOS: ./start.sh
# or on Windows: scripts\start.bat
```
*(To switch PHP versions, set `PHP_IMAGE=php:8.2-apache` or `php:7.4-apache` in `.env` and run `make rebuild`.)*

### 2. Access Your Application
Open your browser at:
- **Web Application**: [http://localhost](http://localhost)
- **Adminer Database Manager**: [http://localhost:8080](http://localhost:8080) (when `COMPOSE_PROFILES=db,adminer` in `.env`)
- **Nginx Proxy Manager Admin UI**: [http://localhost:81](http://localhost:81) (when `COMPOSE_PROFILES=...,proxy` in `.env`, initial login: `admin@example.com` / `changeme`)

### 3. Clear Grav Cache
```bash
make clear-cache
```

---

## ⚡ Essential Commands Reference

| Action | Makefile Shortcut | Linux / macOS Script | Windows Batch Script |
| :--- | :--- | :--- | :--- |
| **Start Containers** | `make up` | `./start.sh` | `scripts\start.bat` |
| **Stop Containers** | `make stop` | `./stop.sh` | `scripts\stop.bat` |
| **Rebuild Image** | `make rebuild` | `./rebuild.sh` | `scripts\rebuild.bat` |
| **Container Shell** | `make shell` | `./shell.sh` | `scripts\shell.bat` |
| **Clear Grav Cache** | `make clear-cache` | `docker compose exec webserver php bin/grav clearcache` | N/A |
| **Deploy (RSYNC)** | `make deploy` | `./deploy.sh` | `scripts\deploy.bat` |
| **Deploy (FTP)** | `make deploy-ftp` | `./deploy.sh --ftp` | N/A |
| **Run Backups** | `make backup` | `./backup.sh` | `scripts\backup.bat` |
| **Merge Feature Branch**| `make merge-main` | `./merge-to-main.sh` | `scripts\merge-to-main.bat` |

### Entering & Running Container Commands (`docker compose exec`)
- **Interactive Container Shell**: Run `make shell` (or `./shell.sh` / `docker compose exec webserver bash`) to open an interactive Bash prompt inside `/var/www/html`.
- **Run Non-Interactive Commands**: Run `docker compose exec webserver <command>` (e.g. `docker compose exec webserver php bin/grav clearcache`).

---

## 📦 Automated Deployments (RSYNC & FTP)

Deploy your application plugins, themes, and configuration from development to production with per-run log file generation:

```bash
# Standard RSYNC Deployment (Configured via .env)
make deploy

# FTP Transport Deployment
make deploy-ftp

# Preview changes (Dry Run)
./deploy.sh --dry-run
```

*Every execution creates a timestamped log in `logs/deployments/deploy_YYYYMMDD_HHMMSS.log`.*

---

## 📂 Project Directory Structure

```text
grav-lamp/
├── HOWTO.md                 # Full User Manual & Comprehensive Usage Guide
├── GRAV-QUICKSTART.md       # First-time Grav setup & admin user reset guide
├── WORDPRESS-QUICKSTART.md  # First-time WordPress setup & database config guide
├── docker-compose.yml       # Local Docker Compose configuration (git-ignored)
├── docker-compose.yml.example # Default template for Docker Compose services definition
├── .env                     # Local environment variables (created from env.example)
├── env.example              # Template for environment configuration
├── Makefile                 # Cross-platform 1-word command shortcuts
├── deploy.sh                # Automated deployment script (RSYNC & FTP)
├── backup.sh                # Automated WWW & MariaDB backup script
├── merge-to-main.sh         # Helper script to merge branch into main (excluding pages)
├── start.sh / stop.sh       # Container control shell scripts
├── rebuild.sh / shell.sh    # Image rebuild & container shell scripts
├── docker/                  # Dockerfile & entrypoint scripts
├── scripts/                 # Windows CMD/PowerShell batch scripts
├── config/                  # Apache, PHP, and MariaDB config overrides & template examples (.example)
├── logs/                    # Host-mounted log directories (apache, php, deployments)
└── src/                     # Web application web root (var/www/html)
```

---

## 📚 Documentation & Guides

- **[HOWTO User Manual](file:///home/milkboy/Documents/docker-stacks-dev/docker-lamp-grav/HOWTO.md)**: Full guide covering all features, parameters, deployments, and troubleshooting.
- **[Grav Quickstart Guide](file:///home/milkboy/Documents/docker-stacks-dev/docker-lamp-grav/GRAV-QUICKSTART.md)**: Grav CMS initial setup and admin user management.
- **[WordPress Quickstart Guide](file:///home/milkboy/Documents/docker-stacks-dev/docker-lamp-grav/WORDPRESS-QUICKSTART.md)**: WordPress 5-minute setup, MariaDB configuration, and WP-CLI usage.
