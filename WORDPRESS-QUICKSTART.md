# WordPress First-Time Quickstart & Setup Guide

This guide provides step-by-step instructions for deploying and running **WordPress** inside your Docker LAMP environment, configuring database connectivity, managing WP-CLI, and executing backups.

---

## Table of Contents

1. [Prerequisites & Environment Setup](#1-prerequisites--environment-setup)
2. [Step 1: Enable MariaDB Database](#step-1-enable-mariadb-database)
3. [Step 2: Download & Extract WordPress Core](#step-2-download--extract-wordpress-core)
4. [Step 3: Configure `wp-config.php`](#step-3-configure-wp-configphp)
5. [Step 4: Complete WordPress Browser Installation](#step-4-complete-wordpress-browser-installation)
6. [Using WP-CLI inside Docker](#using-wp-cli-inside-docker)
7. [Backups & Deployment](#backups--deployment)
8. [WordPress Diagnostics & Troubleshooting](#wordpress-diagnostics--troubleshooting)

---

## 1. Prerequisites & Environment Setup

Ensure your Docker LAMP stack is ready. If you haven't started your environment yet:
```bash
make up
# or
./start.sh
```

---

## Step 1: Enable MariaDB Database

WordPress requires a MySQL/MariaDB database server.

1. Open your `.env` file and ensure `COMPOSE_PROFILES` includes `db` and optionally `adminer`:
   ```ini
   COMPOSE_PROFILES=db,adminer
   ```
2. Note your database credentials from `.env`:
   - **Database Host**: `db` (internal Docker service name)
   - **Database Name**: `${MARIADB_DATABASE}` (default: `grav_db` or `wordpress_db`)
   - **Database User**: `${MARIADB_USER}` (default: `grav_user`)
   - **Database Password**: `${MARIADB_PASSWORD}` (default: `change_this_user_password`)

3. Restart containers to apply database profile:
   ```bash
   make up
   ```

---

## Step 2: Download & Extract WordPress Core

Place WordPress core files inside the host `src/` directory (which maps to container `/var/www/html/`).

### Option A: Via Terminal (Linux / macOS / WSL)
```bash
# Clean existing contents in src/ (if switching from Grav or sample site)
rm -rf src/*

# Download latest WordPress release
curl -sL https://wordpress.org/latest.tar.gz | tar -xz -C src/ --strip-components=1
```

### Option B: Download Manually
1. Download [WordPress latest ZIP](https://wordpress.org/latest.zip).
2. Extract the contents directly into your local `src/` folder so `src/index.php` and `src/wp-load.php` exist.

---

## Step 3: Configure `wp-config.php`

Copy the sample configuration file and update your database credentials:

```bash
# Create wp-config.php from sample
cp src/wp-config-sample.php src/wp-config.php
```

Edit `src/wp-config.php` to set database connection parameters:

```php
// ** Database settings - Read from Docker container ** //
define( 'DB_NAME', 'grav_db' );             // Your MARIADB_DATABASE in .env
define( 'DB_USER', 'grav_user' );           // Your MARIADB_USER in .env
define( 'DB_PASSWORD', 'change_this_user_password' ); // Your MARIADB_PASSWORD in .env
define( 'DB_HOST', 'db' );                  // Use Docker service name 'db'
define( 'DB_CHARSET', 'utf8mb4' );
define( 'DB_COLLATE', '' );
```

---

## Step 4: Complete WordPress Browser Installation

1. Open your browser and navigate to **[http://localhost](http://localhost)**.
2. The 5-Minute WordPress Installation Wizard will appear:
   - **Site Title**: Enter your site name.
   - **Username**: Enter your desired WordPress admin username.
   - **Password**: Enter a strong admin password.
   - **Your Email**: Enter your admin email address.
3. Click **Install WordPress**.
4. Log in to your WordPress dashboard at **[http://localhost/wp-admin](http://localhost/wp-admin)**.

---

## Using WP-CLI inside Docker

WP-CLI allows you to manage WordPress core, plugins, themes, and users via the terminal:

### Running WP-CLI inside Container:
```bash
# Open container shell
make shell

# Check WP-CLI version
wp --info --allow-root

# Update WordPress Core
wp core update --allow-root

# Install & Activate a Plugin (e.g. Elementor, WooCommerce, Yoast)
wp plugin install elementor --activate --allow-root

# List Installed Plugins
wp plugin list --allow-root
```

---

## Backups & Deployment

### 1. Backing Up WordPress Files & MariaDB
Run the interactive backup script to capture WordPress files and database dumps:
```bash
make backup
```
- Backups are stored in `./backups/` (e.g. `grav_lamp_db_YYYYMMDD.sql.gz` and `grav_lamp_www_YYYYMMDD.tar.gz`).

### 2. Deploying WordPress Plugins & Themes
Use the deployment script to sync local `src/wp-content/` or custom plugins/themes to production:
```bash
make deploy
```

---

## WordPress Diagnostics & Troubleshooting

### 1. Run WordPress Diagnostic Test Script
Verify PHP 8.3 database connectivity, extension modules, and folder permissions:
```bash
# Deploy diagnostic page
make test

# Open diagnostic suite in browser
http://localhost/test.php
```

### 2. File Permission Fixes
The container's `docker-entrypoint.sh` automatically ensures Apache (`www-data`) has read/write permissions to `/var/www/html/wp-content/uploads/` and `/var/www/html/wp-content/plugins/`.

If you experience permission issues, restart the container:
```bash
make restart
```
