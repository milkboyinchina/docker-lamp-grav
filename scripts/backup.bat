@echo off
REM ==============================================================================
REM Windows CMD / PowerShell Backup Script for WWW Site Files & MariaDB
REM ==============================================================================

setlocal enabledelayedexpansion

REM Set default values
set "BACKUP_DIR=backups"
set "BACKUP_PREFIX=grav_lamp"
set "SRC_PATH=src"
set "LOGS_BACKUP_PATH=logs\backup.log"
set "MARIADB_DATABASE=grav_db"
set "MARIADB_USER=grav_user"
set "MARIADB_PASSWORD=change_this_user_password"
set "ENV_FOUND=true"

REM Read configuration from .env file if present
if not exist .env (
    set "ENV_FOUND=false"
) else (
    for /f "usebackq tokens=1,* delims==" %%A in (`findstr /v "^#" .env`) do (
        set "KEY=%%A"
        set "VAL=%%B"
        if "!KEY!"=="BACKUP_DIR" set "BACKUP_DIR=%%B"
        if "!KEY!"=="BACKUP_PREFIX" set "BACKUP_PREFIX=%%B"
        if "!KEY!"=="SRC_PATH" set "SRC_PATH=%%B"
        if "!KEY!"=="LOGS_BACKUP_PATH" set "LOGS_BACKUP_PATH=%%B"
        if "!KEY!"=="MARIADB_DATABASE" set "MARIADB_DATABASE=%%B"
        if "!KEY!"=="MARIADB_USER" set "MARIADB_USER=%%B"
        if "!KEY!"=="MARIADB_PASSWORD" set "MARIADB_PASSWORD=%%B"
    )
)

REM Generate date/time timestamp (YYYYMMDD_HHMMSS)
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value 2^>nul') do set "LDT=%%I"
if defined LDT (
    set "TIMESTAMP=!LDT:~0,8!_!LDT:~8,6!"
) else (
    set "TIMESTAMP=%date:~-4%%date:~4,2%%date:~7,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
    set "TIMESTAMP=!TIMESTAMP: =0!"
)

REM Ensure backup target and log directories exist
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"
for %%F in ("%LOGS_BACKUP_PATH%") do if not exist "%%~dpF" mkdir "%%~dpF"

REM Pre-flight Warnings
if "%ENV_FOUND%"=="false" (
    echo [WARNING] .env configuration file not found! Using fallback defaults.
    echo [%date% %time%] [WARNING] .env configuration file not found! >> "%LOGS_BACKUP_PATH%"
)

set "MODE=%~1"

if "%MODE%"=="" (
    echo ======================================================================
    echo    Docker LAMP Stack Backup Helper (Windows)
    echo ======================================================================
    echo   1) www - Backup WWW site files (%SRC_PATH%) -^> *_www_%TIMESTAMP%.zip
    echo   2) db  - Backup MariaDB database (%MARIADB_DATABASE%) -^> *_db_%TIMESTAMP%.sql
    echo   3) all - Backup combined stack archive -^> *_all_%TIMESTAMP%.zip
    echo ======================================================================
    set /p CHOICE="Select backup option [1-3]: "
    if "!CHOICE!"=="1" set "MODE=www"
    if "!CHOICE!"=="2" set "MODE=db"
    if "!CHOICE!"=="3" set "MODE=all"
    if "!CHOICE!"=="www" set "MODE=www"
    if "!CHOICE!"=="grav" set "MODE=www"
    if "!CHOICE!"=="db" set "MODE=db"
    if "!CHOICE!"=="all" set "MODE=all"
)

if "%MODE%"=="www" goto do_www
if "%MODE%"=="grav" goto do_www
if "%MODE%"=="db" goto do_db
if "%MODE%"=="all" goto do_all

echo [ERROR] Invalid argument '%MODE%'. Usage: %0 [www^|db^|all]
echo [%date% %time%] [ERROR] Invalid argument '%MODE%'. >> "%LOGS_BACKUP_PATH%"
goto end

