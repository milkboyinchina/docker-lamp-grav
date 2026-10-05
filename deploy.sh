#!/usr/bin/env bash
# ==============================================================================
# Script: deploy.sh
# Description: Deploys Grav CMS files from local development stack to target environment via RSYNC or FTP.
#              Supports selective deployment for:
#                1. Pages ONLY (src/user/pages)
#                2. User folder (src/user)
#                3. Whole src folder (src/)
#              Excludes cache directories and clears cache on BOTH source and target.
# Usage: ./deploy.sh [OPTIONS] [DESTINATION_PATH]
# Options:
#   -t, --target SCOPE   Target scope: 'pages' (src/user/pages), 'user' (src/user), or 'src' (whole src folder)
#   --pages-only, --pages Deploy ONLY src/user/pages/ directory
#   --src, --all         Deploy the WHOLE src/ folder
#   -d, --dry-run        Perform a trial run with no changes made
#   -p, --include-pages  Include src/user/pages directory in user deployment
#   -f, --ftp            Use FTP deployment mode
#   -r, --rsync          Use RSYNC local deployment mode (default)
#   -h, --help           Display this help message
# ==============================================================================

set -eo pipefail

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Determine script root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Auto-load .env configuration if present
if [ -f "${SCRIPT_DIR}/.env" ]; then
    set -a
    # shellcheck disable=SC1091
    source <(grep -v '^#' "${SCRIPT_DIR}/.env" | grep -v '^\s*$')
    set +a
fi

# Defaults
MODE="${DEPLOY_MODE:-rsync}"
TARGET_SCOPE="user"
DRY_RUN=false
VERBOSE=false
INCLUDE_PAGES=false
CUSTOM_DEST=""

# Help screen
show_help() {
    echo "Usage: ./deploy.sh [OPTIONS] [DESTINATION_PATH]"
    echo ""
    echo "Target Scope Options:"
    echo "  --pages-only, --pages  Deploy ONLY 'src/user/pages/'"
    echo "  -t, --target user      Deploy 'src/user/' (plugins, themes, config)"
    echo "  --src, --all, -t src   Deploy the WHOLE 'src/' folder"
    echo ""
    echo "General Options:"
    echo "  -v, --verbose          Show progress / detailed transfer output"
    echo "  -d, --dry-run          Perform a dry-run without copying files"
    echo "  -p, --include-pages    Include 'src/user/pages/' during user folder deployment"
    echo "  -f, --ftp              Force FTP deployment mode"
    echo "  -r, --rsync            Force RSYNC local deployment mode (default)"
    echo "  -h, --help             Show this help message"
}

# Parse options
while [[ $# -gt 0 ]]; do
    case "$1" in
        --pages-only|--pages)
            TARGET_SCOPE="pages"
            shift
            ;;
        --src|--all|--root)
            TARGET_SCOPE="src"
            shift
            ;;
        -t|--target)
            TARGET_SCOPE="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -p|--include-pages)
            INCLUDE_PAGES=true
            shift
            ;;
        -f|--ftp)
            MODE="ftp"
            shift
            ;;
        -r|--rsync)
            MODE="rsync"
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        -*)
            echo -e "${RED}❌ ERROR: Unknown option '$1'${NC}"
            show_help
            exit 1
            ;;
        *)
            CUSTOM_DEST="$1"
            shift
            ;;
    esac
done

# Calculate Source & Target Base Paths
# NOTE: No hardcoded host paths here on purpose. If this repository directory
# is renamed, scripts must never recreate the old folder name. The target
# location must come from DEPLOY_TARGET_BASE, DEPLOY_DEST_DIR (.env), or an
# explicit DESTINATION_PATH argument. Fail fast instead of writing to a
# stale default path.
TARGET_BASE_DIR="${DEPLOY_TARGET_BASE:-}"
APP_SRC_BASE="${SRC_PATH:-${SCRIPT_DIR}/src}"
if [ ! -d "${APP_SRC_BASE}" ] && [ -d "${SCRIPT_DIR}/src" ]; then
    APP_SRC_BASE="${SCRIPT_DIR}/src"
fi

