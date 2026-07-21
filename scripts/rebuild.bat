@echo off
REM Windows CMD / PowerShell Docker Stack Rebuild Script
IF NOT EXIST .env (
    echo Creating .env configuration file from env.example...
    copy env.example .env
)
echo Rebuilding Docker LAMP Stack image...
docker compose up -d --build --no-cache
echo.
echo Rebuild complete! Access your site at http://localhost
pause
