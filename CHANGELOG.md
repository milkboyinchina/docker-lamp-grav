# Changelog

All notable changes to this infrastructure stack are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- Host port publishing overlay (`docker-compose.direct.yml` + example) with
  `COMPOSE_FILE` switch in `.env`: direct standalone access vs proxied mode
  (NPM / Traefik / tunnel) with zero published host ports. `NPM_ADMIN_BIND`
  controls Admin UI exposure (`127.0.0.1` host-only vs `0.0.0.0` LAN).

### Changed
- Web root is now location-agnostic: `backup.sh` loads `.env` from its own
  directory and resolves `SRC_PATH` to an absolute path; `deploy.sh` purges
  `${APP_SRC_BASE}/cache` instead of the hardcoded in-repo path; `make test`
  and `make clean-test` target `SRC_PATH` (fallback `./src`).
- Clarified `DEPLOY_SRC_DIR` scope: Windows helper scripts (`scripts\*.bat`)
  only; Bash scripts resolve the web root from `SRC_PATH`. Aligned local
  `.env` value to `./src/user`.
- Documented external web-root layouts and the in-repo-only scope of
  `merge-to-main.sh` in `README.md` and `HOWTO.md`.

## [2026-10-05] - Repository folder rename safety (`a99e6f2`)

### Changed
- Pinned Compose project name (`name: grav-lamp` in `docker-compose.yml`
  and `docker-compose.yml.example`) so renaming the repository directory no
  longer orphans networks and volumes.
- `deploy.sh`: removed hardcoded `/mnt/.../docker-lamp-grav` and absolute
  `SRC_PATH` fallbacks. Target resolution order is now `DEPLOY_TARGET_BASE`
  → derived from `DEPLOY_DEST_DIR` → explicit argument → fail with exit 1.
  Target cache clearing is guarded against an empty base; health check uses
  `HTTP_PORT`.
- `upload-article.sh`: source pages respect `SRC_PATH`; `DEPLOY_DEST_DIR` is
  required in rsync mode instead of a hardcoded default; health check uses
  `HTTP_PORT`.
- `Makefile clear-cache`: target cache directory is derived from
  `DEPLOY_DEST_DIR` in `.env`, never hardcoded; stale directory comment fixed.
- `scripts/deploy.bat`, `scripts/upload-article.bat`: error when
  `DEPLOY_DEST_DIR` is unset instead of falling back to a stale path.
- `env.example`: documented `DEPLOY_TARGET_BASE` (also added to local `.env`).
- `README.md`: absolute `file:///...` links replaced with relative links.

## [2026-10-05] - Targeted deployments and docs (`b0194f9`)

### Added
- `Makefile` targets: `deploy-user`, `deploy-pages`, `deploy-user-all`,
  `deploy-src` / `deploy-all`.
- `deploy.sh` scopes: `--target user|src`, `--pages-only`, `--include-pages`.
- `AGENTS.md` with infrastructure scope, boundaries, and deploy-scripts policy.

### Changed
- `make rebuild` split into `docker compose build --no-cache` + `up -d`.
- Cache clearing is dual: source container plus target environment.
- `README.md` / `HOWTO.md`: targeted deployment docs, dual cache
  invalidation, per-run deployment logs.
- Restored executable bits on `*.sh`, removed them from `scripts/*.bat`,
  restored `src/.gitkeep`.
