@echo off
REM Windows CMD/PowerShell - Enter webserver container bash shell
echo 🐚 Entering webserver container bash shell...
echo    Type 'exit' or press Ctrl+D to return to host.
echo.
docker compose exec webserver bash
