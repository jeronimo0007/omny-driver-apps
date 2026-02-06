# Gera os App Bundles (.aab) para publicar User e Driver no Google Play
# Uso: .\build-release-google.ps1
# Pré-requisito: coloque driver-keystore.jks em cada pasta android/app/ (user e driver)

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot

Write-Host "=== Build Omny - User e Driver (Google Play) ===" -ForegroundColor Cyan
Write-Host ""

# 1. User
$userDir = Join-Path $root "driver-app-user"
$userJks = Join-Path $userDir "android\app\driver-keystore.jks"
if (-not (Test-Path $userJks)) {
    Write-Host "[USER] Keystore nao encontrado: android\app\driver-keystore.jks" -ForegroundColor Yellow
    Write-Host "       Copie seu arquivo .jks para: $userDir\android\app\" -ForegroundColor Yellow
    Write-Host ""
} else {
    Write-Host "[USER] Gerando app bundle..." -ForegroundColor Green
    Push-Location $userDir
    flutter build appbundle --release
    if ($LASTEXITCODE -ne 0) { Pop-Location; exit 1 }
    Pop-Location
    $userAab = Join-Path $userDir "build\app\outputs\bundle\release\app-release.aab"
    Write-Host "[USER] OK: $userAab" -ForegroundColor Green
    Write-Host ""
}

# 2. Driver
$driverDir = Join-Path $root "driver-app-driver"
$driverJks = Join-Path $driverDir "android\app\driver-keystore.jks"
if (-not (Test-Path $driverJks)) {
    Write-Host "[DRIVER] Keystore nao encontrado: android\app\driver-keystore.jks" -ForegroundColor Yellow
    Write-Host "         Copie seu arquivo .jks para: $driverDir\android\app\" -ForegroundColor Yellow
    Write-Host ""
} else {
    Write-Host "[DRIVER] Gerando app bundle..." -ForegroundColor Green
    Push-Location $driverDir
    flutter build appbundle --release
    if ($LASTEXITCODE -ne 0) { Pop-Location; exit 1 }
    Pop-Location
    $driverAab = Join-Path $driverDir "build\app\outputs\bundle\release\app-release.aab"
    Write-Host "[DRIVER] OK: $driverAab" -ForegroundColor Green
    Write-Host ""
}

if (-not (Test-Path $userJks) -or -not (Test-Path $driverJks)) {
    Write-Host "Coloque o arquivo driver-keystore.jks nas pastas indicadas e execute o script novamente." -ForegroundColor Yellow
    exit 1
}

Write-Host "=== Concluido ===" -ForegroundColor Cyan
Write-Host "User (passageiro):  driver-app-user\build\app\outputs\bundle\release\app-release.aab"
Write-Host "Driver (motorista):  driver-app-driver\build\app\outputs\bundle\release\app-release.aab"
Write-Host ""
Write-Host "Envie cada .aab no Google Play Console no app correspondente (Produção ou Teste interno)." -ForegroundColor Gray
