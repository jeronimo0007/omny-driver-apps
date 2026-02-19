# Prompt: Reajustar login dos 2 apps (User e Driver) – Login por e-mail/senha + OTP opcional

Use este texto como prompt para uma IA ou como especificação para implementar o novo fluxo de login.

---

## Contexto

- Existem **dois apps Flutter**: **driver-app-user** (passageiro) e **driver-app-driver** (motorista).
- O login e o cadastro serão reajustados para usar um **novo endpoint/base**; o restante das APIs continua na base atual.
- Tudo deve ser controlado por uma **variável de configuração** em `lib/config/api_config.dart` em cada app.
- **Os dois fluxos coexistem:** quando `login_email_pswd == 1` usa-se auth.omny.app.br e telas novas; quando `login_email_pswd == 0` mantém-se o fluxo antigo (telefone/OTP atual).

---

## URLs

| Uso | URL base |
|-----|----------|
| **Login e cadastro (auth)** | `https://auth.omny.app.br/` |
| **Demais fluxos (já existentes)** | `https://driver.omny.app.br/` |

Ou seja:
- Chamadas de **login, cadastro, OTP, esqueci senha, logout** (quando no novo fluxo) → `auth.omny.app.br`
- Todas as outras (perfil, corridas, pedidos, etc.) → `driver.omny.app.br` (como hoje)

---

## Configuração em `lib/config/api_config.dart`

Em **ambos** os apps (user e driver), o arquivo `lib/config/api_config.dart` deve:

1. Expor a **URL base da API geral** (para o restante do app): `driver.omny.app.br` (ex.: `apiBaseUrl`).
2. Expor a **URL base de autenticação**: `https://auth.omny.app.br/` (ex.: `authBaseUrl`).
3. Ter uma **flag de comportamento**:
   - `login_email_pswd = 1` → usar o **novo** fluxo (e-mail/senha, auth.omny.app.br, esqueci senha, cadastro, OTP por e-mail).
   - `login_email_pswd = 0` → manter o **fluxo antigo** (login por telefone/OTP como está hoje; não usar auth.omny.app.br para login).

Exemplo de estrutura:

```dart
// lib/config/api_config.dart

/// 1 = novo login (e-mail/senha + auth.omny.app.br); 0 = fluxo antigo
const int loginEmailPswd = 1;

/// URL base para login/cadastro (novo fluxo)
String get authBaseUrl => 'https://auth.omny.app.br/';

/// URL base para as demais APIs (perfil, corridas, etc.)
String get apiBaseUrl => 'https://driver.omny.app.br/';
```

Todas as chamadas listadas abaixo (login, validate-otp, send-otp, register, forgot-password, reset-password, logout) usam `authBaseUrl` **somente quando** `loginEmailPswd == 1`.

---

## Endpoints na nova URL (auth.omny.app.br)

Todos os endpoints abaixo são relativos à base **auth.omny.app.br** (ex.: `authBaseUrl + 'api/v1/...'`). Só são usados quando `login_email_pswd == 1`.

| Endpoint | Método | Autenticação | Body (exemplo) |
|----------|--------|--------------|----------------|
| **Login** | POST | Não | `{ "emailOrMobile": "...", "password": "...", "type": "user" \| "driver", "device_token": "..." }` |
| **Validar OTP** | POST | **Sim (Bearer)** | `{ "otp": "123456" }` |
| **Reenviar OTP** | POST | **Sim (Bearer)** | `{ "type": "email" }` ou `{ "type": "mobile" }` |
| **Cadastro motorista** | POST | Não | conforme API – `authBaseUrl + 'api/v1/driver/register'` |
| **Cadastro owner** | POST | Não | conforme API – `authBaseUrl + 'api/v1/owner/register'` |
| **Cadastro usuário** | POST | Não | conforme API – `authBaseUrl + 'api/v1/user/register'` |
| **Esqueci senha** | POST | Não | `{ "email": "string", "mobile": "" }` — neste fluxo **apenas e-mail** (mobile vazio). |
| **Reset senha** | POST | Não | `{ "email": "string" }` (e demais campos conforme backend) |
| **Logout** | POST | Conforme backend | – |

