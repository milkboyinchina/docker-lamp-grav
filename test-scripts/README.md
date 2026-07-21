# 🧪 Unified Diagnostic Test Script

This directory contains the unified PHP environment diagnostic script (`test.php.example`) to verify PHP extensions, server settings, and database connectivity for **Grav CMS**, **WordPress**, and custom PHP applications before deployment.

---

## 📂 Diagnostic Script (`test.php.example`)

* **File**: `test-scripts/test.php.example`
* **Purpose**: Single comprehensive diagnostic page checking system compatibility for Grav CMS, WordPress Core, and MariaDB.

### 🚀 How to Run:
Deploy the test script to your application root directory (`src/`):

```bash
# Using Makefile:
make test

# Or manual copy:
cp test-scripts/test.php.example src/test.php
```

Access via browser at **[http://localhost/test.php](http://localhost/test.php)**.

---

## ⚠️ Automatic Warning Banners & Alerts

The diagnostic script automatically scans your environment on page load, rendering visual alert banners:

* ⛔ **CRITICAL ALERT (Red)**: Displayed if any required extension (`gd`, `zip`, `mbstring`, `mysqli`, `yaml`, `curl`, `xml`, `zlib`) is missing.
* ⚠️ **WARNING ALERT (Yellow)**: Displayed if any performance extension (`opcache`, `imagick`, `exif`) is disabled or memory limit is low.
* ℹ️ **DATABASE ALERT (Notice)**: Displayed if MariaDB is disconnected (explains database requirements for Grav vs WordPress).
* ✅ **SYSTEM READY (Green)**: Displayed when all required & recommended extensions are loaded and MariaDB is connected!

---

## 🧹 Clean Up Test Script
Once testing is complete, remove the file from your `src/` directory:

```bash
# Using Makefile:
make clean-test

# Or manual remove:
rm src/test.php
```
