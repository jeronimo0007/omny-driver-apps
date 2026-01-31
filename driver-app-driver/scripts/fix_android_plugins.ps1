# Script permanente para corrigir plugins Android
# Execute: powershell -ExecutionPolicy Bypass -File scripts\fix_android_plugins.ps1

$pubCache = "$env:LOCALAPPDATA\Pub\Cache\hosted\pub.dev"

# Função para remover atributo package do AndroidManifest.xml
function Remove-PackageFromManifest {
    param([string]$pluginPath)
    
    $manifestPath = Join-Path $pluginPath "android\src\main\AndroidManifest.xml"
    if (-not (Test-Path $manifestPath)) { return $false }
    
    $content = Get-Content $manifestPath -Raw -ErrorAction SilentlyContinue
    if (-not $content) { return $false }
    
    # Verifica se tem atributo package
    if ($content -notmatch 'package="[^"]*"') { return $false }
    
    # Remove o atributo package
    $newContent = $content -replace '\s+package="[^"]*"', ''
    Set-Content -Path $manifestPath -Value $newContent -NoNewline -ErrorAction SilentlyContinue
    
    return $true
}

Write-Host "`n=== Corrigindo plugins Android ===" -ForegroundColor Cyan

$namespacePlugins = @{
    "cashfree_pg" = "com.cashfree.pg"
    # "contacts_service" removido - substituído por flutter_contacts
    "permission_handler_android" = "com.baseflow.permissionhandler"
    "razorpay_flutter" = "com.razorpay.razorpay_flutter"
}

$firebasePlugins = @(
    "firebase_auth",
    "firebase_core", 
    "firebase_database",
    "firebase_messaging"
)

$fixed = 0

