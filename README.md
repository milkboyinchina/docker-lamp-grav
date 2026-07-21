# Dockerized LAMP Stack (PHP 8.3 + Apache + MariaDB)

A lightweight, high-performance, and developer-friendly Docker environment running Apache and PHP 8.3, pre-configured for **Grav CMS**, **WordPress**, or any custom PHP web application.

> **Flexible & General-Purpose PHP Stack**:  
> While this Docker environment is pre-configured and thoroughly tested with **Grav CMS**, it is **not restricted to Grav**. You can clear the contents of `src/` and drop in **WordPress**, **Laravel**, **Symfony**, or any custom PHP scripts. Standalone diagnostic test scripts are included for both Grav and WordPress out of the box!

### Key Features
* **PHP 8.3 & Apache 2.4**: Pre-built with required and performance PHP extensions (`GD`, `ZIP`, `OPcache`, `APCu`, `Redis`, `YAML`, `MySQLi`, `PDO_MySQL`, `mbstring`, `exif`, `intl`).
* **Optional MariaDB & Adminer**: Pre-configured database and web-based database management interface ready to enable with 1 click.
* **Cross-Platform Readiness**: Includes 1-word `Makefile` shortcuts, Windows `.bat` double-click scripts, Linux/macOS `.sh` scripts, and `.gitattributes` line-ending protection.
* **Automatic Permission Management**: Self-healing entrypoint script fixes file permissions inside `/var/www/html/` on container startup.
* **Built-in Diagnostic Suite**: Pre-packaged test scripts to verify runtime compatibility for Grav CMS and WordPress.

---

## Project Structure

```text
grav-lamp/
├── docker-compose.yml       # Docker Compose services definition
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
├── scripts/                 # Windows CMD/PowerShell batch scripts
│   ├── start.bat            # Windows 1-click start batch script
│   ├── stop.bat             # Windows 1-click stop batch script
│   └── rebuild.bat          # Windows 1-click rebuild batch script
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
│   └── php/                 # PHP error.log
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
* **`PHP_VERSION`** (or `PHP_IMAGE`): PHP version target (defaults to `8.3-apache`).
* **`SERVER_NAME`**: Set to your domain (e.g., `www.example.com` or `localhost`).
* **`HTTP_PORT`**: Port to expose on your host machine (defaults to `80`).
* **`MARIADB_*`**: Database credentials for the MariaDB service (if enabled).

### 3. Spin up the Stack
Build the custom PHP image and start the containers in the background:
```bash
docker compose up -d --build
```

Once running, you can access your site at:
* **Main Website**: [http://localhost](http://localhost) (or the port defined in `HTTP_PORT`).
* **Grav Admin Panel**: [http://localhost/admin](http://localhost/admin).

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

### 2. Windows (Double-Click Batch Scripts)
For Windows Command Prompt / PowerShell users:
* **`scripts\start.bat`**: Double-click to start stack.
* **`scripts\stop.bat`**: Double-click to stop stack.
* **`scripts\rebuild.bat`**: Double-click to rebuild stack without cache.

### 3. Linux / macOS (Shell Scripts)
For terminal users on Linux / macOS / WSL:
* **`./start.sh`**: Start containers in background.
* **`./stop.sh`**: Stop running containers.
* **`./rebuild.sh`**: Rebuild PHP image & restart stack.

---

## Container Operations (Run, Stop, Remove & Rebuild)

Here are the essential Docker Compose commands to manage your LAMP stack environment:

### 1. Run / Start Containers
* **Start containers in background (detached mode)**:
  ```bash
  docker compose up -d
  ```
* **Start containers and attach to terminal logs**:
  ```bash
  docker compose up
  ```

### 2. Stop Containers
* **Stop running containers (without removing them)**:
  ```bash
  docker compose stop
  ```
* **Stop and remove running containers & networks**:
  ```bash
  docker compose down
  ```

### 3. Remove Containers & Database Volumes
* **Stop containers, remove networks, and purge persistent database volumes**:
  ```bash
  docker compose down -v
  ```
* **Force remove stopped container instances**:
  ```bash
  docker compose rm -f
  ```

### 4. Rebuild Images & Container Stack
* **Rebuild the PHP/Apache image without cache and restart containers**:
  ```bash
  docker compose up -d --build --no-cache
  ```
* **Rebuild specific service image (e.g. webserver)**:
  ```bash
  docker compose build --no-cache webserver
  docker compose up -d
  ```

---

## Verification & Diagnostics

The project includes a unified diagnostic test script in [`test-scripts/test.php.example`](file:///home/milkboy/Documents/grav-lamp-docker/test-scripts/test.php.example) to verify environment compatibility, PHP extensions, and database connections for **Grav CMS** and **WordPress**:

### Deploying the Test Script:
```bash
# Using Makefile shortcut:
make test

# Or manual copy:
cp test-scripts/test.php.example src/test.php
```

Access at **[http://localhost/test.php](http://localhost/test.php)** to view the compatibility summary and extension matrix.

> For detailed documentation on the test script, check out [`test-scripts/README.md`](file:///home/milkboy/Documents/grav-lamp-docker/test-scripts/README.md).

---

## Enabling MariaDB & Adminer (Optional)

By default, the MariaDB database and Adminer database manager services are commented out in `docker-compose.yml` to keep the stack super lightweight. If your project/plugins require a database:

1. Open `docker-compose.yml`.
2. Locate the `db` and `adminer` service blocks, and the `depends_on` block under the `webserver` service.
3. Uncomment those blocks (remove the `#` symbols).
4. Run `docker compose up -d` to spin up the database and tool.
5. **Adminer Database Manager**: Access it at [http://localhost:8080](http://localhost:8080) (or the port defined in `ADMINER_PORT`).

---

## Customizing Configuration & Logs

This stack mounts configuration files from the host directly into the container so you can make edits without rebuilding:

* **PHP Settings**: Modify `config/php/custom.ini` to adjust `memory_limit`, `upload_max_filesize`, execution time, or to tune OPcache.
* **Apache Host**: Modify `config/apache/000-default.conf` to customize rewrite rules, headers, or document paths.
* **MariaDB (if enabled)**: Modify `config/mysql/custom.cnf` to adjust server limits, character sets, or collation.
* **Logs**: Check local folders `logs/apache/` and `logs/php/` to view log files in real-time.

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
* Uncomment the `db` (MariaDB) and `adminer` services in `docker-compose.yml`.
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

### 4. Flat-File PHP scripts (Kirby, Pico, Statamic, or standalone PHP apps)
* Deploy database-less flat-file CMS platforms or custom standalone PHP scripts directly into `src/` with zero database configuration required.
