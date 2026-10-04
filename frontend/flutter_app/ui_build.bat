@echo off
REM TailorSync UI redesign - clean release build. Output in ui_build_log.txt
cd /d "%~dp0"
set LOG=%~dp0ui_build_log.txt
echo === START %date% %time% === > "%LOG%"
call flutter clean >> "%LOG%" 2>&1
call flutter pub get >> "%LOG%" 2>&1
echo === BUILD APK (fat) === >> "%LOG%"
call flutter build apk --release >> "%LOG%" 2>&1
echo === BUILD APK (split per ABI) === >> "%LOG%"
call flutter build apk --release --split-per-abi >> "%LOG%" 2>&1
echo === OUTPUTS === >> "%LOG%"
dir build\app\outputs\flutter-apk\*.apk >> "%LOG%" 2>&1
echo === DONE %date% %time% === >> "%LOG%"
