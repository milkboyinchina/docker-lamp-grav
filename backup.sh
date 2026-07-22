#!/usr/bin/env bash
# ==============================================================================
# Linux / macOS / WSL Backup Script for WWW Site Files & MariaDB
# ==============================================================================

set -e

# Load environment variables from .env if available
ENV_FOUND=true
if [ -f .env ]; then
    set -a
    source .env
    set +a
else
    ENV_FOUND=false
fi

# Set defaults from .env or fallback values
BACKUP_DIR="${BACKUP_DIR:-./backups}"
BACKUP_PREFIX="${BACKUP_PREFIX:-grav_lamp}"
SRC_PATH="${SRC_PATH:-./src}"
LOGS_BACKUP_PATH="${LOGS_BACKUP_PATH:-./logs/backup.log}"
MARIADB_DATABASE="${MARIADB_DATABASE:-grav_db}"
MARIADB_USER="${MARIADB_USER:-grav_user}"
MARIADB_PASSWORD="${MARIADB_PASSWORD:-userpassword}"

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Ensure backup and log directories exist
mkdir -p "$BACKUP_DIR"
mkdir -p "$(dirname "$LOGS_BACKUP_PATH")"

# Logger helper functions
log_info() {
    local MSG="$1"
    local TS=$(date +"%Y-%m-%d %H:%M:%S")
    echo "ℹ️  INFO: ${MSG}"
    echo "[${TS}] [INFO] ${MSG}" >> "$LOGS_BACKUP_PATH"
}

log_warn() {
    local MSG="$1"
    local TS=$(date +"%Y-%m-%d %H:%M:%S")
    echo "⚠️  WARNING: ${MSG}"
    echo "[${TS}] [WARNING] ${MSG}" >> "$LOGS_BACKUP_PATH"
}

log_err() {
    local MSG="$1"
    local TS=$(date +"%Y-%m-%d %H:%M:%S")
    echo "❌ ERROR: ${MSG}"
    echo "[${TS}] [ERROR] ${MSG}" >> "$LOGS_BACKUP_PATH"
}

log_success() {
    local MSG="$1"
    local TS=$(date +"%Y-%m-%d %H:%M:%S")
    echo "✅ SUCCESS: ${MSG}"
    echo "[${TS}] [SUCCESS] ${MSG}" >> "$LOGS_BACKUP_PATH"
}

# Run Pre-flight Warnings Check
run_warning_checks() {
    if [ "$ENV_FOUND" = false ]; then
        log_warn ".env configuration file not found! Using default fallback environment settings."
    fi

    # Disk space check (warn if under 500MB free)
    if command -v df >/dev/null 2>&1; then
        local FREE_KB
        FREE_KB=$(df -k "$BACKUP_DIR" | awk 'NR==2 {print $4}')
        if [ -n "$FREE_KB" ] && [ "$FREE_KB" -lt 512000 ]; then
            local FREE_MB=$((FREE_KB / 1024))
            log_warn "Low disk space detected on target storage: ${FREE_MB} MB available."
        fi
    fi
}

backup_www() {
    log_info "Starting WWW site files backup from '${SRC_PATH}'..."
    
    if [ ! -d "$SRC_PATH" ]; then
        log_err "Source directory '${SRC_PATH}' does not exist!"
        return 1
    fi

    if [ -z "$(ls -A "$SRC_PATH" 2>/dev/null)" ]; then
        log_warn "Source directory '${SRC_PATH}' is currently empty!"
    fi

    local OUT_FILE="${BACKUP_DIR}/${BACKUP_PREFIX}_www_${TIMESTAMP}.tar.gz"
    tar -czf "$OUT_FILE" -C "$SRC_PATH" .
    local FILE_SIZE
    FILE_SIZE=$(du -h "$OUT_FILE" | cut -f1)
    log_success "WWW site files backup created successfully: ${OUT_FILE} (${FILE_SIZE})"
}

