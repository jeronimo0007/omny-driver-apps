# Diagnóstico de Comunicação Firebase

## Configuração Atual

### Firebase Project
- **Project ID**: `goin-7372e`
- **Project Number**: `725859983456`
- **Database URL**: `https://goin-7372e-default-rtdb.firebaseio.com`
- **Storage Bucket**: `goin-7372e.firebasestorage.app`

### Configuração Android (google-services.json)
- **Package Name**: `br.app.omny.driver`
- **API Key**: `AIzaSyDQfTS6lgiK2E1iOYmQj6Mm63j0I27N9N4`
- **App ID**: `1:725859983456:android:99a85914b9ca7c7d6c2305`

### Configuração Web (fornecida)
- **API Key**: `AIzaSyCceQTKfoIsPblC4vWMyxC8HfaVUKc0U5U`
- **App ID**: `1:725859983456:web:7d738c80d0d3e3376c2305`

## Problemas Comuns e Soluções

### 1. Problema: Timeout ao conectar ao Firebase Database

**Sintomas:**
- Logs mostram "TIMEOUT: Não recebeu resposta em 10 segundos"
- App não consegue ler o nó `call_FB_OTP`

**Possíveis Causas:**
1. **Regras de Segurança do Firebase bloqueando acesso**
   - Verifique as regras do Firebase Realtime Database no Firebase Console
   - O nó `call_FB_OTP` precisa estar acessível para leitura

2. **Problema de conectividade**
   - Verifique se o dispositivo tem internet
   - Verifique se há firewall bloqueando conexões

3. **Firebase Database não está ativo**
   - Verifique no Firebase Console se o Realtime Database está habilitado
   - Verifique se está usando o banco correto (padrão vs. específico)

**Solução:**
```json
// Regras sugeridas para Firebase Realtime Database
{
  "rules": {
    "call_FB_OTP": {
      ".read": true,
      ".write": false
    },
    "drivers": {
      ".read": "auth != null",
      ".write": "auth != null"
    },
    "requests": {
      ".read": "auth != null",
      ".write": "auth != null"
    }
  }
}
```

### 2. Problema: PERMISSION_DENIED

**Sintomas:**
- Logs mostram "ERRO DE PERMISSÃO: As regras do Firebase estão bloqueando o acesso"

**Solução:**
1. Acesse o Firebase Console
2. Vá em Realtime Database > Rules
3. Verifique se o nó `call_FB_OTP` tem permissão de leitura
4. Para testes, você pode usar regras temporárias:
```json
{
  "rules": {
    ".read": true,
    ".write": false
  }
}
```
⚠️ **ATENÇÃO**: Essas regras são apenas para testes. Configure regras adequadas para produção.

### 3. Problema: Nó call_FB_OTP não existe

**Sintomas:**
- Logs mostram "AVISO: Nó call_FB_OTP não existe no Firebase"

**Solução:**
1. Acesse o Firebase Console
2. Vá em Realtime Database > Data
3. Crie o nó `call_FB_OTP` com o valor necessário (geralmente `0` ou `1`)
4. Verifique se o nó está na raiz do banco de dados

### 4. Problema: Diferença entre configurações Web e Android

**Observação:**
- As API Keys são diferentes entre Web e Android (isso é normal)
- O importante é que o `project_id` seja o mesmo (ambos usam `goin-7372e` ✅)
- O `databaseURL` deve ser o mesmo (ambos usam `https://goin-7372e-default-rtdb.firebaseio.com` ✅)

### 5. Problema: App não inicializa Firebase corretamente

**Sintomas:**
- App trava na inicialização
- Erros relacionados a `Firebase.initializeApp()`

**Solução:**
1. Verifique se `google-services.json` está no local correto: `android/app/google-services.json`
2. Verifique se o plugin `google-services` está aplicado no `build.gradle`
3. Verifique se o `package_name` no `google-services.json` corresponde ao `applicationId` no `build.gradle`

## Como Verificar os Logs

Execute o app e procure pelos seguintes logs no console:

### Logs de Inicialização
```
🔥 [FIREBASE INIT] Iniciando Firebase...
🔥 [FIREBASE INIT] Firebase inicializado com sucesso
🔥 [FIREBASE CHECK] Verificando conexão com Firebase Database...
🔥 [FIREBASE CHECK] Database URL: https://goin-7372e-default-rtdb.firebaseio.com
```

### Logs de Sucesso
```
🔥 [FIREBASE CHECK] Nó call_FB_OTP existe: [valor]
🔥 [FIREBASE CHECK] Conexão com Firebase Database: OK
```

### Logs de Erro
```
🔥 [FIREBASE] otpCall - ERRO: [mensagem de erro]
🔥 [FIREBASE] otpCall - Tipo do erro: [tipo]
```

## Checklist de Verificação

- [ ] `google-services.json` está em `android/app/google-services.json`
- [ ] `package_name` no `google-services.json` é `br.app.omny.driver`
- [ ] Plugin `google-services` está aplicado no `build.gradle`
- [ ] Firebase Realtime Database está habilitado no Firebase Console
- [ ] Nó `call_FB_OTP` existe no Firebase Database
- [ ] Regras do Firebase permitem leitura do nó `call_FB_OTP`
- [ ] App tem permissão de internet no `AndroidManifest.xml`
- [ ] Dispositivo/Emulador tem conexão com internet

## Verificação no Firebase Console

1. Acesse: https://console.firebase.google.com/
2. Selecione o projeto `goin-7372e`
3. Vá em **Realtime Database**
4. Verifique:
   - Se o banco está ativo
   - Se o nó `call_FB_OTP` existe
   - Se as regras permitem leitura

## Verificação das Regras

1. No Firebase Console, vá em **Realtime Database > Rules**
2. Verifique se há regras bloqueando o acesso
3. Para testes, use regras temporárias (conforme mostrado acima)
4. ⚠️ **NUNCA deixe regras abertas em produção**

## Contato com o Servidor/API

Se o problema persistir, verifique com a equipe do servidor:

1. **O servidor está conseguindo conectar ao Firebase?**
   - Verifique os logs do servidor
   - Verifique se o servidor usa as mesmas credenciais

2. **As configurações do servidor estão corretas?**
   - Verifique se o `project_id` é o mesmo
   - Verifique se o `databaseURL` é o mesmo
   - Verifique se as regras permitem acesso do servidor

3. **Há algum problema de rede/firewall?**
   - Verifique se o servidor pode acessar o Firebase
   - Verifique se há firewall bloqueando conexões

## Próximos Passos

1. Execute o app e verifique os logs
2. Identifique qual erro está ocorrendo
3. Siga as soluções específicas para o erro encontrado
4. Se o problema persistir, compartilhe os logs completos com a equipe
