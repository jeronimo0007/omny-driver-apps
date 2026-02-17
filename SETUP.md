# Guia de Configuração e Execução

## ✅ Soluções Permanentes Implementadas

### 1. Script de Correção Automática de Plugins

Foi criado um script que corrige automaticamente plugins Android incompatíveis com AGP 8.1.1+.

**Localização:** `scripts/fix_android_plugins.ps1`

**Como usar:**

#### Opção 1: Script combinado (Recomendado)
```powershell
powershell -ExecutionPolicy Bypass -File scripts\pub_get_with_fix.ps1
```

#### Opção 2: Manual
```powershell
flutter pub get
powershell -ExecutionPolicy Bypass -File scripts\fix_android_plugins.ps1
```

### 2. Plugins Corrigidos Automaticamente

O script corrige automaticamente os seguintes plugins:

**Namespaces adicionados:**
- `cashfree_pg` → `com.cashfree.pg`
- `contacts_service` → `flutter.plugins.contactsservice.contactsservice`
- `permission_handler_android` → `com.baseflow.permissionhandler`
- `razorpay_flutter` → `com.razorpay.razorpay_flutter`

**BuildConfig habilitado:**
- `firebase_auth`
- `firebase_core`
- `firebase_database`
- `firebase_messaging`

**KotlinOptions corrigido:**
- `stripe_android` → jvmTarget = '1.8'

### 3. Configurações do Projeto

- **Package Name:** `br.app.omny.driver`
- **Namespace:** `br.app.omny.driver`
- **Gradle:** 8.5
- **Android Gradle Plugin:** 8.1.1
- **Kotlin:** 1.9.10

### 4. Firebase

O arquivo `google-services.json` está configurado em:
- `android/app/google-services.json`

## 🚀 Como Rodar a Aplicação

### Primeira vez ou após limpar cache:

```powershell
# 1. Obter dependências e aplicar correções
powershell -ExecutionPolicy Bypass -File scripts\pub_get_with_fix.ps1

# 2. Rodar a aplicação
flutter run -d emulator-5554 --android-skip-build-dependency-validation
```

### Execuções subsequentes:

```powershell
flutter run -d emulator-5554 --android-skip-build-dependency-validation
```

## ⚠️ Importante

- **Sempre execute o script de correção após:**
  - `flutter pub get`
  - `flutter pub cache repair`
  - Limpar o cache do Flutter
  - Adicionar/atualizar dependências

- **O script é permanente** e será executado sempre que necessário, corrigindo os plugins automaticamente.

## 📝 Notas

- Os avisos sobre plataformas não suportadas podem ser ignorados (apenas Android, iOS e Web são suportados)
- Use `--android-skip-build-dependency-validation` para pular validações de versão (necessário devido a plugins desatualizados)
