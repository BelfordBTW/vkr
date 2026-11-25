@echo off
rem Folder with PostgreSQL 18 programs (psql.exe, pg_ctl.exe, initdb.exe, pgbench.exe).
rem Edit this ONE line if PostgreSQL is installed somewhere else,
rem e.g. C:\Program Files\PostgreSQL\18\bin
set PG_BIN=D:\Tools\pgsql\bin
set PG_PORT=5441
if not exist "%PG_BIN%\psql.exe" (
  echo PostgreSQL not found in "%PG_BIN%".
  echo Edit the PG_BIN line in %~dp0pg_path.bat
  exit /b 1
)
exit /b 0
