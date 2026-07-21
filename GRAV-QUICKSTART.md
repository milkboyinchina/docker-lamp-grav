# 🌌 Grav CMS First-Time Quickstart & Admin Reset Guide

This guide provides step-by-step instructions for getting started with **Grav CMS** inside your Docker environment, configuring initial admin credentials, installing plugins/themes, and resetting admin accounts if locked out.

---

## ⚡ First-Time Grav Setup

### 1. Start the Container Stack
Run your Docker stack using Makefile or Docker Compose:
```bash
make up
# or
docker compose up -d
```

### 2. Access Your Grav Site
Open your browser and navigate to:
* **Website Homepage**: [http://localhost](http://localhost)
* **Grav Admin Panel**: [http://localhost/admin](http://localhost/admin)

---

## 👤 Creating & Managing Admin Users

### Method 1: Creating Admin via Admin Panel UI
1. Navigate to **[http://localhost/admin](http://localhost/admin)** in your browser.
2. If no admin account exists, Grav will automatically display the **"Create an Account"** registration form.
3. Fill in your desired `Username`, `Email`, `Full Name`, and `Password`.
4. Click **Create User** to finalize registration and enter the Grav Admin dashboard.

---

### Method 2: Creating Admin via Docker CLI (Recommended)
You can create new admin accounts instantly inside the running container without using the UI:

```bash
docker compose exec webserver php bin/plugin admin new-user
```
Follow the interactive terminal prompts to set the username, email, password, and permissions.

---

## 🔑 How to Reset Admin User & Password

If you forgot your password or get locked out of the Grav Admin panel, use one of the following methods:

### 🛠️ Method 1: CLI Password Reset (Recommended & Fast)
Reset an existing user's password using the Grav Admin CLI command inside the container:

```bash
docker compose exec webserver php bin/plugin admin reset-password
```
1. Enter the target **Username** or **Email address** when prompted.
2. Enter your **New Password**.
3. A success confirmation will be printed, and you can log in immediately at [http://localhost/admin](http://localhost/admin).

---

### 🛠️ Method 2: Remove Account File (Force Web Re-registration)
Deleting the admin account YAML file forces Grav to display the first-time admin setup form again:

```bash
# Delete default admin user account file
rm src/user/accounts/admin.yaml

# Clear Grav cache
docker compose exec webserver php bin/grav clear-cache
```
Now navigate to **[http://localhost/admin](http://localhost/admin)** to register a fresh administrator account.

---

### 🛠️ Method 3: Manual Password Hash Update
To manually set a known password hash inside the user account file:

1. Open `src/user/accounts/<username>.yaml` (e.g., `src/user/accounts/admin.yaml`).
2. Replace the `hashed_password` line with an encrypted hash or update user privileges:
   ```yaml
   state: enabled
   email: admin@example.com
   fullname: Administrator
   title: Administrator
   access:
     admin:
       login: true
       super: true
     site:
       login: true
   ```
3. Clear Grav cache:
   ```bash
   docker compose exec webserver php bin/grav clear-cache
   ```

---

## 📦 Useful Grav CLI Commands

Run any Grav CLI command directly inside your Docker container:

* **Clear Grav Cache**:
  ```bash
  docker compose exec webserver php bin/grav clear-cache
  ```
* **Check Package Updates**:
  ```bash
  docker compose exec webserver php bin/gpm index
  ```
* **Install a Theme or Plugin via GPM**:
  ```bash
  docker compose exec webserver php bin/gpm install <plugin-or-theme-name>
  ```
* **List Installed Plugins & Themes**:
  ```bash
  docker compose exec webserver php bin/gpm infos
  ```

---

## 📂 Key Directory Locations

* **Pages & Content**: `src/user/pages/`
* **Site Configuration**: `src/user/config/site.yaml` & `src/user/config/system.yaml`
* **Themes**: `src/user/themes/`
* **Plugins**: `src/user/plugins/`
* **User Accounts**: `src/user/accounts/`
