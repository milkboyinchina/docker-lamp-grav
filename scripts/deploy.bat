@echo off
REM Windows CMD / PowerShell Deployment Helper Script
IF NOT EXIST .env (
    echo Creating .env configuration file from env.example...
    copy env.example .env
)

REM Load .env variables in Windows CMD
FOR /F "tokens=1* delims==" %%A IN ('findstr /V "^#" .env') DO SET %%A=%%B

IF "%DEPLOY_SRC_DIR%"=="" SET DEPLOY_SRC_DIR=.\src\user
IF "%DEPLOY_DEST_DIR%"=="" SET DEPLOY_DEST_DIR=C:\docker\docker-lamp-grav\src\user
IF "%DEPLOY_LOG_DIR%"=="" SET DEPLOY_LOG_DIR=.\logs\deployments

IF NOT EXIST %DEPLOY_LOG_DIR% mkdir %DEPLOY_LOG_DIR%

FOR /F "tokens=2 delims==" %%I IN ('wmic os get localdatetime /value') DO SET datetime=%%I
SET TIMESTAMP=%datetime:~0,8%_%datetime:~8,6%
SET LOG_FILE=%DEPLOY_LOG_DIR%\deploy_%TIMESTAMP%.log

echo ====================================================================== >> %LOG_FILE%
echo  Grav LAMP Stack - Windows Deployment Helper >> %LOG_FILE%
echo ====================================================================== >> %LOG_FILE%
echo Timestamp: %date% %time% >> %LOG_FILE%
echo Source:      %DEPLOY_SRC_DIR% >> %LOG_FILE%
echo Destination: %DEPLOY_DEST_DIR% >> %LOG_FILE%

echo ======================================================================
echo  Grav LAMP Stack - Windows Deployment Helper
echo ======================================================================
echo Source:      %DEPLOY_SRC_DIR%
echo Destination: %DEPLOY_DEST_DIR%
echo Log File:    %LOG_FILE%
echo ======================================================================

robocopy %DEPLOY_SRC_DIR% %DEPLOY_DEST_DIR% /E /XD .git cache data pages /XF .gitignore /NP /NDL /NJS /NJH >> %LOG_FILE% 2>&1

echo.
echo Clearing Grav CMS cache inside webserver container...
docker compose exec webserver php bin/grav clearcache >> %LOG_FILE% 2>&1

echo.
echo Deployment finished! Log saved to %LOG_FILE%
pause
