# 🧪 Diagnostic & Compatibility Test Scripts

This directory contains standalone PHP diagnostic scripts to verify environment compatibility, required/optional PHP extensions, server settings, and database connectivity for various CMS platforms before deployment.

---

## ⚠️ Automatic Warning Banners & Alerts

Both diagnostic scripts automatically scan your PHP environment and database services on load, rendering prominent **Visual Warning Banners**:

* ⛔ **CRITICAL ALERT (Red)**: Triggered immediately if any **Required PHP Extension** (e.g. `gd`, `zip`, `mbstring`, `mysqli`, `yaml`) is missing.
* ⚠️ **WARNING ALERT (Yellow)**: Triggered if any **Recommended Extension** (e.g. `opcache`, `imagick`, `exif`) is disabled, or if PHP `memory_limit` is below 128MB.
* ℹ️ **DATABASE ALERT (Yellow / Red)**: Triggered if the MariaDB service is disconnected or unavailable. (For Grav CMS, database disconnection is noted as optional; for WordPress, it is flagged as critical).
* ✅ **SYSTEM READY (Green)**: Displayed when all required and recommended extensions are loaded and database is fully connected!

---

## 📂 Available Test Scripts

### 1. 🌌 Grav CMS Diagnostic Script
* **File**: `index.php.grav.testing.example`
* **Purpose**: Verifies that your PHP runtime and MariaDB/MySQL database satisfy all requirements for **Grav CMS**.
* **Checks**:
  * **Required Extensions**: `gd`, `mbstring`, `xml`, `zip`, `zlib`, `curl`, `yaml`.
  * **Performance & Optional**: `opcache`, `apcu`, `redis`, `memcache`, `exif`, `intl`, `pdo`, `pdo_mysql`.
  * **Database**: PDO MariaDB connection & server version check.

#### 🚀 How to Run for Grav:
```bash
cp test-scripts/index.php.grav.testing.example src/diagnostics.php
```
Access via browser at **[http://localhost/diagnostics.php](http://localhost/diagnostics.php)**.

---

### 2. 📝 WordPress CMS Diagnostic Script
* **File**: `index.php.wordpress.testing.example`
* **Purpose**: Verifies environment compatibility and MySQLi database connectivity for **WordPress Core**.
* **Checks**:
  * **PHP Version**: `PHP 7.4+` (PHP 8.0 - 8.3 recommended).
  * **Required Extensions**: `mysqli`, `curl`, `gd`, `mbstring`, `xml`, `zip`, `zlib`.
  * **Recommended & Optional**: `opcache`, `exif`, `fileinfo`, `intl`, `openssl`, `sodium`, `imagick`, `redis`, `apcu`.
  * **Limits**: `memory_limit` (>= 128M check), `upload_max_filesize`, `post_max_size`.
  * **Database**: MySQLi connection & database version check.

#### 🚀 How to Run for WordPress:
```bash
cp test-scripts/index.php.wordpress.testing.example src/wp-diagnostics.php
```
Access via browser at **[http://localhost/wp-diagnostics.php](http://localhost/wp-diagnostics.php)**.

---

## 💡 Usage Tip
Once diagnostics are complete, you can safely remove the testing file from your `src/` directory:
```bash
rm src/diagnostics.php src/wp-diagnostics.php
```
