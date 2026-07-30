#!/usr/bin/env bash
# ==============================================================================
# Script: upload-article.sh
# Description: Synchronizes local Grav CMS articles/pages (src/user/pages)
#              from development stack to production/target environment via RSYNC or FTP.
# Usage: ./upload-article.sh [OPTIONS] [ARTICLE_NAME_OR_SUBDIR]
# Examples:
#   ./upload-article.sh                      # Interactive prompt to select article
#   ./upload-article.sh 05.faq               # Upload specific article/folder
#   ./upload-article.sh --all                # Upload all articles and pages
#   ./upload-article.sh --dry-run 05.faq     # Dry run trial
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

# Environment-based defaults with fallbacks
SRC_PAGES_DIR="${SCRIPT_DIR}/src/user/pages"
DEFAULT_DEST_DIR="${DEPLOY_DEST_DIR:-/mnt/1.milkboy/docker/docker-lamp-grav/src/user}"
DEST_PAGES_DIR="${DEFAULT_DEST_DIR%/}/pages"
LOG_DIR="${DEPLOY_LOG_DIR:-${SCRIPT_DIR}/logs/deployments}"
MODE="${DEPLOY_MODE:-rsync}"

DRY_RUN=false
UPLOAD_ALL=false
TARGET_ARTICLE=""

# Help screen
show_help() {
    echo "Usage: ./upload-article.sh [OPTIONS] [ARTICLE_NAME_OR_SUBDIR]"
    echo ""
    echo "Options:"
    echo "  -a, --all            Upload ALL articles and pages"
    echo "  -d, --dry-run        Perform a dry-run without copying files"
    echo "  -f, --ftp            Force FTP deployment mode"
    echo "  -r, --rsync          Force RSYNC local deployment mode"
    echo "  -h, --help           Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./upload-article.sh 05.faq              Upload src/user/pages/05.faq"
    echo "  ./upload-article.sh blog/my-article     Upload nested article folder"
    echo "  ./upload-article.sh --all               Upload entire src/user/pages/"
}

# Parse command line options
while [[ $# -gt 0 ]]; do
    case "$1" in
        -a|--all)
            UPLOAD_ALL=true
            shift
            ;;
        -d|--dry-run)
            DRY_RUN=true
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
            TARGET_ARTICLE="$1"
            shift
            ;;
    esac
done

# Ensure source pages directory exists
if [ ! -d "${SRC_PAGES_DIR}" ]; then
    echo -e "${RED}❌ ERROR: Source pages directory '${SRC_PAGES_DIR}' does not exist.${NC}"
    exit 1
fi

