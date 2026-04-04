@echo off
SETLOCAL EnableDelayedExpansion

:: --- CONFIGURATION ---
SET SDK_PATH=D:\flutter
SET FLUTTER_EXE=%SDK_PATH%\bin\flutter.bat
SET PROJECT_ROOT=%~dp0..
SET PORT=61725

echo --- PHASE 1: Surgical Unblock...
:: Recursively unblock ps1 files to avoid the Zone.Identifier error
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-ChildItem -Path '%SDK_PATH%' -Recurse -File -Include *.ps1 | Unblock-File -ErrorAction SilentlyContinue"

echo --- PHASE 2: Building Web (Dubai LifeOS Edition)...
cd /d %PROJECT_ROOT%
call %FLUTTER_EXE% clean
call %FLUTTER_EXE% build web --release

echo --- PHASE 3: Hosting on Port %PORT%...
echo Dubai LifeOS Live on: http://127.0.0.1:%PORT%
:: Use individual dart.exe to host (bypass python missing)
D:\flutter\bin\cache\dart-sdk\bin\dart.exe tools/host.dart
