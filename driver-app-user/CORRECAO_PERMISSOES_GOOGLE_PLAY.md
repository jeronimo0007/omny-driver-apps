# Correção de Permissões - Política do Google Play

## ✅ Alterações Realizadas

### 1. Remoção da Permissão READ_MEDIA_IMAGES

**Arquivo**: `android/app/src/main/AndroidManifest.xml`

**Antes:**
```xml
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
```

**Depois:**
```xml
<!-- Permissão removida conforme política do Google Play -->
```

### 2. Ajuste no Código para Usar Photo Picker

**Arquivo**: `lib/pages/NavigatorPages/editprofile.dart`

**Mudanças:**
- **Android 13+ (API 33+)**: Agora usa o Photo Picker do Android diretamente, sem solicitar permissão
- **Android 12 e abaixo (API 32-)**: Mantém a verificação de permissão de storage (necessária)
- **iOS**: Mantém a verificação de permissão de fotos (necessária)

**Código atualizado:**
```dart
// Android 13+: usa Photo Picker sem permissão
if (androidInfo.version.sdkInt >= 33) {
  final pickedFile = await picker.pickImage(
    source: ImageSource.gallery, 
    imageQuality: 50
  );
  // Não requer permissão - usa Photo Picker automaticamente
}
```

## 📋 O que foi feito

1. ✅ Removida a permissão `READ_MEDIA_IMAGES` do AndroidManifest.xml
2. ✅ Ajustado o código para usar Photo Picker no Android 13+ sem solicitar permissão
3. ✅ Mantida compatibilidade com Android 12 e abaixo (usa permissão de storage)
4. ✅ Mantida funcionalidade no iOS (usa permissão de fotos)

## 🎯 Conformidade com Google Play

- ✅ Não usa `READ_MEDIA_IMAGES` em nenhuma versão
- ✅ Não usa `READ_MEDIA_VIDEO` em nenhuma versão
- ✅ Usa Photo Picker do Android para seleção de fotos (Android 13+)
- ✅ Mantém funcionalidade para versões antigas do Android

## 📱 Como Funciona Agora

### Android 13+ (API 33+)
- **Sem permissão necessária**: O Photo Picker do Android é usado automaticamente
- **Experiência do usuário**: O usuário seleciona fotos através do seletor nativo do Android
- **Privacidade**: O app não tem acesso a todas as fotos, apenas à foto selecionada

### Android 12 e abaixo (API 32-)
- **Permissão necessária**: `READ_EXTERNAL_STORAGE` (com `maxSdkVersion="32"`)
- **Compatibilidade**: Mantém funcionamento em dispositivos antigos

### iOS
- **Permissão necessária**: `Permission.photos`
- **Funcionalidade**: Mantém o comportamento original

## ✅ Próximos Passos

1. **Testar a funcionalidade**:
   - Testar seleção de fotos no Android 13+
   - Testar seleção de fotos no Android 12 e abaixo
   - Testar seleção de fotos no iOS

2. **Gerar novo build**:
   ```bash
   flutter clean
   flutter pub get
   flutter build appbundle --release
   ```

3. **Enviar para Google Play**:
   - O novo build não terá a permissão `READ_MEDIA_IMAGES`
   - Deve passar na verificação de políticas do Google Play

## 🔍 Verificação

Para verificar se a permissão foi removida corretamente:

1. Gere o APK/AAB
2. Use `aapt dump permissions <arquivo.apk>` ou
3. Verifique no Google Play Console após o upload

A permissão `READ_MEDIA_IMAGES` não deve aparecer na lista de permissões do app.
