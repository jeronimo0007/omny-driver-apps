# 🔥 Configuração Completa do Firebase Realtime Database

## 📋 Nós Necessários

Baseado na documentação oficial, você precisa criar os seguintes nós no Firebase Realtime Database:

### Nós de Configuração OTP
- ✅ `call_FB_OTP` - Controla se usa Firebase OTP ou OTP próprio (true/false)

### Nós de Package/Bundle
- ✅ `user_package_name` - Nome do pacote do app de usuário
- ✅ `user_bundle_id` - Bundle ID do app de usuário (iOS)
- ✅ `driver_package_name` - Nome do pacote do app de motorista
- ✅ `driver_bundle_id` - Bundle ID do app de motorista (iOS)

### Nós de Versão (Opcional)
- `driver_android_version` - Versão mínima do Android para motoristas
- `driver_ios_version` - Versão mínima do iOS para motoristas
- `user_android_version` - Versão mínima do Android para usuários
- `user_ios_version` - Versão mínima do iOS para usuários

### Nós de Dados (Criados Automaticamente)
- `drivers` - Dados dos motoristas
- `requests` - Solicitações de corrida
- `request-meta` - Metadados das solicitações
- `bid-meta` - Metadados de lances
- `owners` - Dados dos proprietários
- `SOS` - Dados de emergência

## 🔧 Passo a Passo: Como Configurar

### Passo 1: Acessar o Firebase Console

1. Acesse: https://console.firebase.google.com/
2. Faça login com a conta do projeto
3. Selecione o projeto: **goin-7372e**

### Passo 2: Acessar Realtime Database

1. No menu lateral, clique em **Realtime Database**
2. Se você ainda não criou o banco:
   - Clique em **Criar banco de dados**
   - Escolha a localização (recomendado: mais próxima dos usuários)
   - Escolha o modo: **Modo de teste** (para começar)

### Passo 3: Criar os Nós de Configuração

Na aba **Data**, clique no botão **"+"** na raiz e crie cada nó:

#### 3.1. call_FB_OTP
```
Nome: call_FB_OTP
Valor: false (ou true)
Tipo: boolean
```
- `false` = Usa OTP próprio (recomendado para testes)
- `true` = Usa Firebase Auth para OTP

#### 3.2. driver_package_name
```
Nome: driver_package_name
Valor: br.app.omny.driver
Tipo: string
```

#### 3.3. driver_bundle_id
```
Nome: driver_bundle_id
Valor: br.app.omny.driver
Tipo: string
```

#### 3.4. user_package_name
```
Nome: user_package_name
Valor: br.app.omny.user
Tipo: string
```

#### 3.5. user_bundle_id
```
Nome: user_bundle_id
Valor: br.app.omny.user
Tipo: string
```

#### 3.6. Nós de Versão (Opcional)
```
driver_android_version: 1
driver_ios_version: 1
user_android_version: 1
user_ios_version: 1
```

### Passo 4: Configurar Regras de Segurança

1. Na aba **Rules**, substitua TODO o conteúdo por:

```json
{
  "rules": {
    "drivers": {
      ".read": true,
      ".write": true,
      ".indexOn": ["is_active", "g", "service_location_id", "vehicle_type", "l", "ownerid"]
    },
    "requests": {
      ".read": true,
      ".write": true,
      ".indexOn": ["service_location_id"]
    },
    "SOS": {
      ".read": true,
      ".write": true
    },
    "call_FB_OTP": {
      ".read": true,
      ".write": true
    },
    "driver_android_version": {
      ".read": true,
      ".write": true
    },
    "driver_ios_version": {
      ".read": true,
      ".write": true
    },
    "user_android_version": {
      ".read": true,
      ".write": true
    },
    "user_ios_version": {
      ".read": true,
      ".write": true
    },
    "user_package_name": {
      ".read": true,
      ".write": true
    },
    "user_bundle_id": {
      ".read": true,
      ".write": true
    },
    "driver_package_name": {
      ".read": true,
      ".write": true
    },
    "driver_bundle_id": {
      ".read": true,
      ".write": true
    },
    "request-meta": {
      ".read": true,
      ".write": true,
      ".indexOn": ["driver_id", "user_id"]
    },
    "bid-meta": {
      ".read": true,
      ".write": true,
      ".indexOn": ["driver_id", "user_id", "g"]
    },
    "owners": {
      ".read": true,
      ".write": true,
      ".indexOn": ["driver_id", "user_id"]
    }
  }
}
```

