@echo off
rem Stops the private PostgreSQL cluster of the VKR.
setlocal
cd /d "%~dp0"
call "%~dp0pg_path.bat" || (if /i not "%~1"=="nopause" pause & exit /b 1)
"%PG_BIN%\pg_ctl.exe" -D pgdata stop -m fast
if /i not "%~1"=="nopause" pause
