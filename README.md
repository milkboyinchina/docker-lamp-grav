# Dockerized LAMP Stack for Grav CMS

A pre-configured, lightweight, and developer-friendly Docker environment running an Apache/PHP container, with optional support for **MariaDB** and **Adminer**.

> **Note**: While this Docker stack is pre-configured and thoroughly tested using **Grav CMS**, it is **not exclusively for Grav**. You can delete the contents of the `src/` directory and place a fresh Grav CMS installation, a custom PHP application, or any other PHP scripts you prefer.

This setup automatically takes care of system dependencies, required/optional PHP extensions (like OPcache, APCu, YAML, Redis, GD, etc.), file permissions, and custom server configurations.

---

## 📂 Project Structure

```text
grav-lamp/
├── docker-compose.yml       # Docker Compose services definition
├── Dockerfile               # Custom PHP-Apache image definition with Grav extensions
├── docker-entrypoint.sh     # Auto-runs on container startup (handles permissions)
├── .env                     # Local environment variables (created from env.example)
├── env.example              # Template for environment configuration
├── project-structure        # Reference map of the project
├── index.php.testing.example# Grav CMS & Database diagnostic script
├── index.php.wordpress-testing.example# WordPress CMS & Database diagnostic script
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

## ⚡ Quick Start

### 1. Prerequisites
Ensure you have the following installed on your machine:
* [Docker](https://docs.docker.com/get-docker/)
* [Docker Compose](https://docs.docker.com/compose/install/)

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

---

## 🐳 Container Operations (Run, Stop, Remove & Rebuild)

Here are the essential Docker Compose commands to manage your LAMP stack environment:

### 1. ▶️ Run / Start Containers
* **Start containers in background (detached mode)**:
  ```bash
  docker compose up -d
  ```
* **Start containers and attach to terminal logs**:
  ```bash
  docker compose up
  ```

### 2. ⏹️ Stop Containers
* **Stop running containers (without removing them)**:
  ```bash
  docker compose stop
  ```
* **Stop and remove running containers & networks**:
  ```bash
  docker compose down
  ```

### 3. 🗑️ Remove Containers & Database Volumes
* **Stop containers, remove networks, and purge persistent database volumes**:
  ```bash
  docker compose down -v
  ```
* **Force remove stopped container instances**:
  ```bash
  docker compose rm -f
  ```

### 4. 🔄 Rebuild Images & Container Stack
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

## 🔍 Verification & Diagnostics

The project includes pre-configured diagnostic scripts to verify environment compatibility and database connections:

### 1. Grav CMS Diagnostic Script (`index.php.testing.example`)
Checks Grav required/recommended extensions (`gd`, `mbstring`, `yaml`, `opcache`, `apcu`, `redis`, etc.) and PDO MariaDB connection:
```bash
cp index.php.testing.example src/diagnostics.php
```
Access at [http://localhost/diagnostics.php](http://localhost/diagnostics.php).

### 2. WordPress CMS Diagnostic Script (`index.php.wordpress-testing.example`)
Checks WordPress core runtime compatibility (`mysqli`, `gd`, `curl`, `mbstring`, `xml`, `zip`, `zlib`, `fileinfo`, `openssl`, memory limits, and MySQLi database connectivity):
```bash
cp index.php.wordpress-testing.example src/wp-diagnostics.php
```
Access at [http://localhost/wp-diagnostics.php](http://localhost/wp-diagnostics.php).

---

## 🗄️ Enabling MariaDB & Adminer (Optional)

By default, the MariaDB database and Adminer database manager services are commented out in `docker-compose.yml` to keep the stack super lightweight. If your project/plugins require a database:

1. Open `docker-compose.yml`.
2. Locate the `db` and `adminer` service blocks, and the `depends_on` block under the `webserver` service.
3. Uncomment those blocks (remove the `#` symbols).
4. Run `docker compose up -d` to spin up the database and tool.
5. **Adminer Database Manager**: Access it at [http://localhost:8080](http://localhost:8080) (or the port defined in `ADMINER_PORT`).

---

## 🔧 Customizing Configuration & Logs

This stack mounts configuration files from the host directly into the container so you can make edits without rebuilding:

* **PHP Settings**: Modify `config/php/custom.ini` to adjust `memory_limit`, `upload_max_filesize`, execution time, or to tune OPcache.
* **Apache Host**: Modify `config/apache/000-default.conf` to customize rewrite rules, headers, or document paths.
* **MariaDB (if enabled)**: Modify `config/mysql/custom.cnf` to adjust server limits, character sets, or collation.
* **Logs**: Check local folders `logs/apache/` and `logs/php/` to view log files in real-time.

---

## 🔒 Permissions & Security

Grav CMS requires write access to several system directories. To make this seamless, the `docker-entrypoint.sh` script automatically fixes permissions inside the container for the following directories on startup:
* `/var/www/html/cache`
* `/var/www/html/logs`
* `/var/www/html/images`
* `/var/www/html/assets`
* `/var/www/html/tmp`
* `/var/www/html/backup`
* `/var/www/html/user`

It assigns ownership to the `www-data` user and ensures files are writable (permissions set to `777` fallback).
