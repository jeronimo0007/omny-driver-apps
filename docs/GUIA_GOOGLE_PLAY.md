# Guia para Publicar no Google Play Store

## 📋 Pré-requisitos

1. Conta de desenvolvedor no Google Play Console (custo único de $25)
2. Keystore criada e configurada

---

## 🔐 Passo 1: Criar a Keystore

Execute no terminal (PowerShell ou CMD):

```bash
cd android
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**Informações que você precisará fornecer:**
- **Senha da keystore** (mínimo 6 caracteres) - ⚠️ **GUARDE BEM ESTA SENHA!**
- **Senha da chave** (pode ser a mesma da keystore)
- Seu nome completo
- Nome da unidade organizacional
- Nome da organização
- Cidade
- Estado
- Código do país (ex: BR)

**⚠️ IMPORTANTE:**
- Guarde o arquivo `upload-keystore.jks` em local seguro
- Guarde as senhas em local seguro
- Você precisará deles para TODAS as atualizações futuras do app
- Se perder a keystore ou senha, não conseguirá atualizar o app no Google Play

---

## ⚙️ Passo 2: Configurar key.properties

Após criar a keystore, edite o arquivo `android/key.properties`:

```properties
storePassword=SUA_SENHA_KEYSTORE_AQUI
keyPassword=SUA_SENHA_CHAVE_AQUI
keyAlias=upload
storeFile=upload-keystore.jks
```

**Substitua:**
- `SUA_SENHA_KEYSTORE_AQUI` pela senha da keystore que você criou
- `SUA_SENHA_CHAVE_AQUI` pela senha da chave (pode ser a mesma)

---

## 📦 Passo 3: Gerar o App Bundle (AAB) - RECOMENDADO

O Google Play prefere o formato **AAB** (Android App Bundle) ao invés de APK.

```bash
flutter build appbundle --release
```

O arquivo será gerado em:
```
build/app/outputs/bundle/release/app-release.aab
```

**Este é o arquivo que você deve fazer upload no Google Play Console.**

---

## 📱 Passo 4: Gerar APK de Release (Alternativa)

Se preferir gerar um APK (não recomendado para Google Play, mas útil para testes):

```bash
flutter build apk --release
```

O arquivo será gerado em:
```
build/app/outputs/flutter-apk/app-release.apk
```

---

## 🚀 Passo 5: Publicar no Google Play Console

1. Acesse [Google Play Console](https://play.google.com/console)
2. Crie um novo app ou selecione um existente
3. Vá em **Produção** > **Criar nova versão**
4. Faça upload do arquivo `app-release.aab`
5. Preencha as informações da versão:
   - Nome da versão
   - Notas de versão
6. Revise e publique

---

## 📝 Informações do App Atual

- **Package Name:** `br.app.omny.driver`
- **Versão Atual:** `1.0.1+1` (versão 1.0.1, build 1)
- **Min SDK:** Definido pelo Flutter
- **Target SDK:** 36

---

## 🔄 Para Atualizações Futuras

1. Atualize a versão no `pubspec.yaml`:
   ```yaml
   version: 1.0.2+2  # versão 1.0.2, build 2
   ```

2. Gere o novo AAB:
   ```bash
   flutter build appbundle --release
   ```

3. Faça upload no Google Play Console

---

## ⚠️ Checklist Antes de Publicar

- [ ] Keystore criada e configurada
- [ ] `key.properties` preenchido corretamente
- [ ] Versão atualizada no `pubspec.yaml` (se necessário)
- [ ] App testado em modo release
- [ ] Ícones e splash screen configurados
- [ ] Política de privacidade preparada (obrigatório no Google Play)
- [ ] Descrição do app preparada
- [ ] Screenshots preparados
- [ ] Categoria do app definida

---

## 🆘 Problemas Comuns

### Erro: "Keystore file not found"
- Verifique se o arquivo `upload-keystore.jks` está na pasta `android/`
- Verifique o caminho no `key.properties`

### Erro: "Wrong password"
- Verifique se as senhas no `key.properties` estão corretas
- Certifique-se de não ter espaços extras

### Erro: "Key alias not found"
- Verifique se o `keyAlias` no `key.properties` corresponde ao alias usado na criação da keystore

---

## 📚 Links Úteis

- [Documentação Flutter - Build and Release](https://docs.flutter.dev/deployment/android)
- [Google Play Console](https://play.google.com/console)
- [Android App Signing](https://developer.android.com/studio/publish/app-signing)