Write-Host "`nAdicionando namespaces..." -ForegroundColor Yellow
foreach ($plugin in $namespacePlugins.Keys) {
    $pluginDirs = Get-ChildItem -Path $pubCache -Filter "${plugin}-*" -Directory -ErrorAction SilentlyContinue
    foreach ($dir in $pluginDirs) {
        $buildGradle = Join-Path $dir.FullName "android\build.gradle"
        if (-not (Test-Path $buildGradle)) { continue }
        
        $lines = Get-Content $buildGradle -ErrorAction SilentlyContinue
        if (-not $lines) { continue }
        
        $hasNamespace = $false
        foreach ($line in $lines) {
            if ($line -match "namespace") { $hasNamespace = $true; break }
        }
        if ($hasNamespace) { continue }
        
        $newLines = @()
        $namespace = $namespacePlugins[$plugin]
        $added = $false
        foreach ($line in $lines) {
            $newLines += $line
            if (-not $added -and $line -match "android\s*\{") {
                $newLines += "    namespace `"$namespace`""
                $added = $true
            }
        }
        
        if ($added) {
            Set-Content -Path $buildGradle -Value ($newLines -join "`n") -ErrorAction SilentlyContinue
            Write-Host "  ✓ Namespace: $(Split-Path $dir -Leaf)" -ForegroundColor Green
            $fixed++
        }
        
        # Remove package do AndroidManifest se existir
        if (Remove-PackageFromManifest -pluginPath $dir.FullName) {
            $fixed++
        }
    }
}

Write-Host "`nAdicionando buildConfig..." -ForegroundColor Yellow
foreach ($plugin in $firebasePlugins) {
    $pluginDirs = Get-ChildItem -Path $pubCache -Filter "${plugin}-*" -Directory -ErrorAction SilentlyContinue
    foreach ($dir in $pluginDirs) {
        $buildGradle = Join-Path $dir.FullName "android\build.gradle"
        if (-not (Test-Path $buildGradle)) { continue }
        
        $lines = Get-Content $buildGradle -ErrorAction SilentlyContinue
        if (-not $lines) { continue }
        
        $hasBuildFeatures = $false
        foreach ($line in $lines) {
            if ($line -match "buildFeatures") { $hasBuildFeatures = $true; break }
        }
        if ($hasBuildFeatures) { continue }
        
        $newLines = @()
        $added = $false
        foreach ($line in $lines) {
            $newLines += $line
            if (-not $added -and $line -match "compileSdkVersion") {
                $newLines += '  buildFeatures {'
                $newLines += '      buildConfig true'
                $newLines += '  }'
                $added = $true
            }
        }
        
        if ($added) {
            Set-Content -Path $buildGradle -Value ($newLines -join "`n") -ErrorAction SilentlyContinue
            Write-Host "  ✓ BuildConfig: $(Split-Path $dir -Leaf)" -ForegroundColor Green
            $fixed++
        }
    }
}

Write-Host "`nCorrigindo cashfree_pg (repositorio Maven)..." -ForegroundColor Yellow
$cashfreeDirs = Get-ChildItem -Path $pubCache -Filter "cashfree_pg-*" -Directory -ErrorAction SilentlyContinue
foreach ($dir in $cashfreeDirs) {
    $buildGradle = Join-Path $dir.FullName "android\build.gradle"
    if (-not (Test-Path $buildGradle)) { continue }
    
    $content = Get-Content $buildGradle -Raw -ErrorAction SilentlyContinue
    if (-not $content) { continue }
    
    $modified = $false
    
    # Remove repositorio Cashfree do rootProject.allprojects
    if ($content -match "rootProject\.allprojects.*?maven.*?cashfree") {
        $content = $content -replace "(rootProject\.allprojects \{\s+repositories \{\s+google\(\)\s+mavenCentral\(\))\s+maven \{ url 'https://maven\.cashfree\.com/release'\}", '$1'
        $modified = $true
    }
    
    # Garante que o modulo especifico tem repositorios com Maven Central primeiro
    if ($content -notmatch "apply plugin: 'com\.android\.library'\s+repositories") {
        $repositoriesBlock = "`n`nrepositories {`n    mavenCentral()`n    google()`n    jcenter()`n    maven { url 'https://maven.cashfree.com/release'}`n}"
        $content = $content -replace "(apply plugin: 'com\.android\.library')", "`$1$repositoriesBlock"
        $modified = $true
    }
    
    # Adiciona configuracao de resolucao para forcar Maven Central para volley
    if ($content -notmatch "eachDependency.*com\.android\.volley") {
        $resolutionBlock = "`n`nconfigurations.all {`n    resolutionStrategy {`n        eachDependency { DependencyResolveDetails details ->`n            if (details.requested.group == 'com.android.volley' && details.requested.name == 'volley') {`n                details.useTarget group: 'com.android.volley', name: 'volley', version: '1.1.1'`n                details.because 'Cashfree repository returns 403'`n            }`n        }`n    }`n}"
        $content = $content -replace "(apply plugin: 'com\.android\.library')", "`$1$resolutionBlock"
        $modified = $true
    }
    
    if ($modified) {
        Set-Content -Path $buildGradle -Value $content -NoNewline -ErrorAction SilentlyContinue
        Write-Host "  OK Repositorios corrigidos: $(Split-Path $dir -Leaf)" -ForegroundColor Green
        $fixed++
    }
}

# Corrige o build.gradle principal para remover Cashfree do allprojects
$mainBuildGradle = Join-Path $PSScriptRoot "..\android\build.gradle"
if (Test-Path $mainBuildGradle) {
    $mainContent = Get-Content $mainBuildGradle -Raw -ErrorAction SilentlyContinue
    if ($mainContent -match "allprojects.*?maven.*?cashfree") {
        $mainContent = $mainContent -replace "(allprojects \{\s+repositories \{\s+google\(\)\s+mavenCentral\(\))\s+// Reposit[^\n]*\s+maven \{\s+url 'https://maven\.cashfree\.com/release'\s+\}", '$1'
        Set-Content -Path $mainBuildGradle -Value $mainContent -NoNewline -ErrorAction SilentlyContinue
        Write-Host "  OK Build.gradle principal corrigido" -ForegroundColor Green
        $fixed++
    }
}

if ($fixed -gt 0) {
    Write-Host "`n✓ $fixed correções aplicadas!" -ForegroundColor Green
} else {
    Write-Host "`n✓ Plugins já estão corretos" -ForegroundColor Green
}

Write-Host "`n=== Concluído ===`n" -ForegroundColor Cyan
