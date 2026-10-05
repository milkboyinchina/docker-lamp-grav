# Dockerized LAMP Stack (PHP 8.3 + Apache + MariaDB)

A lightweight, high-performance, and developer-friendly Docker environment running Apache and PHP 8.3, pre-configured for **Grav CMS**, **WordPress**, or any custom PHP web application.

> [!NOTE]
> **📖 Full User Manual & Advanced Usage Guide**  
> For complete step-by-step instructions, backup operations, database management, and branch workflows, please read the **[HOWTO User Manual](HOWTO.md)** (`HOWTO.md`).

---

## 🚀 Quick Start (3 Steps)

### 1. Start the Stack
Run the start command (automatically creates `.env` and `docker-compose.yml` if missing):
```bash
make up
# or on Linux/macOS: ./start.sh
# or on Windows: scripts\start.bat
```
*(To switch PHP versions, set `PHP_VERSION=8.4` in `.env` and run `make rebuild`.)*

### 2. Access Your Application
Open your browser at:
- **Web Application**: [http://localhost](http://localhost)
- **Adminer Database Manager**: [http://localhost:8080](http://localhost:8080) (when `COMPOSE_PROFILES=db,adminer` in `.env`)
- **Nginx Proxy Manager Admin UI**: [http://localhost:81](http://localhost:81) (when `COMPOSE_PROFILES=...,proxy` in `.env`, initial login: `admin@example.com` / `changeme`)

*(Note: Stack uses `grav-network` bridge by default. Comment out `ports:` if routing traffic through Traefik or Nginx Proxy Manager; see [HOWTO.md](HOWTO.md) for external network setup.)*

### 3. Clear Grav Cache
```bash
make clear-cache
```

---

## ⚡ Essential Commands Reference

| Action | Makefile Shortcut | Linux / macOS Script | Description |
| :--- | :--- | :--- | :--- |
| **Start Containers** | `make up` | `./start.sh` | Starts Docker stack in background |
| **Stop Containers** | `make stop` | `./stop.sh` | Stops running stack containers |
| **Rebuild Image** | `make rebuild` | `./rebuild.sh` | Rebuilds PHP image without cache & restarts |
| **Container Shell** | `make shell` | `./shell.sh` | Opens Bash shell inside `webserver` container |
| **Clear App Cache** | `make clear-cache` | `make cc` | Clears app cache inside the container |
| **Run Backups** | `make backup` | `./backup.sh` | Interactive WWW & MariaDB backup helper |
| **Merge Feature Branch**| `make merge-main` | `./merge-to-main.sh` | Merges branch into main excluding pages |

### Entering & Running Container Commands (`docker compose exec`)
- **Interactive Container Shell**: Run `make shell` (or `./shell.sh` / `docker compose exec webserver bash`) to open an interactive Bash prompt inside `/var/www/html`.
- **Run Non-Interactive Commands**: Run `docker compose exec webserver <command>` (e.g. `docker compose exec webserver php bin/grav clearcache`).

---

## 📦 Application Deployments

This stack runs web servers; it does not deploy applications. Deployments
(including target cache invalidation) live in the application repository —
e.g. `personal-cv-site/bin/deploy.sh`.

---

## 📂 Project Directory Structure

```text
grav-lamp/
├── HOWTO.md                 # Full User Manual & Comprehensive Usage Guide
├── GRAV-QUICKSTART.md       # First-time Grav setup & admin user reset guide
├── WORDPRESS-QUICKSTART.md  # First-time WordPress setup & database config guide
├── docker-compose.yml       # Local Docker Compose configuration (git-ignored)
├── docker-compose.yml.example # Default template for Docker Compose services definition
├── docker-compose.direct.yml  # Host port publishing overlay (git-ignored; omit via COMPOSE_FILE for proxied mode)
├── docker-compose.direct.yml.example # Template for host port publishing overlay
├── .env                     # Local environment variables (created from env.example)
├── env.example              # Template for environment configuration
├── Makefile                 # Cross-platform 1-word command shortcuts
├── backup.sh                # Automated WWW & MariaDB backup script
├── merge-to-main.sh         # Git branch merge script (excludes pages)
├── config/                  # Apache, PHP, and MySQL custom override configuration templates
│   ├── apache/              # Apache 000-default.conf virtualhost override
│   ├── php/                 # PHP custom.ini memory/upload limits override
│   └── mysql/               # MariaDB custom.cnf buffer pool override
├── logs/                    # Execution logs directory
│   └── backup.log           # Backup script execution logs
└── src/                     # Web application document root (/var/www/html)
    ├── user/                # Grav CMS user directory (plugins, themes, pages, config)
    │   ├── config/          # Grav system and plugin configuration files
    │   ├── pages/           # Grav markdown pages and content
    │   ├── plugins/         # Grav installed plugins (including ai-chatbot)
    │   └── themes/          # Grav active themes
    └── cache/               # Grav cache directory (git-ignored & excluded from deployments)
```

> [!NOTE]
> **External web root**: `SRC_PATH` in `.env` may point outside this repository (e.g. `/home/milkboy/Documents/web-app/personal-cv-site`). All scripts (`backup.sh`, `make test`) resolve the web root from `SRC_PATH`; `./src/` is only a stub for in-repo layouts.

---

## 🤝 Support & Documentation

For detailed information on configuring reverse proxies (Traefik / Nginx Proxy Manager), custom domain binding, database restoration, or AI Chatbot integration, see **[HOWTO.md](HOWTO.md)**.
