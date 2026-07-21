@echo off
REM Windows CMD / PowerShell Docker Stack Quick Start Script
IF NOT EXIST .env (
    echo Creating .env configuration file from env.example...
    copy env.example .env
)
echo Starting Docker LAMP Stack...
docker compose up -d
echo.
echo Stack is running! Access your site at http://localhost
pause
