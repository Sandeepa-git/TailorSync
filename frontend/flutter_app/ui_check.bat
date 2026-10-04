@echo off
REM TailorSync UI redesign - dependency, analyzer and test check.
REM Double-click this file. Output is written to ui_check_log.txt next to it.
cd /d "%~dp0"
set LOG=%~dp0ui_check_log.txt
echo === START %date% %time% === > "%LOG%"
call flutter --version >> "%LOG%" 2>&1
echo === PUB GET === >> "%LOG%"
call flutter pub get >> "%LOG%" 2>&1
echo === ANALYZE === >> "%LOG%"
call flutter analyze --no-fatal-infos --no-fatal-warnings lib test >> "%LOG%" 2>&1
echo === TEST === >> "%LOG%"
call flutter test >> "%LOG%" 2>&1
echo === DONE %date% %time% === >> "%LOG%"
