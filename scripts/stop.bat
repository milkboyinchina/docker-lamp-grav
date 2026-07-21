@echo off
REM Windows CMD / PowerShell Docker Stack Stop Script
echo Stopping Docker LAMP Stack containers...
docker compose stop
echo.
echo Containers stopped successfully.
pause
