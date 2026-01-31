# 🌐 Guia para Testar no Chrome

## Como executar no Chrome

### 1. Executar o app em modo web
```bash
flutter run -d chrome
```

Ou para build de release:
```bash
flutter build web
```

Depois, para servir localmente:
```bash
cd build/web
python -m http.server 8000
# ou
npx serve
```

Acesse: `http://localhost:8000`

## ⚠️ Funcionalidades que podem não funcionar no web

### Funcionalidades desabilitadas no web:
- **Notificações push** (Firebase Messaging) - não suportado no web
- **Métodos nativos** (MethodChannel) - protegidos com `kIsWeb`
- **Atualização de posição em background** - requer permissões específicas
- **Package Info** - limitado no web
- **Algumas permissões** - podem não estar disponíveis

### Funcionalidades que funcionam:
- ✅ Login com email/celular
- ✅ Chamadas de API
- ✅ Firebase Database (com configuração)
- ✅ Firebase Auth
- ✅ Navegação entre telas
- ✅ Formulários
- ✅ Google Maps (com API key)

## 🔧 Ajustes realizados

1. **Import de `kIsWeb`** adicionado em `main.dart` e `functions.dart`
2. **Proteção de MethodChannel** - todas as chamadas nativas protegidas
3. **Configuração do Firebase para web** - adicionada no `index.html`
4. **Verificações de plataforma** - ajustadas para incluir web
5. **Login by** - agora envia 'web' quando executado no Chrome

## 📝 Logs

Os logs agora mostram quando está rodando no web:
```
🔥 [FIREBASE INIT] Plataforma: WEB
🌐 [INIT] Web detectado - pulando initMessaging
🌐 [INIT] Web detectado - pulando currentPositionUpdate
```

## 🚀 Comandos úteis

```bash
# Limpar build
flutter clean

# Obter dependências
flutter pub get

# Executar no Chrome
flutter run -d chrome

# Build para produção
flutter build web --release
```

## ⚡ Dicas

1. Use o DevTools do Chrome (F12) para ver os logs
2. Algumas funcionalidades podem precisar de HTTPS em produção
3. Permissões de localização precisam ser concedidas manualmente no navegador
4. Firebase Database pode ter limitações no web dependendo da configuração
