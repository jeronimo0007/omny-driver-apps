# Scripts de Correção Automática

## Problema
Alguns plugins Flutter não são compatíveis com Android Gradle Plugin 8.1.1+ e precisam de correções:
- Adicionar `namespace` em alguns plugins
- Habilitar `buildConfig` em plugins Firebase

## Scripts Disponíveis

### 1. flutter_run.ps1 - Executar app com emulador automático (⭐ Recomendado)
```powershell
powershell -ExecutionPolicy Bypass -File scripts\flutter_run.ps1
```

Este script:
- Verifica se há um dispositivo Android conectado
- Se não houver, inicia automaticamente um emulador
- Aguarda o emulador estar pronto
- Executa `flutter run` no dispositivo/emulador

**Uso:**
```powershell
# Executa com emulador automático
.\scripts\flutter_run.ps1

# Executa em dispositivo específico
.\scripts\flutter_run.ps1 -DeviceId emulator-5554

# Executa sem iniciar emulador (se já houver dispositivo)
.\scripts\flutter_run.ps1 -NoEmulator
```

### 2. pub_get_with_fix.ps1 - Obter dependências com correções
```powershell
powershell -ExecutionPolicy Bypass -File scripts\pub_get_with_fix.ps1
```

Este script executa `flutter pub get` e depois:
- Remove automaticamente as pastas de plataformas não utilizadas (linux, windows, macos)
- Aplica as correções nos plugins Android

### 3. fix_android_plugins.ps1 - Aplicar correções manualmente
```powershell
powershell -ExecutionPolicy Bypass -File scripts\fix_android_plugins.ps1
```

### 4. fix_contacts_service.ps1 - Corrigir contacts_service
```powershell
powershell -ExecutionPolicy Bypass -File scripts\fix_contacts_service.ps1
```

### 5. remove_unused_platforms.ps1 - Remover plataformas não utilizadas
```powershell
powershell -ExecutionPolicy Bypass -File scripts\remove_unused_platforms.ps1
```

Este script remove manualmente as pastas de plataformas não utilizadas (linux, windows, macos).
Útil se essas pastas forem criadas por algum comando Flutter fora dos scripts.

## Quando executar

**flutter_run.ps1:**
- Use sempre que quiser executar o app (substitui `flutter run`)

**pub_get_with_fix.ps1:**
- Após `flutter pub get`
- Após `flutter pub cache repair`
- Após limpar o cache do Flutter
- Sempre que adicionar/atualizar dependências

## Plugins corrigidos automaticamente

**Namespaces:**
- cashfree_pg
- contacts_service
- permission_handler_android

**BuildConfig:**
- firebase_auth
- firebase_core
- firebase_database
- firebase_messaging