Detalhes:

- **`/validate-otp`**  
  Requer usuário **autenticado**: enviar o **Bearer token** obtido no login (resposta do login que devolveu `device_token: true` e `user`).  
  Body: `{ "otp": "123456" }`.

- **`/login/send-otp`**  
  Requer usuário **autenticado**: enviar o **Bearer token** do login.  
  Body: `{ "type": "email" }` ou `{ "type": "mobile" }`.

- **`/forgot-password`**  
  Neste fluxo (novo login): enviar **apenas e-mail**; **mobile** mandar vazio: `"mobile": ""`.

- **Cadastros:**  
  `authBaseUrl + 'api/v1/driver/register'`, `.../owner/register`, `.../user/register` conforme o app (driver vs user).

---

## Novo fluxo de login (quando `login_email_pswd == 1`)

### Restrição deste fluxo

- **Login apenas com e-mail** (não usar celular para login neste fluxo).
- **OTP apenas por e-mail** (não por SMS neste fluxo).

### Tela de login

- Campos: **e-mail** e **senha**.
- **Botão “Entrar”** (ou equivalente): envia POST para `auth.omny.app.br/api/v1/login` com `emailOrMobile`, `password`, `type` (user/driver), `device_token` (quando houver).
- **Botão “Ir para cadastro”** (ou “Cadastrar”): navega para a tela de cadastro (user/driver/owner conforme o app).
- **Link/Botão “Esqueci minha senha”**: navega para a **tela de Esqueci senha**.

### Tela de Esqueci senha

- Um **campo para e-mail** (e apenas e-mail neste fluxo).
- Ação: chamar `authBaseUrl + 'api/v1/forgot-password'` com body `{ "email": "...", "mobile": "" }`.
- Conforme resposta do backend, mostrar mensagem de sucesso ou erro e, se houver fluxo de reset, seguir para tela de reset (conforme API de reset-password).

### Passo 1 – Request de login

- **Método:** POST  
- **URL:** `auth.omny.app.br/api/v1/login`  
- **Body (JSON):**
  ```json
  {
    "emailOrMobile": "usuario@email.com",
    "password": "123456789",
    "type": "driver",
    "device_token": "123434"
  }
  ```
- App **user** → `"type": "user"`; app **driver** → `"type": "driver"`.
- Se não houver device_token, enviar string vazia ou omitir; o backend pode devolver que precisa de OTP.

### Passo 2 – Tratamento da resposta do POST `/api/v1/login`

Há dois tipos de resposta:

---

#### Caso A – Login concluído (já tem token)

Resposta quando o backend devolve tokens direto (ex.: device_token aceito):

```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "token_type": "Bearer",
    "expires_in": 86400,
    "access_token": "eyJhbGciOiJIUzUxMiJ9...",
    "refresh_token": "eyJhbGciOiJIUzUxMiJ9..."
  }
}
```

**Ação no app:**
- Guardar `access_token` (e opcionalmente `refresh_token`) como hoje (ex.: `bearerToken`, SharedPreferences).
- Usar **apiBaseUrl** (`driver.omny.app.br`) e o token para chamar **getUserDetails** (ou equivalente) com `Authorization: Bearer <access_token>`.
- Redirecionar para a **área logada** (mesmo fluxo atual após login).

---

#### Caso B – Precisa OTP (device_token não enviado ou não aceito)

Resposta quando o backend exige OTP (pode incluir um token temporário em `data.user`):

```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "device_token": true,
    "user": {
      "access_token": "eyJhbGciOiJIUzUxMiJ9...",
      "id": 123,
      "name": "joao",
      "email": "a@a.com",
      "mobile": ""
    }
  }
}
```

