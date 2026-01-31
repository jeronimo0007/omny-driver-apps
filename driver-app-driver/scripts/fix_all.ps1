# Script completo para aplicar todas as correções necessárias
# Execute: powershell -ExecutionPolicy Bypass -File scripts\fix_all.ps1

Write-Host "`n=== Aplicando todas as correções ===" -ForegroundColor Cyan

# 1. Obter dependências
Write-Host "`n1. Obtendo dependências..." -ForegroundColor Yellow
& "$PSScriptRoot\pub_get_with_fix.ps1"
if ($LASTEXITCODE -ne 0) {
    Write-Host "Erro ao obter dependências!" -ForegroundColor Red
    exit 1
}

# 2. Corrigir plugins Android
Write-Host "`n2. Corrigindo plugins Android..." -ForegroundColor Yellow
& "$PSScriptRoot\fix_android_plugins.ps1"

# 3. contacts_service removido - substituído por flutter_contacts (não precisa de correção)
# Write-Host "`n3. Corrigindo contacts_service..." -ForegroundColor Yellow
# & "$PSScriptRoot\fix_contacts_service.ps1"

Write-Host "`n=== Todas as correções aplicadas! ===" -ForegroundColor Green
Write-Host "Agora você pode executar: flutter run ou .\run.ps1`n" -ForegroundColor Cyan
