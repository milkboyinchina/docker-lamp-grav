#!/usr/bin/env bash
# ==============================================================================
# Script: merge-to-main.sh
# Description: Merges a feature branch into main while excluding changes to src/user/pages
# Usage: ./merge-to-main.sh [source-branch]
# ==============================================================================

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Determine current branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")

# Determine source branch from parameter or default to current branch
SOURCE_BRANCH="${1:-$CURRENT_BRANCH}"

if [ -z "$SOURCE_BRANCH" ]; then
    echo -e "${RED}❌ ERROR: Unable to detect source branch.${NC}"
    echo "Usage: ./merge-to-main.sh [source-branch]"
    exit 1
fi

if [ "$SOURCE_BRANCH" = "main" ]; then
    echo -e "${RED}❌ ERROR: Source branch cannot be 'main'. Please switch to your feature branch or specify it as an argument.${NC}"
    echo "Usage: ./merge-to-main.sh <feature-branch>"
    exit 1
fi

# Check for uncommitted changes
if [ -n "$(git status --porcelain)" ]; then
    echo -e "${YELLOW}⚠️ WARNING: You have uncommitted changes in your working directory.${NC}"
    echo "Please commit or stash your changes before merging."
    git status -s
    exit 1
fi

echo -e "${BLUE}ℹ️ Starting merge of branch '${SOURCE_BRANCH}' into 'main' (excluding src/user/pages)...${NC}"

# Ensure source branch exists
if ! git rev-parse --verify "$SOURCE_BRANCH" >/dev/null 2>&1; then
    echo -e "${RED}❌ ERROR: Branch '$SOURCE_BRANCH' does not exist.${NC}"
    exit 1
fi

# Switch to main branch
echo -e "${BLUE}ℹ️ Checking out 'main' branch...${NC}"
git checkout main

# Save current commit on main
PREV_COMMIT=$(git rev-parse HEAD)

echo -e "${BLUE}ℹ️ Merging '${SOURCE_BRANCH}' into 'main'...${NC}"
if ! git merge --no-ff --no-commit "$SOURCE_BRANCH"; then
    echo -e "${YELLOW}⚠️ Resolving merge conflicts...${NC}"
    git checkout --theirs -- . 2>/dev/null || true
    git add -A
fi

# Restore src/user/pages/ to pre-merge state from main (completely excluding any changes/additions)
echo -e "${BLUE}ℹ️ Restoring 'src/user/pages' to previous main state...${NC}"
git restore -s "$PREV_COMMIT" --staged --worktree src/user/pages
git clean -fd src/user/pages

# Commit the merge
COMMIT_MSG="Merge branch '$SOURCE_BRANCH' into main (excluding src/user/pages)"
echo -e "${BLUE}ℹ️ Committing merge...${NC}"
git commit -m "$COMMIT_MSG"

echo -e "${GREEN}✅ SUCCESS: Merged '$SOURCE_BRANCH' into 'main' with 'src/user/pages' excluded!${NC}"
echo ""
echo "Files merged in this commit:"
git diff --stat "${PREV_COMMIT}..HEAD"
