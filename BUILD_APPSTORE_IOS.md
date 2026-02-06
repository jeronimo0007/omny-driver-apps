# Compilar os dois apps para publicar na App Store

## Pré-requisitos

1. **Conta Apple Developer** (paga) – [developer.apple.com](https://developer.apple.com)
2. **Xcode 15.2 ou superior** (para o app driver, por causa do Firebase 12)
3. **Certificados e Provisioning Profiles** configurados no [App Store Connect](https://appstoreconnect.apple.com) e no Xcode

## Antes de compilar

### 1. Definir Bundle ID e time no Xcode

Os projetos usam placeholders (`bundle.id`, `team.id`). Antes do build de release:

- Abra cada app no Xcode:
  - `driver-app-driver/ios/Runner.xcworkspace`
  - `driver-app-user/ios/Runner.xcworkspace`
- Em **Runner** → **Signing & Capabilities**:
  - **Team:** selecione seu Apple Developer Team
  - **Bundle Identifier:** ex.: `com.suaempresa.omnydriver` e `com.suaempresa.omnyuser`

### 2. Versão e build number

Atualize no `pubspec.yaml` de cada app (e, se quiser, no Xcode):

- **driver-app-driver:** `version: 1.0.1+5` → ex.: `1.0.2+6` para nova submissão
- **driver-app-user:** `version: 1.0.3+6` → ex.: `1.0.4+7` para nova submissão

O número depois do `+` deve **subir a cada envio** à App Store.

---

## Opção A: Build pelo Flutter (recomendado)

No Terminal, **na pasta raiz de cada app** (onde está o `pubspec.yaml`):

### App do motorista (driver)

```bash
cd /Users/mac/Documents/projetos/omny/omny-driver-apps/driver-app-driver

flutter clean
flutter pub get
flutter build ipa
```

O `.ipa` fica em:  
`build/ios/ipa/` (ou o caminho que o Flutter mostrar no fim do comando).

### App do usuário (user)

```bash
cd /Users/mac/Documents/projetos/omny/omny-driver-apps/driver-app-user

flutter clean
flutter pub get
flutter build ipa
```

O `.ipa` fica em:  
`build/ios/ipa/` (ou o caminho que o Flutter mostrar no fim do comando).

---

## Opção B: Build pelo Xcode (Archive)

1. Abra o **.xcworkspace** (nunca o .xcodeproj quando há CocoaPods):
   - `driver-app-driver/ios/Runner.xcworkspace`
   - `driver-app-user/ios/Runner.xcworkspace`
2. No Xcode: **Product** → **Destination** → **Any iOS Device (arm64)**.
3. **Product** → **Archive**.
4. Quando terminar, abre o **Organizer**: **Window** → **Organizer** → **Archives**.
5. Selecione o archive → **Distribute App** → **App Store Connect** → seguir o assistente.

---

## Envio para a App Store

1. Acesse [App Store Connect](https://appstoreconnect.apple.com).
2. Crie (ou use) o app para cada Bundle ID.
3. **Transporter** (Mac): envie o `.ipa` gerado pelo `flutter build ipa`, ou use **Distribute App** no Xcode a partir do Archive.
4. No App Store Connect, preencha versão, screenshots, descrição e submeta para revisão.

---

## Resumo dos comandos (ambos os apps)

```bash
# Driver
cd driver-app-driver && flutter clean && flutter pub get && flutter build ipa && cd ..

# User
cd driver-app-user && flutter clean && flutter pub get && flutter build ipa && cd ..
```

Se aparecer erro de **signing**, configure **Team** e **Bundle ID** no Xcode em cada projeto e rode de novo.
