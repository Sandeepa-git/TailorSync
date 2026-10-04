@echo off
REM Push the committed UI redesign to GitHub (uses your Windows git credentials)
cd /d "%~dp0..\.."
git push origin main
pause
