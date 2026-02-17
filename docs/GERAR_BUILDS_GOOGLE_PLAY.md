# Gerar os 2 apps (User e Driver) para publicar no Google Play

## 1. Keystore

Os dois apps usam o mesmo keystore (arquivo `.jks`). O `key.properties` em cada projeto já está configurado para `driver-keystore.jks`.

**Coloque o arquivo `driver-keystore.jks` nestas duas pastas:**

| App   | Pasta onde colar o .jks |
|-------|-------------------------|
| **User** (passageiro)  | `driver-app-user\android\app\`   |
| **Driver** (motorista) | `driver-app-driver\android\app\` |

Ou use o mesmo arquivo em um lugar só e altere em cada `android\key.properties` o `storeFile` para o caminho correto (ex.: `storeFile=../../minha-pasta/driver-keystore.jks`).

## 2. Gerar os App Bundles (.aab)

No PowerShell, na pasta raiz do projeto (`omny-driver-apps`):

```powershell
.\build-release-google.ps1
```

O script gera os dois bundles. Se o keystore não estiver em uma das pastas, ele avisa e só gera o app que tiver o arquivo.

## 3. Onde ficam os arquivos para enviar ao Google

| App    | Caminho do .aab |
|--------|------------------|
| **User**  | `driver-app-user\build\app\outputs\bundle\release\app-release.aab`   |
| **Driver**| `driver-app-driver\build\app\outputs\bundle\release\app-release.aab` |

Envie cada `.aab` no **Google Play Console** no app correspondente (Produção, Teste fechado ou Teste interno).

## 4. Erro "Keystore file ... not found"

Se aparecer algo como:

```text
Keystore file '...\android\app\driver-keystore.jks' not found
```

confirme que o arquivo `driver-keystore.jks` está dentro de `android\app\` do projeto (user ou driver) que está sendo buildado.

## 5. Versão do app

Antes de gerar uma nova versão para a Play Store, atualize no `pubspec.yaml` de cada app:

```yaml
version: 1.0.0+1   # 1.0.0 = versão; +1 = número do build (incremente a cada envio)
```

- **User:** `driver-app-user\pubspec.yaml`
- **Driver:** `driver-app-driver\pubspec.yaml`

Guia detalhado (criar keystore, key.properties, etc.): **GUIA_BUILD_GOOGLE_PLAY.md**
