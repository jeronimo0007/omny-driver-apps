# Script que executa flutter pub get e depois aplica as correções automaticamente
# Use este script ao invés de "flutter pub get" diretamente

Write-Host "Executando flutter pub get..." -ForegroundColor Cyan
flutter pub get

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nRemovendo pastas de plataformas não utilizadas (linux, windows, macos)..." -ForegroundColor Yellow
    $platformsToRemove = @("linux", "windows", "macos")
    foreach ($platform in $platformsToRemove) {
        if (Test-Path $platform) {
            Remove-Item -Recurse -Force $platform -ErrorAction SilentlyContinue
            Write-Host "  ✓ Removida pasta: $platform" -ForegroundColor Green
        }
    }
    
    Write-Host "`nAplicando correções nos plugins..." -ForegroundColor Cyan
    & "$PSScriptRoot\fix_android_plugins.ps1"
    # contacts_service removido - substituído por flutter_contacts (não precisa de correção)
    # & "$PSScriptRoot\fix_contacts_service.ps1"
} else {
    Write-Host "Erro ao executar flutter pub get!" -ForegroundColor Red
    exit 1
}
