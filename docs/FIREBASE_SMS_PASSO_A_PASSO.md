# Passo a passo: configurar Firebase para enviar SMS (autenticação por telefone)

Quando aparece o erro **"missing-client-identifier"** ou **"This request is missing a valid app identifier"**, o Firebase não está reconhecendo o app. Siga estes passos para o envio de SMS funcionar.

---

## Parte 1: Obter as impressões digitais (SHA-1 e SHA-256) do app

### Passo 1.1 – Abrir o terminal no Windows

- Pressione **Win + R**, digite `cmd` e Enter, **ou**
- Abra o **PowerShell** ou o **Prompt de Comando**.

### Passo 1.2 – Rodar o comando do keytool (build de DEBUG)

Cole e execute o comando abaixo.  
Se o seu usuário do Windows **não** for `Jeronimo`, troque `Jeronimo` pelo seu nome de usuário.

```bash
keytool -list -v -keystore C:\Users\Jeronimo\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android
```

**Senha do keystore de debug:** `android` (padrão do Android).

### Passo 1.3 – Copiar SHA-1 e SHA-256

Na saída do comando, procure por linhas assim:

```
Alias name: androiddebugkey
...
SHA1: AB:CD:EF:12:34:56:78:90:AB:CD:EF:12:34:56:78:90:AB:CD:EF:12
SHA256: AB:CD:EF:12:34:56:78:90:AB:CD:EF:12:34:56:78:90:AB:CD:EF:12:34:56:78:90:AB:CD:EF:12:34:56:78:90:AB
```

- Copie a linha inteira do **SHA1:** (incluindo os dois pontos).
- Copie a linha inteira do **SHA256:**.

Guarde em um bloco de notas; você vai colar no Firebase.

### Passo 1.4 – Keystore de RELEASE (.jks) para publicar no Google Play

Se você já tem um keystore **.jks** para assinar o app e publicar na Play Store, use o **mesmo** arquivo para obter SHA-1 e SHA-256 e cadastrar no Firebase. Assim o login por telefone também funciona no app publicado.

1. No terminal (CMD ou PowerShell), rode (ajuste **caminho**, **alias** e **senha**):

```bash
keytool -list -v -keystore C:\caminho\para\seu-arquivo.jks -alias SEU_ALIAS
```

Exemplo (substitua pelo seu caminho e alias):

```bash
keytool -list -v -keystore C:\Users\Jeronimo\omny-release.jks -alias upload
```

2. Quando pedir, digite a **senha do keystore** (a que você definiu ao criar o .jks).
3. Na saída, copie as linhas **SHA1:** e **SHA256:**.
4. No Firebase (Parte 2), adicione essas duas impressões digitais no app Android correspondente (user ou driver).

**Onde achar o caminho e o alias:**  
Eles costumam estar no arquivo `android/key.properties` (não vai pro Git) ou em `android/app/build.gradle` em `signingConfigs.release`: `storeFile` é o caminho do .jks, `keyAlias` é o alias. O alias costuma ser algo como `upload`, `key0` ou o nome que você deu ao criar o keystore.

---

## Parte 2: Cadastrar as impressões digitais no Firebase

### Passo 2.1 – Abrir o Firebase Console

1. Acesse: **https://console.firebase.google.com**
2. Faça login na conta Google do projeto.
3. Clique no **projeto** que usa o app Omny (user e/ou driver).

### Passo 2.2 – Ir em Configurações do projeto

1. Clique no **ícone de engrenagem** ao lado de “Visão geral do projeto”.
2. Clique em **“Configurações do projeto”**.

### Passo 2.3 – Escolher o app Android

Na aba **“Geral”**, em **“Seus apps”**, você verá os apps registrados, por exemplo:

- **Omny (usuário):** package `br.app.omny.user`
- **Omny Driver:** package `br.app.omny.driver`

- Se você está testando o **app do usuário**, clique no app com **br.app.omny.user**.
- Se está testando o **app do motorista**, clique no app com **br.app.omny.driver**.

### Passo 2.4 – Adicionar SHA-1

1. Role até **“Impressões digitais do certificado SHA”**.
2. Clique em **“Adicionar impressão digital”**.
3. Cole o valor do **SHA-1** que você copiou no Passo 1.3 (ou 1.4).
4. Clique em **“Salvar”**.

### Passo 2.5 – Adicionar SHA-256

1. Clique de novo em **“Adicionar impressão digital”**.
2. Cole o valor do **SHA-256** que você copiou.
3. Clique em **“Salvar”**.

### Passo 2.6 – Repetir para o outro app (se usar os dois)

Se você usa **user** e **driver** no mesmo projeto Firebase:

- Repita os **Passos 2.3 a 2.5** para o **outro** app (o outro package name).
- Para cada app, use os SHAs do **mesmo** keystore com o qual você está gerando aquele app (debug ou release).

---

## Parte 3: Números de teste (para receber SMS de verdade)

Se o seu número estava cadastrado como “número de teste”, o Firebase **não** envia SMS; ele usa um código fixo. Para receber SMS real:

