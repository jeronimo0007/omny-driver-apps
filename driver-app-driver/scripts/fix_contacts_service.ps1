# Script para corrigir o plugin contacts_service incompatível com Flutter moderno
# Este script corrige o arquivo Java do plugin no cache do pub

$contactsServicePath = "$env:LOCALAPPDATA\Pub\Cache\hosted\pub.dev\contacts_service-0.6.3\android\src\main\java\flutter\plugins\contactsservice\contactsservice\ContactsServicePlugin.java"

if (Test-Path $contactsServicePath) {
    Write-Host "Corrigindo contacts_service..." -ForegroundColor Yellow
    
    $content = Get-Content $contactsServicePath -Raw
    
    # Remove as referências ao Registrar antigo
    $content = $content -replace 'import io\.flutter\.plugin\.common\.PluginRegistry\.Registrar;', ''
    $content = $content -replace 'private void initDelegateWithRegister\(Registrar registrar\)', 'private void initDelegateWithRegister(Object registrar)'
    $content = $content -replace 'public static void registerWith\(Registrar registrar\)', 'public static void registerWith(Object registrar)'
    $content = $content -replace 'private final PluginRegistry\.Registrar registrar;', 'private final Object registrar;'
    $content = $content -replace 'ContactServiceDelegateOld\(PluginRegistry\.Registrar registrar\)', 'ContactServiceDelegateOld(Object registrar)'
    
    # Comenta o método registerWith que não é mais necessário
    $content = $content -replace '(\s+)public static void registerWith\(Object registrar\) \{', '$1// Método removido - não compatível com Flutter embedding v2+'
    $content = $content -replace '(\s+)// Método removido - não compatível com Flutter embedding v2+', '$1// Método removido - não compatível com Flutter embedding v2+`n$1// public static void registerWith(Object registrar) {'
    
    Set-Content -Path $contactsServicePath -Value $content -NoNewline
    
    Write-Host "contacts_service corrigido com sucesso!" -ForegroundColor Green
} else {
    Write-Host "Arquivo contacts_service não encontrado em: $contactsServicePath" -ForegroundColor Red
    Write-Host "Execute 'flutter pub get' primeiro." -ForegroundColor Yellow
}
