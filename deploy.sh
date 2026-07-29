#!/usr/bin/env bash
# ==============================================================================
# Script: deploy.sh
# Description: Deploys Grav CMS user directory (plugins, themes, config) from local
#              development stack to target environment via RSYNC or FTP.
#              Generates a timestamped log file for each execution.
# Usage: ./deploy.sh [OPTIONS] [DESTINATION_PATH]
# Options:
#   -d, --dry-run        Perform a trial run with no changes made
#   -p, --include-pages  Include src/user/pages directory in deployment
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
    # Export non-commented lines from .env
    set -a
    # shellcheck disable=SC1091
    source <(grep -v '^#' "${SCRIPT_DIR}/.env" | grep -v '^\s*$')
    set +a
fi

# Environment-based defaults with fallbacks
SRC_USER_DIR="${DEPLOY_SRC_DIR:-${SCRIPT_DIR}/src/user}"
DEFAULT_DEST_DIR="${DEPLOY_DEST_DIR:-/mnt/1.milkboy/docker/docker-lamp-grav/src/user}"
DEST_DIR="${DEFAULT_DEST_DIR}"
LOG_DIR="${DEPLOY_LOG_DIR:-${SCRIPT_DIR}/logs/deployments}"
MODE="${DEPLOY_MODE:-rsync}"

DRY_RUN=false
INCLUDE_PAGES=false

# Help screen
show_help() {
    echo "Usage: ./deploy.sh [OPTIONS] [DESTINATION_PATH]"
    echo ""
    echo "Options:"
    echo "  -d, --dry-run        Perform a dry-run without copying files"
    echo "  -p, --include-pages  Include src/user/pages/ in the deployment"
    echo "  -f, --ftp            Force FTP deployment mode"
    echo "  -r, --rsync          Force RSYNC local deployment mode"
    echo "  -h, --help           Show this help message"
    echo ""
    echo "Environment Variables (from .env or shell):"
    echo "  DEPLOY_MODE          'rsync' or 'ftp' (Current: ${MODE})"
    echo "  DEPLOY_SRC_DIR       Source path (Current: ${SRC_USER_DIR})"
    echo "  DEPLOY_DEST_DIR      Target path (Current: ${DEST_DIR})"
    echo "  DEPLOY_LOG_DIR       Logs output directory (Current: ${LOG_DIR})"
    echo "  FTP_HOST             FTP server address (Current: ${FTP_HOST:-none})"
    echo "  FTP_USER             FTP username"
    echo "  FTP_REMOTE_DIR       FTP remote path (Current: ${FTP_REMOTE_DIR:-/public_html/user})"
}

