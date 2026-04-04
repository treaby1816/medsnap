# tools/build_and_host.ps1
$sdkPath = "D:\flutter"
$flutterExe = "D:\flutter\bin\flutter.bat"
$projectRoot = Get-Location

Write-Host ">>> STEP 1: Surgical Unblock..." -ForegroundColor Cyan
$files = Get-ChildItem -Path $sdkPath -Recurse -File -Include "*.ps1","*.bat","*.exe"
foreach ($file in $files) {
    if (Get-Item -Path $file.FullName -Stream "Zone.Identifier" -ErrorAction SilentlyContinue) {
        Unblock-File -Path $file.FullName -ErrorAction SilentlyContinue
        Remove-Item -Path $file.FullName -Stream "Zone.Identifier" -ErrorAction SilentlyContinue
    }
}

Write-Host ">>> STEP 2: Building Web (Dubai LifeOS Edition)..." -ForegroundColor Cyan
& $flutterExe clean
& $flutterExe build web --release --web-renderer=html

Write-Host ">>> STEP 3: Hosting on Port 61725..." -ForegroundColor Cyan
Write-Host "Open your browser at: http://127.0.0.1:61725" -ForegroundColor Green
python -m http.server 61725 --directory build/web --bind 127.0.0.1
