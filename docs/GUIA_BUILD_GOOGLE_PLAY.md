# Guia Completo: Gerar Build e Enviar para Google Play Store

## 📋 Pré-requisitos

1. Conta no Google Play Console (https://play.google.com/console)
2. Flutter SDK instalado e configurado
3. Java JDK 17 ou superior instalado
4. Android Studio instalado (opcional, mas recomendado)

---

## 🔐 Passo 1: Criar Keystore (Chave de Assinatura)

A keystore é necessária para assinar o aplicativo. **IMPORTANTE: Guarde esta keystore com segurança!**

### 1.1. Abrir Terminal/PowerShell

Navegue até a pasta do projeto:
```bash
cd d:\projetos\omny\driver-app-user
```

### 1.2. Criar a Keystore

Execute o comando abaixo (substitua as informações conforme necessário):

```bash
keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**Informações que você precisará fornecer:**
- **Senha da keystore**: Crie uma senha forte e anote em local seguro
- **Senha da chave**: Pode ser a mesma da keystore ou diferente
- **Nome e sobrenome**: Seu nome completo
- **Unidade organizacional**: Nome da sua empresa/organização
- **Organização**: Nome da organização
- **Cidade**: Sua cidade
- **Estado**: Seu estado
- **Código do país**: BR (para Brasil)

**Exemplo:**
```
Senha da keystore: MinhaSenhaSegura123!
Confirmar senha: MinhaSenhaSegura123!
Nome e sobrenome: João Silva
Unidade organizacional: Desenvolvimento
Organização: Minha Empresa
Cidade: São Paulo
Estado: SP
Código do país: BR
```

### 1.3. Verificar se a Keystore foi criada

```bash
dir android\app\upload-keystore.jks
```

---

## 🔑 Passo 2: Configurar key.properties

### 2.1. Criar arquivo key.properties

Crie um arquivo chamado `key.properties` na pasta `android/` com o seguinte conteúdo:

```properties
storePassword=SuaSenhaDaKeystore
keyPassword=SuaSenhaDaChave
keyAlias=upload
storeFile=app/upload-keystore.jks
```

**Substitua:**
- `SuaSenhaDaKeystore`: A senha que você criou para a keystore
- `SuaSenhaDaChave`: A senha da chave (pode ser a mesma)
- `upload`: O alias que você usou ao criar a keystore
- `app/upload-keystore.jks`: Caminho relativo da keystore

### 2.2. Adicionar ao .gitignore

**IMPORTANTE:** Adicione o arquivo `key.properties` e a keystore ao `.gitignore` para não commitar informações sensíveis:

Abra o arquivo `android/.gitignore` e adicione:
```
key.properties
upload-keystore.jks
```

---

## ⚙️ Passo 3: Atualizar build.gradle

### 3.1. Editar android/app/build.gradle

O arquivo já está parcialmente configurado. Você precisa atualizar a seção `buildTypes` para usar a keystore de produção:

**Localizar a seção `buildTypes` (linha ~76) e substituir:**

```gradle
buildTypes {
    release {
        // Signing with the debug keys for now, so `flutter run --release` works.
        signingConfig signingConfigs.debug // Usar chave de debug para testes
        minifyEnabled false // Desabilitar minificação temporariamente
        shrinkResources false
    }
}
```

**Por:**

```gradle
signingConfigs {
    release {
        if (keystorePropertiesExist) {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile file(keystoreProperties['storeFile'])
            storePassword keystoreProperties['storePassword']
        }
    }
}

buildTypes {
    release {
        signingConfig signingConfigs.release
        minifyEnabled true
        shrinkResources true
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
    }
}
```

### 3.2. Criar arquivo proguard-rules.pro (opcional)

Crie o arquivo `android/app/proguard-rules.pro` com regras básicas:

```proguard
# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Google Maps
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
```

---

## 📦 Passo 4: Atualizar Versão do App

### 4.1. Editar pubspec.yaml

Atualize a versão no arquivo `pubspec.yaml`:

```yaml
version: 1.0.1+1
```

**Formato:** `version: X.Y.Z+BUILD_NUMBER`
- **X.Y.Z**: Versão do app (ex: 1.0.1)
- **BUILD_NUMBER**: Número de build incremental (ex: 1, 2, 3...)

**Para cada nova versão enviada ao Google Play:**
- Incremente o BUILD_NUMBER (ex: 1.0.1+2, 1.0.1+3...)
- Para atualizações maiores, altere a versão (ex: 1.0.2+1)

---

## 🏗️ Passo 5: Gerar o Android App Bundle (AAB)

### 5.1. Limpar builds anteriores

```bash
flutter clean
```

### 5.2. Obter dependências

```bash
flutter pub get
```

### 5.3. Gerar o AAB (Android App Bundle)

```bash
flutter build appbundle --release
```

**O arquivo será gerado em:**
```
build/app/outputs/bundle/release/app-release.aab
```

### 5.4. Verificar o tamanho do arquivo

```bash
dir build\app\outputs\bundle\release\app-release.aab
```

---

## 📤 Passo 6: Enviar para Google Play Console

### 6.1. Acessar Google Play Console

1. Acesse: https://play.google.com/console
2. Faça login com sua conta Google
3. Selecione seu app ou crie um novo

### 6.2. Criar Nova Versão (se for a primeira vez)

1. No menu lateral, clique em **"Produção"** ou **"Teste interno"**
2. Clique em **"Criar nova versão"**
3. Preencha as informações da versão

### 6.3. Fazer Upload do AAB

1. Na seção **"App bundles e APKs"**, clique em **"Fazer upload"**
2. Selecione o arquivo: `build/app/outputs/bundle/release/app-release.aab`
3. Aguarde o upload e processamento

### 6.4. Preencher Informações da Versão

- **Notas da versão**: Descreva as mudanças desta versão
- **Conteúdo da versão**: Informações sobre o que foi atualizado

### 6.5. Revisar e Publicar

1. Revise todas as informações
2. Clique em **"Revisar versão"**
3. Se tudo estiver correto, clique em **"Iniciar lançamento para produção"**

---

## ✅ Checklist Antes de Enviar

- [ ] Keystore criada e guardada em local seguro
- [ ] Arquivo `key.properties` configurado corretamente
- [ ] `build.gradle` atualizado com signingConfig de release
- [ ] Versão atualizada no `pubspec.yaml`
- [ ] `.gitignore` atualizado para não commitar keystore
- [ ] App testado em modo release
- [ ] Todas as permissões configuradas no AndroidManifest.xml
- [ ] Ícone do app configurado
- [ ] Nome do app correto
- [ ] Política de privacidade configurada (se necessário)

---

## 🔧 Comandos Úteis

### Gerar APK para testes (não usar para Play Store)
```bash
flutter build apk --release
```

### Verificar informações do app
```bash
flutter doctor -v
```

### Verificar versão atual
```bash
flutter --version
```

### Limpar cache e rebuild
```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

---

## 🆘 Solução de Problemas

### Erro: "Keystore file not found"
- Verifique se o caminho no `key.properties` está correto
- Certifique-se de que a keystore está em `android/app/upload-keystore.jks`

### Erro: "Wrong password"
- Verifique as senhas no arquivo `key.properties`
- Certifique-se de que não há espaços extras

### Erro: "Version code already used"
- Incremente o BUILD_NUMBER no `pubspec.yaml`
- Exemplo: de `1.0.1+1` para `1.0.1+2`

### Erro: "App not signed"
- Verifique se o `signingConfig` está configurado corretamente no `build.gradle`
- Certifique-se de que o `key.properties` existe e está correto

---

## 📝 Notas Importantes

1. **NUNCA compartilhe ou commite a keystore ou key.properties no Git**
2. **Guarde a keystore em local seguro** - se perder, não poderá atualizar o app
3. **Cada versão enviada ao Play Store precisa ter um BUILD_NUMBER maior**
4. **O Google Play aceita apenas AAB (App Bundle), não APK**
5. **O processo de revisão do Google pode levar algumas horas ou dias**

---

## 📞 Suporte

Se encontrar problemas:
1. Verifique os logs do Flutter: `flutter build appbundle --release -v`
2. Consulte a documentação oficial: https://docs.flutter.dev/deployment/android
3. Verifique o Google Play Console para mensagens de erro específicas

---

---

## 🔑 Usar a Mesma Keystore em Múltiplos Apps?

### ⚠️ **NÃO é Recomendado, mas é Possível**

**Resposta curta:** Tecnicamente você **pode** usar a mesma keystore em todos os seus apps, mas **NÃO é recomendado** por questões de segurança e boas práticas.

### ❌ **Desvantagens de Usar a Mesma Keystore:**

1. **Risco de Segurança Ampliado**
   - Se a keystore for comprometida, **TODOS** os seus apps estarão em risco
   - Um único ponto de falha afeta múltiplos projetos
   - Se alguém conseguir acesso à keystore, pode atualizar qualquer um dos seus apps

2. **Dificuldade de Gestão**
   - Se precisar revogar ou trocar a keystore de um app específico, todos serão afetados
   - Não é possível isolar problemas de segurança por app

3. **Boas Práticas de Segurança**
   - Princípio de "menor privilégio": cada app deve ter sua própria chave
   - Facilita auditoria e rastreamento de problemas

4. **Compartilhamento de Equipe**
   - Se diferentes desenvolvedores/equipes trabalham em apps diferentes, todos precisariam ter acesso à mesma keystore
   - Aumenta o risco de vazamento acidental

### ✅ **Vantagens de Usar a Mesma Keystore:**

1. **Facilidade de Gerenciamento**
   - Uma única senha para lembrar
   - Um único arquivo para fazer backup
   - Menos complexidade na configuração inicial

2. **Cenários Válidos:**
   - Apps da mesma família/marca (ex: App Cliente, App Motorista, App Admin)
   - Apps que compartilham a mesma infraestrutura e equipe
   - Projetos internos da mesma organização

### 🎯 **Recomendação:**

#### **Use a mesma keystore APENAS se:**
- ✅ Os apps fazem parte da mesma família/marca
- ✅ A mesma equipe gerencia todos os apps
- ✅ Você entende e aceita o risco de segurança
- ✅ Os apps compartilham a mesma infraestrutura

#### **Use keystores separadas se:**
- ❌ Os apps são de clientes diferentes
- ❌ Diferentes equipes gerenciam os apps
- ❌ Os apps têm níveis diferentes de criticidade
- ❌ Você quer isolar riscos de segurança

### 📝 **Estratégia Recomendada:**

**Para apps da mesma família (ex: Omny User, Omny Driver):**
```
omny-keystore.jks  → Usar para todos os apps Omny
```

**Para apps de clientes diferentes:**
```
cliente1-keystore.jks  → App do Cliente 1
cliente2-keystore.jks  → App do Cliente 2
omny-keystore.jks      → Apps Omny
```

### 🔒 **Se Decidir Usar a Mesma Keystore:**

1. **Backup Seguro:**
   - Faça backup em múltiplos locais seguros
   - Use criptografia adicional para o backup
   - Documente onde está guardada

2. **Controle de Acesso:**
   - Limite quem tem acesso à keystore
   - Use um gerenciador de senhas seguro
   - Documente quem tem acesso

3. **Monitoramento:**
   - Monitore atualizações nos apps regularmente
   - Configure alertas no Google Play Console

### 💡 **Alternativa: Google Play App Signing**

O Google Play oferece o **App Signing by Google Play**, onde:
- Você cria uma "upload key" (chave de upload)
- O Google Play cria e gerencia a "app signing key" (chave de assinatura final)
- Se perder a upload key, o Google pode gerar uma nova
- Mais seguro e fácil de gerenciar

**Para ativar:**
1. No Google Play Console, vá em **App Integrity**
2. Ative **App Signing by Google Play**
3. Siga as instruções para fazer upload da keystore inicial

---

**Boa sorte com o lançamento! 🚀**
