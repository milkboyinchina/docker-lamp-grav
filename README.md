# Dockerized LAMP Stack (PHP 8.3 + Apache + MariaDB)

A lightweight, high-performance, and developer-friendly Docker environment running Apache and PHP 8.3, pre-configured for **Grav CMS**, **WordPress**, or any custom PHP web application.

> **Flexible & General-Purpose PHP Stack**:  
> While this Docker environment is pre-configured and thoroughly tested with **Grav CMS**, it is **not restricted to Grav**. You can clear the contents of `src/` and drop in **WordPress**, **Laravel**, **Symfony**, or any custom PHP scripts. Standalone diagnostic test scripts are included for both Grav and WordPress out of the box!

### Key Features
* **PHP 8.3 & Apache 2.4**: Pre-built with required and performance PHP extensions (`GD`, `ZIP`, `OPcache`, `APCu`, `Redis`, `YAML`, `MySQLi`, `PDO_MySQL`, `mbstring`, `exif`, `intl`).
* **Optional MariaDB & Adminer via Docker Profiles**: Pre-configured database and web-based database management interface ready to enable with `COMPOSE_PROFILES=db,adminer` in `.env`.
* **Automated Backup Suite with Logging & Warnings**: Integrated Bash and Windows Batch scripts (`backup.sh` and `scripts/backup.bat`) with option-matching file suffixes (`_www`, `_db`, `_all`), pre-flight warnings, and persistent file logging (`logs/backup.log`).
* **Configurable Environment & Volume Paths**: All volume paths (`src`, `logs`, `config`), restart policies, and ports are customizable via `.env`.
* **Traefik Reverse Proxy & TLS Ready**: Built-in, commented Traefik labels and external network configuration supporting SSL/TLS termination out of the box.
* **Cross-Platform Readiness**: Includes 1-word `Makefile` shortcuts, Windows `.bat` double-click scripts, Linux/macOS `.sh` scripts, and `.gitattributes` line-ending protection.
* **Automatic Permission Management**: Self-healing entrypoint script fixes file permissions inside `/var/www/html/` on container startup.
* **Built-in Diagnostic Suite**: Pre-packaged test scripts to verify runtime compatibility for Grav CMS and WordPress.

---

## Project Structure

```text
grav-lamp/
├── docker-compose.yml       # Docker Compose services definition (webserver, db, adminer)
├── docker/                  # Docker build files and entrypoint scripts
│   ├── Dockerfile           # Custom PHP-Apache image definition with extensions
│   └── docker-entrypoint.sh # Auto-runs on container startup (handles permissions)
├── .env                     # Local environment variables (created from env.example)
├── env.example              # Template for environment configuration
├── GRAV-QUICKSTART.md       # First-time Grav setup & admin user reset guide
├── .gitattributes           # Enforces LF line endings for Windows/Linux/macOS
├── Makefile                 # Cross-platform 1-word command shortcuts
├── start.sh / stop.sh       # Linux/macOS/WSL 1-click shell scripts
├── rebuild.sh               # Rebuild container image shell script
├── backup.sh                # Automated WWW site files & MariaDB backup shell script
├── scripts/                 # Windows CMD/PowerShell batch scripts
│   ├── start.bat            # Windows 1-click start batch script
│   ├── stop.bat             # Windows 1-click stop batch script
│   ├── rebuild.bat          # Windows 1-click rebuild batch script
│   └── backup.bat           # Windows 1-click backup batch script
├── test-scripts/            # Diagnostic & compatibility test scripts
│   ├── README.md            # Documentation for test scripts
│   └── test.php.example     # Unified diagnostic script for Grav CMS & WordPress
├── config/                  # Configuration files mounted to the container
│   ├── apache/
│   │   └── 000-default.conf # VirtualHost and ServerName configuration
│   ├── php/
│   │   └── custom.ini       # Custom php.ini overrides (limits, OPcache settings)
│   └── mysql/
│       └── custom.cnf       # Custom MariaDB server settings
├── logs/                    # Host-mounted log directories
│   ├── apache/              # Apache access.log and error.log
│   ├── php/                 # PHP error.log
│   └── backup.log           # Automated backup execution logs and warnings
└── src/                     # Grav CMS application directory (web root)
    └── index.php            # Main entrypoint of your application
```

