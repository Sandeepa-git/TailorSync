@echo off
REM Foundry agent + live API test. No venv needed.
cd /d "%~dp0"
set PY=python
where py >nul 2>nul && set PY=py
echo Installing test packages for your user (one time)...
%PY% -m pip install --user --quiet azure-ai-projects azure-identity openai requests
echo.
%PY% agent_test_standalone.py %*
echo.
pause