backup_db() {
    log_info "Starting MariaDB database backup for '${MARIADB_DATABASE}'..."
    
    # Verify if db service container is running
    if ! docker compose ps --services --filter "status=running" 2>/dev/null | grep -q "^db$"; then
        log_warn "MariaDB database container 'db' is not running!"
        log_err "Database backup skipped. Enable via COMPOSE_PROFILES=db,adminer in .env and run 'make up'."
        return 1
    fi

    local OUT_FILE="${BACKUP_DIR}/${BACKUP_PREFIX}_db_${TIMESTAMP}.sql.gz"
    
    if docker compose exec -T db mariadb-dump -u"${MARIADB_USER}" -p"${MARIADB_PASSWORD}" "${MARIADB_DATABASE}" 2>/dev/null | gzip > "$OUT_FILE"; then
        local FILE_SIZE
        FILE_SIZE=$(du -h "$OUT_FILE" | cut -f1)
        log_success "MariaDB database backup created successfully: ${OUT_FILE} (${FILE_SIZE})"
    elif docker compose exec -T db mysqldump -u"${MARIADB_USER}" -p"${MARIADB_PASSWORD}" "${MARIADB_DATABASE}" 2>/dev/null | gzip > "$OUT_FILE"; then
        local FILE_SIZE
        FILE_SIZE=$(du -h "$OUT_FILE" | cut -f1)
        log_success "MariaDB database backup created successfully: ${OUT_FILE} (${FILE_SIZE})"
    else
        log_err "Failed to generate MariaDB database dump!"
        rm -f "$OUT_FILE"
        return 1
    fi
}

backup_all() {
    log_info "Starting full stack combined backup (option: all)..."
    
    local TEMP_DIR
    TEMP_DIR=$(mktemp -d)
    trap 'rm -rf "$TEMP_DIR"' EXIT

    # Copy WWW files
    if [ -d "$SRC_PATH" ] && [ -n "$(ls -A "$SRC_PATH" 2>/dev/null)" ]; then
        cp -r "$SRC_PATH" "$TEMP_DIR/src"
    else
        log_warn "Source directory '${SRC_PATH}' missing or empty."
    fi

    # Export DB dump if running
    if docker compose ps --services --filter "status=running" 2>/dev/null | grep -q "^db$"; then
        if docker compose exec -T db mariadb-dump -u"${MARIADB_USER}" -p"${MARIADB_PASSWORD}" "${MARIADB_DATABASE}" > "$TEMP_DIR/database_dump.sql" 2>/dev/null; then
            log_info "Database dump included in full backup package."
        elif docker compose exec -T db mysqldump -u"${MARIADB_USER}" -p"${MARIADB_PASSWORD}" "${MARIADB_DATABASE}" > "$TEMP_DIR/database_dump.sql" 2>/dev/null; then
            log_info "Database dump included in full backup package."
        else
            log_warn "Could not export MariaDB database dump for full archive package."
        fi
    else
        log_warn "MariaDB database container 'db' is not running. Full backup created without DB dump."
    fi

    local OUT_FILE="${BACKUP_DIR}/${BACKUP_PREFIX}_all_${TIMESTAMP}.tar.gz"
    tar -czf "$OUT_FILE" -C "$TEMP_DIR" .
    local FILE_SIZE
    FILE_SIZE=$(du -h "$OUT_FILE" | cut -f1)
    log_success "Combined full stack backup created successfully: ${OUT_FILE} (${FILE_SIZE})"
}

MODE="${1:-}"

if [ -z "$MODE" ]; then
    echo "======================================================================"
    echo "   Docker LAMP Stack Backup Helper"
    echo "======================================================================"
    echo "  1) www - Backup WWW site files (${SRC_PATH}) -> *_www_${TIMESTAMP}.tar.gz"
    echo "  2) db  - Backup MariaDB database (${MARIADB_DATABASE}) -> *_db_${TIMESTAMP}.sql.gz"
    echo "  3) all - Backup combined stack archive -> *_all_${TIMESTAMP}.tar.gz"
    echo "======================================================================"
    read -rp "Select backup option [1-3]: " CHOICE
    case "$CHOICE" in
        1|www|grav) MODE="www" ;;
        2|db)      MODE="db" ;;
        3|all)     MODE="all" ;;
        *)         log_err "Invalid backup choice selected!"; exit 1 ;;
    esac
fi

run_warning_checks

case "$MODE" in
    www|grav)
        backup_www
        ;;
    db)
        backup_db
        ;;
    all|both)
        backup_all
        ;;
    *)
        log_err "Invalid argument '$MODE'. Usage: $0 [www|db|all]"
        exit 1
        ;;
esac

log_info "Backup operation turn completed."
