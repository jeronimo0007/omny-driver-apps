# Omny Driver

Aplicativo Flutter para motoristas.

## Plataformas Suportadas

- ✅ Android
- ✅ iOS  
- ✅ Web

## Como Executar

### Método Rápido (Recomendado)

Use o script que inicia automaticamente o emulador Android:

```powershell
.\run.ps1
```

ou

```powershell
powershell -ExecutionPolicy Bypass -File scripts\flutter_run.ps1
```

Este script:
- Verifica se há um dispositivo Android conectado
- Se não houver, inicia automaticamente um emulador
- Aguarda o emulador estar pronto
- Executa o app no dispositivo/emulador

### Método Manual

```powershell
# 1. Iniciar emulador (se necessário)
flutter emulators --launch Pixel_7

# 2. Executar o app
flutter run
```

## Scripts Disponíveis

Consulte `scripts/README.md` para mais informações sobre os scripts de correção automática.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
