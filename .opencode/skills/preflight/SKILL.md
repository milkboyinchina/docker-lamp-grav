---
name: preflight
description: Verification chain for docker-lamp-grav changes. Load before finalizing any edit: syntax checks, compose renders, hardcoded-path sweeps, live-container safety, commit checklist.
---

# Skill: Preflight (docker-lamp-grav)

Run this chain from the repository root before finalizing any change. Stop and fix on the first failure.

## 1. Syntax and parse checks

```bash
bash -n backup.sh start.sh rebuild.sh shell.sh stop.sh merge-to-main.sh docker/docker-entrypoint.sh
make help >/dev/null && echo MAKE-OK
```

## 2. Compose renders (both port modes, plus active profiles)

```bash
docker compose config >/dev/null && echo BASE-OK
COMPOSE_FILE=docker-compose.yml:docker-compose.direct.yml docker compose config | grep -c "published:"  # must be >0
COMPOSE_FILE=docker-compose.yml docker compose config | grep -c "ports:"  # must be 0
COMPOSE_PROFILES=proxy,tunnel docker compose config | grep -A6 "tunnel:"  # tunnel present only when profiled
```

Expected: no `ports:` in base render, published ports only via the direct overlay, profile-gated services absent by default.

## 3. Hardcoded-path and stale-reference sweep

```bash
grep -rn "docker-lamp-grav" --include="*.sh" --include="Makefile" --include="*.bat" --include="*.yml" . | grep -v "\.example"
grep -rn "PHP_IMAGE" . --exclude-dir=.git  # must be empty (selector is PHP_VERSION)
grep -rniE "deploy\.sh|upload-article|DEPLOY_|FTP_" . --exclude-dir=.git --exclude=CHANGELOG.md  # only intentional pointers
```

Remaining `docker-lamp-grav` hits are allowed only in docs prose, `.example` target-path examples, and the local gitignored `.env`.

## 4. Paired-file consistency

- `.env` / `env.example` and `docker-compose.yml` / `docker-compose.yml.example` (likewise `.direct.yml`) changed in tandem.
- Fallback defaults identical across each pair (`:-80`, `:-8.4`, bind addresses).
- Validation allow-lists identical (`start.sh`, `rebuild.sh`, `Makefile check-php`).

## 5. Live-container safety

```bash
docker compose ps
```

If a container is serving traffic, state the impact before recreating it (image flips, project renames, `container_name` conflicts). Remove orphan `docker-lamp-grav_*` networks/volumes after renames; never disrupt a serving stack silently.

## 6. Commit checklist

- One logical change per commit; `README.md` / `HOWTO.md` / `CHANGELOG.md` (`Unreleased`) ride along when behavior changes.
- Local-only files (`.env`, `docker-compose.yml`, `docker-compose.direct.yml`) updated for runtime but never staged.
- `git push` only on explicit user request.
