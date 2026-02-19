import 'package:flutter/foundation.dart';

/// 1 = novo login (e-mail/senha em auth.omny.app.br); 0 = fluxo antigo (telefone/OTP).
/// Definido pela API common/modules (enable_loginEmailPswd) na inicialização; padrão 0.
int loginEmailPswd = 0;

/// IMPORTANTE (login por e-mail): driver.omny.app.br precisa validar o JWT com o MESMO
/// segredo usado pelo auth.omny.app.br. Senão todas as chamadas ao driver retornam 401.

/// Localhost só em debug (web/emulador). APK/release usa auth.omny.app.br e driver.omny.app.br.
const bool useLocalAuth = !kReleaseMode;

/// No emulador Android, localhost é o próprio emulador. 10.0.2.2 = localhost do PC.
String get _localHost =>
    (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
        ? '10.0.2.2'
        : 'localhost';

/// URL base para login/cadastro (novo fluxo)
String get authBaseUrl =>
    useLocalAuth ? 'http://$_localHost:8081/' : 'https://auth.omny.app.br/';
//String get authBaseUrl => 'https://auth.omny.app.br/';

/// Path do endpoint de refresh (access_token expira em 180s). Ex.: 'api/v1/refresh' ou 'api/v1/token/refresh'
const String authRefreshPath = 'api/v1/refresh';

/// URL base para as demais APIs (perfil, corridas, etc.)
String get apiBaseUrl => kReleaseMode
    ? 'https://driver.omny.app.br/'
    : 'https://driver.omny.app.br/';