:do_www
echo [INFO] Backing up WWW site files from '%SRC_PATH%'...
echo [%date% %time%] [INFO] Backing up WWW site files from '%SRC_PATH%'... >> "%LOGS_BACKUP_PATH%"
if not exist "%SRC_PATH%" (
    echo [ERROR] Source directory '%SRC_PATH%' does not exist!
    echo [%date% %time%] [ERROR] Source directory '%SRC_PATH%' does not exist! >> "%LOGS_BACKUP_PATH%"
    goto end
)
set "OUT_FILE=%BACKUP_DIR%\%BACKUP_PREFIX%_www_%TIMESTAMP%.zip"
powershell -Command "Compress-Archive -Path '%SRC_PATH%\*' -DestinationPath '%OUT_FILE%' -Force"
echo [SUCCESS] WWW site files backed up to: %OUT_FILE%
echo [%date% %time%] [SUCCESS] WWW site files backed up to: %OUT_FILE% >> "%LOGS_BACKUP_PATH%"
goto end

:do_db
echo [INFO] Backing up MariaDB database '%MARIADB_DATABASE%'...
echo [%date% %time%] [INFO] Backing up MariaDB database '%MARIADB_DATABASE%'... >> "%LOGS_BACKUP_PATH%"
set "OUT_FILE=%BACKUP_DIR%\%BACKUP_PREFIX%_db_%TIMESTAMP%.sql"
docker compose exec -T db mariadb-dump -u%MARIADB_USER% -p%MARIADB_PASSWORD% %MARIADB_DATABASE% > "%OUT_FILE%" 2>nul
if %errorlevel% neq 0 (
    docker compose exec -T db mysqldump -u%MARIADB_USER% -p%MARIADB_PASSWORD% %MARIADB_DATABASE% > "%OUT_FILE%" 2>nul
)
if exist "%OUT_FILE%" (
    echo [SUCCESS] MariaDB database backed up to: %OUT_FILE%
    echo [%date% %time%] [SUCCESS] MariaDB database backed up to: %OUT_FILE% >> "%LOGS_BACKUP_PATH%"
) else (
    echo [WARNING] Container 'db' is not running or dump failed!
    echo [%date% %time%] [WARNING] Container 'db' is not running or dump failed! >> "%LOGS_BACKUP_PATH%"
)
goto end

:do_all
echo [INFO] Creating full stack combined backup archive...
echo [%date% %time%] [INFO] Creating full stack combined backup archive... >> "%LOGS_BACKUP_PATH%"
set "OUT_FILE=%BACKUP_DIR%\%BACKUP_PREFIX%_all_%TIMESTAMP%.zip"
set "TEMP_SQL=%BACKUP_DIR%\temp_dump.sql"

if exist "%SRC_PATH%" (
    docker compose exec -T db mariadb-dump -u%MARIADB_USER% -p%MARIADB_PASSWORD% %MARIADB_DATABASE% > "%TEMP_SQL%" 2>nul
    powershell -Command "Compress-Archive -Path '%SRC_PATH%\*', '%TEMP_SQL%' -DestinationPath '%OUT_FILE%' -Force" 2>nul
    if exist "%TEMP_SQL%" del "%TEMP_SQL%"
    echo [SUCCESS] Combined full stack backup created to: %OUT_FILE%
    echo [%date% %time%] [SUCCESS] Combined full stack backup created to: %OUT_FILE% >> "%LOGS_BACKUP_PATH%"
) else (
    echo [ERROR] Source directory '%SRC_PATH%' missing.
    echo [%date% %time%] [ERROR] Source directory '%SRC_PATH%' missing. >> "%LOGS_BACKUP_PATH%"
)
goto end

:end
echo.
echo [%date% %time%] [INFO] Backup process completed. >> "%LOGS_BACKUP_PATH%"
echo Backup process finished. See logs at: %LOGS_BACKUP_PATH%
pause
