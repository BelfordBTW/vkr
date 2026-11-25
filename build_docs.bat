@echo off
rem Rebuilds the VKR documents: thesis text, annotation, last page and the presentation.
rem Does not need PostgreSQL (uses the saved results in bench\ and figures\).
setlocal
cd /d "%~dp0"
set PYTHONIOENCODING=utf-8
python thesis\build_thesis.py || goto fail
python ..\tools\build_vkr_docs.py || goto fail
python build_deck.py || goto fail
echo.
echo VKR documents are in %~dp0 and %~dp0docs
if /i not "%~1"=="nopause" pause
exit /b 0
:fail
echo.
echo BUILD FAILED - see the messages above. Missing libraries? Run setup.bat once.
if /i not "%~1"=="nopause" pause
exit /b 1
