# AGENTS.md — Docker LAMP Multi-App Infrastructure Stack

> **Independent Infrastructure Project**: This repository manages, builds, tunes, and optimizes the containerized Docker LAMP stack runtime environment for **Grav 2.x, WordPress, Laravel, CodeIgniter, and custom PHP applications**.
>
> Sections are ordered by importance. §1–§2 are binding on every change; §3–§4 are reference.

---

## 1. 🚨 Hard Boundaries (read first, non-negotiable)

* **Role**: Container infrastructure, Docker image builds, Apache 2.4 vhosts, PHP 8.3–8.5 runtime tuning, and MariaDB configuration. Web apps are selected via `APP_TYPE` (`grav|laravel|codeigniter|wordpress|custom`) and `APACHE_DOCROOT` in `.env`.
* **Separation of Concerns**: Do NOT modify the mounted web application source code (`SRC_PATH`) from this repository. Work on the web app directly in `/home/milkboy/Documents/web-app/personal-cv-site`.
* **Persona**: Accurate, disciplined software engineer. **DO NOT TRY TO BE FUNNY.**
* **Deployment Policy (Removed)**: This repository runs web servers; it contains **no** deployment scripts. Application deployment (including target cache invalidation) is managed exclusively from the application repository (`personal-cv-site/bin/deploy.sh`).
* **Live-Stack Caution**: The dev container may be running. Recreating it (image flips, project renames, container-name conflicts, orphan networks/volumes) gets a user-visible note — never silently disrupt a serving stack.

---

## 2. ⚙️ Workflow Rules (every change, every session)

1. **Paired-file discipline.** `.env`/`env.example` and `docker-compose.yml`/`docker-compose.yml.example` (likewise the `.direct.yml` pair) are edited in tandem, always.
2. **Single source of truth per variable.** No two variables driving one behavior, no dead config, no secret defaults.
3. **No hardcoded fallbacks for paths or names.** Fail fast with an actionable error instead of writing to a stale default. Never recreate an old directory name after a rename.
4. **Verify by execution, not review.** Load the `preflight` skill (§4) and run its chain: `bash -n`, both-mode `docker compose config` render, hardcoded-path grep, `make help` parse, plus a real container boot before flipping defaults.
5. **Docs ride with code.** `README.md` / `HOWTO.md` / `CHANGELOG.md` (`Unreleased`) are updated in the same commit as the behavior change.
6. **Commit per unit, never push unasked.** One logical change per commit; `git push` only on explicit request. Local-only files (`.env`, `docker-compose.yml`, `docker-compose.direct.yml`) are gitignored — update them for runtime but never commit them.
7. **Needs a decision? Ask.** State the options with a recommendation instead of guessing on load-bearing choices (image versions, defaults, scope cuts).

---

## 3. 🌐 Stack Reference

| Service | Container Name | Image | Access |
| :--- | :--- | :--- | :--- |
| **Webserver** | `grav-lamp-web` | `php:<PHP_VERSION>-apache` (default 8.4, Debian) | `HTTP_PORT=18888` (`http://localhost:18888/`) in direct mode |
| **Database** | `grav-lamp-db` | `mariadb:latest` (optional profile) | Internal / Docker network |
| **Adminer** | `grav-lamp-adminer` | `adminer:latest` (optional profile) | `ADMINER_PORT=18080` in direct mode |
| **Proxy (NPM)** | `grav-lamp-npm` | `jc21/nginx-proxy-manager` (optional profile) | Ports `8000`, `81`, `8443` in direct mode |
| **Tunnel** | `grav-lamp-tunnel` | `cloudflare/cloudflared:latest` (optional profile) | Outbound-only, no published ports |

* **Web Root Volume Mount**: `SRC_PATH` in `.env` (points to `/home/milkboy/Documents/web-app/personal-cv-site` -> mounted to `/var/www/html`). May live outside this repo.
* **Port Modes**: `COMPOSE_FILE` in `.env` selects direct (`docker-compose.yml:docker-compose.direct.yml`) vs proxied (`docker-compose.yml` only, zero host ports).
* **Multisite**: See `multisite-proposal.md` (proposal, not implemented).

### Management Commands

Run from this directory:
```bash
make up          # Start containers in background (validates PHP_VERSION first)
make down        # Stop and remove containers and network
make restart     # Restart running containers
make rebuild     # Rebuild image without cache & restart
make logs        # Follow webserver logs
make logs-tunnel # Follow Cloudflare Tunnel logs
make status      # Check status of containers
make shell       # Open interactive shell inside grav-lamp-web container
make clear-cache # Clear app cache inside web container (local only)
```

### Configuration Touchpoints

```text
docker-lamp-grav/
├── docker-compose.yml         # Base services (expose-only) & volume definitions
├── docker-compose.direct.yml  # Host port publishing overlay (omit for proxied mode)
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

---

## 4. 🧠 Skills

* **`preflight`** (`.opencode/skills/preflight/SKILL.md`): the verification chain for every change — load it before finalizing any edit. Covers syntax checks, compose renders, hardcoded-path sweeps, live-container safety, and the commit checklist.
