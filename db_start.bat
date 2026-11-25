@echo off
rem Starts the private PostgreSQL cluster for the VKR (folder vkr\pgdata, port 5441).
rem Creates the cluster and the rpg_vkr database on first run.
setlocal
cd /d "%~dp0"
call "%~dp0pg_path.bat" || goto fail
if not exist "pgdata\PG_VERSION" (
  echo Creating a new cluster in %~dp0pgdata ...
  "%PG_BIN%\initdb.exe" -D pgdata -U postgres -A trust -E UTF8 --locale=C >nul || goto fail
  >>pgdata\postgresql.conf echo port = %PG_PORT%
  >>pgdata\postgresql.conf echo listen_addresses = '127.0.0.1'
  >>pgdata\postgresql.conf echo shared_buffers = 256MB
  >>pgdata\postgresql.conf echo work_mem = 16MB
  >>pgdata\postgresql.conf echo max_connections = 60
)
"%PG_BIN%\pg_ctl.exe" -D pgdata status >nul 2>nul && (echo PostgreSQL is already running on port %PG_PORT%.) || (
  "%PG_BIN%\pg_ctl.exe" -D pgdata -l pg.log -w start >nul || goto fail
  echo PostgreSQL started on port %PG_PORT%.
)
"%PG_BIN%\psql.exe" -h 127.0.0.1 -p %PG_PORT% -U postgres -tAc "select 1 from pg_database where datname='rpg_vkr'" | findstr 1 >nul || (
  "%PG_BIN%\psql.exe" -h 127.0.0.1 -p %PG_PORT% -U postgres -qc "create database rpg_vkr" || goto fail
  echo Database rpg_vkr created.
)
if /i not "%~1"=="nopause" pause
exit /b 0
:fail
echo FAILED - see pg.log
if /i not "%~1"=="nopause" pause
exit /b 1