**Ação no app:**
- Se o backend devolver um `access_token` dentro de `data.user`, guardá-lo temporariamente para usar nas chamadas **autenticadas** de OTP (`/validate-otp` e `/login/send-otp`).
- Ir para a **tela de OTP** (código enviado por **e-mail** neste fluxo).
- **Reenviar OTP:** POST `authBaseUrl + 'api/v1/login/send-otp'` com header `Authorization: Bearer <token>` e body `{ "type": "email" }`.
- Ao digitar o **OTP correto:** POST `authBaseUrl + 'api/v1/validate-otp'` com header `Authorization: Bearer <token>` e body `{ "otp": "123456" }`.
- Resposta esperada após OTP correto (exemplo):
  ```json
  {
    "success": true,
    "message": "Login successful",
    "data": {
      "token_type": "Bearer",
      "expires_in": 86400,
      "access_token": "eyJhbGciOiJIUzUxMiJ9...",
      "refresh_token": "eyJhbGciOiJIUzUxMiJ9..."
    }
  }
  ```
- Guardar tokens, chamar getUserDetails em `driver.omny.app.br` com o token e redirecionar para a área logada (igual ao Caso A).

---

## Resumo de regras

1. **Só auth** (login, cadastro, OTP, esqueci senha, reset, logout) usa `auth.omny.app.br` quando `login_email_pswd == 1`; todas as outras requisições continuam em `driver.omny.app.br`.
2. **Config:** `api_config.dart` com `authBaseUrl`, `apiBaseUrl` e `login_email_pswd` (1 = novo fluxo, 0 = antigo). Sempre verificar a variável antes de usar as novas URLs.
3. **Novo login:** POST `auth.omny.app.br/api/v1/login` com `emailOrMobile`, `password`, `type` (user/driver), `device_token` quando houver. Neste fluxo: **apenas e-mail para login; OTP por e-mail**.
4. **Tela de login:** botão/link para **Cadastro** e **Esqueci senha**. Tela de Esqueci senha: campo de **e-mail** e chamada a `/forgot-password` com `mobile` vazio.
5. **Se a resposta do login trouxer `access_token` em `data`** → salvar token, getUserDetails na API normal, ir para área logada.
6. **Se a resposta trouxer `data.device_token == true` e `data.user`** → (opcionalmente guardar token de `data.user` para OTP), ir para tela de OTP; validar com `/validate-otp` (Bearer); reenviar com `/login/send-otp` (Bearer, type: "email"); após resposta com tokens, salvar e seguir o mesmo fluxo (getUserDetails + área logada).
7. **Quando `login_email_pswd == 0`**, manter o fluxo atual de login (sem usar auth.omny.app.br para login).

---

## Onde alterar nos projetos

- **driver-app-user** e **driver-app-driver**:
  - **`lib/config/api_config.dart`:** já com `authBaseUrl`, `apiBaseUrl` e `login_email_pswd`. Garantir que toda lógica de auth nova verifica `login_email_pswd == 1`.
  - **Telas de login:** quando `login_email_pswd == 1`: campos e-mail e senha; botão Entrar (POST `authBaseUrl + 'api/v1/login'`); link “Ir para cadastro”; link “Esqueci minha senha”. Tratar Caso A e Caso B da resposta.
  - **Tela de Esqueci senha:** campo e-mail; POST `authBaseUrl + 'api/v1/forgot-password'` com `{ "email": "...", "mobile": "" }`.
  - **Tela de OTP (novo fluxo):** usar token (de `data.user` do login) em `Authorization` para `authBaseUrl + 'api/v1/validate-otp'` e `authBaseUrl + 'api/v1/login/send-otp'` (body `{ "type": "email" }`).
  - **Cadastro:** usar `authBaseUrl + 'api/v1/user/register'`, `.../driver/register` ou `.../owner/register` conforme o app.
  - **Logout:** quando no novo fluxo, chamar endpoint de logout em auth (conforme contrato do backend).
  - **Fluxo pós-login (getUserDetails, área logada):** inalterado, sempre com `apiBaseUrl` e token Bearer.

Use esta especificação para implementar o reajuste de login nos dois apps, mantendo os dois fluxos (antigo e novo) conforme a variável de configuração.
