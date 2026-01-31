# Script para executar Flutter com emulador automático
# Uso: powershell -ExecutionPolicy Bypass -File scripts\flutter_run.ps1
# Ou: .\scripts\flutter_run.ps1

param(
    [string]$DeviceId = "",
    [switch]$NoEmulator = $false,
    [switch]$Chrome = $false,
    [switch]$Web = $false
)

Write-Host "`n=== Flutter Run com Emulador Automático ===" -ForegroundColor Cyan

# Se Chrome ou Web foi especificado, executa diretamente
if ($Chrome -or $Web) {
    $targetDevice = if ($Chrome) { "chrome" } else { "chrome" }
    Write-Host "`nExecutando Flutter no Chrome..." -ForegroundColor Yellow
    flutter run -d $targetDevice
    exit $LASTEXITCODE
}

# Função para obter dispositivos Android
function Get-AndroidDevices {
    $devicesOutput = flutter devices 2>&1 | Out-String
    $androidDevices = @()
    
    $lines = $devicesOutput -split "`n"
    foreach ($line in $lines) {
        if ($line -match "android" -and $line -match "•") {
            $parts = $line -split "•" | ForEach-Object { $_.Trim() }
            if ($parts.Count -ge 3) {
                $androidDevices += @{
                    Id = $parts[0].Trim()
                    Name = $parts[1].Trim()
                    Type = $parts[2].Trim()
                }
            }
        }
    }
    
    return $androidDevices
}

# Verifica se há dispositivos Android conectados
Write-Host "`nVerificando dispositivos Android..." -ForegroundColor Yellow
$androidDevices = Get-AndroidDevices

if ($androidDevices.Count -gt 0 -and -not $NoEmulator) {
    Write-Host "✓ Dispositivo Android encontrado!" -ForegroundColor Green
    
    # Usa o dispositivo especificado ou o primeiro disponível
    if ($DeviceId -eq "") {
        $DeviceId = $androidDevices[0].Id
    }
    
    Write-Host "Usando dispositivo: $DeviceId ($($androidDevices[0].Name))" -ForegroundColor Cyan
    Write-Host "`nExecutando Flutter no dispositivo: $DeviceId" -ForegroundColor Yellow
    flutter run -d $DeviceId
    exit $LASTEXITCODE
}

# Se não há dispositivo Android, inicia um emulador
if (-not $NoEmulator) {
    Write-Host "`nNenhum dispositivo Android encontrado. Iniciando emulador..." -ForegroundColor Yellow
    
    # Lista emuladores disponíveis
    $emulatorsOutput = flutter emulators 2>&1 | Out-String
    $emulatorLines = $emulatorsOutput -split "`n" | Where-Object { $_ -match "•" -and $_ -notmatch "Id.*Name" }
    
    if ($emulatorLines.Count -gt 0) {
        $firstEmulator = $emulatorLines[0]
        $parts = $firstEmulator -split "•" | ForEach-Object { $_.Trim() }
        
        if ($parts.Count -ge 2) {
            $emulatorId = $parts[0].Trim()
            $emulatorName = $parts[1].Trim()
            
            Write-Host "Iniciando emulador: $emulatorName ($emulatorId)" -ForegroundColor Cyan
            Start-Process -FilePath "flutter" -ArgumentList "emulators", "--launch", $emulatorId -NoNewWindow -PassThru | Out-Null
            
            Write-Host "Aguardando emulador inicializar..." -ForegroundColor Yellow
            Start-Sleep -Seconds 25
            
            # Verifica se o emulador está pronto
            $maxAttempts = 12
            $attempt = 0
            $emulatorReady = $false
            
            while ($attempt -lt $maxAttempts -and -not $emulatorReady) {
                Start-Sleep -Seconds 5
                $androidDevices = Get-AndroidDevices
                
                if ($androidDevices.Count -gt 0) {
                    $DeviceId = $androidDevices[0].Id
                    $emulatorReady = $true
                    Write-Host "✓ Emulador pronto: $DeviceId" -ForegroundColor Green
                } else {
                    $attempt++
                    Write-Host "Aguardando emulador... ($attempt/$maxAttempts)" -ForegroundColor Yellow
                }
            }
            
            if ($emulatorReady) {
                Write-Host "`nExecutando Flutter no emulador: $DeviceId" -ForegroundColor Yellow
                flutter run -d $DeviceId
                exit $LASTEXITCODE
            } else {
                Write-Host "`n⚠ Emulador não ficou pronto a tempo. Executando flutter run sem dispositivo específico..." -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host "⚠ Nenhum emulador encontrado. Executando flutter run sem dispositivo específico..." -ForegroundColor Yellow
    }
}

# Executa flutter run normalmente
Write-Host "`nExecutando Flutter..." -ForegroundColor Yellow
flutter run
exit $LASTEXITCODE
