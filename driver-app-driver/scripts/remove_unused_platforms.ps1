# Script para remover pastas de plataformas não utilizadas
# Use: powershell -ExecutionPolicy Bypass -File scripts\remove_unused_platforms.ps1

Write-Host "Removendo pastas de plataformas não utilizadas (linux, windows, macos)..." -ForegroundColor Yellow

$platformsToRemove = @("linux", "windows", "macos")
$removedCount = 0

foreach ($platform in $platformsToRemove) {
    if (Test-Path $platform) {
        try {
            Remove-Item -Recurse -Force $platform -ErrorAction Stop
            Write-Host "  ✓ Removida pasta: $platform" -ForegroundColor Green
            $removedCount++
        } catch {
            Write-Host "  ✗ Erro ao remover pasta $platform : $_" -ForegroundColor Red
        }
    } else {
        Write-Host "  - Pasta $platform não existe" -ForegroundColor Gray
    }
}

if ($removedCount -gt 0) {
    Write-Host "`n✓ $removedCount pasta(s) removida(s) com sucesso!" -ForegroundColor Green
} else {
    Write-Host "`n✓ Nenhuma pasta para remover." -ForegroundColor Green
}
