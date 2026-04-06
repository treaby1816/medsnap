# extract_sha1.ps1
# Script to extract SHA-1 fingerprint from the Keystore for Firebase Configuration

$keystorePath = "android/app/upload-keystore.jks"
$storePass = "vailmeds2026"
$alias = "upload"

if (Test-Path $keystorePath) {
    Write-Host "--- VailMeds v2 Keystore Scanner ---" -ForegroundColor Cyan
    keytool -list -v -keystore $keystorePath -alias $alias -storepass $storePass | Select-String "SHA1:"
    Write-Host "`nCopy this fingerprint to Firebase Console -> Project Settings -> General -> Android app -> Add fingerprint" -ForegroundColor Green
} else {
    Write-Host "ERROR: upload-keystore.jks not found at $keystorePath" -ForegroundColor Red
}
