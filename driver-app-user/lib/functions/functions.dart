import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../pages/NavigatorPages/editprofile.dart';
import '../pages/NavigatorPages/history.dart';
import '../pages/NavigatorPages/historydetails.dart';
import '../pages/loadingPage/loadingpage.dart';
import '../pages/login/login.dart';
import '../pages/login/namepage.dart';
import '../pages/onTripPage/booking_confirmation.dart';
import '../pages/onTripPage/map_page.dart';
import '../pages/onTripPage/review_page.dart';
import '../pages/referralcode/referral_code.dart';
import '../config/api_config.dart';
import '../styles/styles.dart';

//languages code
dynamic phcode;
dynamic platform;
dynamic pref;
String isActive = '';
double duration = 30.0;
var audio = 'audio/notification_sound.mp3';
bool internet = true;

// Variável global para armazenar mensagem de erro do servidor
String serverErrorMessage = '';

// Código de indicação no cadastro (preenchido na NamePage)
String loginReferralCode = '';

//base url (local em debug, produção em release - ver lib/config/api_config.dart)
String url = apiBaseUrl;
String mapkey = 'AIzaSyDIFOaDalHwTa--63nbVUVVM13X3EWTI6Q';

/// Formata número para exibição no padrão brasileiro (vírgula como decimal).
/// Apenas para exibição; envio à API continua com ponto.
String formatDecimalBr(dynamic value) {
  if (value == null) return '0,00';
  final s = value.toString().replaceFirst(',', '.');
  final n = value is num ? value : (double.tryParse(s) ?? 0);
  return n.toStringAsFixed(2).replaceAll('.', ',');
}

// Função helper para extrair mensagem de erro do servidor
// Suporta diferentes formatos de resposta de erro (400, 422, etc.)
String extractErrorMessage(http.Response response) {
  try {
    var responseBody = response.body;
    if (responseBody.isEmpty) {
      return 'Erro desconhecido do servidor';
    }

    var jsonData = jsonDecode(responseBody);

    // Tentar diferentes formatos de resposta de erro
    // Formato 1: { "message": "mensagem" }
    if (jsonData['message'] != null) {
      return jsonData['message'].toString();
    }

    // Formato 2: { "error": "mensagem" }
    if (jsonData['error'] != null) {
      return jsonData['error'].toString();
    }

    // Formato 3: { "errors": { "campo": ["mensagem1", "mensagem2"] } }
    if (jsonData['errors'] != null) {
      var errors = jsonData['errors'];
      if (errors is Map) {
        // Pegar a primeira mensagem de erro
        var firstKey = errors.keys.isNotEmpty ? errors.keys.first : null;
        if (firstKey != null) {
          var errorMessages = errors[firstKey];
          if (errorMessages is List && errorMessages.isNotEmpty) {
            return errorMessages[0]
                .toString()
                .replaceAll('[', '')
                .replaceAll(']', '');
          } else if (errorMessages is String) {
            return errorMessages;
          }
        }
      }
    }

    // Formato 4: { "data": { "message": "mensagem" } }
    if (jsonData['data'] != null && jsonData['data'] is Map) {
      var data = jsonData['data'];
      if (data['message'] != null) {
        return data['message'].toString();
      }
    }

    // Se não encontrou nenhum formato conhecido, retornar o body completo (limitado)
    return responseBody.length > 200
        ? '${responseBody.substring(0, 200)}...'
        : responseBody;
  } catch (e) {
    debugPrint('⚠️ Erro ao extrair mensagem de erro: $e');
    debugPrint('   Response body: ${response.body}');
    // Se não conseguir decodificar, retornar uma mensagem genérica com o status code
    return 'Erro ${response.statusCode}: ${response.body.length > 100 ? "${response.body.substring(0, 100)}..." : response.body}';
  }
}

// Função helper para logar requisições HTTP
void logApiCall(String method, String endpoint,
    {Map<String, String>? headers,
    dynamic body,
    int? statusCode,
    String? responseBody,
    String? error}) {
  debugPrint('═══════════════════════════════════════════════════════════');
  debugPrint('🌐 API CALL: $method $endpoint');
  debugPrint('───────────────────────────────────────────────────────────');
  if (headers != null && headers.isNotEmpty) {
    debugPrint('📤 Headers:');
    headers.forEach((key, value) {
      // Mostrar bearer token completo para debug
      debugPrint('   $key: $value');
    });
  }
  if (body != null) {
    debugPrint('📦 Body: $body');
  }
  if (statusCode != null) {
    debugPrint('📥 Status Code: $statusCode');
  }
  if (responseBody != null) {
    debugPrint('📥 Response: $responseBody');
  }
  if (error != null) {
    debugPrint('❌ Error: $error');
  }
  debugPrint('═══════════════════════════════════════════════════════════');
}

//check internet connection

checkInternetConnection() {
  Connectivity().onConnectivityChanged.listen((connectionState) {
    if (connectionState == ConnectivityResult.none) {
      internet = false;
      valueNotifierHome.incrementNotifier();
      valueNotifierBook.incrementNotifier();
    } else {
      internet = true;
      valueNotifierHome.incrementNotifier();
      valueNotifierBook.incrementNotifier();
    }
  });
}

getDetailsOfDevice() async {
  debugPrint('🔄 Iniciando getDetailsOfDevice()...');
  try {
    debugPrint('🔄 Verificando conectividade...');
    var connectivityResult = await (Connectivity().checkConnectivity()).timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        debugPrint('⏱️ Timeout ao verificar conectividade');
        return ConnectivityResult.none;
      },
    );

    if (connectivityResult == ConnectivityResult.none) {
      internet = false;
      debugPrint('⚠️ Sem conexão com internet');
    } else {
      internet = true;
      debugPrint('✅ Conectividade OK');
    }

    debugPrint('🔄 Carregando assets de mapa...');
    try {
      if (isDarkTheme == true) {
        mapStyle = await rootBundle.loadString('assets/dark.json').timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint('⏱️ Timeout ao carregar dark.json');
            return '';
          },
        );
      } else {
        mapStyle =
            await rootBundle.loadString('assets/map_style_black.json').timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint('⏱️ Timeout ao carregar map_style_black.json');
            return '';
          },
        );
      }
      debugPrint('✅ Assets de mapa carregados');
    } catch (e) {
      debugPrint('⚠️ Erro ao carregar assets de mapa: $e');
      mapStyle = '';
    }

    debugPrint('🔄 Inicializando SharedPreferences...');
    pref = await SharedPreferences.getInstance().timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        debugPrint('⏱️ Timeout ao inicializar SharedPreferences');
        throw TimeoutException('Timeout ao inicializar SharedPreferences');
      },
    );
    debugPrint('✅ SharedPreferences inicializado');
  } catch (e) {
    debugPrint('❌ Erro em getDetailsOfDevice(): $e');
    // Tentar inicializar SharedPreferences mesmo em caso de erro
    try {
      pref ??= await SharedPreferences.getInstance();
    } catch (e2) {
      debugPrint('❌ Erro crítico ao inicializar SharedPreferences: $e2');
    }
  }
}

// dynamic timerLocation;
dynamic locationAllowed;

bool positionStreamStarted = false;
StreamSubscription<Position>? positionStream;

LocationSettings locationSettings = (platform == TargetPlatform.android)
    ? AndroidSettings(accuracy: LocationAccuracy.high, distanceFilter: 50)
    : AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.otherNavigation,
        distanceFilter: 50,
      );

positionStreamData() {
  // Na web, não iniciar stream de posição (não suportado)
  if (kIsWeb) {
    debugPrint('🌐 Web: Pulando positionStreamData (não suportado)');
    return;
  }

  positionStream =
      Geolocator.getPositionStream(locationSettings: locationSettings)
          .handleError((error) {
    positionStream = null;
    positionStream?.cancel();
  }).listen((Position? position) {
    if (position != null) {
      currentLocation = LatLng(position.latitude, position.longitude);
    } else {
      positionStream!.cancel();
    }
  });
}

//validate email already exist

