@echo off
REM Windows CMD / PowerShell Article Uploader Helper Script
IF NOT EXIST .env (
    echo Creating .env configuration file from env.example...
    copy env.example .env
)

FOR /F "tokens=1* delims==" %%A IN ('findstr /V "^#" .env') DO SET %%A=%%B

IF "%DEPLOY_SRC_DIR%"=="" SET DEPLOY_SRC_DIR=.\src\user
IF "%DEPLOY_DEST_DIR%"=="" SET DEPLOY_DEST_DIR=C:\docker\docker-lamp-grav\src\user
IF "%DEPLOY_LOG_DIR%"=="" SET DEPLOY_LOG_DIR=.\logs\deployments

SET SRC_PAGES=%DEPLOY_SRC_DIR%\pages
SET DEST_PAGES=%DEPLOY_DEST_DIR%\pages

IF NOT EXIST %DEPLOY_LOG_DIR% mkdir %DEPLOY_LOG_DIR%

FOR /F "tokens=2 delims==" %%I IN ('wmic os get localdatetime /value') DO SET datetime=%%I
SET TIMESTAMP=%datetime:~0,8%_%datetime:~8,6%
SET LOG_FILE=%DEPLOY_LOG_DIR%\upload_article_%TIMESTAMP%.log

echo ====================================================================== >> %LOG_FILE%
echo  Grav LAMP Stack - Windows Article Uploader >> %LOG_FILE%
echo ====================================================================== >> %LOG_FILE%
echo Timestamp: %date% %time% >> %LOG_FILE%
echo Source:      %SRC_PAGES% >> %LOG_FILE%
echo Destination: %DEST_PAGES% >> %LOG_FILE%

echo ======================================================================
echo  Grav LAMP Stack - Windows Article Uploader
echo ======================================================================
echo Source:      %SRC_PAGES%
echo Destination: %DEST_PAGES%
echo Log File:    %LOG_FILE%
echo ======================================================================

robocopy %SRC_PAGES% %DEST_PAGES% %1 /E /XD .git /NP /NDL /NJS /NJH >> %LOG_FILE% 2>&1

echo.
echo Clearing Grav CMS cache inside webserver container...
docker compose exec webserver php bin/grav clearcache >> %LOG_FILE% 2>&1

echo.
echo Article upload finished! Log saved to %LOG_FILE%
pause