---

## Quick Start

### 1. Prerequisites

#### General Prerequisites (Linux / macOS):
* [Docker Engine](https://docs.docker.com/get-docker/) & [Docker Compose v2](https://docs.docker.com/compose/install/)

#### Windows OS Prerequisites:
To ensure smooth container startup, file mounting, and script execution on Windows:
* **[Docker Desktop for Windows](https://docs.docker.com/desktop/install/windows-install/)**: Installed and running in your system tray.
* **[WSL 2 (Windows Subsystem for Linux 2)](https://learn.microsoft.com/en-us/windows/wsl/install)**: Enabled as the Docker backend engine:
  ```powershell
  wsl --install
  ```
  *(Ensure **"Use the WSL 2 based engine"** is checked in Docker Desktop -> Settings -> General)*.
* **Git for Windows** (Recommended): Provides Git Bash terminal support for running `.sh` and `make` commands on Windows: [https://git-scm.com/download/win](https://git-scm.com/download/win).
* **Terminal**: Supported in **PowerShell**, **CMD**, **Git Bash**, or **WSL 2** (`ubuntu`).

### 2. Environment Configuration
Copy the template environment file to create your local configurations:
```bash
cp env.example .env
```
Open the `.env` file and customize the variables as needed:
* **`COMPOSE_PROFILES`**: Control active services (`db,adminer` for full database stack, or empty for lightweight webserver-only mode).
* **`RESTART_POLICY`**: Container restart strategy (defaults to `unless-stopped`; options: `unless-stopped`, `always`, `on-failure`, `no`).
* **`SERVER_NAME`**: Set to your domain (defaults to `www.mydom.com`).
* **`HTTP_PORT` / `ADMINER_PORT`**: Ports exposed on host machine (defaults to `80` and `8080`).
* **`SRC_PATH`, `LOGS_*_PATH`, `CONFIG_*_PATH`**: Host paths for application source, log directories, and configuration files.
* **`BACKUP_DIR`, `BACKUP_PREFIX`, `LOGS_BACKUP_PATH`**: Output directory, file prefix, and execution log location for automated backups.
* **`MARIADB_*`**: Database credentials for the MariaDB service.

### 3. Spin up the Stack
Build the custom PHP image and start the containers in the background:
```bash
docker compose up -d --build
```

Once running, you can access your site at:
* **Main Website**: [http://localhost](http://localhost) (or the domain defined in `SERVER_NAME`).
* **Grav Admin Panel**: [http://localhost/admin](http://localhost/admin).
* **Adminer Database Manager**: [http://localhost:8080](http://localhost:8080) (when `COMPOSE_PROFILES=db,adminer` is active).

> **First-Time Grav User & Admin Reset Guide**:  
> Check out [`GRAV-QUICKSTART.md`](file:///home/milkboy/Documents/grav-lamp-docker/GRAV-QUICKSTART.md) for detailed instructions on first-time setup, creating admin users via CLI, and resetting admin accounts if locked out.

---

## Cross-Platform Easy Shortcuts (Windows, Linux, macOS)

To make running and managing `docker-compose.yml` seamless on any operating system, the stack includes **Makefile** shortcuts and **1-click OS helper scripts**:

### 1. Makefile Shortcuts (Linux, macOS, WSL, Windows Git Bash)
If you have `make` installed, run these 1-word commands from your terminal:
* **`make up`**: Start containers in the background (automatically creates `.env` if missing).
* **`make stop`**: Stop running containers.
* **`make down`**: Stop and remove containers & network interfaces.
* **`make rebuild`**: Rebuild PHP image without cache & restart stack.
* **`make logs`**: Stream live webserver logs.
* **`make status`**: Check status of running containers.
* **`make test`**: Deploy unified diagnostic test page to `http://localhost/test.php`.
* **`make clean-test`**: Remove diagnostic test page from `src/`.
* **`make backup`**: Run interactive backup helper with logging and pre-flight warning checks.
* **`make merge-main`**: Merge active branch into `main` while automatically excluding `src/user/pages/`.

### 2. Windows (Double-Click Batch Scripts)
For Windows Command Prompt / PowerShell users:
* **`scripts\start.bat`**: Double-click to start stack.
* **`scripts\stop.bat`**: Double-click to stop stack.
* **`scripts\rebuild.bat`**: Double-click to rebuild stack without cache.
* **`scripts\backup.bat`**: Double-click or run from CMD to perform interactive backups with logging.
* **`scripts\merge-to-main.bat`**: Merge feature branch into `main` excluding `src/user/pages/`.

### 3. Linux / macOS (Shell Scripts)
For terminal users on Linux / macOS / WSL:
* **`./start.sh`**: Start containers in background.
* **`./stop.sh`**: Stop running containers.
* **`./rebuild.sh`**: Rebuild PHP image & restart stack.
* **`./backup.sh`**: Run backup helper script.
* **`./merge-to-main.sh`**: Merge current or specified branch into `main` excluding `src/user/pages/`.

---

## Automated Backups (WWW Site Files & MariaDB)

The project includes built-in backup scripts (`backup.sh` for Linux/macOS/WSL and `scripts/backup.bat` for Windows) supporting selective and full backups with automatic logging and warning checks.

### 1. Backup Configuration in `.env`
Backup behavior is configured using variables in `.env`:
```env
# Host directory output path for generated backup archives
BACKUP_DIR=./backups

# Custom filename prefix for backup files
BACKUP_PREFIX=grav_lamp

# Path to append backup operation execution logs and warnings
LOGS_BACKUP_PATH=./logs/backup.log
```

### 2. Suffix Rules & Output Files
Generated backup archives automatically attach a suffix matching the selected option (`_www`, `_db`, `_all`):

| Target Option | Linux / macOS / WSL File Format | Windows File Format | Description |
| :--- | :--- | :--- | :--- |
| **`www`** | `<prefix>_www_<timestamp>.tar.gz` | `<prefix>_www_<timestamp>.zip` | Archives web application files in `src/`. |
| **`db`** | `<prefix>_db_<timestamp>.sql.gz` | `<prefix>_db_<timestamp>.sql` | Dumps MariaDB database via `mariadb-dump`. |
| **`all`** | `<prefix>_all_<timestamp>.tar.gz` | `<prefix>_all_<timestamp>.zip` | Combined archive containing both `src/` files and database SQL dump. |

### 3. Execution & Pre-Flight Warnings

#### Interactive Selection:
Run the script without arguments to open an interactive menu:
* **Linux / macOS / WSL**: `./backup.sh` (or `make backup`)
* **Windows**: `scripts\backup.bat`

#### Command-Line Direct Invocation:
Pass the backup target directly as an argument (`www`, `db`, or `all`):
```bash
./backup.sh www       # Backup WWW site files
./backup.sh db        # Backup MariaDB database
./backup.sh all       # Backup combined stack archive
```

#### Pre-Flight Warnings & Logging:
- **Execution Logs**: All actions, timestamps, generated archive sizes, and completion status are written to `logs/backup.log`.
- **Pre-Flight Warning Checks**:
  - Warns if `.env` file is missing.
  - Warns if available host disk space is low (< 500MB).
  - Warns if `src/` directory is missing or empty.
  - Warns if `db` container is stopped or database is unavailable.

---

## Enabling MariaDB & Adminer via Compose Profiles

The stack uses **Docker Compose Profiles** to easily enable or disable MariaDB and Adminer without editing `docker-compose.yml`:

1. Open `.env`.
2. Edit `COMPOSE_PROFILES`:
   * `COMPOSE_PROFILES=db,adminer` — Enables Apache + MariaDB + Adminer.
   * `COMPOSE_PROFILES=db` — Enables Apache + MariaDB only.
   * `COMPOSE_PROFILES=` — Lightweight mode (Apache Webserver only).
3. Run `docker compose up -d` to apply changes.
4. **Adminer Database Manager**: Access it at [http://localhost:8080](http://localhost:8080) (or via `ADMINER_PORT`).

---

## Traefik Reverse Proxy & TLS Setup (Optional)

`docker-compose.yml` includes pre-configured, commented Traefik routing rules and TLS SSL settings for `www.mydom.com` and `www.mydom.com/adminer`:

1. **Create external Traefik network** (if not already existing):
   ```bash
   docker network create traefik
   ```
2. Open `docker-compose.yml`.
3. In `webserver` and `adminer` services:
   * Comment out the direct host `ports:` block.
   * Uncomment `- traefik` under `networks:`.
   * Uncomment the `labels:` block (includes `traefik.http.routers.<service>.tls=true` and path rules).
4. At the bottom of `docker-compose.yml`, uncomment the top-level `traefik:` network definition.
5. Run `docker compose up -d`.

---

## Customizing Configuration & Logs

This stack mounts configuration files from the host directly into the container so you can make edits without rebuilding:

* **PHP Settings**: Modify `config/php/custom.ini` (or path set in `CONFIG_PHP_PATH`) to adjust `memory_limit`, `upload_max_filesize`, execution time, or OPcache settings.
* **Apache Host**: Modify `config/apache/000-default.conf` (or path set in `CONFIG_APACHE_PATH`) to customize rewrite rules, headers, or document paths.
* **MariaDB**: Modify `config/mysql/custom.cnf` (or path set in `CONFIG_MYSQL_PATH`) to adjust server limits, character sets, or collation.
* **Logs**: Check local folders `logs/apache/`, `logs/php/`, and `logs/backup.log` to view log files in real-time.

---

## Permissions & Security

Grav CMS requires write access to several system directories. To make this seamless, the `docker-entrypoint.sh` script automatically fixes permissions inside the container for the following directories on startup:
* `/var/www/html/cache`
* `/var/www/html/logs`
* `/var/www/html/images`
* `/var/www/html/assets`
* `/var/www/html/tmp`
* `/var/www/html/backup`
* `/var/www/html/user`

It assigns ownership to the `www-data` user and ensures files are writable (permissions set to `777` fallback).

---

## Other Use Cases

While pre-configured and optimized for **Grav CMS**, this Docker environment is built as a general-purpose, high-performance PHP 8.3 + Apache stack. You can clear the contents of `src/` and deploy:

### 1. WordPress Local Development & Staging
* Delete files inside `src/` and extract a fresh WordPress package.
* Ensure `COMPOSE_PROFILES=db,adminer` is enabled in `.env`.
* Run `make up` and navigate to [http://localhost](http://localhost) to complete the 5-minute WordPress installation.

### 2. Modern PHP Frameworks (Laravel, Symfony, CodeIgniter, Slim)
* Drop your **Laravel**, **Symfony**, or **CodeIgniter** project files into `src/`.
* Modify `config/apache/000-default.conf` to set `DocumentRoot /var/www/html/public` for framework routing.
* Run Composer commands directly inside the webserver container:
  ```bash
  docker compose exec webserver composer install
  ```

### 3. PHP Extension Prototyping & Custom Web Apps
* Prototype custom PHP 8.3 applications utilizing pre-built performance and graphic libraries (`imagick`, `gd --with-webp`, `redis`, `apcu`, `yaml`, `bcmath`, `sockets`, `opcache`).
* Use `make test` to verify extension availability and compatibility scores.

### 4. Flat-File PHP Scripts & Database-less Applications
Deploy database-less flat-file PHP scripts or custom applications directly into `src/` with zero database configuration required:
* **Flat-File CMS & Publishing**: **Kirby**, **Pico CMS**, **Statamic**, **Bludit**, **WonderCMS**, **Automad**, **HTMLy**, **PhileCMS**.
* **Flat-File Wikis & Documentation**: **DokuWiki**, **Raneto**, **WikiDocs**.
* **Single-File Utilities & Tools**: **TinyFileManager**, **Adminer**, or custom single-file PHP microservices.
