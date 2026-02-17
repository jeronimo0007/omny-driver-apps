# Publicar na App Store (User e Driver)

Guia para gerar e publicar os apps **User** e **Driver** na Apple App Store.

---

## 1. Pré-requisitos

- [ ] **Conta Apple Developer** (Apple Developer Program, pago)
- [ ] **Xcode** instalado (última versão estável)
- [ ] **Flutter** instalado e no PATH (`flutter doctor`)
- [ ] **Certificados e perfis**: no [Apple Developer](https://developer.apple.com/account) crie:
  - App ID para cada app (ex.: `com.omny.user`, `com.omny.driver`)
  - Provisioning Profile de **Distribution** (App Store)
  - Certificado de **Distribution** (Apple Distribution)

---

## 2. Configurar Bundle ID e Team (obrigatório)

Os projetos usam placeholders. Antes de gerar o build, configure em cada app:

### User (`driver-app-user`)

| Onde | O que trocar | Exemplo |
|------|----------------|--------|
| Xcode: **Runner** → **Signing & Capabilities** | **Team** | Sua equipe (Apple Developer) |
| Xcode: **Runner** → **General** → **Bundle Identifier** | `bundle.id` | `com.omny.user` |
| `ios/Runner/Info.plist` | `CFBundleDisplayName` → `product.name` | Nome que aparece na loja (ex.: "Omny") |

Ou edite manualmente:

- **Bundle ID e Team**: em `driver-app-user/ios/Runner.xcodeproj/project.pbxproj`  
  - Substitua `bundle.id` pelo Bundle ID real (ex.: `com.omny.user`).  
  - Substitua `teamid` (ou `team.id`) pelo seu **Team ID** (encontrado em [developer.apple.com/account](https://developer.apple.com/account) → Membership).
- **Nome do app**: em `driver-app-user/ios/Runner/Info.plist` altere a string de `CFBundleDisplayName` de `product.name` para o nome público do app.

### Driver (`driver-app-driver`)

- Mesmo processo, usando um Bundle ID diferente (ex.: `com.omny.driver`).
- Em `driver-app-driver/ios/Runner.xcodeproj/project.pbxproj`: `bundle.id` → `com.omny.driver` e `team.id` → seu Team ID.
- Em `driver-app-driver/ios/Runner/Info.plist`: `CFBundleDisplayName` com o nome do app para motoristas.

---

## 3. Versão e build number

- **User**: em `driver-app-user/pubspec.yaml` → `version: 1.0.3+6` (versão 1.0.3, build 6).
- **Driver**: em `driver-app-driver/pubspec.yaml` → `version: 1.0.1+6`.

Para a próxima publicação, aumente o número após o `+` (build) e, se quiser, a versão (ex.: `1.0.4+7`).

---

## 4. Gerar o build para a App Store

Na raiz do repositório:

```bash
# Dar permissão ao script (uma vez)
chmod +x scripts/build-ios-app-store.sh

# Gerar os dois apps
./scripts/build-ios-app-store.sh all

# Ou apenas um:
./scripts/build-ios-app-store.sh user
./scripts/build-ios-app-store.sh driver
```

Isso roda `flutter build ipa` em cada app. Os IPAs ficam em:

- **User**: `driver-app-user/build/ios/ipa/`
- **Driver**: `driver-app-driver/build/ios/ipa/`

---

## 5. Enviar para a App Store

### Opção A – Xcode (Archive + Upload)

1. Abra o projeto no Xcode:
   - User: `driver-app-user/ios/Runner.xcworkspace`
   - Driver: `driver-app-driver/ios/Runner.xcworkspace`
2. Selecione **Any iOS Device** como destino.
3. Menu **Product** → **Archive**.
4. No **Organizer**, selecione o archive e clique em **Distribute App** → **App Store Connect** → **Upload**.

### Opção B – App Transporter

1. Instale o [Transporter](https://apps.apple.com/app/transporter/id1450874784) da Mac App Store.
2. Arraste o arquivo `.ipa` (de `build/ios/ipa/`) para o Transporter e envie.

### Opção C – Flutter (upload direto)

Se o Xcode estiver com signing e team corretos:

```bash
cd driver-app-user
flutter build ipa --export-options-plist=ios/ExportOptions.plist
# O Flutter pode perguntar se deseja enviar ao App Store Connect; confirme se quiser.
```

(Se não tiver `ExportOptions.plist`, use Xcode ou Transporter para o upload.)

---

## 6. App Store Connect

1. Acesse [App Store Connect](https://appstoreconnect.apple.com).
2. Crie um app para **User** e outro para **Driver** (se ainda não existirem), com os mesmos Bundle IDs configurados no Xcode.
3. Após o upload, preencha:
   - Descrição, screenshots, ícone, categoria, etc.
   - Preço (ou gratuito).
   - Política de privacidade (URL).
4. Envie para revisão.

---

## Resumo rápido

| Passo | Ação |
|-------|--------|
| 1 | Configurar Bundle ID e Team em cada app (Xcode ou `project.pbxproj` + `Info.plist`) |
| 2 | Ajustar `version` / build no `pubspec.yaml` se necessário |
| 3 | Rodar `./scripts/build-ios-app-store.sh all` |
| 4 | Enviar o(s) IPA via Xcode (Archive) ou Transporter |
| 5 | Completar metadados no App Store Connect e enviar para revisão |

Se aparecer erro de **signing** ou **provisioning**, confira no Xcode: **Signing & Capabilities** do target **Runner** (Team e Bundle ID) e os Provisioning Profiles no portal Apple Developer.
