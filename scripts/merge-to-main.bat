@echo off
rem ==============================================================================
rem Script: merge-to-main.bat
rem Description: Merges a feature branch into main while excluding changes to src/user/pages
rem Usage: scripts\merge-to-main.bat [source-branch]
rem ==============================================================================

setlocal enabledelayedexpansion

set SOURCE_BRANCH=%1

if "%SOURCE_BRANCH%"=="" (
    for /f "tokens=*" %%a in ('git rev-parse --abbrev-ref HEAD 2^>nul') do set SOURCE_BRANCH=%%a
)

if "%SOURCE_BRANCH%"=="" (
    echo [ERROR] Unable to detect source branch.
    echo Usage: scripts\merge-to-main.bat [source-branch]
    exit /b 1
)

if "%SOURCE_BRANCH%"=="main" (
    echo [ERROR] Source branch cannot be 'main'.
    echo Usage: scripts\merge-to-main.bat ^<feature-branch^>
    exit /b 1
)

echo [INFO] Merging branch '%SOURCE_BRANCH%' into 'main' (excluding src/user/pages)...

git checkout main
if errorlevel 1 exit /b 1

for /f "tokens=*" %%i in ('git rev-parse HEAD') do set PREV_COMMIT=%%i

git merge --no-ff --no-commit %SOURCE_BRANCH%
if errorlevel 1 (
    echo [INFO] Resolving merge conflicts...
    git checkout --theirs -- .
    git add -A
)

git restore -s %PREV_COMMIT% --staged --worktree src/user/pages
git clean -fd src/user/pages

git commit -m "Merge branch '%SOURCE_BRANCH%' into main (excluding src/user/pages)"

echo.
echo [SUCCESS] Merged '%SOURCE_BRANCH%' into 'main' with 'src/user/pages' excluded!
echo.
git diff --stat %PREV_COMMIT%..HEAD
