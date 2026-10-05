# AGENTS.md — Docker LAMP Multi-App Infrastructure Stack

> **Independent Infrastructure Project**: This repository manages, builds, tunes, and optimizes the containerized Docker LAMP stack runtime environment for **Grav 2.x, WordPress, Laravel, CodeIgniter, and custom PHP applications**.

---

## 1. 🚨 Critical Directives & Boundaries (Priority 1)

### A. Project Scope & Independence
* **Role**: Dedicated to container infrastructure, Docker image builds, Apache 2.4 vhosts, PHP 8.3–8.5 runtime tuning, and MariaDB configuration. Web apps are selected via `APP_TYPE` (`grav|laravel|codeigniter|wordpress|custom`) and `APACHE_DOCROOT` in `.env`.
* **Separation of Concerns**: Do NOT modify the mounted web application source code (`SRC_PATH`) from this repository. Work on the web app directly in `/home/milkboy/Documents/web-app/personal-cv-site`.
* **Persona**: Accurate, disciplined software engineer. **DO NOT TRY TO BE FUNNY.**

### B. Deployment Policy (Removed)
* This repository runs web servers; it contains **no** deployment scripts. Application deployment (including target cache invalidation) is managed exclusively from the application repository (`personal-cv-site/bin/deploy.sh`).

---

## 2. 🌐 Stack Topology & Environment

| Service | Container Name | Base Image | Port Mapping |
| :--- | :--- | :--- | :--- |
| **Webserver** | `grav-lamp-web` | `php:8.3-apache` (Debian Bookworm) | `HTTP_PORT=18888` (`http://localhost:18888/`) |
| **Database** | `grav-lamp-db` | `mariadb:latest` (optional profile) | Internal / Docker network |
| **Adminer** | `grav-lamp-adminer` | `adminer:latest` (optional profile) | `ADMINER_PORT=18080` |
| **Proxy (NPM)**| `grav-lamp-npm` | `jc21/nginx-proxy-manager` | Ports `8000`, `81`, `8443` |

* **Web Root Volume Mount**: `SRC_PATH` in `.env` (points to `/home/milkboy/Documents/web-app/personal-cv-site` -> mounted to `/var/www/html`).

---

## 3. ⚡ Stack Management Commands

Run from this directory:
```bash
make up         # Start containers in background (verifies .env and configs first)
make down       # Stop and remove containers and network
make restart    # Restart running containers
make rebuild    # Rebuild image without cache & restart
make logs       # Follow live Apache & PHP logs
make status     # Check status of containers
make shell      # Open interactive shell inside grav-lamp-web container
make clear-cache# Run Grav clearcache command inside web container
```

---

## 4. 🛠️ Configuration & Optimization Touchpoints

```text
docker-lamp-grav/
├── docker-compose.yml         # Container services & volume definitions
├── docker/Dockerfile          # Custom PHP Apache build (version via PHP_VERSION)
├── .env                       # PHP selection, APP_TYPE, ports, mount paths (SRC_PATH), profiles
├── config/
│   ├── apache/000-default.conf # VirtualHost, mod_rewrite, headers, KeepAlive
│   ├── php/custom.ini         # OPcache, JIT, memory limits, upload limits
│   └── mysql/custom.cnf       # MariaDB InnoDB buffer pool & performance tuning
└── Makefile                   # Container management shortcuts
```

### Key Performance Tuning Guidelines
* **OPcache & JIT**: Configured in `config/php/custom.ini`. Ensure OPcache memory and JIT buffer sizes align with high-performance Grav flat-file cache requirements.
* **Apache Rewrite & Security**: Configured in `config/apache/000-default.conf`. Ensure `AllowOverride All` is maintained for Grav `.htaccess` routing.