# Parse options
while [[ $# -gt 0 ]]; do
    case "$1" in
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
            DEST_DIR="$1"
            shift
            ;;
    esac
done

# Ensure source user directory exists
if [ ! -d "${SRC_USER_DIR}" ]; then
    echo -e "${RED}❌ ERROR: Source directory '${SRC_USER_DIR}' does not exist.${NC}"
    exit 1
fi

# Prepare Log Directory and Log File for this run
mkdir -p "${LOG_DIR}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="${LOG_DIR}/deploy_${TIMESTAMP}.log"

# Setup Dual Output Tee to Log File
exec > >(tee -a "${LOG_FILE}") 2>&1

# Ensure trailing slashes for paths
SRC_USER_DIR="${SRC_USER_DIR%/}/"

echo -e "${BLUE}======================================================================${NC}"
echo -e "${BLUE} 🚀 Grav LAMP Stack - Deployment Tool${NC}"
echo -e "${BLUE}======================================================================${NC}"
echo -e "Timestamp:   $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "Log File:    ${LOG_FILE}"
echo -e "Source:      ${SRC_USER_DIR}"
echo -e "Transport:   ${MODE^^}"

if [ "${MODE}" = "ftp" ]; then
    echo -e "FTP Host:    ${FTP_HOST:-Not Configured}"
    echo -e "FTP User:    ${FTP_USER:-Not Configured}"
    echo -e "Remote Dir:  ${FTP_REMOTE_DIR:-/public_html/user}"
else
    DEST_DIR="${DEST_DIR%/}/"
    echo -e "Destination: ${DEST_DIR}"
fi

if [ "$DRY_RUN" = true ]; then
    echo -e "Mode:        ${YELLOW}DRY RUN (No files will be modified)${NC}"
else
    echo -e "Mode:        ${GREEN}LIVE DEPLOYMENT${NC}"
fi

if [ "$INCLUDE_PAGES" = true ]; then
    echo -e "Pages:       ${YELLOW}INCLUDED${NC}"
else
    echo -e "Pages:       ${BLUE}EXCLUDED (Preserving target pages)${NC}"
fi
echo -e "${BLUE}----------------------------------------------------------------------${NC}"

# ==============================================================================
# Execution Step 1: Synchronize Source to Target
# ==============================================================================
echo -e "${BLUE}ℹ️ Step 1/3: Synchronizing files via ${MODE^^}...${NC}"

if [ "${MODE}" = "rsync" ]; then
    RSYNC_OPTS=("-avz" "--exclude=.git" "--exclude=cache" "--exclude=data")
    if [ "$INCLUDE_PAGES" = false ]; then
        RSYNC_OPTS+=("--exclude=pages")
    fi
    if [ "$DRY_RUN" = true ]; then
        RSYNC_OPTS+=("--dry-run")
    fi

    rsync "${RSYNC_OPTS[@]}" "${SRC_USER_DIR}" "${DEST_DIR}"

elif [ "${MODE}" = "ftp" ]; then
    if [ -z "${FTP_HOST}" ] || [ -z "${FTP_USER}" ]; then
        echo -e "${RED}❌ ERROR: FTP deployment requires FTP_HOST and FTP_USER configured in .env.${NC}"
        exit 1
    fi

    REMOTE_TARGET="${FTP_REMOTE_DIR:-/public_html/user}"
    PORT="${FTP_PORT:-21}"
    USE_SSL="${FTP_SSL:-false}"

    EXCLUDES=("cache" "data" ".git")
    if [ "$INCLUDE_PAGES" = false ]; then
        EXCLUDES+=("pages")
    fi

    # Check for lftp utility
    if command -v lftp >/dev/null 2>&1; then
        echo -e "${BLUE}ℹ️ Using lftp for FTP deployment...${NC}"
        
        EXCLUDE_FLAGS=""
        for exc in "${EXCLUDES[@]}"; do
            EXCLUDE_FLAGS="${EXCLUDE_FLAGS} -X ${exc}/"
        done

        DRY_FLAG=""
        if [ "$DRY_RUN" = true ]; then
            DRY_FLAG="--dry-run"
        fi

        lftp -c "
        set net:timeout 10;
        set net:max-retries 2;
        set ftp:ssl-allow ${USE_SSL};
        open -u '${FTP_USER}','${FTP_PASS}' -p ${PORT} '${FTP_HOST}';
        mirror -R ${DRY_FLAG} --delete ${EXCLUDE_FLAGS} '${SRC_USER_DIR}' '${REMOTE_TARGET}'
        "
    else
        echo -e "${BLUE}ℹ️ Using built-in Python FTP engine for deployment...${NC}"
        
        python3 - "${SRC_USER_DIR}" "${FTP_HOST}" "${PORT}" "${FTP_USER}" "${FTP_PASS}" "${REMOTE_TARGET}" "${DRY_RUN}" "${INCLUDE_PAGES}" "${USE_SSL}" << 'EOF'
import sys, os, ftplib

src_dir, host, port, user, passwd, remote_dir, dry_run, include_pages, use_ssl = sys.argv[1:]
dry_run = dry_run.lower() == 'true'
include_pages = include_pages.lower() == 'true'
use_ssl = use_ssl.lower() == 'true'
port = int(port)

excludes = {'cache', 'data', '.git'}
if not include_pages:
    excludes.add('pages')

print(f"Connecting to FTP server {host}:{port}...")

try:
    if use_ssl:
        ftp = ftplib.FTP_TLS()
        ftp.connect(host, port)
        ftp.login(user, passwd)
        ftp.prot_p()
    else:
        ftp = ftplib.FTP()
        ftp.connect(host, port)
        ftp.login(user, passwd)

    print("FTP connection established.")

    def ensure_remote_dir(path):
        dirs = path.strip('/').split('/')
        current = ''
        for d in dirs:
            if not d: continue
            current += '/' + d
            try:
                ftp.cwd(current)
            except ftplib.error_perm:
                if not dry_run:
                    try:
                        ftp.mkd(current)
                        print(f"[MKDIR] {current}")
                    except Exception as e:
                        pass

    ensure_remote_dir(remote_dir)

    for root, dirs, files in os.walk(src_dir):
        rel_path = os.path.relpath(root, src_dir)
        if rel_path == '.':
            rel_path = ''

        # Filter excluded directories
        parts = rel_path.split(os.sep) if rel_path else []
        if any(p in excludes for p in parts):
            continue
        dirs[:] = [d for d in dirs if d not in excludes]

        target_dir = os.path.join(remote_dir, rel_path).replace('\\', '/')
        ensure_remote_dir(target_dir)

        for fname in files:
            local_file = os.path.join(root, fname)
            remote_file = os.path.join(target_dir, fname).replace('\\', '/')
            
            if dry_run:
                print(f"[DRY-RUN UPLOAD] {local_file} -> {remote_file}")
            else:
                with open(local_file, 'rb') as f:
                    ftp.storbinary(f'STOR {remote_file}', f)
                    print(f"[UPLOAD] {fname} -> {target_dir}")

    ftp.quit()
    print("FTP sync completed.")
except Exception as err:
    print(f"FTP Error: {err}", file=sys.stderr)
    sys.exit(1)
EOF
    fi
fi

if [ "$DRY_RUN" = true ]; then
    echo ""
    echo -e "${YELLOW}✅ Dry run completed. Log saved to: ${LOG_FILE}${NC}"
    exit 0
fi

# ==============================================================================
# Execution Step 2: Invalidation & Permissions
# ==============================================================================
echo ""
echo -e "${BLUE}ℹ️ Step 2/3: Invalidation & Permissions...${NC}"

CONTAINER_NAME=$(docker compose ps -q webserver 2>/dev/null || docker ps -q --filter "name=grav-lamp-web" 2>/dev/null || echo "")

if [ -n "${CONTAINER_NAME}" ]; then
    echo -e "${BLUE}ℹ️ Container detected (${CONTAINER_NAME}). Clearing Grav CMS cache...${NC}"
    if docker exec "${CONTAINER_NAME}" php bin/grav clearcache 2>/dev/null; then
        echo -e "${GREEN}✅ Grav cache cleared successfully!${NC}"
    else
        echo -e "${YELLOW}⚠️ Warning: Unable to run 'bin/grav clearcache' inside container.${NC}"
    fi

    docker exec "${CONTAINER_NAME}" chmod -R 777 /var/www/html/user/config /var/www/html/user/data /var/www/html/cache 2>/dev/null || true
else
    echo -e "${YELLOW}⚠️ Notice: No running local container detected. Remote cache clear skipped.${NC}"
fi

# ==============================================================================
# Execution Step 3: Health Check
# ==============================================================================
echo ""
echo -e "${BLUE}ℹ️ Step 3/3: Running health check...${NC}"
HEALTH_URL="http://localhost"
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