validateEmail(email) async {
  dynamic result;
  try {
    String endpoint = '${url}api/v1/user/validate-mobile';
    Map<String, String> body = {'email': email};

    logApiCall('POST', endpoint, body: body);

    var response = await http.post(
      Uri.parse(endpoint),
      body: body,
    );

    logApiCall('POST', endpoint,
        body: body,
        statusCode: response.statusCode,
        responseBody: response.body);

    if (response.statusCode == 200) {
      var jsonVal = jsonDecode(response.body);
      if (jsonVal['success'] == true) {
        result = 'success';
      } else {
        // Exibir mensagem original do backend (ex: email_exists)
        serverErrorMessage = jsonVal['message']?.toString() ?? response.body;
        result = serverErrorMessage.isNotEmpty ? serverErrorMessage : 'failed';
        debugPrint('❌ validateEmail: Servidor retornou sucesso=false: $result');
      }
    } else if (response.statusCode == 422) {
      debugPrint(response.body);
      var error = jsonDecode(response.body)['errors'];
      result = error[error.keys.toList()[0]]
          .toString()
          .replaceAll('[', '')
          .replaceAll(']', '')
          .toString();
    } else {
      debugPrint(response.body);
      result = jsonDecode(response.body)['message'];
    }
    return result;
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

//language code
var choosenLanguage = '';
var languageDirection = '';

List languagesCode = [
  {'name': 'Portugue (Brasil)', 'code': 'pt-BR'},
  {'name': 'English', 'code': 'en'},
  {'name': 'Spanish', 'code': 'es'},
  {'name': 'French', 'code': 'fr'},
  {'name': 'Portuguese (Portugal)', 'code': 'pt'},
];

//getting country code

/// Quando true, usa a API api/v1/countries. Quando false, usa apenas Brasil fixo (sem opção de trocar).
bool useApiCountries = false;

List countries = [];
getCountryCode() async {
  dynamic result;
  try {
    if (!useApiCountries) {
      // Padrão: Brasil fixo, sem chamar a API (para reabilitar no futuro, use useApiCountries = true)
      countries = [
        {
          'name': 'Brazil',
          'dial_code': '+55',
          'dial_min_length': 10,
          'dial_max_length': 11,
          'default': true,
          'flag': 'https://flagcdn.com/w40/br.png',
        },
      ];
      phcode = 0;
      result = 'success';
      debugPrint(
          '🌎 getCountryCode: Usando país padrão Brasil (API desabilitada)');
      return result;
    }

    String endpoint = '${url}api/v1/countries';

    logApiCall('GET', endpoint);

    final response = await http.get(Uri.parse(endpoint));

    logApiCall('GET', endpoint,
        statusCode: response.statusCode,
        responseBody: response.body.length > 500
            ? '${response.body.substring(0, 500)}...'
            : response.body);

    if (response.statusCode == 200) {
      countries = jsonDecode(response.body)['data'];
      phcode =
          (countries.where((element) => element['default'] == true).isNotEmpty)
              ? countries.indexWhere((element) => element['default'] == true)
              : 0;
      result = 'success';
    } else {
      debugPrint(response.body);
      result = 'error';
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

//login firebase

String userUid = '';
var verId = '';
int? resendTokenId;
bool phoneAuthCheck = false;
dynamic credentials;
bool _isProcessingVerification =
    false; // Flag para evitar processamento duplicado

/// Cooldown para não enviar SMS várias vezes (evita bloqueio "too-many-requests")
DateTime? lastPhoneAuthRequestTime;
const int phoneAuthCooldownSeconds = 60;

int getPhoneAuthCooldownRemaining() {
  if (lastPhoneAuthRequestTime == null) return 0;
  final elapsed = DateTime.now().difference(lastPhoneAuthRequestTime!).inSeconds;
  if (elapsed >= phoneAuthCooldownSeconds) return 0;
  return phoneAuthCooldownSeconds - elapsed;
}

/// Retorna true se a requisição foi enviada, false se bloqueada por cooldown
Future<bool> phoneAuth(String phone) async {
  try {
    if (getPhoneAuthCooldownRemaining() > 0) {
      debugPrint('⚠️ Cooldown ativo. Aguarde ${getPhoneAuthCooldownRemaining()}s para reenviar.');
      phoneAuthCheck = false;
      valueNotifierLogin.incrementNotifier();
      return false;
    }

    _isProcessingVerification = false;
    credentials = null;
    lastPhoneAuthRequestTime = DateTime.now();

    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('📱 INICIANDO VERIFICAÇÃO DE TELEFONE VIA FIREBASE');
    debugPrint('───────────────────────────────────────────────────────────');
    debugPrint('📞 Número de telefone: $phone');
    debugPrint(
        '🔑 Firebase App: ${Firebase.apps.isNotEmpty ? Firebase.apps.first.name : "Nenhum app inicializado"}');
    debugPrint('🔐 Firebase Auth: ${FirebaseAuth.instance.app.name}');
    debugPrint('═══════════════════════════════════════════════════════════');

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Não usar auto-complete: exigir que o usuário digite o código e toque em Continuar (igual app do motorista)
        debugPrint(
            '🔥 [FIREBASE] verificationCompleted (ignorado: exigir código manual)');
      },
      forceResendingToken: resendTokenId,
      verificationFailed: (FirebaseAuthException e) {
        _isProcessingVerification = false;
        debugPrint(
            '═══════════════════════════════════════════════════════════');
        debugPrint('❌ ERRO NA VERIFICAÇÃO DO FIREBASE');
        debugPrint(
            '───────────────────────────────────────────────────────────');
        debugPrint('📞 Número tentado: $phone');
        debugPrint('🔴 Código do erro: ${e.code}');
        debugPrint('📝 Mensagem: ${e.message}');
        debugPrint(
            '═══════════════════════════════════════════════════════════');

        if (e.code == 'invalid-phone-number') {
          debugPrint('⚠️ O número de telefone fornecido não é válido.');
          debugPrint(
              '💡 Dica: Certifique-se de que o número está no formato internacional (ex: +5511999999999)');
        } else if (e.code == 'too-many-requests') {
          debugPrint('⚠️ Muitas tentativas. Tente novamente mais tarde.');
        } else if (e.code == 'quota-exceeded') {
          debugPrint('⚠️ Cota de SMS excedida no Firebase.');
        } else if (e.code == 'missing-phone-number') {
          debugPrint('⚠️ Número de telefone não fornecido.');
        } else if (e.code == 'operation-not-allowed') {
          debugPrint(
              '⚠️ Phone Authentication não está habilitado no Firebase Console.');
          debugPrint(
              '💡 Ação necessária: Habilite Phone Authentication em Authentication > Sign-in method no Firebase Console');
        } else if (e.code == 'missing-client-identifier' ||
            (e.message != null && e.message!.toLowerCase().contains('app identifier'))) {
          debugPrint(
              '⚠️ Firebase não reconhece o app (Play Integrity). Para enviar SMS de verdade:');
          debugPrint(
              '💡 1) No Firebase Console: Configurações do projeto > Seus apps > Android (br.app.omny.user)');
          debugPrint(
              '💡 2) Adicione as impressões digitais SHA-1 e SHA-256 do keystore (debug ou release)');
          debugPrint(
              '💡 3) Obter SHA: keytool -list -v -keystore C:\\Users\\SEU_USUARIO\\.android\\debug.keystore -alias androiddebugkey -storepass android');
          debugPrint(
              '💡 4) Se o número estava em "Números de teste" (Phone testing), remova para receber SMS real');
        }
        phoneAuthCheck = false;
        valueNotifierLogin.incrementNotifier();
      },
      codeSent: (String verificationId, int? resendToken) async {
        debugPrint(
            '📱 Código SMS enviado com sucesso! VerificationId: $verificationId');
        verId = verificationId;
        resendTokenId = resendToken;
        phoneAuthCheck = true;
        _isProcessingVerification = false;
        valueNotifierLogin.incrementNotifier();
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        debugPrint('⏱️ Timeout na recuperação automática do código');
        verId = verificationId;
        _isProcessingVerification = false;
      },
      timeout: const Duration(seconds: 60),
    );
    return true;
  } catch (e) {
    _isProcessingVerification = false;
    debugPrint('❌ Erro ao verificar telefone: $e');
    if (e is SocketException) {
      internet = false;
    }
    phoneAuthCheck = false;
    valueNotifierLogin.incrementNotifier();
    return false;
  }
}

//get local bearer token

String lastNotification = '';

getLocalData() async {
  dynamic result;
  debugPrint('🔄 Iniciando getLocalData()...');

  try {
    bearerToken.clear();
    debugPrint('🔄 Verificando conectividade...');

    var connectivityResult = await (Connectivity().checkConnectivity()).timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        debugPrint('⏱️ Timeout ao verificar conectividade');
        return ConnectivityResult.none;
      },
    );

    if (connectivityResult == ConnectivityResult.none) {
      internet = false;
      debugPrint('⚠️ Sem conexão com internet');
    } else {
      internet = true;
      debugPrint('✅ Conectividade OK');
    }

    debugPrint('🔄 Carregando dados do SharedPreferences...');

    if (pref.containsKey('lastNotification')) {
      lastNotification = pref.getString('lastNotification') ?? '';
    }
    if (pref.containsKey('autoAddress')) {
      try {
        var val = pref.getString('autoAddress');
        if (val != null) {
          storedAutoAddress = jsonDecode(val);
        }
      } catch (e) {
        debugPrint('⚠️ Erro ao decodificar autoAddress: $e');
      }
    }
    if (pref.containsKey('choosenLanguage')) {
      var savedLanguage = pref.getString('choosenLanguage') ?? '';
      debugPrint('🔄 Idioma salvo: $savedLanguage');
      // Validar se o idioma salvo ainda existe na lista de idiomas permitidos
      if (savedLanguage.isNotEmpty &&
          ['en', 'es', 'fr', 'pt', 'pt-BR'].contains(savedLanguage)) {
        choosenLanguage = savedLanguage;
        languageDirection = pref.getString('languageDirection') ?? 'ltr';
        debugPrint('✅ Idioma válido: $choosenLanguage');
      } else {
        // Se o idioma não existe mais, usar pt-BR como padrão
        choosenLanguage = 'pt-BR';
        languageDirection = 'ltr';
        pref.setString('choosenLanguage', 'pt-BR');
        pref.setString('languageDirection', 'ltr');
        debugPrint('⚠️ Idioma inválido, usando pt-BR como padrão');
      }
      if (choosenLanguage.isNotEmpty) {
        if (pref.containsKey('Bearer')) {
          var tokens = pref.getString('Bearer');
          if (tokens != null && tokens.isNotEmpty) {
            debugPrint('🔄 Token encontrado, verificando usuário...');
            bearerToken.add(BearerClass(type: 'Bearer', token: tokens));

            try {
              var responce = await getUserDetails().timeout(
                const Duration(seconds: 15),
                onTimeout: () {
                  debugPrint('⏱️ Timeout ao buscar detalhes do usuário');
                  return false;
                },
              );
              if (responce == true) {
                debugPrint('✅ Usuário autenticado (result = 3)');
                result = '3';
              } else {
                debugPrint('⚠️ Usuário não autenticado (result = 2)');
                result = '2';
              }
            } catch (e) {
              debugPrint('❌ Erro ao buscar detalhes do usuário: $e');
              result = '2';
            }
          } else {
            debugPrint('⚠️ Token vazio (result = 2)');
            result = '2';
          }
        } else {
          debugPrint('⚠️ Nenhum token encontrado (result = 2)');
          result = '2';
        }
      } else {
        debugPrint('⚠️ Idioma vazio (result = 1)');
        result = '1';
      }
    } else {
      debugPrint('⚠️ Nenhum idioma salvo (result = 1)');
      result = '1';
    }
    if (pref.containsKey('isDarkTheme')) {
      isDarkTheme = pref.getBool('isDarkTheme');
      if (isDarkTheme == true) {
        page = Colors.black;
        textColor = Colors.white.withOpacity(0.9);
        buttonColor = theme; // Roxo: Color.fromARGB(255, 154, 3, 233)
        loaderColor = theme; // Roxo
        hintColor = Colors.white.withOpacity(0.3);
      } else {
        page = Colors.white;
        textColor = Colors.black;
        buttonColor = theme;
        loaderColor = theme;
        hintColor = const Color(0xff12121D).withOpacity(0.3);
      }
      if (isDarkTheme == true) {
        mapStyle = await rootBundle.loadString('assets/dark.json');
      } else {
        mapStyle = await rootBundle.loadString('assets/map_style_black.json');
      }
    } else {
      // Tema claro por padrão
      isDarkTheme = false;
      page = Colors.white;
      textColor = Colors.black;
      buttonColor = theme;
      loaderColor = theme;
      hintColor = const Color(0xff12121D).withOpacity(0.3);
      mapStyle = await rootBundle.loadString('assets/map_style_black.json');
      pref.setBool('isDarkTheme', false);
    }
  } catch (e) {
    if (e is SocketException) {
      result = 'no internet';
      internet = false;
    }
  }
  return result;
}

//register user

List<BearerClass> bearerToken = <BearerClass>[];

registerUser() async {
  bearerToken.clear();
  dynamic result = 'false';
  try {
    // Tratar Firebase Messaging token (pode ser null no Chrome)
    String fcm = '';
    try {
      if (kIsWeb) {
        // No web, gerar um token temporário ou usar um valor padrão
        // O servidor requer device_token, então vamos usar um valor válido
        fcm = 'web_token_${DateTime.now().millisecondsSinceEpoch}';
        debugPrint('🌐 Web: Usando token temporário para device_token');
      } else {
        var token = await FirebaseMessaging.instance.getToken();
        fcm = token?.toString() ?? '';
        if (fcm.isEmpty) {
          // Se ainda estiver vazio, gerar um token temporário
          fcm = 'mobile_token_${DateTime.now().millisecondsSinceEpoch}';
        }
      }
    } catch (e) {
      debugPrint('⚠️ Erro ao obter FCM token: $e');
      // Garantir que sempre tenha um valor, mesmo que seja temporário
      fcm = 'fallback_token_${DateTime.now().millisecondsSinceEpoch}';
    }

    String endpoint = '${url}api/v1/user/register';

    final response = http.MultipartRequest(
      'POST',
      Uri.parse(endpoint),
    );
    response.headers.addAll({'Content-Type': 'application/json'});

    // Tratar upload de imagem (não funciona no web)
    if (proImageFile != null && !kIsWeb) {
      try {
        response.files.add(
          await http.MultipartFile.fromPath('profile_picture', proImageFile),
        );
      } catch (e) {
        debugPrint('⚠️ Erro ao adicionar imagem: $e');
      }
    }

    // Tratar country code (pode ser null)
    String countryCode = '';
    try {
      if (phcode != null &&
          phcode is int &&
          phcode >= 0 &&
          phcode < countries.length &&
          countries[phcode] != null) {
        countryCode = countries[phcode]['dial_code']?.toString() ?? '';
      }
    } catch (e) {
      debugPrint('⚠️ Erro ao obter country code: $e');
    }

    // Tratar platform (servidor não aceita "web", usar "android" como padrão)
    String loginBy = 'android'; // Padrão para web/Chrome
    if (!kIsWeb) {
      if (platform == TargetPlatform.android) {
        loginBy = 'android';
      } else if (platform == TargetPlatform.iOS) {
        loginBy = 'ios';
      }
    } else {
      // No Chrome/web, usar "android" pois o servidor não aceita "web"
      loginBy = 'android';
      debugPrint(
          '🌐 Web: Usando login_by="android" (servidor não aceita "web")');
    }

    // Validar e garantir que os campos obrigatórios não estejam vazios
    String nameValue = name.toString().trim();
    String mobileValue = phnumber.toString().trim();
    String emailValue = email.toString().trim();

    // Limitar name a 50 caracteres
    if (nameValue.length > 50) {
      nameValue = nameValue.substring(0, 50);
    }

    // Log dos valores antes de enviar
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('📝 registerUser: Valores dos campos:');
    debugPrint('   name: "$nameValue" (${nameValue.length} caracteres)');
    debugPrint('   mobile: "$mobileValue"');
    debugPrint('   email: "$emailValue"');
    debugPrint('   country: "$countryCode"');
    debugPrint('   login_by: "$loginBy"');
    debugPrint('   lang: "$choosenLanguage"');
    debugPrint('   gender: "$gender"');
    debugPrint('   document: "$document"');
    debugPrint('   birth_date: "$birthDate"');
    debugPrint('   passenger_preference: "$passengerPreference"');
    debugPrint('═══════════════════════════════════════════════════════════');

    // Validar campos obrigatórios
    if (nameValue.isEmpty) {
      result = 'Nome é obrigatório';
      debugPrint('❌ registerUser: Nome está vazio');
      return result;
    }
    if (mobileValue.isEmpty) {
      result = 'Telefone é obrigatório';
      debugPrint('❌ registerUser: Telefone está vazio');
      return result;
    }
    if (emailValue.isEmpty) {
      result = 'Email é obrigatório';
      debugPrint('❌ registerUser: Email está vazio');
      return result;
    }

    Map<String, String> fields = {
      "name": nameValue,
      "mobile": mobileValue,
      "email": emailValue,
      "device_token": fcm,
      "country": countryCode,
      "login_by": loginBy,
      'lang': choosenLanguage,
      'email_confirmed': (value == 0) ? '0' : '1',
    };

    // Adicionar novos campos se estiverem preenchidos
    if (gender.isNotEmpty) {
      fields['gender'] = gender;
    }
    if (document.isNotEmpty) {
      fields['document'] = document;
    }
    if (birthDate.isNotEmpty) {
      fields['birth_date'] = birthDate;
    }
    if (passengerPreference.isNotEmpty) {
      fields['passenger_preference'] = passengerPreference;
    }
    if (loginReferralCode.trim().isNotEmpty) {
      fields['referral_code'] = loginReferralCode.trim();
    }

    response.fields.addAll(fields);

    logApiCall('POST', endpoint, headers: response.headers, body: fields);

    var request = await response.send();
    var respon = await http.Response.fromStream(request);

    logApiCall('POST', endpoint,
        headers: response.headers,
        body: fields,
        statusCode: respon.statusCode,
        responseBody: respon.body.length > 500
            ? '${respon.body.substring(0, 500)}...'
            : respon.body);

    if (respon.statusCode == 200) {
      var jsonVal = jsonDecode(respon.body);

      // Servidor pode retornar 200 com success: false (ex: email_exists)
      if (jsonVal['success'] == false && jsonVal['message'] != null) {
        serverErrorMessage = jsonVal['message'].toString();
        result = serverErrorMessage;
        debugPrint(
            '❌ registerUser: Servidor retornou sucesso=false: $serverErrorMessage');
        return result;
      }

      // Verificar se os campos existem antes de acessar
      if (jsonVal['token_type'] != null && jsonVal['access_token'] != null) {
        bearerToken.add(
          BearerClass(
            type: jsonVal['token_type'].toString(),
            token: jsonVal['access_token'].toString(),
          ),
        );
        if (bearerToken.isNotEmpty) {
          pref.setString('Bearer', bearerToken[0].token);
          await getUserDetails();
        }
        result = 'true';
      } else {
        debugPrint(
            '❌ registerUser: Resposta inválida - token_type ou access_token ausentes');
        serverErrorMessage = extractErrorMessage(respon);
        result = serverErrorMessage.isNotEmpty
            ? serverErrorMessage
            : 'Erro ao processar resposta do servidor';
      }
    } else if (respon.statusCode == 400 || respon.statusCode == 422) {
      // Extrair mensagem de erro do servidor
      serverErrorMessage = extractErrorMessage(respon);
      debugPrint('❌ registerUser: Erro ${respon.statusCode}');
      debugPrint('   Mensagem do servidor: $serverErrorMessage');
      result = serverErrorMessage;
    } else {
      debugPrint(respon.body);
      serverErrorMessage = extractErrorMessage(respon);
      result = serverErrorMessage;
    }
    return result;
  } catch (e) {
    debugPrint('❌ registerUser: Erro na execução: $e');
    if (e is SocketException) {
      internet = false;
      result = 'Sem conexão com a internet';
    } else {
      result = 'Erro ao registrar usuário: ${e.toString()}';
    }
    return result;
  }
}

//update referral code

updateReferral() async {
  dynamic result;
  try {
    var response = await http.post(
      Uri.parse('${url}api/v1/update/user/referral'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({"refferal_code": referralCode}),
    );
    if (response.statusCode == 200) {
      if (jsonDecode(response.body)['success'] == true) {
        result = 'true';
      } else {
        debugPrint(response.body);
        result = 'false';
      }
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'false';
    }
    return result;
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

//call firebase otp

otpCall() async {
  dynamic result;
  try {
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('🔥 FIREBASE CALL: Realtime Database - call_FB_OTP');
    debugPrint('───────────────────────────────────────────────────────────');
    var otp = await FirebaseDatabase.instance
        .ref()
        .child('call_FB_OTP')
        .get()
        .timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        debugPrint('⏱️ Timeout ao buscar call_FB_OTP do Firebase');
        throw TimeoutException('Timeout ao buscar call_FB_OTP');
      },
    );

    // Verificar se o nó existe e tem valor
    if (otp.exists && otp.value != null) {
      debugPrint('📥 Firebase Response: ${otp.value}');
      debugPrint('═══════════════════════════════════════════════════════════');
      result = otp;
    } else {
      // Nó não existe ou está vazio - usar padrão (OTP próprio = false)
      debugPrint('⚠️ Nó call_FB_OTP não existe ou está vazio no Firebase');
      debugPrint('📝 Usando padrão: OTP próprio (false)');
      debugPrint(
          '💡 Para habilitar Firebase OTP, crie o nó "call_FB_OTP" no Firebase Realtime Database com valor true');
      debugPrint('═══════════════════════════════════════════════════════════');
      // Retornar um objeto que simula false
      result = null; // Será tratado como false no login.dart
    }
  } catch (e) {
    debugPrint('❌ Firebase Error: $e');
    if (e is SocketException || e is TimeoutException) {
      internet = false;
      result = 'no Internet';
      valueNotifierHome.incrementNotifier();
    } else {
      // Para outros erros (nó não existe, permissão negada, etc), usar padrão
      debugPrint('⚠️ Erro ao acessar call_FB_OTP: $e');
      debugPrint('📝 Usando padrão: OTP próprio (false)');
      debugPrint(
          '💡 Para habilitar Firebase OTP, crie o nó "call_FB_OTP" no Firebase Realtime Database');
      debugPrint('   Exemplo: { "call_FB_OTP": true }');
      result = null; // Será tratado como false no login.dart
    }
  }
  return result;
}

// verify user already exist

verifyUser(String number) async {
  dynamic val;
  try {
    String endpoint = '${url}api/v1/user/validate-mobile-for-login';
    Map<String, String> body = {"mobile": number};

    logApiCall('POST', endpoint, body: body);

    var response = await http.post(
      Uri.parse(endpoint),
      body: body,
    );

    logApiCall('POST', endpoint,
        body: body,
        statusCode: response.statusCode,
        responseBody: response.body);

    if (response.statusCode == 200) {
      val = jsonDecode(response.body)['success'];

      if (val == true) {
        var check = await userLogin();
        if (check == true) {
          var uCheck = await getUserDetails();
          val = uCheck;
        } else {
          val = false;
        }
      } else {
        val = false;
      }
    } else if (response.statusCode == 400 || response.statusCode == 422) {
      // Extrair mensagem de erro do servidor
      serverErrorMessage = extractErrorMessage(response);
      debugPrint('❌ verifyUser: Erro ${response.statusCode}');
      debugPrint('   Mensagem do servidor: $serverErrorMessage');
      val = serverErrorMessage;
    } else {
      debugPrint(response.body);
      serverErrorMessage = extractErrorMessage(response);
      val = serverErrorMessage;
    }
    return val;
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

acceptRequest(body) async {
  dynamic result;
  try {
    var response = await http.post(
      Uri.parse('${url}api/v1/request/respond-for-bid'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode == 200) {
      await getUserDetails();
      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      valueNotifierBook.incrementNotifier();

      result = false;
    }
    return result;
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

//user login
userLogin() async {
  bearerToken.clear();
  dynamic result;
  try {
    var token = await FirebaseMessaging.instance.getToken();
    var fcm = token.toString();
    String endpoint = '${url}api/v1/user/login';
    Map<String, String> headers = {'Content-Type': 'application/json'};
    Map<String, dynamic> bodyData = {
      "mobile": phnumber,
      'device_token': fcm,
      "login_by": (platform == TargetPlatform.android) ? 'android' : 'ios',
    };

    logApiCall('POST', endpoint, headers: headers, body: bodyData);

    var response = await http.post(
      Uri.parse(endpoint),
      headers: headers,
      body: jsonEncode(bodyData),
    );

    logApiCall('POST', endpoint,
        headers: headers,
        body: bodyData,
        statusCode: response.statusCode,
        responseBody: response.body);

    if (response.statusCode == 200) {
      var jsonVal = jsonDecode(response.body);
      bearerToken.add(
        BearerClass(
          type: jsonVal['token_type'].toString(),
          token: jsonVal['access_token'].toString(),
        ),
      );
      result = true;
      pref.setString('Bearer', bearerToken[0].token);
      // Evitar Firebase Database no web (pode causar travamento)
      if (!kIsWeb) {
        try {
          package = await PackageInfo.fromPlatform();
          if (platform == TargetPlatform.android && package != null) {
            await FirebaseDatabase.instance.ref().update({
              'user_package_name': package.packageName.toString(),
            });
          } else if (package != null) {
            await FirebaseDatabase.instance.ref().update({
              'user_bundle_id': package.packageName.toString(),
            });
          }
        } catch (e) {
          debugPrint('⚠️ userLogin: Erro ao atualizar Firebase Database: $e');
        }
      } else {
        debugPrint('🌐 Web: Pulando atualização do Firebase Database');
      }
    } else if (response.statusCode == 400 || response.statusCode == 422) {
      // Extrair mensagem de erro do servidor
      serverErrorMessage = extractErrorMessage(response);
      debugPrint('❌ userLogin: Erro ${response.statusCode}');
      debugPrint('   Mensagem do servidor: $serverErrorMessage');
      result = false;
    } else {
      debugPrint(response.body);
      serverErrorMessage = extractErrorMessage(response);
      result = false;
    }
    return result;
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

Map<String, dynamic> userDetails = {};
List favAddress = [];
List tripStops = [];
List banners = [];
//user current state
getUserDetails() async {
  dynamic result;
  debugPrint('═══════════════════════════════════════════════════════════');
  debugPrint('👤 getUserDetails: Buscando detalhes do usuário...');
  debugPrint(
      '   [GETUSER] userRequestDriverJustRejected ao ENTRAR = $userRequestDriverJustRejected');
  debugPrint('───────────────────────────────────────────────────────────');

  try {
    if (bearerToken.isEmpty) {
      debugPrint('❌ getUserDetails: bearerToken está vazio!');
      return 'failure';
    }

    String endpoint = '${url}api/v1/user';
    debugPrint('   Endpoint: $endpoint');

    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${bearerToken[0].token}',
    };

    logApiCall('GET', endpoint, headers: headers);

    var response = await http
        .get(
      Uri.parse(endpoint),
      headers: headers,
    )
        .timeout(
      const Duration(seconds: 20),
      onTimeout: () {
        debugPrint('⏱️ getUserDetails: Timeout na requisição');
        throw TimeoutException('Timeout ao buscar detalhes do usuário');
      },
    );

    logApiCall('GET', endpoint,
        headers: headers,
        statusCode: response.statusCode,
        responseBody: response.body.length > 500
            ? '${response.body.substring(0, 500)}...'
            : response.body);

    debugPrint('📥 getUserDetails: Status ${response.statusCode}');
    if (response.statusCode == 200) {
      try {
        var responseData = jsonDecode(response.body);
        if (responseData['data'] != null) {
          userDetails = Map<String, dynamic>.from(responseData['data']);
          debugPrint('✅ getUserDetails: Dados do usuário carregados');
          debugPrint('   User ID: ${userDetails['id']}');
          debugPrint('   Name: ${userDetails['name']}');
          debugPrint('   Mobile: ${userDetails['mobile']}');

          favAddress = userDetails['favouriteLocations']?['data'] ?? [];
          sosData = userDetails['sos']?['data'] ?? [];

          if (userDetails['bannerImage']?['data']?.toString().startsWith('{') ==
              true) {
            banners.clear();
            banners.add(userDetails['bannerImage']['data']);
          } else {
            banners = userDetails['bannerImage']?['data'] ?? [];
          }

          // Log do que o SERVIDOR retornou (debug: onTripRequest vs metaRequest)
          debugPrint(
              '📋 [GETUSER] Servidor: onTripRequest=${userDetails['onTripRequest'] != null}, metaRequest=${userDetails['metaRequest'] != null}');
          if (userDetails['onTripRequest'] != null) {
            final reqData =
                userDetails['onTripRequest']['data'] as Map<String, dynamic>?;
            debugPrint(
                '📋 [GETUSER] onTripRequest.data: accepted_at=${reqData?['accepted_at']}, driverDetail!=null=${reqData?['driverDetail'] != null}');
            if (reqData?['driverDetail'] != null) {
              final dd = reqData!['driverDetail'];
              final data = (dd is Map) ? (dd['data'] ?? dd) : null;
              debugPrint(
                  '📋 [GETUSER] driverDetail.data.id=${(data is Map) ? data['id'] : 'N/A'}');
            }
          }
          if (userDetails['metaRequest'] != null) {
            debugPrint('📋 [GETUSER] metaRequest presente (corrida pendente)');
          }

          if (userDetails['onTripRequest'] != null) {
            debugPrint('🚗 getUserDetails: Requisição em andamento encontrada');
            addressList.clear();
            userRequestData = userDetails['onTripRequest']['data'];
            final driverJustRejected = userRequestDriverJustRejected;
            debugPrint(
                '📋 [GETUSER] userRequestDriverJustRejected(flag)=$driverJustRejected');
            if (driverJustRejected) {
              userRequestDriverJustRejected = false;
              userRequestData['accepted_at'] = null;
              userRequestData['driverDetail'] = null;
              debugPrint(
                  '🟢 [GETUSER] Decisão: MOTORISTA RECUSOU → tela PROCURANDO');
            } else {
              final dd = userRequestData['driverDetail'];
              final driverData =
                  (dd != null && dd is Map) ? (dd['data'] ?? dd) : null;
              final hasValidDriver = driverData is Map &&
                  driverData.isNotEmpty &&
                  driverData['id'] != null;
              debugPrint(
                  '📋 [GETUSER] hasValidDriver=$hasValidDriver, driverData.id=${(driverData is Map) ? driverData['id'] : 'N/A'}');
              if (!hasValidDriver) {
                userRequestData['accepted_at'] = null;
                userRequestData['driverDetail'] = null;
                debugPrint(
                    '🟢 [GETUSER] Decisão: sem motorista válido → tela PROCURANDO');
              } else {
                debugPrint(
                    '🟢 [GETUSER] Decisão: motorista válido → tela CÓDIGO/ACEITOU');
              }
            }
            debugPrint('   Request ID: ${userRequestData['id']}');
            debugPrint(
                '   Driver: ${userRequestData['driverDetail']?['data']?['name'] ?? 'N/A'}');

            if (userRequestData['transport_type'] == 'taxi') {
              choosenTransportType = 0;
            } else {
              choosenTransportType = 1;
            }
            tripStops =
                userDetails['onTripRequest']['data']['requestStops']['data'];
            addressList.add(
              AddressList(
                id: '1',
                type: 'pickup',
                address: userRequestData['pick_address'],
                latlng: LatLng(
                  userRequestData['pick_lat'],
                  userRequestData['pick_lng'],
                ),
                name: userRequestData['pickup_poc_name'],
                pickup: true,
                number: userRequestData['pickup_poc_mobile'],
                instructions: userRequestData['pickup_poc_instruction'],
              ),
            );

            if (tripStops.isNotEmpty) {
              for (var i = 0; i < tripStops.length; i++) {
                addressList.add(
                  AddressList(
                    id: (i + 2).toString(),
                    type: 'drop',
                    pickup: false,
                    address: tripStops[i]['address'],
                    latlng: LatLng(
                      tripStops[i]['latitude'],
                      tripStops[i]['longitude'],
                    ),
                    name: tripStops[i]['poc_name'],
                    number: tripStops[i]['poc_mobile'],
                    instructions: tripStops[i]['poc_instruction'],
                  ),
                );
              }
            } else if (userDetails['onTripRequest']['data']['is_rental'] !=
                    true &&
                userRequestData['drop_lat'] != null) {
              addressList.add(
                AddressList(
                  id: '2',
                  type: 'drop',
                  pickup: false,
                  address: userRequestData['drop_address'],
                  latlng: LatLng(
                    userRequestData['drop_lat'],
                    userRequestData['drop_lng'],
                  ),
                  name: userRequestData['drop_poc_name'],
                  number: userRequestData['drop_poc_mobile'],
                  instructions: userRequestData['drop_poc_instruction'],
                ),
              );
            }
            // Evitar getCurrentMessages no web se não houver necessidade
            if (userRequestData['accepted_at'] != null) {
              if (!kIsWeb) {
                getCurrentMessages();
              } else {
                debugPrint(
                    '🌐 Web: Pulando getCurrentMessages (pode ser chamado depois)');
              }
            }

            // Evitar streams do Firebase no web (pode causar travamento)
            if (!kIsWeb) {
              if (userRequestData.isNotEmpty) {
                if (rideStreamUpdate == null ||
                    rideStreamUpdate?.isPaused == true ||
                    rideStreamStart == null ||
                    rideStreamStart?.isPaused == true) {
                  streamRide();
                }
              } else {
                if (rideStreamUpdate != null ||
                    rideStreamUpdate?.isPaused == false ||
                    rideStreamStart != null ||
                    rideStreamStart?.isPaused == false) {
                  rideStreamUpdate?.cancel();
                  rideStreamUpdate = null;
                  rideStreamStart?.cancel();
                  rideStreamStart = null;
                }
              }
            } else {
              debugPrint('🌐 Web: Pulando streams do Firebase (não suportado)');
            }
            valueNotifierHome.incrementNotifier();
            valueNotifierBook.incrementNotifier();
          } else if (userDetails['metaRequest'] != null) {
            debugPrint(
                '🟢 [GETUSER] Entrando em metaRequest → tela PROCURANDO');
            addressList.clear();
            userRequestData = userDetails['metaRequest']['data'];
            userRequestData['accepted_at'] = null;
            userRequestData['driverDetail'] = null;
            requestCancelledByDriver = false;
            tripStops =
                userDetails['metaRequest']['data']['requestStops']['data'];
            addressList.add(
              AddressList(
                id: '1',
                type: 'pickup',
                address: userRequestData['pick_address'],
                pickup: true,
                latlng: LatLng(
                  userRequestData['pick_lat'],
                  userRequestData['pick_lng'],
                ),
                name: userRequestData['pickup_poc_name'],
                number: userRequestData['pickup_poc_mobile'],
                instructions: userRequestData['pickup_poc_instruction'],
              ),
            );

            if (tripStops.isNotEmpty) {
              for (var i = 0; i < tripStops.length; i++) {
                addressList.add(
                  AddressList(
                    id: (i + 2).toString(),
                    type: 'drop',
                    pickup: false,
                    address: tripStops[i]['address'],
                    latlng: LatLng(
                      tripStops[i]['latitude'],
                      tripStops[i]['longitude'],
                    ),
                    name: tripStops[i]['poc_name'],
                    number: tripStops[i]['poc_mobile'],
                    instructions: tripStops[i]['poc_instruction'],
                  ),
                );
              }
            } else if (userDetails['metaRequest']['data']['is_rental'] !=
                    true &&
                userRequestData['drop_lat'] != null) {
              addressList.add(
                AddressList(
                  id: '2',
                  type: 'drop',
                  address: userRequestData['drop_address'],
                  pickup: false,
                  latlng: LatLng(
                    userRequestData['drop_lat'],
                    userRequestData['drop_lng'],
                  ),
                  name: userRequestData['drop_poc_name'],
                  number: userRequestData['drop_poc_mobile'],
                  instructions: userRequestData['drop_poc_instruction'],
                ),
              );
            }

            if (userRequestData['transport_type'] == 'taxi') {
              choosenTransportType = 0;
            } else {
              choosenTransportType = 1;
            }

            // Evitar streams do Firebase no web (pode causar travamento)
            if (!kIsWeb) {
              if (requestStreamStart == null ||
                  requestStreamStart?.isPaused == true ||
                  requestStreamEnd == null ||
                  requestStreamEnd?.isPaused == true) {
                streamRequest();
              }
            } else {
              debugPrint('🌐 Web: Pulando streamRequest (não suportado)');
            }
            valueNotifierHome.incrementNotifier();
            valueNotifierBook.incrementNotifier();
          } else {
            debugPrint(
                '🟢 [GETUSER] Sem onTripRequest e sem metaRequest → userRequestData limpo');
            chatList.clear();
            userRequestData = {};
            requestStreamStart?.cancel();
            requestStreamEnd?.cancel();
            rideStreamUpdate?.cancel();
            rideStreamStart?.cancel();
            requestStreamEnd = null;
            requestStreamStart = null;
            rideStreamUpdate = null;
            rideStreamStart = null;
            valueNotifierHome.incrementNotifier();
            valueNotifierBook.incrementNotifier();
          }
          if (userDetails['active'] == false) {
            isActive = 'false';
          } else {
            isActive = 'true';
          }
          result = true;
        } else {
          debugPrint('⚠️ getUserDetails: Resposta sem data');
          result = false;
        }
      } catch (e) {
        debugPrint('❌ getUserDetails: Erro ao processar resposta: $e');
        debugPrint('   Response: ${response.body}');
        result = false;
      }
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = false;
    }
  } catch (e) {
    debugPrint('❌ getUserDetails: Erro na execução: $e');
    if (e is SocketException) {
      // Verificar conectividade real antes de definir internet = false
      try {
        var connectivityResult =
            await Connectivity().checkConnectivity().timeout(
                  const Duration(seconds: 3),
                  onTimeout: () => ConnectivityResult.none,
                );
        if (connectivityResult == ConnectivityResult.none) {
          internet = false;
          debugPrint('⚠️ Sem conectividade detectada');
        } else {
          // Há conectividade, mas o servidor não está acessível
          // Não definir internet = false para não bloquear a UI
          debugPrint('⚠️ Servidor inacessível, mas há conectividade');
        }
      } catch (connectivityError) {
        debugPrint('⚠️ Erro ao verificar conectividade: $connectivityError');
        // Em caso de erro na verificação, não assumir que não há internet
      }
    }
    // Garantir que sempre retorne um valor
    result ??= false;
  }
  debugPrint('📤 getUserDetails: Retornando resultado: $result');
  return result ?? false;
}

class BearerClass {
  final String type;
  final String token;
  BearerClass({required this.type, required this.token});

  BearerClass.fromJson(Map<String, dynamic> json)
      : type = json['type'],
        token = json['token'];

  Map<String, dynamic> toJson() => {'type': type, 'token': token};
}

Map<String, dynamic> driverReq = {};

class ValueNotifying {
  ValueNotifier value = ValueNotifier(0);

  void incrementNotifier() {
    value.value++;
  }
}

ValueNotifying valueNotifier = ValueNotifying();

class ValueNotifyingHome {
  ValueNotifier value = ValueNotifier(0);

  void incrementNotifier() {
    debugPrint('🔄 [DEBUG] ValueNotifyingHome.incrementNotifier() chamado');
    debugPrint('   📊 Valor ANTES: ${value.value}');
    value.value++;
    debugPrint('   📊 Valor DEPOIS: ${value.value}');
    debugPrint('   📋 addAutoFill.length: ${addAutoFill.length}');
  }
}

class ValueNotifyingChat {
  ValueNotifier value = ValueNotifier(0);

  void incrementNotifier() {
    value.value++;
  }
}

class ValueNotifyingKey {
  ValueNotifier value = ValueNotifier(0);

  void incrementNotifier() {
    value.value++;
  }
}

class ValueNotifyingNotification {
  ValueNotifier value = ValueNotifier(0);

  void incrementNotifier() {
    value.value++;
  }
}

class ValueNotifyingLogin {
  ValueNotifier value = ValueNotifier(0);

  void incrementNotifier() {
    value.value++;
  }
}

bool deleteAccount = false;
ValueNotifyingHome valueNotifierHome = ValueNotifyingHome();
ValueNotifyingChat valueNotifierChat = ValueNotifyingChat();
ValueNotifyingKey valueNotifierKey = ValueNotifyingKey();
ValueNotifyingNotification valueNotifierNotification =
    ValueNotifyingNotification();
ValueNotifyingLogin valueNotifierLogin = ValueNotifyingLogin();
ValueNotifyingTimer valueNotifierTimer = ValueNotifyingTimer();

class ValueNotifyingTimer {
  ValueNotifier value = ValueNotifier(0);

  void incrementNotifier() {
    debugPrint('🔄 [DEBUG] ValueNotifyingTimer.incrementNotifier() chamado');
    debugPrint('   📊 Valor ANTES: ${value.value}');
    value.value++;
    debugPrint('   📊 Valor DEPOIS: ${value.value}');
  }
}

class ValueNotifyingBook {
  ValueNotifier value = ValueNotifier(0);

  void incrementNotifier() {
    value.value++;
  }
}

ValueNotifyingBook valueNotifierBook = ValueNotifyingBook();

//sound
AudioCache audioPlayer = AudioCache();
AudioPlayer audioPlayers = AudioPlayer();

//get reverse geo coding

var pickupAddress = '';
var dropAddress = '';

geoCoding(double lat, double lng) async {
  dynamic result;
  try {
    var response = await http.get(
      Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$mapkey',
      ),
    );

    if (response.statusCode == 200) {
      var val = jsonDecode(response.body);
      result = val['results'][0]['formatted_address'];
    } else {
      debugPrint(response.body);
      result = '';
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

//lang
getlangid() async {
  dynamic result;
  try {
    var response = await http.post(
      Uri.parse('${url}api/v1/user/update-my-lang'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${bearerToken[0].token}',
      },
      body: {'lang': choosenLanguage},
    );
    if (response.statusCode == 200) {
      if (jsonDecode(response.body)['success'] == true) {
        result = 'success';
      } else {
        debugPrint(response.body);
        result = 'failed';
      }
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else if (response.statusCode == 422) {
      debugPrint(response.body);
      var error = jsonDecode(response.body)['errors'];
      result = error[error.keys.toList()[0]]
          .toString()
          .replaceAll('[', '')
          .replaceAll(']', '')
          .toString();
    } else {
      debugPrint(response.body);
      result = jsonDecode(response.body)['message'];
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

//get address auto fill data
List storedAutoAddress = [];
List addAutoFill = [];

getAutoAddress(input, sessionToken, lat, lng) async {
  debugPrint('🔍 [DEBUG] getAutoAddress CHAMADO');
  debugPrint('   📝 Input: $input');
  debugPrint('   🎫 SessionToken: $sessionToken');
  debugPrint('   📍 Lat: $lat, Lng: $lng');
  dynamic response;
  var countryCode = userDetails['country_code'];
  try {
    // Codificar o input para URL
    String encodedInput = Uri.encodeComponent(input);
    String url;

    if (userDetails['enable_country_restrict_on_map'] == '1' &&
        userDetails['country_code'] != null) {
      url =
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$encodedInput&library=places&location=$lat%2C$lng&radius=2000&components=country:$countryCode&key=$mapkey&sessiontoken=$sessionToken&language=pt-BR';
      debugPrint('URL com restrição de país: $url');
    } else {
      url =
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$encodedInput&library=places&key=$mapkey&sessiontoken=$sessionToken&language=pt-BR';
      debugPrint('URL sem restrição: $url');
    }

    // Para Flutter Web, usar um proxy CORS ou fazer requisição via JavaScript
    if (kIsWeb) {
      // No web, usar um proxy CORS ou fazer requisição via JavaScript
      // Solução: usar um proxy público (para desenvolvimento) ou configurar um proxy próprio (para produção)
      // Alternativa: usar a biblioteca JavaScript do Google Places diretamente
      try {
        // Tentar primeiro sem proxy (pode funcionar em alguns casos)
        response = await http.get(Uri.parse(url), headers: {
          'Accept': 'application/json',
        }).timeout(const Duration(seconds: 10));
      } catch (e) {
        // Se falhar por CORS, tentar com proxy (apenas para desenvolvimento)
        debugPrint('Erro CORS detectado, tentando com proxy: $e');
        // Para produção, configure um proxy próprio no seu backend
        // Exemplo de proxy: 'https://seu-proxy.com/api/places?url=...'
        // Por enquanto, vamos apenas logar o erro
        throw Exception(
            'Erro CORS: A API do Google Places requer um proxy no Flutter Web. Configure um proxy no backend ou use a biblioteca JavaScript do Google Places.');
      }
    } else {
      // Para mobile, usar requisição direta
      response = await http.get(Uri.parse(url));
    }
    debugPrint('📡 [DEBUG] Status code da resposta: ${response.statusCode}');
    if (response.statusCode == 200) {
      var decodedResponse = jsonDecode(response.body);
      debugPrint('✅ [DEBUG] Resposta recebida com sucesso');
      debugPrint('   📊 Status da API: ${decodedResponse['status']}');

      // Verificar se há erro na resposta da API
      if (decodedResponse['status'] == 'OK' ||
          decodedResponse['status'] == 'ZERO_RESULTS') {
        addAutoFill = decodedResponse['predictions'] ?? [];
        debugPrint(
            '📋 [DEBUG] Número de resultados encontrados: ${addAutoFill.length}');

        // Se não houver resultados, limpar a lista
        if (addAutoFill.isEmpty) {
          addAutoFill = [];
          debugPrint(
              '⚠️ [DEBUG] Nenhum resultado encontrado, limpando addAutoFill');
        } else {
          debugPrint(
              '✅ [DEBUG] Adicionando ${addAutoFill.length} resultados ao addAutoFill');
          // ignore: avoid_function_literals_in_foreach_calls
          addAutoFill.forEach((element) {
            if (storedAutoAddress
                .where(
                  (e) =>
                      e['description'].toString().toLowerCase() ==
                      element['description'].toString().toLowerCase(),
                )
                .isEmpty) {
              storedAutoAddress.add(element);
            }
          });
          pref.setString(
              'autoAddress', jsonEncode(storedAutoAddress).toString());
        }
      } else {
        debugPrint(
            '❌ [DEBUG] Status da API inválido: ${decodedResponse['status']}');
        addAutoFill = [];
      }
      debugPrint('🔄 [DEBUG] Chamando valueNotifierHome.incrementNotifier()');
      // Usar um delay maior para garantir que o layout esteja completamente finalizado
      Future.delayed(const Duration(milliseconds: 100), () {
        valueNotifierHome.incrementNotifier();
        debugPrint(
            '✅ [DEBUG] valueNotifierHome.incrementNotifier() chamado (após delay)');
      });
    } else {
      debugPrint('❌ [DEBUG] Erro na resposta HTTP: ${response.statusCode}');
      debugPrint('   📄 Body: ${response.body}');
      addAutoFill = [];
      debugPrint(
          '🔄 [DEBUG] Chamando valueNotifierHome.incrementNotifier() após erro HTTP');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        valueNotifierHome.incrementNotifier();
      });
    }
  } catch (e) {
    debugPrint('💥 [DEBUG] ERRO em getAutoAddress: $e');
    debugPrint('   📚 Tipo do erro: ${e.runtimeType}');
    debugPrint('   📍 StackTrace: ${StackTrace.current}');
    addAutoFill = [];
    if (e is SocketException) {
      debugPrint('🌐 [DEBUG] Erro de conexão detectado');
      internet = false;
    }
    debugPrint(
        '🔄 [DEBUG] Chamando valueNotifierHome.incrementNotifier() após exceção');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      valueNotifierHome.incrementNotifier();
    });
  }
  debugPrint(
      '🏁 [DEBUG] getAutoAddress FINALIZADO. addAutoFill.length = ${addAutoFill.length}');
}

//geocodeing location

geoCodingForLatLng(placeid) async {
  try {
    var response = await http.get(
      Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json?placeid=$placeid&key=$mapkey&language=pt-BR',
      ),
    );

    if (response.statusCode == 200) {
      var val = jsonDecode(response.body)['result']['geometry']['location'];
      center = LatLng(val['lat'], val['lng']);
    } else {
      debugPrint(response.body);
    }
    return center;
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

//pickup drop address list

class AddressList {
  String address;
  LatLng latlng;
  String id;
  dynamic type;
  dynamic name;
  dynamic number;
  dynamic instructions;
  bool pickup;

  AddressList({
    required this.id,
    required this.address,
    required this.latlng,
    required this.pickup,
    this.type,
    this.name,
    this.number,
    this.instructions,
  });
}

//get polylines

List<LatLng> polyList = [];

getPolylines() async {
  polyList.clear();
  String pickLat = '';
  String pickLng = '';
  String dropLat = '';
  String dropLng = '';

  for (var i = 1; i < addressList.length; i++) {
    pickLat = addressList[i - 1].latlng.latitude.toString();
    pickLng = addressList[i - 1].latlng.longitude.toString();
    dropLat = addressList[i].latlng.latitude.toString();
    dropLng = addressList[i].latlng.longitude.toString();

    try {
      var response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/directions/json?origin=$pickLat%2C$pickLng&destination=$dropLat%2C$dropLng&avoid=ferries|indoor&transit_mode=bus&mode=driving&key=$mapkey',
        ),
      );
      if (response.statusCode == 200) {
        var steps = jsonDecode(
          response.body,
        )['routes'][0]['overview_polyline']['points'];
        decodeEncodedPolyline(steps);
      } else {
        debugPrint(response.body);
      }
    } catch (e) {
      if (e is SocketException) {
        internet = false;
      }
    }
  }
  return polyList;
}

//polyline decode

Set<Polyline> polyline = {};

List<PointLatLng> decodeEncodedPolyline(String encoded) {
  List<PointLatLng> poly = [];
  int index = 0, len = encoded.length;
  int lat = 0, lng = 0;
  polyline.clear();

  while (index < len) {
    int b, shift = 0, result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
    lat += dlat;

    shift = 0;
    result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
    lng += dlng;
    LatLng p = LatLng((lat / 1E5).toDouble(), (lng / 1E5).toDouble());
    polyList.add(p);
  }

  polyline.add(
    Polyline(
      polylineId: const PolylineId('1'),
      color: const Color(0xffFD9898),
      visible: true,
      width: 4,
      points: polyList,
    ),
  );
  valueNotifierBook.incrementNotifier();
  return poly;
}

class PointLatLng {
  /// Creates a geographical location specified in degrees [latitude] and
  /// [longitude].
  ///
  const PointLatLng(double latitude, double longitude)
      // ignore: unnecessary_null_comparison
      : assert(latitude != null),
        // ignore: unnecessary_null_comparison
        assert(longitude != null),
        // ignore: unnecessary_this, prefer_initializing_formals
        this.latitude = latitude,
        // ignore: unnecessary_this, prefer_initializing_formals
        this.longitude = longitude;

  /// The latitude in degrees.
  final double latitude;

  /// The longitude in degrees
  final double longitude;

  @override
  String toString() {
    return "lat: $latitude / longitude: $longitude";
  }
}

//get goods list
List goodsTypeList = [];

getGoodsList() async {
  dynamic result;
  goodsTypeList.clear();
  try {
    var response = await http.get(Uri.parse('${url}api/v1/common/goods-types'));
    if (response.statusCode == 200) {
      goodsTypeList = jsonDecode(response.body)['data'];
      valueNotifierBook.incrementNotifier();
      result = 'success';
    } else {
      debugPrint(response.body);
      result = 'false';
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

//drop stops list
List<DropStops> dropStopList = <DropStops>[];

class DropStops {
  String order;
  double latitude;
  double longitude;
  String? pocName;
  String? pocNumber;
  dynamic pocInstruction;
  String address;

  DropStops({
    required this.order,
    required this.latitude,
    required this.longitude,
    this.pocName,
    this.pocNumber,
    this.pocInstruction,
    required this.address,
  });

  Map<String, dynamic> toJson() => {
        'order': order,
        'latitude': latitude,
        'longitude': longitude,
        'poc_name': pocName,
        'poc_mobile': pocNumber,
        'poc_instruction': pocInstruction,
        'address': address,
      };
}

List etaDetails = [];

//eta request

etaRequest() async {
  dynamic result;
  try {
    var response = await http.post(
      Uri.parse('${url}api/v1/request/eta'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
      body:
          (addressList.where((element) => element.type == 'drop').isNotEmpty &&
                  dropStopList.isEmpty)
              ? jsonEncode({
                  'pick_lat': (userRequestData.isNotEmpty)
                      ? userRequestData['pick_lat']
                      : addressList
                          .firstWhere((e) => e.type == 'pickup')
                          .latlng
                          .latitude,
                  'pick_lng': (userRequestData.isNotEmpty)
                      ? userRequestData['pick_lng']
                      : addressList
                          .firstWhere((e) => e.type == 'pickup')
                          .latlng
                          .longitude,
                  'drop_lat': (userRequestData.isNotEmpty)
                      ? userRequestData['drop_lat']
                      : addressList
                          .lastWhere((e) => e.type == 'drop')
                          .latlng
                          .latitude,
                  'drop_lng': (userRequestData.isNotEmpty)
                      ? userRequestData['drop_lng']
                      : addressList
                          .lastWhere((e) => e.type == 'drop')
                          .latlng
                          .longitude,
                  'ride_type': 1,
                  'transport_type':
                      (choosenTransportType == 0) ? 'taxi' : 'delivery',
                })
              : (dropStopList.isNotEmpty &&
                      addressList
                          .where((element) => element.type == 'drop')
                          .isNotEmpty)
                  ? jsonEncode({
                      'pick_lat': (userRequestData.isNotEmpty)
                          ? userRequestData['pick_lat']
                          : addressList
                              .firstWhere((e) => e.type == 'pickup')
                              .latlng
                              .latitude,
                      'pick_lng': (userRequestData.isNotEmpty)
                          ? userRequestData['pick_lng']
                          : addressList
                              .firstWhere((e) => e.type == 'pickup')
                              .latlng
                              .longitude,
                      'drop_lat': (userRequestData.isNotEmpty)
                          ? userRequestData['drop_lat']
                          : addressList
                              .lastWhere((e) => e.type == 'drop')
                              .latlng
                              .latitude,
                      'drop_lng': (userRequestData.isNotEmpty)
                          ? userRequestData['drop_lng']
                          : addressList
                              .lastWhere((e) => e.type == 'drop')
                              .latlng
                              .longitude,
                      'stops': jsonEncode(dropStopList),
                      'ride_type': 1,
                      'transport_type':
                          (choosenTransportType == 0) ? 'taxi' : 'delivery',
                    })
                  : jsonEncode({
                      'pick_lat': (userRequestData.isNotEmpty)
                          ? userRequestData['pick_lat']
                          : addressList
                              .firstWhere((e) => e.type == 'pickup')
                              .latlng
                              .latitude,
                      'pick_lng': (userRequestData.isNotEmpty)
                          ? userRequestData['pick_lng']
                          : addressList
                              .firstWhere((e) => e.type == 'pickup')
                              .latlng
                              .longitude,
                      'ride_type': 1,
                      'transport_type':
                          (choosenTransportType == 0) ? 'taxi' : 'delivery',
                    }),
    );

    if (response.statusCode == 200) {
      etaDetails = jsonDecode(response.body)['data'];
      choosenVehicle = (etaDetails
              .where((element) => element['is_default'] == true)
              .isNotEmpty)
          ? etaDetails.indexWhere((element) => element['is_default'] == true)
          : 0;
      result = true;
      valueNotifierBook.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      if (jsonDecode(response.body)['message'] ==
          "service not available with this location") {
        serviceNotAvailable = true;
      }
      result = false;
    }
    return result;
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

etaRequestWithPromo() async {
  dynamic result;
  // etaDetails.clear();
  try {
    var response = await http.post(
      Uri.parse('${url}api/v1/request/eta'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
      body:
          (addressList.where((element) => element.type == 'drop').isNotEmpty &&
                  dropStopList.isEmpty)
              ? jsonEncode({
                  'pick_lat': addressList
                      .firstWhere((e) => e.type == 'pickup')
                      .latlng
                      .latitude,
                  'pick_lng': addressList
                      .firstWhere((e) => e.type == 'pickup')
                      .latlng
                      .longitude,
                  'drop_lat': addressList
                      .firstWhere((e) => e.type == 'drop')
                      .latlng
                      .latitude,
                  'drop_lng': addressList
                      .firstWhere((e) => e.type == 'drop')
                      .latlng
                      .longitude,
                  'ride_type': 1,
                  'promo_code': promoCode,
                  'transport_type':
                      (choosenTransportType == 0) ? 'taxi' : 'delivery',
                })
              : (dropStopList.isNotEmpty &&
                      addressList
                          .where((element) => element.type == 'drop')
                          .isNotEmpty)
                  ? jsonEncode({
                      'pick_lat': addressList
                          .firstWhere((e) => e.type == 'pickup')
                          .latlng
                          .latitude,
                      'pick_lng': addressList
                          .firstWhere((e) => e.type == 'pickup')
                          .latlng
                          .longitude,
                      'drop_lat': addressList
                          .firstWhere((e) => e.type == 'drop')
                          .latlng
                          .latitude,
                      'drop_lng': addressList
                          .firstWhere((e) => e.type == 'drop')
                          .latlng
                          .longitude,
                      'stops': jsonEncode(dropStopList),
                      'ride_type': 1,
                      'promo_code': promoCode,
                      'transport_type':
                          (choosenTransportType == 0) ? 'taxi' : 'delivery',
                    })
                  : jsonEncode({
                      'pick_lat': addressList
                          .firstWhere((e) => e.type == 'pickup')
                          .latlng
                          .latitude,
                      'pick_lng': addressList
                          .firstWhere((e) => e.type == 'pickup')
                          .latlng
                          .longitude,
                      'ride_type': 1,
                      'promo_code': promoCode,
                      'transport_type':
                          (choosenTransportType == 0) ? 'taxi' : 'delivery',
                    }),
    );

    if (response.statusCode == 200) {
      etaDetails = jsonDecode(response.body)['data'];
      promoCode = '';
      promoStatus = 1;
      valueNotifierBook.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      promoStatus = 2;
      promoCode = '';
      valueNotifierBook.incrementNotifier();

      result = false;
    }
    return result;
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

//rental eta request

rentalEta() async {
  dynamic result = false;
  try {
    var response = await http.post(
      Uri.parse('${url}api/v1/request/list-packages'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'pick_lat': (userRequestData.isNotEmpty)
            ? userRequestData['pick_lat']
            : addressList.firstWhere((e) => e.type == 'pickup').latlng.latitude,
        'pick_lng': (userRequestData.isNotEmpty)
            ? userRequestData['pick_lng']
            : addressList
                .firstWhere((e) => e.type == 'pickup')
                .latlng
                .longitude,
        'transport_type': (choosenTransportType == 0) ? 'taxi' : 'delivery',
      }),
    );

    if (response.statusCode == 200) {
      etaDetails = jsonDecode(response.body)['data'];
      if (etaDetails.isNotEmpty && etaDetails[0]['typesWithPrice'] != null) {
        rentalOption = etaDetails[0]['typesWithPrice']['data'];
        rentalChoosenOption = 0;
        result = true;
        valueNotifierBook.incrementNotifier();
      } else {
        result = false;
      }
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      result = false;
    }
    return result;
  } catch (e) {
    debugPrint('Erro em rentalEta: $e');
    if (e is SocketException) {
      internet = false;
    }
    return false;
  }
}

rentalRequestWithPromo() async {
  dynamic result;
  try {
    var response = await http.post(
      Uri.parse('${url}api/v1/request/list-packages'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'pick_lat':
            addressList.firstWhere((e) => e.type == 'pickup').latlng.latitude,
        'pick_lng':
            addressList.firstWhere((e) => e.type == 'pickup').latlng.longitude,
        'ride_type': 1,
        'promo_code': promoCode,
        'transport_type': (choosenTransportType == 0) ? 'taxi' : 'delivery',
      }),
    );

    if (response.statusCode == 200) {
      etaDetails = jsonDecode(response.body)['data'];
      rentalOption = etaDetails[0]['typesWithPrice']['data'];
      rentalChoosenOption = 0;
      promoCode = '';
      promoStatus = 1;
      valueNotifierBook.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      promoStatus = 2;
      promoCode = '';
      valueNotifierBook.incrementNotifier();

      result = false;
    }
    return result;
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

//calculate distance

calculateDistance(lat1, lon1, lat2, lon2) {
  var p = 0.017453292519943295;
  var a = 0.5 -
      cos((lat2 - lat1) * p) / 2 +
      cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
  var val = (12742 * asin(sqrt(a))) * 1000;
  return val;
}

Map<String, dynamic> userRequestData = {};

/// Garante que a requisição recém-criada seja exibida como "procurando motorista"
/// até o motorista aceitar (evita API retornar accepted_at/driverDetail e ir direto para tela de código).
void _ensureRequestStateSearching() {
  if (userRequestData.isNotEmpty) {
    userRequestData['accepted_at'] = null;
    userRequestData['driverDetail'] = null;
  }
}

//create request

createRequest(value, api) async {
  dynamic result;
  debugPrint('═══════════════════════════════════════════════════════════');
  debugPrint('🚗 createRequest: Criando requisição...');
  debugPrint('───────────────────────────────────────────────────────────');

  try {
    if (bearerToken.isEmpty) {
      debugPrint('❌ createRequest: bearerToken está vazio!');
      return 'failure';
    }

    String endpoint = '$url$api';
    debugPrint('   Endpoint: $endpoint');
    debugPrint('   API: $api');

    Map<String, String> headers = {
      'Authorization': 'Bearer ${bearerToken[0].token}',
      'Content-Type': 'application/json',
    };

    logApiCall('POST', endpoint, headers: headers, body: value);

    var response = await http
        .post(
      Uri.parse(endpoint),
      headers: headers,
      body: value,
    )
        .timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        debugPrint('⏱️ createRequest: Timeout na requisição');
        throw TimeoutException('Timeout ao criar requisição');
      },
    );

    logApiCall('POST', endpoint,
        headers: headers,
        body: value,
        statusCode: response.statusCode,
        responseBody: response.body.length > 500
            ? '${response.body.substring(0, 500)}...'
            : response.body);

    debugPrint('📥 createRequest: Status ${response.statusCode}');

    if (response.statusCode == 200) {
      try {
        var responseData = jsonDecode(response.body);
        if (responseData['data'] != null) {
          userRequestData = responseData['data'];
          _ensureRequestStateSearching();
          debugPrint('✅ createRequest: Requisição criada com sucesso');
          debugPrint('   Request ID: ${userRequestData['id']}');
          debugPrint(
              '   Driver: ${userRequestData['driverDetail']?['data']?['name'] ?? 'N/A'}');
          streamRequest();
          result = 'success';
          valueNotifierBook.incrementNotifier();
        } else {
          debugPrint('⚠️ createRequest: Resposta sem data');
          debugPrint('   Response: ${response.body}');
          result = 'failure';
        }
      } catch (e) {
        debugPrint('❌ createRequest: Erro ao decodificar resposta: $e');
        debugPrint('   Response: ${response.body}');
        result = 'failure';
      }
    } else if (response.statusCode == 401) {
      debugPrint('⚠️ createRequest: Não autorizado (401)');
      result = 'logout';
    } else if (response.statusCode == 400 || response.statusCode == 422) {
      // Extrair mensagem de erro do servidor
      serverErrorMessage = extractErrorMessage(response);
      debugPrint('❌ createRequest: Erro ${response.statusCode}');
      debugPrint('   Mensagem do servidor: $serverErrorMessage');

      tripReqError = true;
      result = 'failure';
      valueNotifierBook.incrementNotifier();
    } else {
      debugPrint('❌ createRequest: Erro na requisição');
      debugPrint('   Status: ${response.statusCode}');
      debugPrint('   Response: ${response.body}');

      // Tentar extrair mensagem mesmo para outros códigos de erro
      serverErrorMessage = extractErrorMessage(response);

      try {
        var errorData = jsonDecode(response.body);
        String message = errorData['message'] ?? serverErrorMessage;
        debugPrint('   Mensagem: $message');

        if (message == 'no drivers available') {
          noDriverFound = true;
          debugPrint('⚠️ createRequest: Nenhum motorista disponível');
        } else {
          tripReqError = true;
          debugPrint('❌ createRequest: Erro na requisição: $message');
        }
      } catch (e) {
        debugPrint(
            '⚠️ createRequest: Erro ao decodificar mensagem de erro: $e');
        tripReqError = true;
      }

      result = 'failure';
      valueNotifierBook.incrementNotifier();
    }
    debugPrint('═══════════════════════════════════════════════════════════');
  } catch (e, stackTrace) {
    debugPrint('❌ createRequest: Exceção: $e');
    debugPrint('Stack trace: $stackTrace');
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
      valueNotifierBook.incrementNotifier();
    } else if (e is TimeoutException) {
      result = 'timeout';
    } else {
      result = 'failure';
    }
    debugPrint('═══════════════════════════════════════════════════════════');
  }
  return result;
}

//create request

createRequestLater(val, api) async {
  dynamic result;
  debugPrint('═══════════════════════════════════════════════════════════');
  debugPrint('🚗 createRequestLater: Criando requisição agendada...');
  debugPrint('───────────────────────────────────────────────────────────');

  try {
    if (bearerToken.isEmpty) {
      debugPrint('❌ createRequestLater: bearerToken está vazio!');
      return 'failure';
    }

    String endpoint = '$url$api';
    debugPrint('   Endpoint: $endpoint');
    debugPrint('   API: $api');

    // Decodificar e mostrar o body completo para debug
    debugPrint('📤 BODY ENVIADO (RAW):');
    debugPrint('   $val');
    try {
      var decodedBody = jsonDecode(val);
      debugPrint('📤 BODY ENVIADO (DECODED):');
      decodedBody.forEach((key, value) {
        debugPrint('   $key: $value');
      });
    } catch (e) {
      debugPrint('   Erro ao decodificar body: $e');
    }

    logApiCall(
      'POST',
      endpoint,
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
      body: val,
    );

    var response = await http
        .post(
      Uri.parse(endpoint),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
      body: val,
    )
        .timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        debugPrint('⏱️ createRequestLater: Timeout na requisição');
        throw TimeoutException('Timeout ao criar requisição agendada');
      },
    );

    logApiCall(
      'POST',
      endpoint,
      statusCode: response.statusCode,
      responseBody: response.body.length > 500
          ? '${response.body.substring(0, 500)}...'
          : response.body,
    );

    debugPrint('📥 createRequestLater: Status ${response.statusCode}');

    if (response.statusCode == 200) {
      debugPrint(
          '✅ createRequestLater: Requisição agendada criada com sucesso');
      result = 'success';
      streamRequest();
      valueNotifierBook.incrementNotifier();
    } else if (response.statusCode == 401) {
      debugPrint('⚠️ createRequestLater: Não autorizado (401)');
      result = 'logout';
    } else {
      debugPrint('❌ createRequestLater: Erro na requisição');
      debugPrint('   Status: ${response.statusCode}');
      debugPrint('📥 RESPOSTA COMPLETA DO SERVIDOR:');
      debugPrint('   ${response.body}');

      try {
        var errorData = jsonDecode(response.body);
        String message = errorData['message'] ?? 'Erro desconhecido';
        debugPrint('   Mensagem: $message');

        // Mostrar erros de validação se existirem
        if (errorData['errors'] != null) {
          debugPrint('📋 ERROS DE VALIDAÇÃO:');
          (errorData['errors'] as Map).forEach((field, errors) {
            debugPrint('   $field: $errors');
          });
        }

        if (message == 'no drivers available') {
          noDriverFound = true;
          debugPrint('⚠️ createRequestLater: Nenhum motorista disponível');
        } else {
          tripReqError = true;
          serverErrorMessage = extractErrorMessage(response);
          debugPrint('❌ createRequestLater: Erro na requisição: $message');
          debugPrint('   serverErrorMessage: $serverErrorMessage');
        }
      } catch (e) {
        debugPrint(
            '⚠️ createRequestLater: Erro ao decodificar mensagem de erro: $e');
        tripReqError = true;
      }

      result = 'failure';
      valueNotifierBook.incrementNotifier();
    }
    debugPrint('═══════════════════════════════════════════════════════════');
  } catch (e, stackTrace) {
    debugPrint('❌ createRequestLater: Exceção: $e');
    debugPrint('Stack trace: $stackTrace');
    if (e is SocketException) {
      result = 'no internet';
      internet = false;
    }
  }
  return result;
}

//create request with promo code

createRequestLaterPromo() async {
  dynamic result;
  try {
    var response = await http.post(
      Uri.parse('${url}api/v1/request/create'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'pick_lat':
            addressList.firstWhere((e) => e.id == 'pickup').latlng.latitude,
        'pick_lng':
            addressList.firstWhere((e) => e.id == 'pickup').latlng.longitude,
        'drop_lat':
            addressList.firstWhere((e) => e.id == 'drop').latlng.latitude,
        'drop_lng':
            addressList.firstWhere((e) => e.id == 'drop').latlng.longitude,
        'vehicle_type': etaDetails[choosenVehicle]['zone_type_id'],
        'ride_type': 1,
        'payment_opt': (etaDetails[choosenVehicle]['payment_type']
                    .toString()
                    .split(',')
                    .toList()[payingVia] ==
                'card')
            ? 0
            : (etaDetails[choosenVehicle]['payment_type']
                        .toString()
                        .split(',')
                        .toList()[payingVia] ==
                    'cash')
                ? 1
                : 2,
        'pick_address': addressList.firstWhere((e) => e.id == 'pickup').address,
        'drop_address': addressList.firstWhere((e) => e.id == 'drop').address,
        'promocode_id': etaDetails[choosenVehicle]['promocode_id'],
        'trip_start_time': choosenDateTime.toString().substring(0, 19),
        'is_later': true,
        'request_eta_amount': etaDetails[choosenVehicle]['total'],
      }),
    );
    if (response.statusCode == 200) {
      myMarkers.clear();
      streamRequest();
      valueNotifierBook.incrementNotifier();
      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      if (jsonDecode(response.body)['message'] == 'no drivers available') {
        noDriverFound = true;
      } else {
        tripReqError = true;
      }

      result = 'failure';
      valueNotifierBook.incrementNotifier();
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }

  return result;
}

//create rental request

createRentalRequest() async {
  dynamic result;
  try {
    var response = await http.post(
      Uri.parse('${url}api/v1/request/create'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'pick_lat':
            addressList.firstWhere((e) => e.id == 'pickup').latlng.latitude,
        'pick_lng':
            addressList.firstWhere((e) => e.id == 'pickup').latlng.longitude,
        'vehicle_type': rentalOption[choosenVehicle]['zone_type_id'],
        'ride_type': 1,
        'payment_opt': (rentalOption[choosenVehicle]['payment_type']
                    .toString()
                    .split(',')
                    .toList()[payingVia] ==
                'card')
            ? 0
            : (rentalOption[choosenVehicle]['payment_type']
                        .toString()
                        .split(',')
                        .toList()[payingVia] ==
                    'cash')
                ? 1
                : 2,
        'pick_address': addressList.firstWhere((e) => e.id == 'pickup').address,
        'request_eta_amount': rentalOption[choosenVehicle]['fare_amount'],
        'rental_pack_id': etaDetails[rentalChoosenOption]['id'],
      }),
    );
    if (response.statusCode == 200) {
      userRequestData = jsonDecode(response.body)['data'];
      _ensureRequestStateSearching();
      streamRequest();
      result = 'success';

      valueNotifierBook.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      if (jsonDecode(response.body)['message'] == 'no drivers available') {
        noDriverFound = true;
      } else {
        tripReqError = true;
      }

      result = 'failure';
      valueNotifierBook.incrementNotifier();
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
      valueNotifierBook.incrementNotifier();
    }
  }
  return result;
}

createRentalRequestWithPromo() async {
  dynamic result;
  try {
    var response = await http.post(
      Uri.parse('${url}api/v1/request/create'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'pick_lat':
            addressList.firstWhere((e) => e.id == 'pickup').latlng.latitude,
        'pick_lng':
            addressList.firstWhere((e) => e.id == 'pickup').latlng.longitude,
        'vehicle_type': rentalOption[choosenVehicle]['zone_type_id'],
        'ride_type': 1,
        'payment_opt': (rentalOption[choosenVehicle]['payment_type']
                    .toString()
                    .split(',')
                    .toList()[payingVia] ==
                'card')
            ? 0
            : (rentalOption[choosenVehicle]['payment_type']
                        .toString()
                        .split(',')
                        .toList()[payingVia] ==
                    'cash')
                ? 1
                : 2,
        'pick_address': addressList.firstWhere((e) => e.id == 'pickup').address,
        'promocode_id': rentalOption[choosenVehicle]['promocode_id'],
        'request_eta_amount': rentalOption[choosenVehicle]['fare_amount'],
        'rental_pack_id': etaDetails[rentalChoosenOption]['id'],
      }),
    );
    if (response.statusCode == 200) {
      userRequestData = jsonDecode(response.body)['data'];
      _ensureRequestStateSearching();
      streamRequest();
      result = 'success';
      valueNotifierBook.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      if (jsonDecode(response.body)['message'] == 'no drivers available') {
        noDriverFound = true;
      } else {
        debugPrint(response.body);
        tripReqError = true;
      }

      result = 'failure';
      valueNotifierBook.incrementNotifier();
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

createRentalRequestLater() async {
  dynamic result;
  try {
    var response = await http.post(
      Uri.parse('${url}api/v1/request/create'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'pick_lat':
            addressList.firstWhere((e) => e.id == 'pickup').latlng.latitude,
        'pick_lng':
            addressList.firstWhere((e) => e.id == 'pickup').latlng.longitude,
        'vehicle_type': rentalOption[choosenVehicle]['zone_type_id'],
        'ride_type': 1,
        'payment_opt': (rentalOption[choosenVehicle]['payment_type']
                    .toString()
                    .split(',')
                    .toList()[payingVia] ==
                'card')
            ? 0
            : (rentalOption[choosenVehicle]['payment_type']
                        .toString()
                        .split(',')
                        .toList()[payingVia] ==
                    'cash')
                ? 1
                : 2,
        'pick_address': addressList.firstWhere((e) => e.id == 'pickup').address,
        'trip_start_time': choosenDateTime.toString().substring(0, 19),
        'is_later': true,
        'request_eta_amount': rentalOption[choosenVehicle]['fare_amount'],
        'rental_pack_id': etaDetails[rentalChoosenOption]['id'],
      }),
    );
    if (response.statusCode == 200) {
      result = 'success';
      streamRequest();
      valueNotifierBook.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      if (jsonDecode(response.body)['message'] == 'no drivers available') {
        noDriverFound = true;
      } else {
        tripReqError = true;
      }

      result = 'failure';
      valueNotifierBook.incrementNotifier();
    }
  } catch (e) {
    if (e is SocketException) {
      result = 'no internet';
      internet = false;
    }
  }
  return result;
}

createRentalRequestLaterPromo() async {
  dynamic result;
  try {
    var response = await http.post(
      Uri.parse('${url}api/v1/request/create'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'pick_lat':
            addressList.firstWhere((e) => e.id == 'pickup').latlng.latitude,
        'pick_lng':
            addressList.firstWhere((e) => e.id == 'pickup').latlng.longitude,
        'vehicle_type': rentalOption[choosenVehicle]['zone_type_id'],
        'ride_type': 1,
        'payment_opt': (rentalOption[choosenVehicle]['payment_type']
                    .toString()
                    .split(',')
                    .toList()[payingVia] ==
                'card')
            ? 0
            : (rentalOption[choosenVehicle]['payment_type']
                        .toString()
                        .split(',')
                        .toList()[payingVia] ==
                    'cash')
                ? 1
                : 2,
        'pick_address': addressList.firstWhere((e) => e.id == 'pickup').address,
        'promocode_id': rentalOption[choosenVehicle]['promocode_id'],
        'trip_start_time': choosenDateTime.toString().substring(0, 19),
        'is_later': true,
        'request_eta_amount': rentalOption[choosenVehicle]['fare_amount'],
        'rental_pack_id': etaDetails[rentalChoosenOption]['id'],
      }),
    );
    if (response.statusCode == 200) {
      myMarkers.clear();
      streamRequest();
      valueNotifierBook.incrementNotifier();
      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      if (jsonDecode(response.body)['message'] == 'no drivers available') {
        noDriverFound = true;
      } else {
        debugPrint(response.body);
        tripReqError = true;
      }

      result = 'failure';
      valueNotifierBook.incrementNotifier();
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }

  return result;
}

List<RequestCreate> createRequestList = <RequestCreate>[];

class RequestCreate {
  dynamic pickLat;
  dynamic pickLng;
  dynamic dropLat;
  dynamic dropLng;
  dynamic vehicleType;
  dynamic rideType;
  dynamic paymentOpt;
  dynamic pickAddress;
  dynamic dropAddress;
  dynamic promoCodeId;

  RequestCreate({
    this.pickLat,
    this.pickLng,
    this.dropLat,
    this.dropLng,
    this.vehicleType,
    this.rideType,
    this.paymentOpt,
    this.pickAddress,
    this.dropAddress,
    this.promoCodeId,
  });

  Map<String, dynamic> toJson() => {
        'pick_lat': pickLat,
        'pick_lng': pickLng,
        'drop_lat': dropLat,
        'drop_lng': dropLng,
        'vehicle_type': vehicleType,
        'ride_type': rideType,
        'payment_opt': paymentOpt,
        'pick_address': pickAddress,
        'drop_address': dropAddress,
        'promocode_id': promoCodeId,
      };
}

//user cancel request

cancelRequest() async {
  dynamic result;
  try {
    var response = await http.post(
      Uri.parse('${url}api/v1/request/cancel'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'request_id': userRequestData['id']}),
    );
    if (response.statusCode == 200) {
      userCancelled = true;
      cancelRequestByUser = true;
      if (userRequestData['is_bid_ride'] == 1) {
        FirebaseDatabase.instance
            .ref('bid-meta/${userRequestData["id"]}')
            .remove();
      }
      FirebaseDatabase.instance
          .ref('requests')
          .child(userRequestData['id'])
          .update({'cancelled_by_user': true});
      userRequestData = {};
      if (requestStreamStart?.isPaused == false ||
          requestStreamEnd?.isPaused == false) {
        requestStreamStart?.cancel();
        requestStreamEnd?.cancel();
        requestStreamStart = null;
        requestStreamEnd = null;
      }
      if (rideStreamUpdate?.isPaused == false ||
          rideStreamStart?.isPaused == false) {
        rideStreamUpdate?.cancel();
        rideStreamStart?.cancel();
        rideStreamUpdate = null;
        rideStreamStart = null;
      }
      result = 'success';
      valueNotifierBook.incrementNotifier();
      valueNotifierHome.incrementNotifier();
      await getUserDetails();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failed';
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
  return result;
}

cancelLaterRequest(val) async {
  dynamic result;
  try {
    var response = await http.post(
      Uri.parse('${url}api/v1/request/cancel'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'request_id': val}),
    );
    if (response.statusCode == 200) {
      userRequestData = {};
      if (requestStreamStart?.isPaused == false ||
          requestStreamEnd?.isPaused == false) {
        requestStreamStart?.cancel();
        requestStreamEnd?.cancel();
        requestStreamStart = null;
        requestStreamEnd = null;
      }
      result = 'success';
      valueNotifierBook.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      result = 'failed';
      debugPrint(response.body);
    }
    return result;
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

//user cancel request with reason

cancelRequestWithReason(reason) async {
  dynamic result;
  try {
    var response = await http.post(
      Uri.parse('${url}api/v1/request/cancel'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'request_id': userRequestData['id'], 'reason': reason}),
    );
    if (response.statusCode == 200) {
      cancelRequestByUser = true;
      FirebaseDatabase.instance.ref('requests/${userRequestData['id']}').update(
        {'cancelled_by_user': true},
      );
      userRequestData = {};
      if (rideStreamUpdate?.isPaused == false ||
          rideStreamStart?.isPaused == false) {
        rideStreamUpdate?.cancel();
        rideStreamUpdate = null;
        rideStreamStart?.cancel();
        rideStreamStart = null;
      }
      result = 'success';
      valueNotifierBook.incrementNotifier();
      valueNotifierHome.incrementNotifier();
      await getUserDetails();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      result = 'failed';
      debugPrint(response.body);
    }
    return result;
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

//making call to user

makingPhoneCall(phnumber) async {
  try {
    final String raw = phnumber?.toString() ?? '';
    final String digits = raw.replaceAll(RegExp(r'[^\d+]'), '');
    if (digits.isEmpty) return;
    final Uri telUri = Uri.parse('tel:$digits');
    await launchUrl(telUri, mode: LaunchMode.externalApplication);
  } catch (e) {
    debugPrint('makingPhoneCall error: $e');
  }
}

//cancellation reason
List cancelReasonsList = [];
cancelReason(reason) async {
  dynamic result;
  try {
    var response = await http.get(
      Uri.parse(
        '${url}api/v1/common/cancallation/reasons?arrived=$reason&transport_type=${userRequestData['transport_type']}',
      ),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      cancelReasonsList = jsonDecode(response.body)['data'];
      result = true;
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = false;
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

List<CancelReasonJson> cancelJson = <CancelReasonJson>[];

class CancelReasonJson {
  dynamic requestId;
  dynamic reason;

  CancelReasonJson({this.requestId, this.reason});

  Map<String, dynamic> toJson() {
    return {'request_id': requestId, 'reason': reason};
  }
}

//add user rating

userRating() async {
  dynamic result;
  try {
    var response = await http.post(
      Uri.parse('${url}api/v1/request/rating'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'request_id': userRequestData['id'],
        'rating': review,
        'comment': feedback,
      }),
    );
    if (response.statusCode == 200) {
      await getUserDetails();
      result = true;
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = false;
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

//class for realtime database driver data

class NearByDriver {
  double bearing;
  String g;
  String id;
  List l;
  String updatedAt;

  NearByDriver({
    required this.bearing,
    required this.g,
    required this.id,
    required this.l,
    required this.updatedAt,
  });

  factory NearByDriver.fromJson(Map<String, dynamic> json) {
    return NearByDriver(
      id: json['id'],
      bearing: json['bearing'],
      g: json['g'],
      l: json['l'],
      updatedAt: json['updated_at'],
    );
  }
}

//add favourites location

addFavLocation(lat, lng, add, name) async {
  dynamic result;
  try {
    var response = await http.post(
      Uri.parse('${url}api/v1/user/add-favourite-location'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'pick_lat': lat,
        'pick_lng': lng,
        'pick_address': add,
        'address_name': name,
      }),
    );
    if (response.statusCode == 200) {
      result = true;
      await getUserDetails();
      valueNotifierHome.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = false;
    }
    return result;
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

//sos data
List sosData = [];

getSosData(lat, lng) async {
  dynamic result;
  try {
    var response = await http.get(
      Uri.parse('${url}api/v1/common/sos/list/$lat/$lng'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      sosData = jsonDecode(response.body)['data'];
      result = 'success';
      valueNotifierBook.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

//sos admin notification

notifyAdmin() async {
  var db = FirebaseDatabase.instance.ref();
  try {
    await db.child('SOS/${userRequestData['id']}').update({
      "is_driver": "0",
      "is_user": "1",
      "req_id": userRequestData['id'],
      "serv_loc_id": userRequestData['service_location_id'],
      "updated_at": ServerValue.timestamp,
    });
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
  return true;
}

//get current ride messages

List chatList = [];

getCurrentMessages() async {
  dynamic result;
  debugPrint('═══════════════════════════════════════════════════════════');
  debugPrint('💬 getCurrentMessages: Buscando mensagens...');
  debugPrint('───────────────────────────────────────────────────────────');

  try {
    if (userRequestData.isEmpty) {
      debugPrint('❌ getCurrentMessages: userRequestData está vazio!');
      return 'failed';
    }

    if (bearerToken.isEmpty) {
      debugPrint('❌ getCurrentMessages: bearerToken está vazio!');
      return 'failed';
    }

    String requestId = userRequestData['id'].toString();
    debugPrint('   Request ID: $requestId');
    debugPrint('   URL: ${url}api/v1/request/chat-history/$requestId');

    logApiCall('GET', '${url}api/v1/request/chat-history/$requestId', headers: {
      'Authorization': 'Bearer ${bearerToken[0].token}',
      'Content-Type': 'application/json',
    });

    var response = await http.get(
      Uri.parse('${url}api/v1/request/chat-history/$requestId'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
    ).timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        debugPrint('⏱️ getCurrentMessages: Timeout na requisição');
        throw TimeoutException('Timeout ao buscar mensagens');
      },
    );

    logApiCall(
      'GET',
      '${url}api/v1/request/chat-history/$requestId',
      statusCode: response.statusCode,
      responseBody: response.body.length > 500
          ? '${response.body.substring(0, 500)}...'
          : response.body,
    );

    if (response.statusCode == 200) {
      var responseData = jsonDecode(response.body);
      if (responseData['success'] == true) {
        var newChatList = responseData['data'] ?? [];
        debugPrint(
            '✅ getCurrentMessages: ${newChatList.length} mensagens recebidas');
        chatList = newChatList;
        valueNotifierBook.incrementNotifier();
        result = 'success';
      } else {
        debugPrint('⚠️ getCurrentMessages: success = false na resposta');
        result = 'failed';
      }
    } else if (response.statusCode == 401) {
      debugPrint('⚠️ getCurrentMessages: Não autorizado (401)');
      result = 'logout';
    } else {
      debugPrint('❌ getCurrentMessages: Status ${response.statusCode}');
      debugPrint('   Response: ${response.body}');
      result = 'failed';
    }
    debugPrint('═══════════════════════════════════════════════════════════');
    return result;
  } catch (e, stackTrace) {
    debugPrint('❌ getCurrentMessages: Erro: $e');
    debugPrint('Stack trace: $stackTrace');
    if (e is SocketException) {
      internet = false;
    }
  }
}

//send chat

sendMessage(chat) async {
  dynamic result;
  debugPrint('═══════════════════════════════════════════════════════════');
  debugPrint('💬 sendMessage: Enviando mensagem...');
  debugPrint('───────────────────────────────────────────────────────────');

  try {
    if (userRequestData.isEmpty) {
      debugPrint('❌ sendMessage: userRequestData está vazio!');
      return 'failed';
    }

    if (bearerToken.isEmpty) {
      debugPrint('❌ sendMessage: bearerToken está vazio!');
      return 'failed';
    }

    if (chat.toString().trim().isEmpty) {
      debugPrint('⚠️ sendMessage: Mensagem vazia');
      return 'failed';
    }

    String requestId = userRequestData['id'].toString();
    debugPrint('   Request ID: $requestId');
    debugPrint(
        '   Mensagem: ${chat.toString().substring(0, chat.toString().length > 50 ? 50 : chat.toString().length)}...');
    debugPrint('   URL: ${url}api/v1/request/send');

    var requestBody = {'request_id': requestId, 'message': chat.toString()};
    logApiCall(
      'POST',
      '${url}api/v1/request/send',
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
      body: requestBody,
    );

    var response = await http
        .post(
      Uri.parse('${url}api/v1/request/send'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestBody),
    )
        .timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        debugPrint('⏱️ sendMessage: Timeout na requisição');
        throw TimeoutException('Timeout ao enviar mensagem');
      },
    );

    logApiCall(
      'POST',
      '${url}api/v1/request/send',
      statusCode: response.statusCode,
      responseBody: response.body.length > 500
          ? '${response.body.substring(0, 500)}...'
          : response.body,
    );

    if (response.statusCode == 200) {
      debugPrint('✅ sendMessage: Mensagem enviada com sucesso');
      await getCurrentMessages();
      try {
        await FirebaseDatabase.instance.ref('requests/$requestId').update(
          {'message_by_user': chatList.length},
        ).timeout(const Duration(seconds: 5));
        debugPrint('✅ sendMessage: Firebase atualizado');
      } catch (e) {
        debugPrint('⚠️ sendMessage: Erro ao atualizar Firebase: $e');
      }
      result = 'success';
    } else if (response.statusCode == 401) {
      debugPrint('⚠️ sendMessage: Não autorizado (401)');
      result = 'logout';
    } else {
      debugPrint('❌ sendMessage: Status ${response.statusCode}');
      debugPrint('   Response: ${response.body}');
      result = 'failed';
    }
    debugPrint('═══════════════════════════════════════════════════════════');
    return result;
  } catch (e, stackTrace) {
    debugPrint('❌ sendMessage: Erro: $e');
    debugPrint('Stack trace: $stackTrace');
    if (e is SocketException) {
      internet = false;
    }
    return 'failed';
  }
}

//message seen

messageSeen() async {
  debugPrint('═══════════════════════════════════════════════════════════');
  debugPrint('👁️ messageSeen: Marcando mensagens como lidas...');
  debugPrint('───────────────────────────────────────────────────────────');

  try {
    if (userRequestData.isEmpty) {
      debugPrint('⚠️ messageSeen: userRequestData está vazio!');
      return;
    }

    if (bearerToken.isEmpty) {
      debugPrint('⚠️ messageSeen: bearerToken está vazio!');
      return;
    }

    String requestId = userRequestData['id'].toString();
    debugPrint('   Request ID: $requestId');

    logApiCall(
      'POST',
      '${url}api/v1/request/seen',
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
      body: {'request_id': requestId},
    );

    var response = await http
        .post(
      Uri.parse('${url}api/v1/request/seen'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'request_id': requestId}),
    )
        .timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        debugPrint('⏱️ messageSeen: Timeout na requisição');
        throw TimeoutException('Timeout ao marcar mensagens como lidas');
      },
    );

    logApiCall(
      'POST',
      '${url}api/v1/request/seen',
      statusCode: response.statusCode,
      responseBody: response.body.length > 200
          ? '${response.body.substring(0, 200)}...'
          : response.body,
    );

    if (response.statusCode == 200) {
      debugPrint('✅ messageSeen: Mensagens marcadas como lidas');
      getCurrentMessages();
    } else {
      debugPrint('❌ messageSeen: Status ${response.statusCode}');
      debugPrint('   Response: ${response.body}');
    }
    debugPrint('═══════════════════════════════════════════════════════════');
  } catch (e, stackTrace) {
    debugPrint('❌ messageSeen: Erro: $e');
    debugPrint('Stack trace: $stackTrace');
  }
}

//admin chat

dynamic chatStream;
String unSeenChatCount = '0';
streamAdminchat() async {
  chatStream = FirebaseDatabase.instance
      .ref()
      .child(
        'chats/${(adminChatList.length > 2) ? userDetails['chat_id'] : chatid}',
      )
      .onValue
      .listen((event) async {
    var value = Map<String, dynamic>.from(
      jsonDecode(jsonEncode(event.snapshot.value)),
    );
    if (value['to_id'].toString() == userDetails['id'].toString()) {
      adminChatList.add(jsonDecode(jsonEncode(event.snapshot.value)));
    }
    value.clear();
    if (adminChatList.isNotEmpty) {
      unSeenChatCount =
          adminChatList[adminChatList.length - 1]['count'].toString();
      if (unSeenChatCount == 'null') {
        unSeenChatCount = '0';
      }
    }
    valueNotifierChat.incrementNotifier();
  });
}

//admin chat

List adminChatList = [];
dynamic isnewchat = 1;
dynamic chatid;
getadminCurrentMessages() async {
  dynamic result;
  try {
    var response = await http.get(
      Uri.parse('${url}api/v1/request/admin-chat-history'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      adminChatList.clear();
      isnewchat = jsonDecode(response.body)['data']['new_chat'];
      adminChatList = jsonDecode(response.body)['data']['chats'];
      if (adminChatList.isNotEmpty) {
        chatid = adminChatList[0]['chat_id'];
      }
      if (adminChatList.isNotEmpty && chatStream == null) {
        streamAdminchat();
      }
      unSeenChatCount = '0';
      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      result = 'failed';
      debugPrint(response.body);
    }
    return result;
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

sendadminMessage(chat) async {
  dynamic result;
  try {
    var response = await http.post(
      Uri.parse('${url}api/v1/request/send-message'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
      body: (isnewchat == 1)
          ? jsonEncode({'new_chat': isnewchat, 'message': chat})
          : jsonEncode({'new_chat': 0, 'message': chat, 'chat_id': chatid}),
    );
    if (response.statusCode == 200) {
      chatid = jsonDecode(response.body)['data']['chat_id'];
      adminChatList.add({
        'chat_id': chatid,
        'message': jsonDecode(response.body)['data']['message'],
        'from_id': userDetails['id'],
        'to_id': jsonDecode(response.body)['data']['to_id'],
        'user_timezone': jsonDecode(response.body)['data']['user_timezone'],
      });
      isnewchat = 0;
      if (adminChatList.isNotEmpty && chatStream == null) {
        streamAdminchat();
      }
      unSeenChatCount = '0';
      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      result = 'failed';
      debugPrint(response.body);
    }
    return result;
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

adminmessageseen() async {
  dynamic result;
  try {
    var response = await http.get(
      Uri.parse(
        '${url}api/v1/request/update-notification-count?chat_id=$chatid',
      ),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      result = true;
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = false;
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

//add sos

addSos(name, number) async {
  dynamic result;
  try {
    var response = await http.post(
      Uri.parse('${url}api/v1/common/sos/store'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'name': name, 'number': number}),
    );

    if (response.statusCode == 200) {
      await getUserDetails();
      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

//remove sos

deleteSos(id) async {
  dynamic result;
  try {
    var response = await http.post(
      Uri.parse('${url}api/v1/common/sos/delete/$id'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      await getUserDetails();
      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

//open url in browser

openBrowser(browseUrl) async {
  // ignore: deprecated_member_use
  if (await canLaunch(browseUrl)) {
    // ignore: deprecated_member_use
    await launch(browseUrl);
  } else {
    throw 'Could not launch $browseUrl';
  }
}

//get faq
List faqData = [];
Map<String, dynamic> myFaqPage = {};

getFaqData(lat, lng) async {
  dynamic result;
  try {
    var response = await http.get(
      Uri.parse('${url}api/v1/common/faq/list/$lat/$lng'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      faqData = jsonDecode(response.body)['data'];
      myFaqPage = jsonDecode(response.body)['meta'];
      valueNotifierBook.incrementNotifier();
      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
    }
  } catch (e) {
    if (e is SocketException) {
      result = 'no internet';
      internet = false;
    }
  }
  return result;
}

getFaqPages(id) async {
  dynamic result;
  try {
    var response = await http.get(
      Uri.parse('${url}api/v1/common/faq/list/$id'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      var val = jsonDecode(response.body)['data'];
      val.forEach((element) {
        faqData.add(element);
      });
      myFaqPage = jsonDecode(response.body)['meta'];
      valueNotifierHome.incrementNotifier();
      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
    }
  } catch (e) {
    if (e is SocketException) {
      result = 'no internet';
      internet = false;
    }
    return result;
  }
}

//remove fav address

removeFavAddress(id) async {
  dynamic result;
  try {
    var response = await http.get(
      Uri.parse('${url}api/v1/user/delete-favourite-location/$id'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      await getUserDetails();
      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
    }
  } catch (e) {
    if (e is SocketException) {
      result = 'no internet';
      internet = false;
    }
  }
  return result;
}

//get user referral

Map<String, dynamic> myReferralCode = {};
getReferral() async {
  dynamic result;
  try {
    var response = await http.get(
      Uri.parse('${url}api/v1/get/referral'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      result = 'success';
      myReferralCode = jsonDecode(response.body)['data'];
      valueNotifierBook.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
    }
  } catch (e) {
    if (e is SocketException) {
      result = 'no internet';
      internet = false;
    }
  }
  return result;
}

//user logout

userLogout() async {
  dynamic result;
  try {
    var response = await http.post(
      Uri.parse('${url}api/v1/logout'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      pref.remove('Bearer');

      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
    }
  } catch (e) {
    if (e is SocketException) {
      result = 'no internet';
      internet = false;
    }
  }
  return result;
}

//request history
List myHistory = [];
Map<String, dynamic> myHistoryPage = {};

getHistory(id) async {
  dynamic result;

  try {
    var response = await http.get(
      Uri.parse('${url}api/v1/request/history?$id'),
      headers: {'Authorization': 'Bearer ${bearerToken[0].token}'},
    );
    if (response.statusCode == 200) {
      myHistory = jsonDecode(response.body)['data'];
      myHistoryPage = jsonDecode(response.body)['meta'];
      result = 'success';
      valueNotifierBook.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
      valueNotifierBook.incrementNotifier();
    }
  } catch (e) {
    if (e is SocketException) {
      result = 'no internet';

      internet = false;
      valueNotifierBook.incrementNotifier();
    }
  }
  return result;
}

getHistoryPages(id) async {
  dynamic result;

  try {
    var response = await http.get(
      Uri.parse('${url}api/v1/request/history?$id'),
      headers: {'Authorization': 'Bearer ${bearerToken[0].token}'},
    );
    if (response.statusCode == 200) {
      List list = jsonDecode(response.body)['data'];
      // ignore: avoid_function_literals_in_foreach_calls
      list.forEach((element) {
        myHistory.add(element);
      });
      myHistoryPage = jsonDecode(response.body)['meta'];
      result = 'success';
      valueNotifierBook.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
      valueNotifierBook.incrementNotifier();
    }
  } catch (e) {
    if (e is SocketException) {
      result = 'no internet';

      internet = false;
      valueNotifierBook.incrementNotifier();
    }
  }
  return result;
}

//get wallet history

Map<String, dynamic> walletBalance = {};
List walletHistory = [];
Map<String, dynamic> walletPages = {};

getWalletHistory() async {
  dynamic result;
  try {
    var response = await http.get(
      Uri.parse('${url}api/v1/payment/wallet/history'),
      headers: {'Authorization': 'Bearer ${bearerToken[0].token}'},
    );
    if (response.statusCode == 200) {
      walletBalance = jsonDecode(response.body);
      walletHistory = walletBalance['wallet_history']['data'];
      walletPages = walletBalance['wallet_history']['meta']['pagination'];
      result = 'success';
      valueNotifierBook.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
      valueNotifierBook.incrementNotifier();
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
      valueNotifierBook.incrementNotifier();
    }
  }
  return result;
}

getWalletHistoryPage(page) async {
  dynamic result;
  try {
    var response = await http.get(
      Uri.parse('${url}api/v1/payment/wallet/history?page=$page'),
      headers: {'Authorization': 'Bearer ${bearerToken[0].token}'},
    );
    if (response.statusCode == 200) {
      walletBalance = jsonDecode(response.body);
      List list = walletBalance['wallet_history']['data'];
      // ignore: avoid_function_literals_in_foreach_calls
      list.forEach((element) {
        walletHistory.add(element);
      });
      walletPages = walletBalance['wallet_history']['meta']['pagination'];
      result = 'success';
      valueNotifierBook.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
      valueNotifierBook.incrementNotifier();
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
      valueNotifierBook.incrementNotifier();
    }
  }
  return result;
}

//get client token for braintree

getClientToken() async {
  dynamic result;
  try {
    var response = await http.get(
      Uri.parse('${url}api/v1/payment/client/token'),
      headers: {'Authorization': 'Bearer ${bearerToken[0].token}'},
    );
    if (response.statusCode == 200) {
      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

//stripe payment

Map<String, dynamic> stripeToken = {};

getStripePayment(money) async {
  dynamic results;
  try {
    var response = await http.post(
      Uri.parse('${url}api/v1/payment/stripe/intent'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'amount': money}),
    );
    if (response.statusCode == 200) {
      results = 'success';
      stripeToken = jsonDecode(response.body)['data'];
    } else if (response.statusCode == 401) {
      results = 'logout';
    } else {
      debugPrint(response.body);
      results = 'failure';
    }
  } catch (e) {
    if (e is SocketException) {
      results = 'no internet';
      internet = false;
    }
  }
  return results;
}

//stripe add money

addMoneyStripe(amount, nonce) async {
  dynamic result;
  try {
    var response = await http.post(
      Uri.parse('${url}api/v1/payment/stripe/add/money'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'amount': amount,
        'payment_nonce': nonce,
        'payment_id': nonce,
      }),
    );
    if (response.statusCode == 200) {
      await getWalletHistory();
      await getUserDetails();
      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

//stripe pay money

payMoneyStripe(nonce) async {
  dynamic result;
  try {
    var response = await http.post(
      Uri.parse('${url}api/v1/payment/stripe/make-payment-for-ride'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'request_id': userRequestData['id'],
        'payment_id': nonce,
      }),
    );
    if (response.statusCode == 200) {
      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

//flutterwave

addMoneyFlutterwave(amount, nonce) async {
  dynamic result;
  try {
    var response = await http.post(
      Uri.parse('${url}api/v1/payment/flutter-wave/add-money'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'amount': amount,
        'payment_nonce': nonce,
        'payment_id': nonce,
      }),
    );
    if (response.statusCode == 200) {
      await getWalletHistory();
      await getUserDetails();
      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

//edit user profile

updateProfile(name, email) async {
  dynamic result;
  try {
    var response = http.MultipartRequest(
      'POST',
      Uri.parse('${url}api/v1/user/profile'),
    );
    response.headers.addAll({
      'Authorization': 'Bearer ${bearerToken[0].token}',
    });
    if (imageFile != null) {
      response.files.add(
        await http.MultipartFile.fromPath('profile_picture', imageFile),
      );
    }
    response.fields['email'] = email;
    response.fields['name'] = name;

    // Adicionar todos os novos campos sempre (mesmo se vazios ou não modificados)
    response.fields['gender'] = gender;
    response.fields['document'] = document;
    response.fields['birth_date'] = birthDate;
    response.fields['passenger_preference'] = passengerPreference;

    // Log dos campos sendo enviados
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('📤 updateProfile: Enviando todos os campos:');
    debugPrint('   name: "$name"');
    debugPrint('   email: "$email"');
    debugPrint('   gender: "$gender"');
    debugPrint('   document: "$document"');
    debugPrint('   birth_date: "$birthDate"');
    debugPrint('   passenger_preference: "$passengerPreference"');
    debugPrint('═══════════════════════════════════════════════════════════');

    var request = await response.send();
    var respon = await http.Response.fromStream(request);
    final val = jsonDecode(respon.body);
    if (request.statusCode == 200) {
      result = 'success';
      if (val['success'] == true) {
        await getUserDetails();
      }
    } else if (request.statusCode == 401) {
      result = 'logout';
    } else if (request.statusCode == 422) {
      debugPrint(respon.body);
      var error = jsonDecode(respon.body)['errors'];
      result = error[error.keys.toList()[0]]
          .toString()
          .replaceAll('[', '')
          .replaceAll(']', '')
          .toString();
    } else {
      debugPrint(val);
      result = jsonDecode(respon.body)['message'];
    }
  } catch (e) {
    if (e is SocketException) {
      result = 'no internet';
    }
  }
  return result;
}

updateProfileWithoutImage(name, email) async {
  dynamic result;
  try {
    var response = http.MultipartRequest(
      'POST',
      Uri.parse('${url}api/v1/user/profile'),
    );
    response.headers.addAll({
      'Authorization': 'Bearer ${bearerToken[0].token}',
    });
    response.fields['email'] = email;
    response.fields['name'] = name;
    var request = await response.send();
    var respon = await http.Response.fromStream(request);
    final val = jsonDecode(respon.body);
    if (request.statusCode == 200) {
      result = 'success';
      if (val['success'] == true) {
        await getUserDetails();
      }
    } else if (request.statusCode == 401) {
      result = 'logout';
    } else if (request.statusCode == 422) {
      debugPrint(respon.body);
      var error = jsonDecode(respon.body)['errors'];
      result = error[error.keys.toList()[0]]
          .toString()
          .replaceAll('[', '')
          .replaceAll(']', '')
          .toString();
    } else {
      debugPrint(val);
      result = jsonDecode(respon.body)['message'];
    }
  } catch (e) {
    if (e is SocketException) {
      result = 'no internet';
    }
  }
  return result;
}

//get bank info
Map<String, dynamic> bankData = {};

getBankInfo() async {
  bankData.clear();
  dynamic result;
  try {
    var response = await http.get(
      Uri.parse('${url}api/v1/user/get-bank-info'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      result = 'success';
      bankData = jsonDecode(response.body)['data'] ?? {};
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
    }
  } catch (e) {
    if (e is SocketException) {
      result = 'no internet';
      internet = false;
    }
  }
  return result;
}

addBankData(accName, accNo, bankCode, bankName, {String? type}) async {
  dynamic result;
  try {
    var body = <String, dynamic>{
      'account_name': accName,
      'account_no': accNo,
      'bank_code': bankCode,
      'bank_name': bankName,
    };
    if (type != null && type.isNotEmpty) body['type'] = type;
    var response = await http.post(
      Uri.parse('${url}api/v1/user/update-bank-info'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      await getBankInfo();
      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else if (response.statusCode == 422) {
      debugPrint(response.body);
      var error = jsonDecode(response.body)['errors'];
      result = error[error.keys.toList()[0]]
          .toString()
          .replaceAll('[', '')
          .replaceAll(']', '')
          .toString();
    } else {
      debugPrint(response.body);
      result = jsonDecode(response.body)['message'];
    }
  } catch (e) {
    if (e is SocketException) {
      result = 'no internet';
      internet = false;
    }
  }
  return result;
}

//internet true
internetTrue() {
  internet = true;
  valueNotifierHome.incrementNotifier();
}

//make complaint

List generalComplaintList = [];

/// Busca os títulos de reclamação do banco (API).
/// [type] para usuário (passageiro): "user" = reclamação geral do menu, "request" = reclamação de uma viagem.
/// O backend retorna tipos diferentes para user vs driver.
getGeneralComplaint(type) async {
  dynamic result;
  final uri = '${url}api/v1/common/complaint-titles';
  debugPrint('📋 [RECLAMAÇÃO] getGeneralComplaint (user): GET $uri');
  try {
    var response = await http.get(
      Uri.parse(uri),
      headers: {'Authorization': 'Bearer ${bearerToken[0].token}'},
    );
    debugPrint(
        '📋 [RECLAMAÇÃO] getGeneralComplaint (user): status=${response.statusCode} body length=${response.body.length}');
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final data = decoded['data'];
      debugPrint(
          '📋 [RECLAMAÇÃO] getGeneralComplaint (user): response.data type=${data.runtimeType}');
      if (data == null) {
        debugPrint(
            '📋 [RECLAMAÇÃO] getGeneralComplaint (user): data é null - body=${response.body}');
        generalComplaintList = [];
      } else if (data is! List) {
        debugPrint(
            '📋 [RECLAMAÇÃO] getGeneralComplaint (user): data não é lista - body=${response.body}');
        generalComplaintList = [];
      } else {
        generalComplaintList = data;
        debugPrint(
            '📋 [RECLAMAÇÃO] getGeneralComplaint (user): ${generalComplaintList.length} títulos');
        for (var i = 0; i < generalComplaintList.length && i < 5; i++) {
          final item = generalComplaintList[i];
          debugPrint(
              '📋 [RECLAMAÇÃO]   [$i] id=${item['id']} title=${item['title']}');
        }
        if (generalComplaintList.length > 5) {
          debugPrint(
              '📋 [RECLAMAÇÃO]   ... e mais ${generalComplaintList.length - 5}');
        }
      }
      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
      debugPrint('📋 [RECLAMAÇÃO] getGeneralComplaint: 401 logout');
    } else {
      debugPrint(
          '📋 [RECLAMAÇÃO] getGeneralComplaint: failed body=${response.body}');
      result = 'failed';
    }
  } catch (e, stack) {
    debugPrint('📋 [RECLAMAÇÃO] getGeneralComplaint: exception=$e');
    debugPrint('📋 [RECLAMAÇÃO] getGeneralComplaint: stack=$stack');
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    } else {
      result = 'failed';
    }
  }
  return result;
}

makeGeneralComplaint(complaintDesc, [String? complaintTitleId]) async {
  dynamic result;
  const endpoint = 'api/v1/common/make-complaint';
  final fullUrl = '$url$endpoint';
  try {
    // Se não tiver complaintTitleId, usar o da lista ou null
    String? titleId = complaintTitleId ??
        (generalComplaintList.isNotEmpty &&
                complaintType < generalComplaintList.length
            ? generalComplaintList[complaintType]['id'].toString()
            : null);

    // Se o ID começar com 'default_', não enviar (opção padrão)
    if (titleId != null && titleId.startsWith('default_')) {
      titleId = null;
    }

    // Backend exige complaint_title_id obrigatório - não chamar API sem ele
    if (titleId == null || titleId.isEmpty) {
      debugPrint(
          '📋 [RECLAMAÇÃO] makeGeneralComplaint: abortando - complaint_title_id obrigatório');
      return 'failed';
    }

    Map<String, dynamic> body = {
      'description': complaintDesc,
      'complaint_title_id': titleId,
    };

    debugPrint('📋 [RECLAMAÇÃO] makeGeneralComplaint: POST $fullUrl');
    debugPrint('📋 [RECLAMAÇÃO] makeGeneralComplaint: body=$body');

    var response = await http.post(
      Uri.parse(fullUrl),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    debugPrint(
        '📋 [RECLAMAÇÃO] makeGeneralComplaint: status=${response.statusCode} body=${response.body}');

    if (response.statusCode == 200) {
      result = 'success';
      debugPrint('📋 [RECLAMAÇÃO] makeGeneralComplaint: sucesso');
    } else if (response.statusCode == 401) {
      result = 'logout';
      debugPrint('📋 [RECLAMAÇÃO] makeGeneralComplaint: 401 logout');
    } else {
      result = 'failed';
      debugPrint(
          '📋 [RECLAMAÇÃO] makeGeneralComplaint: falha backend status=${response.statusCode}');
    }
  } catch (e, stack) {
    debugPrint('📋 [RECLAMAÇÃO] makeGeneralComplaint: exception=$e');
    debugPrint('📋 [RECLAMAÇÃO] makeGeneralComplaint: stack=$stack');
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    } else {
      result = 'failed';
    }
  }
  return result;
}

makeRequestComplaint() async {
  dynamic result;
  try {
    var response = await http.post(
      Uri.parse('${url}api/v1/common/make-complaint'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'complaint_title_id': generalComplaintList[complaintType]['id'],
        'description': complaintDesc,
        'request_id': myHistory[selectedHistory]['id'],
      }),
    );
    if (response.statusCode == 200) {
      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failed';
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

//requestStream
StreamSubscription<DatabaseEvent>? requestStreamStart;
StreamSubscription<DatabaseEvent>? requestStreamEnd;
bool userCancelled = false;

/// True quando o evento request-meta (motorista recusou) disparou; força próxima resposta a mostrar "procurando".
bool userRequestDriverJustRejected = false;

streamRequest() {
  // Na web, não iniciar streams do Firebase Database (pode causar travamento)
  if (kIsWeb) {
    debugPrint('🌐 Web: Pulando streamRequest (não suportado)');
    return;
  }

  requestStreamEnd?.cancel();
  requestStreamStart?.cancel();
  rideStreamUpdate?.cancel();
  rideStreamStart?.cancel();
  requestStreamStart = null;
  requestStreamEnd = null;
  rideStreamUpdate = null;
  rideStreamStart = null;

  requestStreamStart = FirebaseDatabase.instance
      .ref('request-meta')
      .child(userRequestData['id'])
      .onChildRemoved
      .handleError((onError) {
    requestStreamStart?.cancel();
  }).listen((event) async {
    debugPrint(
        '🔴 [MOTORISTA RECUSOU] request-meta onChildRemoved disparado (request_id=${userRequestData['id']})');
    debugPrint(
        '🔴 [MOTORISTA RECUSOU] Setando userRequestDriverJustRejected = true antes de getUserDetails()');
    userRequestDriverJustRejected = true;
    await getUserDetails();
    requestStreamEnd?.cancel();
    requestStreamStart?.cancel();
    valueNotifierBook.incrementNotifier();
  });
}

StreamSubscription<DatabaseEvent>? rideStreamStart;

StreamSubscription<DatabaseEvent>? rideStreamUpdate;

streamRide() {
  // Na web, não iniciar streams do Firebase Database (pode causar travamento)
  if (kIsWeb) {
    debugPrint('🌐 Web: Pulando streamRide (não suportado)');
    return;
  }

  requestStreamEnd?.cancel();
  requestStreamStart?.cancel();
  rideStreamUpdate?.cancel();
  rideStreamStart?.cancel();
  requestStreamStart = null;
  requestStreamEnd = null;
  rideStreamUpdate = null;
  rideStreamStart = null;
  rideStreamUpdate = FirebaseDatabase.instance
      .ref('requests/${userRequestData['id']}')
      .onChildChanged
      .handleError((onError) {
    rideStreamUpdate?.cancel();
  }).listen((DatabaseEvent event) async {
    if (event.snapshot.key.toString() == 'trip_start' ||
        event.snapshot.key.toString() == 'trip_arrived' ||
        event.snapshot.key.toString() == 'is_completed' ||
        event.snapshot.key.toString() == 'modified_by_driver') {
      getUserDetails();
    } else if (event.snapshot.key.toString() == 'message_by_driver') {
      getCurrentMessages();
    } else if (event.snapshot.key.toString() == 'cancelled_by_driver') {
      requestCancelledByDriver = true;
      getUserDetails();
    }
  });

  rideStreamStart = FirebaseDatabase.instance
      .ref('requests/${userRequestData['id']}')
      .onChildAdded
      .handleError((onError) {
    rideStreamStart?.cancel();
  }).listen((DatabaseEvent event) async {
    if (event.snapshot.key.toString() == 'message_by_driver') {
      getCurrentMessages();
    } else if (event.snapshot.key.toString() == 'cancelled_by_driver') {
      requestCancelledByDriver = true;
      getUserDetails();
    } else if (event.snapshot.key.toString() == 'modified_by_driver') {
      getUserDetails();
    }
  });
}

userDelete() async {
  dynamic result;
  try {
    var response = await http.post(
      Uri.parse('${url}api/v1/user/delete-user-account'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      pref.remove('Bearer');

      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
    }
  } catch (e) {
    if (e is SocketException) {
      result = 'no internet';
      internet = false;
    }
  }
  return result;
}

//request notification
List notificationHistory = [];
Map<String, dynamic> notificationHistoryPage = {};

getnotificationHistory() async {
  dynamic result;

  try {
    var response = await http.get(
      Uri.parse('${url}api/v1/notifications/get-notification'),
      headers: {'Authorization': 'Bearer ${bearerToken[0].token}'},
    );
    if (response.statusCode == 200) {
      notificationHistory = jsonDecode(response.body)['data'];
      notificationHistoryPage = jsonDecode(response.body)['meta'];
      result = 'success';
      valueNotifierHome.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
      valueNotifierHome.incrementNotifier();
    }
  } catch (e) {
    if (e is SocketException) {
      result = 'no internet';

      internet = false;
      valueNotifierHome.incrementNotifier();
    }
  }
  return result;
}

getNotificationPages(id) async {
  dynamic result;

  try {
    var response = await http.get(
      Uri.parse('${url}api/v1/notifications/get-notification?$id'),
      headers: {'Authorization': 'Bearer ${bearerToken[0].token}'},
    );
    if (response.statusCode == 200) {
      List list = jsonDecode(response.body)['data'];
      // ignore: avoid_function_literals_in_foreach_calls
      list.forEach((element) {
        notificationHistory.add(element);
      });
      notificationHistoryPage = jsonDecode(response.body)['meta'];
      result = 'success';
      valueNotifierHome.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
      valueNotifierHome.incrementNotifier();
    }
  } catch (e) {
    if (e is SocketException) {
      result = 'no internet';

      internet = false;
      valueNotifierHome.incrementNotifier();
    }
  }
  return result;
}

//delete notification
deleteNotification(id) async {
  dynamic result;

  try {
    var response = await http.get(
      Uri.parse('${url}api/v1/notifications/delete-notification/$id'),
      headers: {'Authorization': 'Bearer ${bearerToken[0].token}'},
    );
    if (response.statusCode == 200) {
      result = 'success';
      valueNotifierHome.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
      valueNotifierHome.incrementNotifier();
    }
  } catch (e) {
    if (e is SocketException) {
      result = 'no internet';

      internet = false;
      valueNotifierHome.incrementNotifier();
    }
  }
  return result;
}

sharewalletfun({mobile, role, amount}) async {
  dynamic result;
  try {
    var response = await http.post(
      Uri.parse('${url}api/v1/payment/wallet/transfer-money-from-wallet'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${bearerToken[0].token}',
      },
      body: jsonEncode({'mobile': mobile, 'role': role, 'amount': amount}),
    );
    if (response.statusCode == 200) {
      if (jsonDecode(response.body)['success'] == true) {
        result = 'success';
      } else {
        debugPrint(response.body);
        result = 'failed';
      }
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = jsonDecode(response.body)['message'];
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

sendOTPtoEmail(String email) async {
  dynamic result;
  try {
    var response = await http.post(
      Uri.parse('${url}api/v1/send-mail-otp'),
      body: {'email': email},
    );
    if (response.statusCode == 200) {
      var jsonVal = jsonDecode(response.body);
      if (jsonVal['success'] == true) {
        result = 'success';
      } else {
        // Exibir mensagem original do backend (ex: email_exists)
        serverErrorMessage = jsonVal['message']?.toString() ?? response.body;
        result = serverErrorMessage.isNotEmpty ? serverErrorMessage : 'failed';
        debugPrint(
            '❌ sendOTPtoEmail: Servidor retornou sucesso=false: $result');
      }
    } else {
      serverErrorMessage = extractErrorMessage(response);
      result = serverErrorMessage.isNotEmpty ? serverErrorMessage : 'failed';
    }
    return result;
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
    return 'failed';
  }
}

emailVerify(String email, otpNumber) async {
  dynamic val;
  try {
    var response = await http.post(
      Uri.parse('${url}api/v1/validate-email-otp'),
      body: {"email": email, "otp": otpNumber},
    );
    if (response.statusCode == 200) {
      if (jsonDecode(response.body)['success'] == true) {
        val = 'success';
      } else {
        debugPrint(response.body);
        val = 'failed';
      }
    }
    return val;
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

paymentMethod(payment) async {
  dynamic result;
  try {
    var response = await http.post(
      Uri.parse('${url}api/v1/request/user/payment-method'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'request_id': userRequestData['id'],
        'payment_opt': (payment == 'card')
            ? 0
            : (payment == 'cash')
                ? 1
                : (payment == 'wallet')
                    ? 2
                    : 4,
      }),
    );
    if (response.statusCode == 200) {
      FirebaseDatabase.instance
          .ref('requests')
          .child(userRequestData['id'])
          .update({'modified_by_user': ServerValue.timestamp});
      await getUserDetails();
      result = 'success';
      valueNotifierBook.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failed';
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
  return result;
}

String isemailmodule = '1';
getOwnermodule() async {
  dynamic res;
  try {
    final response = await http.get(Uri.parse('${url}api/v1/common/modules'));

    if (response.statusCode == 200) {
      isemailmodule = jsonDecode(response.body)['enable_email_otp'];

      res = 'success';
    } else {
      debugPrint(response.body);
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      res = 'no internet';
    }
  }

  return res;
}