### Passo 3.1 – Abrir Authentication

1. No Firebase Console, no menu lateral, clique em **“Authentication”** (ou “Autenticação”).
2. Clique na aba **“Sign-in method”** / **“Método de login”**.

### Passo 3.2 – Configurar o provedor Telefone

1. Clique no provedor **“Telefone”** / **“Phone”**.
2. Ative o provedor se ainda não estiver ativo (habilitado).
3. Role até **“Números de telefone para teste”** / **“Phone numbers for testing”**.

### Passo 3.3 – Remover seu número da lista de teste

- Se o número que você usa para login (ex.: +5516992282484) estiver na lista de **números de teste**, **remova-o** (ícone de lixeira ou “Remover”).
- Salve as alterações.

Assim o Firebase passará a enviar SMS de verdade para esse número.

### Passo 3.4 – Quando usar números de teste

- Use **números de teste** só para desenvolvimento (sem gastar SMS).
- Para **receber SMS real** no seu celular, **não** coloque esse número em “números de teste”.

---

## Parte 4: Aguardar e testar

### Passo 4.1 – Esperar alguns minutos

Depois de salvar os SHAs e as alterações no método de login, espere **2 a 5 minutos** para o Firebase atualizar.

### Passo 4.2 – Fechar e abrir o app

- Feche o app completamente (remover dos recentes).
- Abra de novo e tente o login por telefone.

### Passo 4.3 – Testar o fluxo

1. Informe o número no formato internacional (ex.: +5516992282484).
2. Toque em “Enviar código” / equivalente.
3. Verifique se o SMS chegou no celular.
4. Digite o código recebido e prossiga.

---

## Resumo rápido

| O que fazer | Onde |
|-------------|------|
| Obter SHA-1 e SHA-256 | `keytool -list -v -keystore ... debug.keystore ...` |
| Colar SHA-1 e SHA-256 | Firebase → Configurações do projeto → Seus apps → App Android → Impressões digitais |
| Parar de usar número de teste | Firebase → Authentication → Sign-in method → Telefone → Remover número da lista de teste |
| Testar de novo | Após 2–5 min, fechar app, abrir e tentar login por telefone |

---

## Firebase Realtime Database: permissão em `/chats/` (app do motorista)

Se no app do **motorista** aparecer:

- **`Listen at /chats/... failed: DatabaseError: Permission denied`**
- **`[firebase_database/permission-denied] Client doesn't have permission to access the desired data`**

é porque as **regras do Realtime Database** não permitem leitura (e escrita) no path `chats/{chat_id}`.

### O que fazer

1. No **Firebase Console** → projeto Omny → **Realtime Database** → aba **Regras**.
2. Inclua permissão para o path `chats` (e filhos). Exemplo de regras que permitem acesso autenticado ao nó de chat:

```json
{
  "rules": {
    "chats": {
      "$chat_id": {
        ".read": "auth != null",
        ".write": "auth != null"
      }
    }
  }
}
```

3. Se já existirem outras regras (ex.: `requests`, `drivers`), **adicione** o bloco `"chats"` dentro de `"rules"` sem apagar o resto. Exemplo com a mesma estrutura do seu projeto:

```json
"chats": {
  "$chat_id": {
    ".read": true,
    ".write": true
  }
}
```

(Use `.read": true` e `.write": true` para manter o mesmo padrão das suas outras regras; ou `"auth != null"` se quiser exigir login.)

4. Clique em **Publicar** e teste de novo o chat no app do motorista.

**Segurança:** `auth != null` permite qualquer usuário logado ler/escrever em qualquer `chat_id`. Para restringir só ao dono do chat, seria preciso guardar no banco quem pertence a cada `chat_id` e usar `.read`/`.write` com essa condição (ex.: `auth.uid == data.child('owner_uid').val()`). O exemplo acima resolve o “Permission denied” para desenvolvimento/teste.

---

## Problemas comuns

- **“Keystore não encontrado”**  
  Confira o caminho do `debug.keystore`. No Windows costuma ser:  
  `C:\Users\SEU_USUARIO\.android\debug.keystore`

- **“Senha incorreta”**  
  No debug, a senha padrão é `android` (tanto storepass quanto keypass).

- **Ainda não envia SMS**  
  Confirme que: (1) os SHAs estão no app **correto** (user ou driver), (2) o número **não** está em “números de teste” e (3) já passaram alguns minutos após salvar no Firebase.

- **App de release (Play Store)**  
  Quando for publicar, adicione também no Firebase os SHAs do **keystore de release** (e, se usar Google Play App Signing, o SHA que a Play Console mostrar para “App signing key”).

- **“Too many requests” / “We have blocked all requests from this device”**  
  O Firebase/Google bloqueou **temporariamente** este dispositivo ou número por muitas tentativas de envio de SMS (proteção contra abuso). **Não é bug do app.**  
  - **O que fazer:** aguardar algumas horas (até cerca de 24 h) e tentar de novo.  
  - Evite ficar solicitando código várias vezes seguidas; use “Reenviar código” só quando precisar.
