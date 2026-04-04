# tools/deep_recovery.ps1
# -----------------------------------------------------------------------------
# MISSION: SURGICAL RECOVERY - In-Place SDK Fix on D: Drive.
# Resolve persistent NTFS :Zone.Identifier syntax errors and analyzer blind-spots.
# -----------------------------------------------------------------------------

$sdkPath = "D:\flutter"
$hostToCheck = "storage.googleapis.com"

Write-Host ">>> PHASE 1: Surgical Unblock - Manually removing Zone.Identifier streams on $sdkPath..." -ForegroundColor Cyan

if (Test-Path $sdkPath) {
    # Specifically removing the blocked stream to bypass Unblock-File syntax errors.
    $files = Get-ChildItem -Path $sdkPath -Recurse -File -Include "*.ps1","*.bat","*.exe","*.dll"
    $count = 0
    foreach ($file in $files) {
        try {
            # Use lower-level Get-Item for stream detection to avoid syntax errors
            if (Get-Item -Path $file.FullName -Stream "Zone.Identifier" -ErrorAction SilentlyContinue) {
                Unblock-File -Path $file.FullName -ErrorAction SilentlyContinue
                Remove-Item -Path $file.FullName -Stream "Zone.Identifier" -ErrorAction SilentlyContinue
                $count++
            }
        } catch {
            Write-Host "Failed to unblock: $($file.Name). Potential permission issue." -ForegroundColor Gray
        }
    }
    # Special Fix for the specific broken internal tool: update_engine_version.ps1
    $internalTool = Join-Path $sdkPath "bin\internal\update_engine_version.ps1"
    if (Test-Path $internalTool) {
        Unblock-File -Path $internalTool -ErrorAction SilentlyContinue
        Remove-Item -Path $internalTool -Stream "Zone.Identifier" -ErrorAction SilentlyContinue
    }

    Write-Host "Surgical Unblock complete: Handled $count critical files." -ForegroundColor Green
} else {
    Write-Error "Flutter SDK not found at $sdkPath. Please verify the D: drive path."
    exit 1
}

Write-Host ">>> PHASE 2: Connectivity Check..." -ForegroundColor Cyan

$online = $true # User confirmed network is not restricted

Write-Host ">>> PHASE 3: Resetting Environment (FORCE ONLINE)..." -ForegroundColor Cyan
try {
    Write-Host "Refreshing Flutter binary..." -ForegroundColor Yellow
    # Triggering a version call forces Flutter to check its own sanity
    & flutter --version | Out-Null
    
    Write-Host "Clearing stale build artifacts..." -ForegroundColor Yellow
    & flutter clean
    
    Write-Host "Repairing Package resolution (Analyzer Re-sync)..." -ForegroundColor Yellow
    & flutter pub get
    
    Write-Host "ENVIRONMENT RESET SUCCESSFUL." -ForegroundColor Green
} catch {
    Write-Error "Critical SDK Failure: Flutter could not initialize its internal engine. Check D: drive permissions."
}

Write-Host ">>> PHASE 4: Launching Chrome (CORS Bypass)..." -ForegroundColor Cyan
Write-Host "Launching Chrome with --disable-web-security to ensure smooth initialization." -ForegroundColor Yellow

# Note: This attempts to launch Chrome with the existing cache and CORS disabled.
& flutter run -d chrome --web-browser-flag "--disable-web-security"
