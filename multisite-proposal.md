# Multisite Proposal — Multiple Web Apps on One Stack

Status: **proposal** (not implemented). Target: after port modes, tunnel,
multi-app runtime, and PHP selector work.

## 1. Goal

Run up to 4 web apps from this single repository / Compose project without
cloning the whole stack per app: one shared backbone (bridge network,
MariaDB, NPM, Cloudflare Tunnel) plus one lightweight web container per app.
NPM routes each hostname to its app container.

## 2. Options considered

| Option | Verdict |
| :--- | :--- |
| **Single Apache, many vhosts** in one container | Rejected. All apps would share one PHP version, extension set, and lifecycle — incompatible with per-app `PHP_VERSION` / `APP_TYPE`. |
| **Per-app fragment files** (`apps/<name>.yml`) composed via a long `COMPOSE_FILE` chain | Rejected. Unbounded scaling, but the hand-edited file chain is error-prone (one wrong path = confusing merge behavior). |
| **Clone-the-stack per app** (status quo) | Rejected except for hard-isolation needs. Duplicates NPM/db/tunnel, port conflicts on every clone, N upgrades. |
| **`APPS=` word list + generator/wrapper scripts** | Rejected. Most magic, most failure modes; every `docker compose` entry point would need the wrapper. |
| **Fixed slots `app-1..app-4` gated by profiles (chosen)** | Bounded, explicit, no chains, no wrappers — profiles are native Compose. Cost: cap of 4 (raise by copying a block) and ~25 lines of duplication per slot. |

## 3. Agreed design

- **Keep `webserver` as slot 1** (always on, today's behavior, zero migration).
  Add `app-2`, `app-3`, `app-4` services, each with `profiles: ["appN"]`.
- **No `SITE_MODE` variable.** The profile list IS the single/multi switch
  (`COMPOSE_PROFILES=app1` vs `app1,app2,proxy,tunnel`). A mode var would need
  translation logic in every entry point — a second source of truth.
- **Fixed slots, flexible locations.** Web roots are NOT forced into
  `src/app-N` (this stack supports external `SRC_PATH`). Each slot gets
  `APP_N_SRC_PATH`, `APP_N_SERVER_NAME`, `APP_N_PHP_VERSION`, `APP_N_TYPE`,
  `APP_N_DOCROOT`. Slot 1 keeps honoring bare `SRC_PATH`/`SERVER_NAME`.
- **No host ports on app services.** All sites are reached through NPM
  (hostname → `<service>:80`); direct/localhost access rides the
  `docker-compose.direct.yml` overlay plan.
- **Databases.** One MariaDB instance, one database per app via
  `./config/mysql/initdb.d/` scripts (plus `MARIADB_DATABASE` for the first).
  Grav apps need none (flat-file).

## 4. Guardrails

- Unused slot (profile off) creates nothing — no error possible.
- Misconfigured slot (profile on, path empty/missing): Compose bind-mounts
  auto-create empty host dirs, so the entrypoint warns on empty docroot and a
  `make check` target validates each enabled slot's path before `up`.
- Naming convention locked by the template: fragment/service/container names
  must match (`app-2` → `grav-lamp-app-2`).
- `deploy.sh` / `backup.sh` stay single-app (slot 1 default); per-app
  selection (`SITE=` parameter) is future work, consistent with their TBD
  status in `AGENTS.md`.

## 5. Relationship to Grav-native multisite

Grav 2.x itself supports multisite via `user/env/<host>/` (verified against
the Grav 2.2 changelog). That is *app-level* multisite (one codebase, many
hostnames) and is complementary: it needs no infra changes. This proposal
covers *infra-level* multi-app (different codebases / frameworks per site).

## 6. Sequencing and build checklist

Depends on: port overlay (B), tunnel (A), multi-app runtime + PHP selector
(C+D) — slots consume all three.

1. `docker-compose.yml` + `.example`: `app-2/3/4` service blocks.
2. `.env` / `env.example`: per-slot vars + profile-combo documentation.
3. `make check` slot validation + entrypoint empty-docroot warning (entrypoint
   warning already exists; extend per slot if needed).
4. `HOWTO.md` multisite section, `README.md`, `CHANGELOG.md`.
5. Verify: single-site default render unchanged; multi-profile render shows
   enabled slots only; `docker compose config` green in both modes.
