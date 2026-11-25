@echo off
rem Load testing of the VKR database (about 3-4 minutes) and regeneration of the figures.
rem Needs a built database (build_db.bat). Temporarily drops and recreates the extra indexes.
rem Results: bench\results.json, bench\results_extra.json; figures: figures\*.png
rem NOTE: new runs give slightly different timings. Tables and charts in the thesis update
rem automatically, but numbers written in the thesis sentences (vkr\thesis\t3_ch3.py) do not.
setlocal
cd /d "%~dp0"
call "%~dp0db_start.bat" nopause || goto fail
call "%~dp0pg_path.bat" || goto fail
set PYTHONIOENCODING=utf-8
python bench\bench.py "%PG_BIN%" || goto fail
python bench\extra.py "%PG_BIN%" || goto fail
python figures\make_figures.py "%PG_BIN%" || goto fail
echo.
echo Benchmark done. Run build_docs.bat to put the new numbers into the thesis and the presentation.
if /i not "%~1"=="nopause" pause
exit /b 0
:fail
echo.
echo FAILED - see the messages above.
if /i not "%~1"=="nopause" pause
exit /b 1