# Derive the target base from DEPLOY_DEST_DIR when DEPLOY_TARGET_BASE is unset.
# DEPLOY_DEST_DIR conventionally points at '<base>/src/user[/...]'.
if [ -z "${TARGET_BASE_DIR}" ] && [ -z "${CUSTOM_DEST}" ] && [ -n "${DEPLOY_DEST_DIR:-}" ]; then
    _DEPLOY_DEST_TRIMMED="${DEPLOY_DEST_DIR%/}"
    case "${_DEPLOY_DEST_TRIMMED}" in
        */src/user/pages|*/src/user/pages/*)
            TARGET_BASE_DIR="${_DEPLOY_DEST_TRIMMED%%/src/user/pages*}"
            ;;
        */src/user|*/src/user/*)
            TARGET_BASE_DIR="${_DEPLOY_DEST_TRIMMED%%/src/user*}"
            ;;
        */src|*/src/*)
            TARGET_BASE_DIR="${_DEPLOY_DEST_TRIMMED%%/src*}"
            ;;
    esac
    unset _DEPLOY_DEST_TRIMMED
fi

case "${TARGET_SCOPE}" in
    pages)
        SRC_DEPLOY_DIR="${APP_SRC_BASE}/user/pages"
        DEST_DEPLOY_DIR="${CUSTOM_DEST:-${TARGET_BASE_DIR}/src/user/pages}"
        SCOPE_LABEL="user/pages ONLY"
        ;;
    src|all|root)
        SRC_DEPLOY_DIR="${APP_SRC_BASE}"
        DEST_DEPLOY_DIR="${CUSTOM_DEST:-${TARGET_BASE_DIR}/src}"
        SCOPE_LABEL="WHOLE Grav CMS folder"
        ;;
    user|*)
        SRC_DEPLOY_DIR="${APP_SRC_BASE}/user"
        DEST_DEPLOY_DIR="${CUSTOM_DEST:-${TARGET_BASE_DIR}/src/user}"
        SCOPE_LABEL="user folder (Plugins, Themes, Config)"
        ;;
esac

# Fail fast when no target is configured (rsync mode). Never fall back to a
# hardcoded path, which would recreate a stale folder after a rename.
if [ "${MODE}" = "rsync" ] && [ -z "${CUSTOM_DEST}" ] && [ -z "${TARGET_BASE_DIR}" ]; then
    echo -e "${RED}❌ ERROR: No deployment target configured.${NC}"
    echo -e "Set DEPLOY_TARGET_BASE in .env (e.g. DEPLOY_TARGET_BASE=/mnt/1.milkboy/docker/<stack-dir>)"
    echo -e "or pass an explicit destination: ./deploy.sh --target user /path/to/target"
    exit 1
fi

# Ensure source directory exists
if [ ! -d "${SRC_DEPLOY_DIR}" ]; then
    echo -e "${RED}❌ ERROR: Source directory '${SRC_DEPLOY_DIR}' does not exist.${NC}"
    exit 1
fi

LOG_DIR="${DEPLOY_LOG_DIR:-${SCRIPT_DIR}/logs/deployments}"
mkdir -p "${LOG_DIR}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="${LOG_DIR}/deploy_${TARGET_SCOPE}_${TIMESTAMP}.log"

# Setup Dual Output Tee to Log File
exec > >(tee -a "${LOG_FILE}") 2>&1

# Ensure trailing slashes for paths
SRC_DEPLOY_DIR="${SRC_DEPLOY_DIR%/}/"

echo -e "${BLUE}======================================================================${NC}"
echo -e "${BLUE} 🚀 Grav LAMP Stack - Deployment Tool${NC}"
echo -e "${BLUE}======================================================================${NC}"
echo -e "Timestamp:   $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "Log File:    ${LOG_FILE}"
echo -e "Target Scope:${GREEN} ${SCOPE_LABEL}${NC}"
echo -e "Source:      ${SRC_DEPLOY_DIR}"
echo -e "Transport:   ${MODE^^}"

if [ "${MODE}" = "ftp" ]; then
    echo -e "FTP Host:    ${FTP_HOST:-Not Configured}"
    echo -e "FTP User:    ${FTP_USER:-Not Configured}"
    echo -e "Remote Dir:  ${FTP_REMOTE_DIR:-/public_html}"
else
    DEST_DEPLOY_DIR="${DEST_DEPLOY_DIR%/}/"
    echo -e "Destination: ${DEST_DEPLOY_DIR}"
fi

if [ "$DRY_RUN" = true ]; then
    echo -e "Mode:        ${YELLOW}DRY RUN (No files will be modified)${NC}"
else
    echo -e "Mode:        ${GREEN}LIVE DEPLOYMENT${NC}"
fi

if [ "${TARGET_SCOPE}" = "user" ]; then
    if [ "$INCLUDE_PAGES" = true ]; then
        echo -e "Pages:       ${YELLOW}INCLUDED${NC}"
    else
        echo -e "Pages:       ${BLUE}EXCLUDED (Preserving target pages)${NC}"
    fi
fi
echo -e "${BLUE}----------------------------------------------------------------------${NC}"

# ==============================================================================
# Execution Step 1: Synchronize Source to Target (Excludes Cache Folders)
# ==============================================================================
echo -e "${BLUE}ℹ️ Step 1/3: Synchronizing files via ${MODE^^} (Excludes cache folder)...${NC}"

if [ "${MODE}" = "rsync" ]; then
    RSYNC_OPTS=(
        "-rlz"
        "-u"
        "--omit-dir-times"
        "--no-perms"
        "--no-owner"
        "--no-group"
        "--exclude=.git"
        "--exclude=cache"
        "--exclude=cache/**"
        "--exclude=user/cache"
        "--exclude=user/cache/**"
        "--exclude=.cache"
        "--exclude=data/ai-chatbot/*.log"
    )
    
    if [ "${TARGET_SCOPE}" = "user" ] && [ "$INCLUDE_PAGES" = false ]; then
        RSYNC_OPTS+=("--exclude=pages")
    fi
    if [ "$VERBOSE" = true ]; then
        RSYNC_OPTS+=("-v" "--info=progress2")
    fi
    if [ "$DRY_RUN" = true ]; then
        RSYNC_OPTS+=("--dry-run")
    fi

    rsync "${RSYNC_OPTS[@]}" "${SRC_DEPLOY_DIR}" "${DEST_DEPLOY_DIR}"

elif [ "${MODE}" = "ftp" ]; then
    if [ -z "${FTP_HOST}" ] || [ -z "${FTP_USER}" ]; then
        echo -e "${RED}❌ ERROR: FTP deployment requires FTP_HOST and FTP_USER configured in .env.${NC}"
        exit 1
    fi

    REMOTE_TARGET="${FTP_REMOTE_DIR:-/public_html}"
    PORT="${FTP_PORT:-21}"
    USE_SSL="${FTP_SSL:-false}"

    EXCLUDES=("cache" "user/cache" "data" ".git")
    if [ "${TARGET_SCOPE}" = "user" ] && [ "$INCLUDE_PAGES" = false ]; then
        EXCLUDES+=("pages")
    fi

    # Check for lftp utility
    if command -v lftp >/dev/null 2>&1; then
        echo -e "${BLUE}ℹ️ Using lftp for FTP deployment...${NC}"
        
        EXCLUDE_FLAGS=""
        for exc in "${EXCLUDES[@]}"; do
            EXCLUDE_FLAGS="${EXCLUDE_FLAGS} -X ${exc}/"
        done

        VERBOSE_FLAG=""
        if [ "$VERBOSE" = true ]; then
            VERBOSE_FLAG="--verbose"
        fi

        DRY_FLAG=""
        if [ "$DRY_RUN" = true ]; then
            DRY_FLAG="--dry-run"
        fi

        lftp -c "
        set net:timeout 10;
        set net:max-retries 2;
        set ftp:ssl-allow ${USE_SSL};
        open -u '${FTP_USER}','${FTP_PASS}' -p ${PORT} '${FTP_HOST}';
        mirror -R ${DRY_FLAG} ${VERBOSE_FLAG} --only-newer --delete ${EXCLUDE_FLAGS} '${SRC_DEPLOY_DIR}' '${REMOTE_TARGET}'
        "
    fi
fi

if [ "$DRY_RUN" = true ]; then
    echo ""
    echo -e "${YELLOW}✅ Dry run completed. Log saved to: ${LOG_FILE}${NC}"
    exit 0
fi

# ==============================================================================
# Execution Step 2: Cache Clearing (BOTH Source and Target Environments)
# ==============================================================================
echo ""
echo -e "${BLUE}ℹ️ Step 2/3: Clearing Cache on BOTH Source and Target environments...${NC}"

# 1. Clear Source (Local) Cache
CONTAINER_NAME=$(docker compose ps -q webserver 2>/dev/null || docker ps -q --filter "name=grav-lamp-web" 2>/dev/null || echo "")

if [ -n "${CONTAINER_NAME}" ]; then
    echo -e "${BLUE}ℹ️ Clearing SOURCE Grav CMS cache inside container (${CONTAINER_NAME})...${NC}"
    if docker exec "${CONTAINER_NAME}" php bin/grav clearcache 2>/dev/null; then
        echo -e "${GREEN}✅ Source Grav cache cleared successfully via CLI!${NC}"
    else
        echo -e "${YELLOW}⚠️ Warning: Unable to run 'bin/grav clearcache' inside local container.${NC}"
    fi

    docker exec "${CONTAINER_NAME}" chmod -R 777 /var/www/html/user/config /var/www/html/user/data /var/www/html/cache 2>/dev/null || true
fi

# Physical clean of source cache directory if exists
LOCAL_CACHE_DIR="${SCRIPT_DIR}/src/cache"
if [ -d "${LOCAL_CACHE_DIR}" ]; then
    echo -e "${BLUE}ℹ️ Purging source cache directory files (${LOCAL_CACHE_DIR})...${NC}"
    rm -rf "${LOCAL_CACHE_DIR:?}"/* 2>/dev/null || true
    echo -e "${GREEN}✅ Source cache directory purged successfully!${NC}"
fi

# 2. Clear Target Environment Cache (only when a target base is configured)
if [ -n "${TARGET_BASE_DIR}" ]; then
    TARGET_CACHE_DIR="${TARGET_BASE_DIR}/src/cache"

    if [ -d "${TARGET_CACHE_DIR}" ]; then
        echo -e "${BLUE}ℹ️ Clearing TARGET Grav CMS cache directory (${TARGET_CACHE_DIR})...${NC}"
        rm -rf "${TARGET_CACHE_DIR:?}"/* 2>/dev/null || true
        echo -e "${GREEN}✅ Target Grav cache directory cleared successfully!${NC}"
    fi

    # Touch target system configuration so Grav automatically rebuilds cache
    if [ -f "${TARGET_BASE_DIR}/src/user/config/system.yaml" ]; then
        touch "${TARGET_BASE_DIR}/src/user/config/system.yaml" 2>/dev/null || true
        echo -e "${GREEN}✅ Target system.yaml touched to trigger cache invalidation!${NC}"
    fi
fi

# ==============================================================================
# Execution Step 3: Health Check
# ==============================================================================
echo ""
echo -e "${BLUE}ℹ️ Step 3/3: Running health check...${NC}"
HEALTH_URL="http://localhost:${HTTP_PORT:-80}"
if command -v curl >/dev/null 2>&1; then
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${HEALTH_URL}" || echo "000")
    if [ "${HTTP_STATUS}" = "200" ] || [ "${HTTP_STATUS}" = "301" ] || [ "${HTTP_STATUS}" = "302" ]; then
        echo -e "${GREEN}✅ Health check passed! HTTP status: ${HTTP_STATUS} (${HEALTH_URL})${NC}"
    else
        echo -e "${YELLOW}⚠️ Health check returned HTTP status ${HTTP_STATUS}.${NC}"
    fi
fi

echo ""
echo -e "${GREEN}======================================================================${NC}"
echo -e "${GREEN} ✅ Deployment successfully finished!${NC}"
echo -e "${GREEN} Log saved to: ${LOG_FILE}${NC}"
echo -e "${GREEN}======================================================================${NC}"