2. Clique em **Publicar**

⚠️ **ATENÇÃO**: Essas regras permitem leitura e escrita para todos. Para produção, implemente autenticação e regras mais restritivas.

### Passo 5: Importar JSON de Exemplo (Opcional)

Se você tiver acesso ao JSON de exemplo:

1. Acesse: https://tagxi-server.ondemandappz.com/firebase-database.json
2. Copie o conteúdo JSON
3. No Firebase Console, vá em **Realtime Database > Data**
4. Clique nos três pontos (⋮) > **Importar JSON**
5. Cole o JSON e clique em **Importar**

⚠️ **CUIDADO**: Isso substituirá todos os dados existentes!

## 📊 Estrutura Final Esperada

Após a configuração, sua estrutura deve ficar assim:

```
goin-7372e-default-rtdb/
├── call_FB_OTP: false
├── driver_package_name: "br.app.omny.driver"
├── driver_bundle_id: "br.app.omny.driver"
├── user_package_name: "br.app.omny.user"
├── user_bundle_id: "br.app.omny.user"
├── driver_android_version: 1 (opcional)
├── driver_ios_version: 1 (opcional)
├── user_android_version: 1 (opcional)
├── user_ios_version: 1 (opcional)
├── drivers/ (criado automaticamente)
├── requests/ (criado automaticamente)
├── request-meta/ (criado automaticamente)
├── bid-meta/ (criado automaticamente)
├── owners/ (criado automaticamente)
└── SOS/ (criado automaticamente)
```

## ✅ Checklist de Verificação

Após configurar, verifique:

- [ ] Nó `call_FB_OTP` existe e tem valor `true` ou `false`
- [ ] Nó `driver_package_name` existe com valor `br.app.omny.driver`
- [ ] Nó `driver_bundle_id` existe com valor `br.app.omny.driver`
- [ ] Nó `user_package_name` existe com valor `br.app.omny.user`
- [ ] Nó `user_bundle_id` existe com valor `br.app.omny.user`
- [ ] Nós de versão foram criados (opcional)
- [ ] Regras de segurança foram atualizadas
- [ ] Regras foram publicadas

## 🧪 Testar a Configuração

1. Execute o app:
   ```bash
   flutter run
   ```

2. Verifique os logs:
   - Procure por: `🔥 [FIREBASE CHECK] Nó call_FB_OTP existe: true/false`
   - Se aparecer "existe: true" ou "existe: false", está funcionando!

3. Teste o login:
   - Tente fazer login com um número de telefone
   - O app deve funcionar normalmente

## 🔒 Segurança para Produção

Para produção, você deve:

1. **Implementar autenticação**:
   - Usuários e motoristas devem estar autenticados
   - Usar Firebase Auth para autenticação

2. **Restringir regras**:
   - Permitir leitura/escrita apenas para usuários autenticados
   - Limitar acesso baseado em roles (driver, user, owner)

3. **Exemplo de regras mais seguras**:
```json
{
  "rules": {
    "drivers": {
      ".read": "auth != null && auth.token.role == 'driver'",
      ".write": "auth != null && auth.token.role == 'driver'"
    },
    "requests": {
      ".read": "auth != null",
      ".write": "auth != null"
    },
    "call_FB_OTP": {
      ".read": true,
      ".write": false
    }
  }
}
```

## 📝 Notas Importantes

- Os nós `drivers`, `requests`, etc. são criados automaticamente pelo app quando necessário
- Você só precisa criar os nós de configuração manualmente
- As regras de segurança devem ser configuradas antes de colocar em produção
- O JSON de exemplo pode ser usado como referência, mas ajuste os valores para seu projeto

## 🆘 Problemas Comuns

### Problema: "Permission Denied"
**Solução**: Verifique se as regras foram publicadas corretamente

### Problema: Nó não aparece
**Solução**: Recarregue a página do Firebase Console

### Problema: App não consegue ler
**Solução**: Verifique se o `package_name` no `google-services.json` corresponde ao valor em `driver_package_name`

## 📞 Suporte

Se tiver problemas:
1. Verifique os logs do app (procure por `🔥 [FIREBASE]`)
2. Verifique as regras no Firebase Console
3. Verifique se todos os nós foram criados
4. Consulte `FIREBASE_DIAGNOSTICO.md` para mais detalhes
