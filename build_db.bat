@echo off
rem Recreates the whole VKR database from scratch (about 45 seconds):
rem schema, functions, indexes, reference data and the load-test data set.
rem WARNING: drops and recreates schema "game" in database rpg_vkr.
setlocal
cd /d "%~dp0"
call "%~dp0db_start.bat" nopause || goto fail
call "%~dp0pg_path.bat" || goto fail
set PGCLIENTENCODING=UTF8
set PGOPTIONS=-c client_min_messages=warning
for %%F in (01_schema 02_functions 03_indexes 04_seed 05_loadtest) do (
  echo == sql\%%F.sql
  "%PG_BIN%\psql.exe" -h 127.0.0.1 -p %PG_PORT% -U postgres -d rpg_vkr -v ON_ERROR_STOP=1 -q -f "sql\%%F.sql" >nul || goto fail
)
echo.
echo Database rpg_vkr rebuilt.
if /i not "%~1"=="nopause" pause
exit /b 0
:fail
echo.
echo BUILD FAILED - see the messages above.
if /i not "%~1"=="nopause" pause
exit /b 1