# Interactive selection if no article specified and --all not flag
if [ "$UPLOAD_ALL" = false ] && [ -z "${TARGET_ARTICLE}" ]; then
    echo -e "${BLUE}======================================================================${NC}"
    echo -e "${BLUE} 📝 Grav Article / Page Selection${NC}"
    echo -e "${BLUE}======================================================================${NC}"
    echo -e "Available articles / page folders in local environment:"
    echo ""
    
    # List top-level directories in src/user/pages/
    PAGES_LIST=()
    while IFS= read -r -d '' dir; do
        rel_dir="${dir#${SRC_PAGES_DIR}/}"
        PAGES_LIST+=("${rel_dir}")
    done < <(find "${SRC_PAGES_DIR}" -mindepth 1 -maxdepth 2 -type d -not -path '*/.*' -print0 | sort -z)

    if [ ${#PAGES_LIST[@]} -eq 0 ]; then
        echo -e "${YELLOW}No article folders found in ${SRC_PAGES_DIR}.${NC}"
        exit 1
    fi

    echo "  [0] ALL ARTICLES (Upload entire pages directory)"
    idx=1
    for item in "${PAGES_LIST[@]}"; do
        echo "  [${idx}] ${item}"
        ((idx++))
    done
    echo ""

    read -rp "Select article number to upload (0-${#PAGES_LIST[@]}): " selection

    if [ "${selection}" = "0" ]; then
        UPLOAD_ALL=true
    elif [[ "${selection}" =~ ^[0-9]+$ ]] && [ "${selection}" -ge 1 ] && [ "${selection}" -le ${#PAGES_LIST[@]} ]; then
        TARGET_ARTICLE="${PAGES_LIST[$((selection - 1))]}"
    else
        echo -e "${RED}❌ Invalid selection. Exiting.${NC}"
        exit 1
    fi
fi

# Determine source and target sync paths
if [ "$UPLOAD_ALL" = true ]; then
    SYNC_SRC="${SRC_PAGES_DIR}/"
    SYNC_DEST="${DEST_PAGES_DIR}/"
    ARTICLE_DESC="ALL ARTICLES (${SRC_PAGES_DIR})"
else
    # Sanitize subfolder name
    TARGET_ARTICLE="${TARGET_ARTICLE#/}"
    TARGET_ARTICLE="${TARGET_ARTICLE%/}"

    if [ ! -d "${SRC_PAGES_DIR}/${TARGET_ARTICLE}" ]; then
        echo -e "${RED}❌ ERROR: Article folder '${SRC_PAGES_DIR}/${TARGET_ARTICLE}' does not exist.${NC}"
        exit 1
    fi

    SYNC_SRC="${SRC_PAGES_DIR}/${TARGET_ARTICLE}/"
    SYNC_DEST="${DEST_PAGES_DIR}/${TARGET_ARTICLE}/"
    ARTICLE_DESC="ARTICLE [${TARGET_ARTICLE}]"
fi

# Prepare Log Directory and Log File
mkdir -p "${LOG_DIR}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="${LOG_DIR}/upload_article_${TIMESTAMP}.log"

# Setup Dual Output Tee to Log File
exec > >(tee -a "${LOG_FILE}") 2>&1

echo -e "${BLUE}======================================================================${NC}"
echo -e "${BLUE} 🚀 Grav LAMP Stack - Article / Page Uploader${NC}"
echo -e "${BLUE}======================================================================${NC}"
echo -e "Timestamp:   $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "Log File:    ${LOG_FILE}"
echo -e "Article:     ${ARTICLE_DESC}"
echo -e "Transport:   ${MODE^^}"

if [ "${MODE}" = "ftp" ]; then
    echo -e "FTP Host:    ${FTP_HOST:-Not Configured}"
    echo -e "FTP User:    ${FTP_USER:-Not Configured}"
    echo -e "Remote Dir:  ${FTP_REMOTE_DIR:-/public_html/user}/pages"
else
    echo -e "Destination: ${SYNC_DEST}"
fi

if [ "$DRY_RUN" = true ]; then
    echo -e "Mode:        ${YELLOW}DRY RUN (No files will be modified)${NC}"
else
    echo -e "Mode:        ${GREEN}LIVE UPLOAD${NC}"
fi
echo -e "${BLUE}----------------------------------------------------------------------${NC}"

# ==============================================================================
# Execution Step 1: Upload Article Files
# ==============================================================================
echo -e "${BLUE}ℹ️ Step 1/3: Uploading article files via ${MODE^^}...${NC}"

if [ "${MODE}" = "rsync" ]; then
    mkdir -p "${SYNC_DEST}"
    RSYNC_OPTS=("-rlz" "--omit-dir-times" "--no-perms" "--no-owner" "--no-group" "--exclude=.git")
    if [ "$DRY_RUN" = true ]; then
        RSYNC_OPTS+=("--dry-run")
    fi

    rsync "${RSYNC_OPTS[@]}" "${SYNC_SRC}" "${SYNC_DEST}"

elif [ "${MODE}" = "ftp" ]; then
    if [ -z "${FTP_HOST}" ] || [ -z "${FTP_USER}" ]; then
        echo -e "${RED}❌ ERROR: FTP deployment requires FTP_HOST and FTP_USER configured in .env.${NC}"
        exit 1
    fi

    REMOTE_TARGET="${FTP_REMOTE_DIR:-/public_html/user}/pages"
    if [ "$UPLOAD_ALL" = false ]; then
        REMOTE_TARGET="${REMOTE_TARGET}/${TARGET_ARTICLE}"
    fi

    PORT="${FTP_PORT:-21}"
    USE_SSL="${FTP_SSL:-false}"

    if command -v lftp >/dev/null 2>&1; then
        echo -e "${BLUE}ℹ️ Using lftp for FTP article upload...${NC}"
        
        DRY_FLAG=""
        if [ "$DRY_RUN" = true ]; then
            DRY_FLAG="--dry-run"
        fi

        lftp -c "
        set net:timeout 10;
        set net:max-retries 2;
        set ftp:ssl-allow ${USE_SSL};
        open -u '${FTP_USER}','${FTP_PASS}' -p ${PORT} '${FTP_HOST}';
        mirror -R ${DRY_FLAG} --delete -X .git/ '${SYNC_SRC}' '${REMOTE_TARGET}'
        "
    else
        echo -e "${BLUE}ℹ️ Using Python FTP engine for article upload...${NC}"
        
        python3 - "${SYNC_SRC}" "${FTP_HOST}" "${PORT}" "${FTP_USER}" "${FTP_PASS}" "${REMOTE_TARGET}" "${DRY_RUN}" "${USE_SSL}" << 'EOF'
import sys, os, ftplib

src_dir, host, port, user, passwd, remote_dir, dry_run, use_ssl = sys.argv[1:]
dry_run = dry_run.lower() == 'true'
use_ssl = use_ssl.lower() == 'true'
port = int(port)

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
                    except Exception:
                        pass

    ensure_remote_dir(remote_dir)

    for root, dirs, files in os.walk(src_dir):
        rel_path = os.path.relpath(root, src_dir)
        if rel_path == '.':
            rel_path = ''

        dirs[:] = [d for d in dirs if d != '.git']

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
    print("FTP article upload completed.")
except Exception as err:
    print(f"FTP Error: {err}", file=sys.stderr)
    sys.exit(1)
EOF
    fi
fi

if [ "$DRY_RUN" = true ]; then
    echo ""
    echo -e "${YELLOW}✅ Article upload dry-run completed. Log saved to: ${LOG_FILE}${NC}"
    exit 0
fi

# ==============================================================================
# Execution Step 2: Cache Clearing
# ==============================================================================
echo ""
echo -e "${BLUE}ℹ️ Step 2/3: Clearing Grav CMS cache...${NC}"

CONTAINER_NAME=$(docker compose ps -q webserver 2>/dev/null || docker ps -q --filter "name=grav-lamp-web" 2>/dev/null || echo "")

if [ -n "${CONTAINER_NAME}" ]; then
    if docker exec "${CONTAINER_NAME}" php bin/grav clearcache 2>/dev/null; then
        echo -e "${GREEN}✅ Grav cache cleared successfully!${NC}"
    else
        echo -e "${YELLOW}⚠️ Warning: Unable to run 'bin/grav clearcache' inside container.${NC}"
    fi
else
    echo -e "${YELLOW}⚠️ Notice: No running local container detected. Cache clear skipped.${NC}"
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
echo -e "${GREEN} ✅ Article / Page upload successfully finished!${NC}"
echo -e "${GREEN} Log saved to: ${LOG_FILE}${NC}"
echo -e "${GREEN}======================================================================${NC}"
