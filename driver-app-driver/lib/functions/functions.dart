import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart' as geolocs;
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../pages/NavigatorPages/editprofile.dart';
import '../pages/NavigatorPages/fleetdocuments.dart';
import '../pages/NavigatorPages/history.dart';
import '../pages/NavigatorPages/historydetails.dart';
import '../pages/login/carinformation.dart';
import '../pages/login/login.dart';
import '../pages/login/namepage.dart';
import '../pages/login/ownerregister.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../pages/login/uploaddocument.dart';
import '../pages/onTripPage/digitalsignature.dart';
import '../pages/onTripPage/droplocation.dart';
import '../pages/onTripPage/invoice.dart';
import '../pages/onTripPage/map_page.dart';
import '../pages/onTripPage/review_page.dart';
import '../pages/onTripPage/rides.dart';
import '../styles/styles.dart';
import 'geohash.dart';

// Firebase Database URL
const String firebaseDatabaseURL =
    'https://goin-7372e-default-rtdb.firebaseio.com';

// Helper function para obter instância do Firebase Database com URL configurada
FirebaseDatabase getFirebaseDatabase() {
  try {
    return FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: firebaseDatabaseURL,
    );
  } catch (e) {
    debugPrint('🔥 [FIREBASE] Erro ao obter instância do Database: $e');
    // Fallback para instância padrão
    return FirebaseDatabase.instance;
  }
}

// Helper function para tratar erros da API
void logApiError(String functionName, int statusCode, String responseBody) {
  debugPrint('🌐 [API] $functionName - ERRO: Status Code $statusCode');
  debugPrint('🌐 [API] $functionName - Response body: $responseBody');

  // Tratamento específico para erros 500 (erro do servidor)
  if (statusCode == 500) {
    debugPrint(
        '🌐 [API] $functionName - ⚠️ ERRO 500: Erro interno do servidor!');
    try {
      final errorJson = jsonDecode(responseBody);
      if (errorJson.containsKey('message')) {
        debugPrint(
            '🌐 [API] $functionName - Mensagem de erro: ${errorJson['message']}');
      }
      if (errorJson.containsKey('debug')) {
        debugPrint(
            '🌐 [API] $functionName - Debug do servidor: ${errorJson['debug']}');
        final debugInfo = errorJson['debug'];
        if (debugInfo is Map) {
          if (debugInfo.containsKey('file')) {
            debugPrint(
                '🌐 [API] $functionName - Arquivo com erro: ${debugInfo['file']}');
          }
          if (debugInfo.containsKey('line')) {
            debugPrint(
                '🌐 [API] $functionName - Linha do erro: ${debugInfo['line']}');
          }
          if (debugInfo.containsKey('class')) {
            debugPrint(
                '🌐 [API] $functionName - Classe do erro: ${debugInfo['class']}');
          }
          if (debugInfo.containsKey('trace')) {
            debugPrint(
                '🌐 [API] $functionName - Stack trace disponível (verifique logs completos)');
          }
        }
      }
      if (errorJson.containsKey('status_code')) {
        debugPrint(
            '🌐 [API] $functionName - Status code do servidor: ${errorJson['status_code']}');
      }
    } catch (e) {
      debugPrint(
          '🌐 [API] $functionName - Não foi possível decodificar erro do servidor: $e');
    }
    debugPrint(
        '🌐 [API] $functionName - ⚠️ Este é um erro do servidor, não do app!');
    debugPrint('🌐 [API] $functionName - ⚠️ Possíveis causas:');
    debugPrint(
        '🌐 [API] $functionName -   1. Versão do PHP incompatível (erro de sintaxe)');
    debugPrint(
        '🌐 [API] $functionName -   2. Dependências desatualizadas no servidor');
    debugPrint(
        '🌐 [API] $functionName -   3. Erro de configuração do servidor');
    debugPrint(
        '🌐 [API] $functionName - ⚠️ Verifique os logs do servidor para mais detalhes.');
  } else if (statusCode == 401) {
    debugPrint('🌐 [API] $functionName - ⚠️ ERRO 401: Não autorizado!');
    debugPrint(
        '🌐 [API] $functionName - ⚠️ Token de autenticação pode estar inválido ou expirado.');
  } else if (statusCode == 404) {
    debugPrint(
        '🌐 [API] $functionName - ⚠️ ERRO 404: Endpoint não encontrado!');
    debugPrint(
        '🌐 [API] $functionName - ⚠️ Verifique se a URL da API está correta.');
  } else if (statusCode == 422) {
    debugPrint('🌐 [API] $functionName - ⚠️ ERRO 422: Erro de validação!');
    try {
      final errorJson = jsonDecode(responseBody);
      if (errorJson.containsKey('errors')) {
        debugPrint(
            '🌐 [API] $functionName - Erros de validação: ${errorJson['errors']}');
      }
    } catch (e) {
      debugPrint(
          '🌐 [API] $functionName - Não foi possível decodificar erros de validação: $e');
    }
  }
}

/// Formata o objeto [errors] da resposta 422 (validação) em uma mensagem legível.
/// Ex: {"postal_code": ["The postal code may not be greater than 6 characters."]}
/// -> "CEP: The postal code may not be greater than 6 characters."
String formatValidationErrors(dynamic errors, {String fallbackMessage = 'Os dados enviados são inválidos.'}) {
  if (errors == null) return fallbackMessage;
  if (errors is! Map) return fallbackMessage;
  final map = Map<String, dynamic>.from(errors);
  if (map.isEmpty) return fallbackMessage;

  final fieldLabels = <String, String>{
    'postal_code': 'CEP',
    'email': 'E-mail',
    'mobile': 'Celular',
    'document': 'CPF',
    'birth_date': 'Data de nascimento',
    'address': 'Endereço',
    'address_number': 'Número',
    'complement': 'Complemento',
    'neighborhood': 'Bairro',
    'city': 'Cidade',
    'state': 'Estado',
    'gender': 'Sexo',
    'passenger_preference': 'Preferência de atendimento',
    'name': 'Nome',
    'referral_code': 'Código de indicação',
  };

  final parts = <String>[];
  for (final entry in map.entries) {
    final key = entry.key.toString();
    final label = fieldLabels[key] ?? key;
    final value = entry.value;
    List<String> messages = [];
    if (value is List) {
      for (final e in value) {
        if (e != null) messages.add(e.toString().trim());
      }
    } else if (value != null) {
      messages.add(value.toString().trim());
    }
    for (final msg in messages) {
      if (msg.isNotEmpty) parts.add('$label: $msg');
    }
  }
  return parts.isEmpty ? fallbackMessage : parts.join(' ');
}

//languages code
dynamic phcode = 0; // Inicializado com 0 para evitar null
dynamic platform;
dynamic pref;
String isActive = '';
double duration = 0.0;
AudioCache audioPlayer = AudioCache();
AudioPlayer audioPlayers = AudioPlayer();
String audio = 'audio/notification_sound.mp3';
bool internet = true;
dynamic centerCheck;

String ischeckownerordriver = '';
String transportType = '';

//base url
String url =
    'https://driver.omny.app.br/'; //add '/' at the end of the url as 'https://url.com/'
String mapkey = 'AIzaSyDIFOaDalHwTa--63nbVUVVM13X3EWTI6Q';
String mapStyle = '';

getDetailsOfDevice() async {
  var connectivityResult = await (Connectivity().checkConnectivity());
  if (connectivityResult == ConnectivityResult.none) {
    internet = false;
  } else {
    internet = true;
  }
  try {
    pref = await SharedPreferences.getInstance();

    // Carregar idioma imediatamente ao inicializar SharedPreferences
    if (pref.containsKey('choosenLanguage')) {
      choosenLanguage = pref.getString('choosenLanguage') ?? 'pt_BR';
      languageDirection = pref.getString('languageDirection') ?? 'ltr';
      if (choosenLanguage.isEmpty) {
        choosenLanguage = 'pt_BR';
        languageDirection = 'ltr';
        pref.setString('choosenLanguage', choosenLanguage);
        pref.setString('languageDirection', languageDirection);
      }
    } else {
      // Define pt_BR como padrão se não houver idioma salvo
      choosenLanguage = 'pt_BR';
      languageDirection = 'ltr';
      pref.setString('choosenLanguage', choosenLanguage);
      pref.setString('languageDirection', languageDirection);
      debugPrint(
          '🌐 [INIT] Idioma padrão definido: pt_BR em getDetailsOfDevice');
    }

    if (pref.containsKey('isDarktheme')) {
      isDarkTheme = pref.getBool('isDarktheme');
    }
    darktheme();
  } catch (e) {
    debugPrint(e.toString());
  }
}

//validate email already exist

validateEmail(email) async {
  dynamic result;
  try {
    var response = await http.post(
      Uri.parse('${url}api/v1/driver/validate-mobile'),
      body: {
        'email': email,
        "role": userDetails.isNotEmpty
            ? userDetails['role'].toString()
            : ischeckownerordriver,
      },
    );
    if (response.statusCode == 200) {
      if (jsonDecode(response.body)['success'] == true) {
        result = 'success';
      } else {
        debugPrint(response.body);
        result = 'failed';
      }
    } else if (response.statusCode == 422) {
      debugPrint(response.body);
      try {
        final body = jsonDecode(response.body);
        result = formatValidationErrors(
          body['errors'],
          fallbackMessage: body['message']?.toString() ?? 'Os dados enviados são inválidos.',
        );
      } catch (_) {
        result = 'Os dados enviados são inválidos.';
      }
    } else {
      debugPrint(response.body);
      try {
        result = jsonDecode(response.body)['message'] ?? 'Erro na validação.';
      } catch (_) {
        result = 'Erro na validação.';
      }
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
      headers: {'Authorization': 'Bearer ${bearerToken[0].token}'},
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

//language code
var choosenLanguage = 'pt_BR'; // Idioma padrão: Português do Brasil
var languageDirection = 'ltr';

List languagesCode = [
  {'name': 'Portuguese (Brazil)', 'code': 'pt_BR'},
  {'name': 'English (US)', 'code': 'en'},
  {
    'name': 'Portuguese (Portugal)',
    'code': 'pt', //pt-PT
  },
  {'name': 'Spanish', 'code': 'es'},
];

// Cadastro: CPF, data nascimento, endereço (preenchido pelo CEP)
String userCpf = '';
String userBirthDate = '';
String userCep = '';
String userAddress = '';
String userNumber = '';
String userComplement = '';
String userNeighborhood = '';
String userCity = '';
String userState = '';
String userGender = ''; // male, female, prefer_not_say
String userPassengerPreference = 'both'; // male, female, both
String loginReferralCode = ''; // código de indicação no login (opcional)

// Opções de gênero (valor enviado à API)
const List<Map<String, String>> genderOptions = [
  {'value': 'male', 'label_pt': 'Masculino'},
  {'value': 'female', 'label_pt': 'Feminino'},
  {'value': 'prefer_not_say', 'label_pt': 'Prefiro não informar'},
];

// Preferência de passageiro (valor enviado à API)
const List<Map<String, String>> passengerPreferenceOptions = [
  {'value': 'male', 'label_pt': 'Homem'},
  {'value': 'female', 'label_pt': 'Mulher'},
  {'value': 'both', 'label_pt': 'Ambos'},
];

// Estados brasileiros (UF)
const List<Map<String, String>> brazilianStates = [
  {'uf': 'AC', 'name': 'Acre'},
  {'uf': 'AL', 'name': 'Alagoas'},
  {'uf': 'AP', 'name': 'Amapá'},
  {'uf': 'AM', 'name': 'Amazonas'},
  {'uf': 'BA', 'name': 'Bahia'},
  {'uf': 'CE', 'name': 'Ceará'},
  {'uf': 'DF', 'name': 'Distrito Federal'},
  {'uf': 'ES', 'name': 'Espírito Santo'},
  {'uf': 'GO', 'name': 'Goiás'},
  {'uf': 'MA', 'name': 'Maranhão'},
  {'uf': 'MT', 'name': 'Mato Grosso'},
  {'uf': 'MS', 'name': 'Mato Grosso do Sul'},
  {'uf': 'MG', 'name': 'Minas Gerais'},
  {'uf': 'PA', 'name': 'Pará'},
  {'uf': 'PB', 'name': 'Paraíba'},
  {'uf': 'PR', 'name': 'Paraná'},
  {'uf': 'PE', 'name': 'Pernambuco'},
  {'uf': 'PI', 'name': 'Piauí'},
  {'uf': 'RJ', 'name': 'Rio de Janeiro'},
  {'uf': 'RN', 'name': 'Rio Grande do Norte'},
  {'uf': 'RS', 'name': 'Rio Grande do Sul'},
  {'uf': 'RO', 'name': 'Rondônia'},
  {'uf': 'RR', 'name': 'Roraima'},
  {'uf': 'SC', 'name': 'Santa Catarina'},
  {'uf': 'SP', 'name': 'São Paulo'},
  {'uf': 'SE', 'name': 'Sergipe'},
  {'uf': 'TO', 'name': 'Tocantins'},
];

/// Busca endereço pela API pública ViaCEP (Brasil).
/// Retorna map com logradouro, bairro, localidade, uf ou null se erro.
Future<Map<String, String>?> fetchCep(String cep) async {
  final digits = cep.replaceAll(RegExp(r'[^\d]'), '');
  if (digits.length != 8) return null;
  try {
    final response = await http.get(
      Uri.parse('https://viacep.com.br/ws/$digits/json/'),
    );
    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body);
    if (data is! Map || data['erro'] == true) return null;
    return {
      'logradouro': (data['logradouro'] ?? '').toString(),
      'bairro': (data['bairro'] ?? '').toString(),
      'localidade': (data['localidade'] ?? '').toString(),
      'uf': (data['uf'] ?? '').toString(),
    };
  } catch (e) {
    debugPrint('🌐 [ViaCEP] Erro: $e');
    return null;
  }
}

//upload docs

uploadDocs() async {
  dynamic result;
  try {
    final apiUrl = '${url}api/v1/driver/upload/documents';
    debugPrint(
        '📄📄📄 [API] uploadDocs - ========== INÍCIO DA CHAMADA ==========');
    debugPrint('📄 [API] uploadDocs - URL: $apiUrl');
    debugPrint('📄 [API] uploadDocs - Método: POST');
    debugPrint('📄 [API] uploadDocs - document_id: $docsId');
    debugPrint('📄 [API] uploadDocs - choosenDocs: $choosenDocs');
    debugPrint('📄 [API] uploadDocs - imageFile: $imageFile');

    var response = http.MultipartRequest(
      'POST',
      Uri.parse(apiUrl),
    );

    final bearerTokenValue =
        bearerToken.isNotEmpty ? bearerToken[0].token : 'N/A';
    debugPrint(
        '📄 [API] uploadDocs - Bearer Token: ${bearerTokenValue.length > 20 ? bearerTokenValue.substring(0, 20) + '...' : bearerTokenValue}');

    response.headers.addAll({
      'Authorization': 'Bearer ${bearerToken[0].token}',
    });
    debugPrint('📄 [API] uploadDocs - Headers: ${response.headers}');

    if (imageFile != null) {
      response.files.add(
        await http.MultipartFile.fromPath('document', imageFile),
      );
      debugPrint(
          '📄 [API] uploadDocs - Arquivo de documento anexado: $imageFile');
    } else {
      debugPrint('📄 [API] uploadDocs - ⚠️ AVISO: imageFile é null!');
    }

    if (documentsNeeded.isNotEmpty && choosenDocs < documentsNeeded.length) {
      if (documentsNeeded[choosenDocs]['has_expiry_date'] == true) {
        response.fields['expiry_date'] = expDate.toString().substring(0, 19);
        debugPrint(
            '📄 [API] uploadDocs - expiry_date: ${expDate.toString().substring(0, 19)}');
      }

      if (documentsNeeded[choosenDocs]['has_identify_number'] == true) {
        response.fields['identify_number'] = docIdNumber;
        debugPrint('📄 [API] uploadDocs - identify_number: $docIdNumber');
      }
    } else {
      debugPrint(
          '📄 [API] uploadDocs - ⚠️ AVISO: documentsNeeded vazio ou choosenDocs inválido');
    }

    response.fields['document_id'] = docsId.toString();

    debugPrint(
        '📄📄📄 [API] uploadDocs - ========== BODY DA REQUISIÇÃO ==========');
    debugPrint('📄 [API] uploadDocs - Fields: ${response.fields}');
    debugPrint('📄 [API] uploadDocs - Files count: ${response.files.length}');
    debugPrint('📄📄📄 [API] uploadDocs - ========== FIM DO BODY ==========');

    debugPrint(
        '📄📄📄 [API] uploadDocs - ========== ENVIANDO REQUISIÇÃO ==========');
    var request = await response.send();

    var respon = await http.Response.fromStream(request);

    debugPrint(
        '📄📄📄 [API] uploadDocs - ========== RESPOSTA RECEBIDA ==========');
    debugPrint('📄 [API] uploadDocs - Status Code: ${request.statusCode}');
    debugPrint('📄 [API] uploadDocs - Response Headers: ${respon.headers}');
    debugPrint(
        '📄 [API] uploadDocs - Response Body (primeiros 500 chars): ${respon.body.length > 500 ? respon.body.substring(0, 500) + '...' : respon.body}');
    if (respon.body.length > 500) {
      debugPrint(
          '📄 [API] uploadDocs - Response Body completo (${respon.body.length} chars)');
    }

    final val = jsonDecode(respon.body);
    if (request.statusCode == 200) {
      result = val['message'];
      debugPrint('📄 [API] uploadDocs - ✅ Sucesso: $result');
    } else if (request.statusCode == 422) {
      debugPrint('📄 [API] uploadDocs - ❌ ERRO 422 (Validation Error)');
      debugPrint('📄 [API] uploadDocs - Response completa: ${respon.body}');
      var error = jsonDecode(respon.body)['errors'];
      result = error[error.keys.toList()[0]]
          .toString()
          .replaceAll('[', '')
          .replaceAll(']', '')
          .toString();
      debugPrint('📄 [API] uploadDocs - Erro extraído: $result');
    } else if (request.statusCode == 401) {
      debugPrint('📄 [API] uploadDocs - ❌ ERRO 401 (Unauthorized)');
      result = 'logout';
    } else {
      debugPrint('📄 [API] uploadDocs - ❌ ERRO ${request.statusCode}');
      debugPrint('📄 [API] uploadDocs - Response: ${respon.body}');
      result = val['message'];
    }
  } catch (e, stackTrace) {
    debugPrint('📄📄📄 [API] uploadDocs - ❌❌❌ EXCEÇÃO: $e');
    debugPrint('📄 [API] uploadDocs - Tipo: ${e.runtimeType}');
    debugPrint('📄 [API] uploadDocs - Stack trace: $stackTrace');
    if (e is SocketException) {
      result = 'no internet';
      internet = false;
      debugPrint('📄 [API] uploadDocs - SocketException: Sem internet');
    } else {
      result = 'Erro ao enviar documento: $e';
    }
  }
  debugPrint('📄📄📄 [API] uploadDocs - Resultado final: $result');
  debugPrint('📄📄📄 [API] uploadDocs - ========== FIM DA CHAMADA ==========');
  return result;
}

uploadFleetDocs(fleetid) async {
  dynamic result;
  try {
    var response = http.MultipartRequest(
      'POST',
      Uri.parse('${url}api/v1/driver/upload/documents'),
    );
    response.headers.addAll({
      'Authorization': 'Bearer ${bearerToken[0].token}',
    });

    response.files.add(
      await http.MultipartFile.fromPath('document', fleetimageFile),
    );

    if (fleetdocumentsNeeded[fleetchoosenDocs]['has_expiry_date'] == true) {
      response.fields['expiry_date'] = fleetexpDate.toString().substring(0, 19);
    }
    if (fleetdocumentsNeeded[fleetchoosenDocs]['has_identify_number'] == true) {
      response.fields['identify_number'] = fleetdocIdNumber;
    }

    response.fields['fleet_id'] = fleetid.toString();

    response.fields['document_id'] = fleetdocsId.toString();
    var request = await response.send();
    var respon = await http.Response.fromStream(request);

    final val = jsonDecode(respon.body);

    if (request.statusCode == 200) {
      result = val['message'];
    } else if (request.statusCode == 422) {
      debugPrint(respon.body);
      var error = jsonDecode(respon.body)['errors'];
      result = error[error.keys.toList()[0]]
          .toString()
          .replaceAll('[', '')
          .replaceAll(']', '')
          .toString();
    } else if (request.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(respon.body);
      result = val['message'];
    }
  } catch (e) {
    if (e is SocketException) {
      result = 'no internet';
      internet = false;
    }
  }
  return result;
}

//getting country code

List countries = [];
getCountryCode() async {
  dynamic result;
  try {
    debugPrint('🌐 [API] getCountryCode - Buscando códigos de país');
    final response = await http.get(Uri.parse('${url}api/v1/countries'));

    debugPrint('🌐 [API] getCountryCode - Status Code: ${response.statusCode}');
    if (response.statusCode == 200) {
      countries = jsonDecode(response.body)['data'] ?? [];
      debugPrint(
          '🌐 [API] getCountryCode - Países recebidos: ${countries.length}');

      if (countries.isNotEmpty) {
        // Forçar Brasil como padrão (DDI +55)
        final brazilIndex = countries.indexWhere((c) {
          final code = c['dial_code']?.toString().replaceAll(' ', '') ?? '';
          final iso = c['iso2']?.toString().toUpperCase() ?? '';
          return code == '+55' || iso == 'BR';
        });
        phcode = (brazilIndex >= 0) ? brazilIndex : 0;
        debugPrint('🌐 [API] getCountryCode - Brasil forçado como padrão, phcode: $phcode');
      } else {
        phcode = 0;
        debugPrint('🌐 [API] getCountryCode - Lista vazia, phcode = 0');
      }

      // Garantir que phcode não seja null
      if (phcode == null || phcode < 0 || phcode >= countries.length) {
        phcode = 0;
        debugPrint('🌐 [API] getCountryCode - phcode ajustado para 0');
      }

      result = 'success';
    } else {
      debugPrint('🌐 [API] getCountryCode - ERRO ${response.statusCode}');
      debugPrint('🌐 [API] getCountryCode - Response: ${response.body}');
      // Inicializar com valores padrão em caso de erro
      phcode = 0;
      result = 'error';
    }
  } catch (e) {
    debugPrint('🌐 [API] getCountryCode - EXCEÇÃO: $e');
    debugPrint('🌐 [API] getCountryCode - Tipo: ${e.runtimeType}');
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
      debugPrint('🌐 [API] getCountryCode - SocketException: Sem internet');
    }
    // Inicializar com valores padrão em caso de exceção
    phcode = 0;
  }
  debugPrint(
      '🌐 [API] getCountryCode - Resultado final: $result, phcode: $phcode');
  return result;
}

//login firebase

String userUid = '';
var verId = '';
int? resendTokenId;
bool phoneAuthCheck = false;
dynamic credentials;

phoneAuth(String phone) async {
  try {
    debugPrint('🔥 [FIREBASE] phoneAuth - Iniciando autenticação por telefone');
    debugPrint('🔥 [FIREBASE] phoneAuth - Telefone: $phone');
    debugPrint('🔥 [FIREBASE] phoneAuth - resendTokenId: $resendTokenId');
    credentials = null;
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Não usar auto-complete: exigir que o usuário digite o código SMS
        debugPrint('🔥 [FIREBASE] phoneAuth - verificationCompleted (ignorado: exigir código manual)');
      },
      forceResendingToken: resendTokenId,
      verificationFailed: (FirebaseAuthException e) {
        debugPrint('🔥 [FIREBASE] phoneAuth - verificationFailed: ${e.code}');
        debugPrint(
            '🔥 [FIREBASE] phoneAuth - verificationFailed: ${e.message}');
        if (e.code == 'invalid-phone-number') {
          debugPrint(
              '🔥 [FIREBASE] phoneAuth - The provided phone number is not valid.');
        }
      },
      codeSent: (String verificationId, int? resendToken) async {
        debugPrint('🔥 [FIREBASE] phoneAuth - codeSent: Código enviado');
        debugPrint('🔥 [FIREBASE] phoneAuth - verificationId: $verificationId');
        verId = verificationId;
        resendTokenId = resendToken;
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        debugPrint(
            '🔥 [FIREBASE] phoneAuth - codeAutoRetrievalTimeout: $verificationId');
      },
    );
    debugPrint('🔥 [FIREBASE] phoneAuth - Finalizado com sucesso');
  } catch (e) {
    debugPrint('🔥 [FIREBASE] phoneAuth - ERRO: $e');
    debugPrint('🔥 [FIREBASE] phoneAuth - Tipo do erro: ${e.runtimeType}');
    if (e is SocketException) {
      internet = false;
      debugPrint('🔥 [FIREBASE] phoneAuth - SocketException: Sem internet');
    }
  }
}

darktheme() async {
  if (isDarkTheme == true) {
    page = Colors.black;
    backgroundColor = Colors.black;
    topBar = Colors.black;
    textColor = Colors.white;
    buttonColor = theme; // Roxo original
    loaderColor = theme; // Roxo original
    hintColor = Colors.white.withOpacity(0.5);
    borderLines = const Color.fromARGB(255, 154, 3, 233)
        .withOpacity(0.3); // Roxo transparente
    backIcon = Colors.white;
    underline = theme.withOpacity(0.5); // Roxo transparente
    inputUnderline = theme.withOpacity(0.3); // Roxo transparente
    inputfocusedUnderline = theme; // Roxo
  } else {
    page = Colors.white;
    backgroundColor = const Color(0xffe5e5e5);
    topBar = const Color(0xffF8F8F8);
    textColor = Colors.black;
    buttonColor = theme;
    loaderColor = theme;
    hintColor = const Color(0xff12121D).withOpacity(0.3);
    borderLines = const Color(0xffE5E5E5);
    backIcon = const Color(0xff12121D);
    underline = const Color(0xff12121D).withOpacity(0.3);
    inputUnderline = const Color(0xff12121D).withOpacity(0.3);
    inputfocusedUnderline = const Color(0xff12121D);
  }
  if (isDarkTheme == true) {
    rootBundle.loadString('assets/dark.json').then((value) {
      mapStyle = value;
    });
  } else {
    rootBundle.loadString('assets/map_style.json').then((value) {
      mapStyle = value;
    });
  }
  if (isDarkTheme == true) {
    await rootBundle.loadString('assets/dark.json').then((value) {
      mapStyle = value;
    });
  } else {
    await rootBundle.loadString('assets/map_style.json').then((value) {
      mapStyle = value;
    });
  }
  valueNotifierHome.incrementNotifier();
}

//get local bearer token

String lastNotification = '';

getLocalData() async {
  dynamic result;
  bearerToken.clear;
  var connectivityResult = await (Connectivity().checkConnectivity());
  if (connectivityResult == ConnectivityResult.none) {
    internet = false;
  } else {
    internet = true;
  }
  try {
    if (pref.containsKey('lastNotification')) {
      lastNotification = pref.getString('lastNotification');
    }
    if (pref.containsKey('autoAddress')) {
      var val = pref.getString('autoAddress');
      storedAutoAddress = jsonDecode(val);
    }
    // Idioma já foi carregado em getDetailsOfDevice, apenas verificar se precisa atualizar
    if (pref.containsKey('choosenLanguage')) {
      final savedLanguage = pref.getString('choosenLanguage') ?? 'pt_BR';
      final savedDirection = pref.getString('languageDirection') ?? 'ltr';

      // Só atualizar se for diferente do atual
      if (choosenLanguage != savedLanguage || choosenLanguage.isEmpty) {
        choosenLanguage = savedLanguage.isEmpty ? 'pt_BR' : savedLanguage;
        languageDirection = savedDirection.isEmpty ? 'ltr' : savedDirection;
        debugPrint(
            '🌐 [INIT] Idioma carregado do SharedPreferences: $choosenLanguage');
      }

      // Garantir que não seja null ou vazio
      if (choosenLanguage.isEmpty) {
        choosenLanguage = 'pt_BR';
        languageDirection = 'ltr';
        pref.setString('choosenLanguage', choosenLanguage);
        pref.setString('languageDirection', languageDirection);
        debugPrint('🌐 [INIT] Idioma ajustado para pt_BR (estava vazio)');
      }
    } else {
      // Define pt_BR como padrão se não houver idioma salvo
      choosenLanguage = 'pt_BR';
      languageDirection = 'ltr';
      pref.setString('choosenLanguage', choosenLanguage);
      pref.setString('languageDirection', languageDirection);
      debugPrint('🌐 [INIT] Idioma padrão definido: pt_BR em getLocalData');
    }

    // Garantir que languageDirection não seja null
    if (languageDirection.isEmpty) {
      languageDirection = 'ltr';
      pref.setString('languageDirection', languageDirection);
    }

    debugPrint(
        '🌐 [INIT] Idioma final: $choosenLanguage, Direção: $languageDirection');

    if (choosenLanguage.isNotEmpty) {
      if (pref.containsKey('Bearer')) {
        var tokens = pref.getString('Bearer');
        if (tokens != null) {
          bearerToken.add(BearerClass(type: 'Bearer', token: tokens));

          var responce = await getUserDetails();
          if (responce == true) {
            if (userDetails['role'] != 'owner' && !kIsWeb) {
              platforms.invokeMethod('login');
            }
            result = '3';
          } else {
            result = '2';
          }
        } else {
          result = '2';
        }
      } else {
        result = '2';
      }
    } else {
      result = '1';
    }
    darktheme();
  } catch (e) {
    if (e is SocketException) {
      result = 'no internet';
      internet = false;
    }
  }
  return result;
}

//get service locations

List serviceLocations = [];

getServiceLocation() async {
  dynamic res;

  // Logs detalhados para debug
  debugPrint('📍 [API] getServiceLocation - Iniciando chamada');
  debugPrint('📍 [API] getServiceLocation - url base: $url');

  final apiUrl = '${url}api/v1/servicelocation';
  debugPrint('📍 [API] getServiceLocation - URL completa: $apiUrl');

  try {
    debugPrint('📍 [API] getServiceLocation - Fazendo requisição GET...');
    final response = await http.get(Uri.parse(apiUrl));

    debugPrint('📍 [API] getServiceLocation - Resposta recebida');
    debugPrint(
        '📍 [API] getServiceLocation - Status Code: ${response.statusCode}');
    debugPrint('📍 [API] getServiceLocation - Headers: ${response.headers}');
    debugPrint('📍 [API] getServiceLocation - Body: ${response.body}');

    if (response.statusCode == 200) {
      try {
        final jsonResponse = jsonDecode(response.body);
        debugPrint(
            '📍 [API] getServiceLocation - JSON decodificado com sucesso');
        debugPrint(
            '📍 [API] getServiceLocation - JSON completo: $jsonResponse');

        if (jsonResponse.containsKey('data')) {
          serviceLocations = jsonResponse['data'];
          debugPrint(
              '📍 [API] getServiceLocation - serviceLocations carregado: ${serviceLocations.length} locais encontrados');
          if (serviceLocations.isNotEmpty) {
            debugPrint(
                '📍 [API] getServiceLocation - Primeiro local: ${serviceLocations[0]}');
            debugPrint('📍 [API] getServiceLocation - Todos os locais:');
            for (var i = 0; i < serviceLocations.length; i++) {
              debugPrint(
                  '📍 [API] getServiceLocation -   [$i] ID: ${serviceLocations[i]['id']}, Nome: ${serviceLocations[i]['name']}');
            }
          } else {
            debugPrint(
                '📍 [API] getServiceLocation - AVISO: Lista de locais vazia!');
          }
          res = 'success';
        } else {
          debugPrint(
              '📍 [API] getServiceLocation - ERRO: JSON não contém campo "data"');
          debugPrint(
              '📍 [API] getServiceLocation - Chaves disponíveis: ${jsonResponse.keys}');
          res = 'failed';
        }
      } catch (jsonError) {
        debugPrint(
            '📍 [API] getServiceLocation - ERRO ao decodificar JSON: $jsonError');
        debugPrint(
            '📍 [API] getServiceLocation - Body que causou erro: ${response.body}');
        res = 'failed';
      }
    } else {
      // Usar função helper para tratar erros
      logApiError('getServiceLocation', response.statusCode, response.body);
      res = 'failed';
    }
  } catch (e) {
    debugPrint('📍 [API] getServiceLocation - EXCEÇÃO capturada: $e');
    debugPrint('📍 [API] getServiceLocation - Tipo do erro: ${e.runtimeType}');
    if (e is SocketException) {
      debugPrint(
          '📍 [API] getServiceLocation - SocketException: Sem conexão com internet');
      res = 'no internet';
      internet = false;
    } else {
      res = 'failed';
    }
  }

  debugPrint('📍 [API] getServiceLocation - Resultado final: $res');
  debugPrint(
      '📍 [API] getServiceLocation - serviceLocations.length: ${serviceLocations.length}');

  return res;
}

//get vehicle type

List vehicleType = [];

getvehicleType() async {
  myServiceId =
      userDetails.isNotEmpty ? userDetails['service_location_id'] : myServiceId;
  dynamic res;

  // Logs detalhados para debug
  debugPrint('🚗 [API] getvehicleType - Iniciando chamada');
  debugPrint('🚗 [API] getvehicleType - myServiceId: $myServiceId');
  debugPrint('🚗 [API] getvehicleType - transportType: $transportType');
  debugPrint('🚗 [API] getvehicleType - url base: $url');

  final apiUrl =
      '${url}api/v1/types/$myServiceId?transport_type=$transportType';
  debugPrint('🚗 [API] getvehicleType - URL completa: $apiUrl');

  try {
    debugPrint('🚗 [API] getvehicleType - Fazendo requisição GET...');
    final response = await http.get(
      Uri.parse(apiUrl),
    );

    debugPrint('🚗 [API] getvehicleType - Resposta recebida');
    debugPrint('🚗 [API] getvehicleType - Status Code: ${response.statusCode}');
    debugPrint('🚗 [API] getvehicleType - Headers: ${response.headers}');
    debugPrint('🚗 [API] getvehicleType - Body: ${response.body}');

    if (response.statusCode == 200) {
      try {
        final jsonResponse = jsonDecode(response.body);
        debugPrint('🚗 [API] getvehicleType - JSON decodificado com sucesso');
        debugPrint('🚗 [API] getvehicleType - JSON completo: $jsonResponse');

        if (jsonResponse.containsKey('data')) {
          vehicleType = jsonResponse['data'] ?? [];
          debugPrint(
              '🚗 [API] getvehicleType - vehicleType carregado: ${vehicleType.length} tipos encontrados');
          if (vehicleType.isNotEmpty) {
            debugPrint(
                '🚗 [API] getvehicleType - Primeiro tipo: ${vehicleType[0]}');
          } else {
            debugPrint(
                '🚗 [API] getvehicleType - AVISO: Lista de tipos vazia!');
          }
          res = 'success';
        } else {
          debugPrint(
              '🚗 [API] getvehicleType - ERRO: JSON não contém campo "data"');
          debugPrint(
              '🚗 [API] getvehicleType - Chaves disponíveis: ${jsonResponse.keys}');
          res = 'failed';
        }
      } catch (jsonError) {
        debugPrint(
            '🚗 [API] getvehicleType - ERRO ao decodificar JSON: $jsonError');
        debugPrint(
            '🚗 [API] getvehicleType - Body que causou erro: ${response.body}');
        res = 'failed';
      }
    } else {
      // Usar função helper para tratar erros
      logApiError('getvehicleType', response.statusCode, response.body);
      res = 'failed';
    }
  } catch (e) {
    debugPrint('🚗 [API] getvehicleType - EXCEÇÃO capturada: $e');
    debugPrint('🚗 [API] getvehicleType - Tipo do erro: ${e.runtimeType}');
    if (e is SocketException) {
      debugPrint(
          '🚗 [API] getvehicleType - SocketException: Sem conexão com internet');
      res = 'no internet';
      internet = false;
    } else {
      res = 'failed';
    }
  }

  debugPrint('🚗 [API] getvehicleType - Resultado final: $res');
  debugPrint(
      '🚗 [API] getvehicleType - vehicleType.length: ${vehicleType.length}');

  return res;
}

//get vehicle make

List vehicleMake = [];

// Lista pré-definida de marcas comuns
List<Map<String, dynamic>> getDefaultMakes() {
  return [
    {'id': '1', 'name': 'Chevrolet'},
    {'id': '2', 'name': 'Volkswagen'},
    {'id': '3', 'name': 'Fiat'},
    {'id': '4', 'name': 'Ford'},
    {'id': '5', 'name': 'Toyota'},
    {'id': '6', 'name': 'Honda'},
    {'id': '7', 'name': 'Hyundai'},
    {'id': '8', 'name': 'Renault'},
    {'id': '9', 'name': 'Nissan'},
    {'id': '10', 'name': 'Peugeot'},
    {'id': '11', 'name': 'Citroën'},
    {'id': '12', 'name': 'Jeep'},
    {'id': '13', 'name': 'Mitsubishi'},
    {'id': '14', 'name': 'Suzuki'},
    {'id': '15', 'name': 'Kia'},
    {'id': '16', 'name': 'Chery'},
    {'id': '17', 'name': 'CAOA Chery'},
    {'id': '18', 'name': 'Audi'},
    {'id': '19', 'name': 'BMW'},
    {'id': '20', 'name': 'Mercedes-Benz'},
    {'id': '21', 'name': 'Volvo'},
    {'id': '22', 'name': 'Land Rover'},
    {'id': '23', 'name': 'JAC'},
  ];
}

getVehicleMake({transportType, myVehicleIconFor}) async {
  dynamic res;

  // Logs detalhados para debug
  debugPrint('🚗 [API] getVehicleMake - Iniciando chamada');
  debugPrint('🚗 [API] getVehicleMake - transportType: $transportType');
  debugPrint('🚗 [API] getVehicleMake - myVehicleIconFor: $myVehicleIconFor');
  debugPrint('🚗 [API] getVehicleMake - url base: $url');

  final apiUrl =
      '${url}api/v1/common/car/makes?transport_type=$transportType&vehicle_type=$myVehicleIconFor';
  debugPrint('🚗 [API] getVehicleMake - URL completa: $apiUrl');

  try {
    debugPrint('🚗 [API] getVehicleMake - Fazendo requisição GET...');
    final response = await http.get(
      Uri.parse(apiUrl),
    );

    debugPrint('🚗 [API] getVehicleMake - Resposta recebida');
    debugPrint('🚗 [API] getVehicleMake - Status Code: ${response.statusCode}');
    debugPrint('🚗 [API] getVehicleMake - Body: ${response.body}');

    if (response.statusCode == 200) {
      try {
        final jsonResponse = jsonDecode(response.body);
        debugPrint('🚗 [API] getVehicleMake - JSON decodificado com sucesso');

        if (jsonResponse.containsKey('data')) {
          vehicleMake = List<Map<String, dynamic>>.from(
              jsonResponse['data'] ?? []);

          // Ordenar por nome
          vehicleMake.sort((a, b) => (a['name'] ?? '')
              .toString()
              .compareTo((b['name'] ?? '').toString()));

          debugPrint(
              '🚗 [API] getVehicleMake - vehicleMake carregado: ${vehicleMake.length} marcas encontradas');
          if (vehicleMake.isNotEmpty) {
            debugPrint(
                '🚗 [API] getVehicleMake - Primeira marca: ${vehicleMake[0]}');
          } else {
            debugPrint(
                '🚗 [API] getVehicleMake - AVISO: Lista de marcas vazia!');
            vehicleMake = [];
          }
          res = 'success';
        } else {
          debugPrint(
              '🚗 [API] getVehicleMake - ERRO: JSON não contém campo "data"');
          debugPrint(
              '🚗 [API] getVehicleMake - Chaves disponíveis: ${jsonResponse.keys}');
          vehicleMake = [];
          res = 'success';
        }
      } catch (jsonError) {
        debugPrint(
            '🚗 [API] getVehicleMake - ERRO ao decodificar JSON: $jsonError');
        debugPrint(
            '🚗 [API] getVehicleMake - Body que causou erro: ${response.body}');
        vehicleMake = [];
        res = 'success';
      }
    } else {
      // Usar função helper para tratar erros
      logApiError('getVehicleMake', response.statusCode, response.body);
      vehicleMake = [];
      res = 'success';
    }
  } catch (e) {
    debugPrint('🚗 [API] getVehicleMake - EXCEÇÃO capturada: $e');
    debugPrint('🚗 [API] getVehicleMake - Tipo do erro: ${e.runtimeType}');
    if (e is SocketException) {
      debugPrint(
          '🚗 [API] getVehicleMake - SocketException: Sem conexão com internet');
      internet = false;
      vehicleMake = [];
      res = 'success';
    } else {
      vehicleMake = [];
      res = 'success';
    }
  }

  debugPrint('🚗 [API] getVehicleMake - Resultado final: $res');
  debugPrint(
      '🚗 [API] getVehicleMake - vehicleMake.length: ${vehicleMake.length}');

  return res;
}

//get vehicle model

List vehicleModel = [];

// Lista pré-definida de modelos comuns por marca
List<Map<String, dynamic>> getDefaultModels(String makeId, String makeName) {
  final modelsMap = <String, List<Map<String, dynamic>>>{
    '1': [
      // Chevrolet
      {'id': '101', 'name': 'Onix'},
      {'id': '102', 'name': 'Prisma'},
      {'id': '103', 'name': 'Cruze'},
      {'id': '104', 'name': 'S10'},
      {'id': '105', 'name': 'Tracker'},
      {'id': '106', 'name': 'Equinox'},
      {'id': '107', 'name': 'Spin'},
      {'id': '108', 'name': 'Montana'},
      {'id': '109', 'name': 'Celta'},
      {'id': '110', 'name': 'Corsa'},
      {'id': '111', 'name': 'Meriva'},
      {'id': '112', 'name': 'Astra'},
      {'id': '113', 'name': 'Vectra'},
      {'id': '114', 'name': 'Blazer'},
      {'id': '115', 'name': 'Trailblazer'},
    ],
    '2': [
      // Volkswagen
      {'id': '201', 'name': 'Gol'},
      {'id': '202', 'name': 'Polo'},
      {'id': '203', 'name': 'Virtus'},
      {'id': '204', 'name': 'Jetta'},
      {'id': '205', 'name': 'Passat'},
      {'id': '206', 'name': 'Amarok'},
      {'id': '207', 'name': 'T-Cross'},
      {'id': '208', 'name': 'Tiguan'},
      {'id': '209', 'name': 'Nivus'},
      {'id': '210', 'name': 'Fox'},
      {'id': '211', 'name': 'Voyage'},
      {'id': '212', 'name': 'Saveiro'},
      {'id': '213', 'name': 'Kombi'},
      {'id': '214', 'name': 'Up!'},
      {'id': '215', 'name': 'Spacefox'},
    ],
    '3': [
      // Fiat
      {'id': '301', 'name': 'Uno'},
      {'id': '302', 'name': 'Palio'},
      {'id': '303', 'name': 'Siena'},
      {'id': '304', 'name': 'Strada'},
      {'id': '305', 'name': 'Toro'},
      {'id': '306', 'name': 'Mobi'},
      {'id': '307', 'name': 'Argo'},
      {'id': '308', 'name': 'Cronos'},
      {'id': '309', 'name': 'Fiorino'},
      {'id': '310', 'name': 'Ducato'},
      {'id': '311', 'name': 'Doblo'},
      {'id': '312', 'name': 'Bravo'},
      {'id': '313', 'name': 'Linea'},
      {'id': '314', 'name': 'Grand Siena'},
      {'id': '315', 'name': 'Punto'},
    ],
    '4': [
      // Ford
      {'id': '401', 'name': 'Ka'},
      {'id': '402', 'name': 'Fiesta'},
      {'id': '403', 'name': 'Focus'},
      {'id': '404', 'name': 'Fusion'},
      {'id': '405', 'name': 'Ranger'},
      {'id': '406', 'name': 'Edge'},
      {'id': '407', 'name': 'EcoSport'},
      {'id': '408', 'name': 'Territory'},
      {'id': '409', 'name': 'Bronco'},
      {'id': '410', 'name': 'Mustang'},
      {'id': '411', 'name': 'Maverick'},
      {'id': '412', 'name': 'F-1000'},
      {'id': '413', 'name': 'F-250'},
      {'id': '414', 'name': 'F-350'},
      {'id': '415', 'name': 'Transit'},
    ],
    '5': [
      // Toyota
      {'id': '501', 'name': 'Corolla'},
      {'id': '502', 'name': 'Camry'},
      {'id': '503', 'name': 'Hilux'},
      {'id': '504', 'name': 'RAV4'},
      {'id': '505', 'name': 'SW4'},
      {'id': '506', 'name': 'Yaris'},
      {'id': '507', 'name': 'Etios'},
      {'id': '508', 'name': 'Prius'},
      {'id': '509', 'name': 'Bandeirante'},
      {'id': '510', 'name': 'Land Cruiser'},
      {'id': '511', 'name': 'Highlander'},
      {'id': '512', 'name': 'Sienna'},
    ],
    '6': [
      // Honda
      {'id': '601', 'name': 'Civic'},
      {'id': '602', 'name': 'Accord'},
      {'id': '603', 'name': 'City'},
      {'id': '604', 'name': 'Fit'},
      {'id': '605', 'name': 'HR-V'},
      {'id': '606', 'name': 'CR-V'},
      {'id': '607', 'name': 'WR-V'},
      {'id': '608', 'name': 'Pilot'},
      {'id': '609', 'name': 'Ridgeline'},
      {'id': '610', 'name': 'Passport'},
    ],
    '7': [
      // Hyundai
      {'id': '701', 'name': 'HB20'},
      {'id': '702', 'name': 'HB20S'},
      {'id': '703', 'name': 'Creta'},
      {'id': '704', 'name': 'Tucson'},
      {'id': '705', 'name': 'Santa Fe'},
      {'id': '706', 'name': 'i30'},
      {'id': '707', 'name': 'Elantra'},
      {'id': '708', 'name': 'Sonata'},
      {'id': '709', 'name': 'Azera'},
      {'id': '710', 'name': 'ix35'},
    ],
    '8': [
      // Renault
      {'id': '801', 'name': 'Kwid'},
      {'id': '802', 'name': 'Sandero'},
      {'id': '803', 'name': 'Logan'},
      {'id': '804', 'name': 'Duster'},
      {'id': '805', 'name': 'Captur'},
      {'id': '806', 'name': 'Oroch'},
      {'id': '807', 'name': 'Fluence'},
      {'id': '808', 'name': 'Megane'},
      {'id': '809', 'name': 'Scenic'},
      {'id': '810', 'name': 'Koleos'},
    ],
    '9': [
      // Nissan
      {'id': '901', 'name': 'March'},
      {'id': '902', 'name': 'Versa'},
      {'id': '903', 'name': 'Sentra'},
      {'id': '904', 'name': 'Kicks'},
      {'id': '905', 'name': 'Frontier'},
      {'id': '906', 'name': 'X-Terra'},
      {'id': '907', 'name': 'Pathfinder'},
      {'id': '908', 'name': 'Altima'},
      {'id': '909', 'name': 'Maxima'},
      {'id': '910', 'name': 'Leaf'},
    ],
    '10': [
      // Peugeot
      {'id': '1001', 'name': '208'},
      {'id': '1002', 'name': '2008'},
      {'id': '1003', 'name': '3008'},
      {'id': '1004', 'name': '5008'},
      {'id': '1005', 'name': 'Partner'},
      {'id': '1006', 'name': 'Expert'},
      {'id': '1007', 'name': 'Boxer'},
    ],
    '11': [
      // Citroën
      {'id': '1101', 'name': 'C3'},
      {'id': '1102', 'name': 'C4'},
      {'id': '1103', 'name': 'Aircross'},
      {'id': '1104', 'name': 'Jumper'},
      {'id': '1105', 'name': 'Berlingo'},
    ],
    '12': [
      // Jeep
      {'id': '1201', 'name': 'Renegade'},
      {'id': '1202', 'name': 'Compass'},
      {'id': '1203', 'name': 'Commander'},
      {'id': '1204', 'name': 'Wrangler'},
      {'id': '1205', 'name': 'Grand Cherokee'},
    ],
    '13': [
      // Mitsubishi
      {'id': '1301', 'name': 'L200'},
      {'id': '1302', 'name': 'Outlander'},
      {'id': '1303', 'name': 'ASX'},
      {'id': '1304', 'name': 'Eclipse Cross'},
      {'id': '1305', 'name': 'Pajero'},
    ],
    '14': [
      // Suzuki
      {'id': '1401', 'name': 'Jimny'},
      {'id': '1402', 'name': 'Vitara'},
      {'id': '1403', 'name': 'S-Cross'},
      {'id': '1404', 'name': 'Grand Vitara'},
    ],
    '15': [
      // Kia
      {'id': '1501', 'name': 'Picanto'},
      {'id': '1502', 'name': 'Rio'},
      {'id': '1503', 'name': 'Cerato'},
      {'id': '1504', 'name': 'Sorento'},
      {'id': '1505', 'name': 'Sportage'},
      {'id': '1506', 'name': 'Soul'},
    ],
    '16': [
      // Chery
      {'id': '1601', 'name': 'QQ'},
      {'id': '1602', 'name': 'Celer'},
      {'id': '1603', 'name': 'Face'},
      {'id': '1604', 'name': 'Tiggo'},
      {'id': '1605', 'name': 'S18'},
    ],
    '17': [
      // CAOA Chery
      {'id': '1701', 'name': 'Tiggo 2'},
      {'id': '1702', 'name': 'Tiggo 3X'},
      {'id': '1703', 'name': 'Tiggo 5X'},
      {'id': '1704', 'name': 'Tiggo 7'},
      {'id': '1705', 'name': 'Tiggo 8'},
    ],
    '18': [
      // Audi
      {'id': '1901', 'name': 'A1'},
      {'id': '1902', 'name': 'A3'},
      {'id': '1903', 'name': 'A4'},
      {'id': '1904', 'name': 'A5'},
      {'id': '1905', 'name': 'A6'},
      {'id': '1906', 'name': 'Q3'},
      {'id': '1907', 'name': 'Q5'},
      {'id': '1908', 'name': 'Q7'},
    ],
    '19': [
      // BMW
      {'id': '2001', 'name': 'Série 1'},
      {'id': '2002', 'name': 'Série 3'},
      {'id': '2003', 'name': 'Série 5'},
      {'id': '2004', 'name': 'X1'},
      {'id': '2005', 'name': 'X3'},
      {'id': '2006', 'name': 'X5'},
    ],
    '20': [
      // Mercedes-Benz
      {'id': '2101', 'name': 'Classe A'},
      {'id': '2102', 'name': 'Classe B'},
      {'id': '2103', 'name': 'Classe C'},
      {'id': '2104', 'name': 'Classe E'},
      {'id': '2105', 'name': 'GLA'},
      {'id': '2106', 'name': 'GLC'},
      {'id': '2107', 'name': 'GLE'},
    ],
    '21': [
      // Volvo
      {'id': '2201', 'name': 'XC40'},
      {'id': '2202', 'name': 'XC60'},
      {'id': '2203', 'name': 'XC90'},
      {'id': '2204', 'name': 'S60'},
      {'id': '2205', 'name': 'S90'},
    ],
    '22': [
      // Land Rover
      {'id': '2301', 'name': 'Discovery'},
      {'id': '2302', 'name': 'Discovery Sport'},
      {'id': '2303', 'name': 'Range Rover'},
      {'id': '2304', 'name': 'Range Rover Evoque'},
      {'id': '2305', 'name': 'Range Rover Sport'},
    ],
    '23': [
      // JAC
      {'id': '2401', 'name': 'J2'},
      {'id': '2402', 'name': 'J3'},
      {'id': '2403', 'name': 'T40'},
      {'id': '2404', 'name': 'T50'},
      {'id': '2405', 'name': 'T60'},
    ],
  };

  return modelsMap[makeId] ?? [];
}

getVehicleModel() async {
  dynamic res;
  try {
    final response = await http.get(
      Uri.parse('${url}api/v1/common/car/models/${vehicleMakeId.toString()}'),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      vehicleModel =
          List<Map<String, dynamic>>.from(jsonResponse['data'] ?? []);

      // Adicionar modelos pré-definidos que não estão na lista da API
      final makeName = vehicleMake
              .firstWhere(
                (m) => m['id'].toString() == vehicleMakeId.toString(),
                orElse: () => {'name': ''},
              )['name']
              ?.toString() ??
          '';

      final defaultModels =
          getDefaultModels(vehicleMakeId.toString(), makeName);
      final existingModelNames =
          vehicleModel.map((m) => m['name'].toString().toLowerCase()).toSet();

      for (var defaultModel in defaultModels) {
        final modelName = defaultModel['name'].toString().toLowerCase();
        if (!existingModelNames.contains(modelName)) {
          vehicleModel.add(defaultModel);
          debugPrint(
              '🚗 [API] getVehicleModel - Adicionado modelo pré-definido: ${defaultModel['name']}');
        }
      }

      // Ordenar por nome
      vehicleModel.sort((a, b) =>
          (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()));

      res = 'success';
    } else {
      debugPrint(response.body);
      // Usar modelos pré-definidos como fallback
      final makeName = vehicleMake
              .firstWhere(
                (m) => m['id'].toString() == vehicleMakeId.toString(),
                orElse: () => {'name': ''},
              )['name']
              ?.toString() ??
          '';
      vehicleModel = getDefaultModels(vehicleMakeId.toString(), makeName);
      res = 'success';
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      // Usar modelos pré-definidos quando não há internet
      final makeName = vehicleMake
              .firstWhere(
                (m) => m['id'].toString() == vehicleMakeId.toString(),
                orElse: () => {'name': ''},
              )['name']
              ?.toString() ??
          '';
      vehicleModel = getDefaultModels(vehicleMakeId.toString(), makeName);
      res = 'success';
    } else {
      // Usar modelos pré-definidos como fallback
      final makeName = vehicleMake
              .firstWhere(
                (m) => m['id'].toString() == vehicleMakeId.toString(),
                orElse: () => {'name': ''},
              )['name']
              ?.toString() ??
          '';
      vehicleModel = getDefaultModels(vehicleMakeId.toString(), makeName);
      res = 'success';
    }
  }
  return res;
}

//register driver

List<BearerClass> bearerToken = <BearerClass>[];

registerDriver() async {
  bearerToken.clear();
  dynamic result;
  try {
    // No web, Firebase Messaging pode não funcionar, usar token vazio ou gerar um
    var fcm = '';
    if (!kIsWeb) {
      try {
        var token = await FirebaseMessaging.instance.getToken();
        fcm = token.toString();
      } catch (e) {
        debugPrint('🌐 [API] registerDriver - Erro ao obter FCM token: $e');
        fcm = '';
      }
    } else {
      // No web, pode usar um token vazio ou gerar um identificador único
      fcm = 'web_${DateTime.now().millisecondsSinceEpoch}';
      debugPrint(
          '🌐 [API] registerDriver - Web detectado, usando token gerado: $fcm');
    }

    final apiUrl = '${url}api/v1/driver/register';
    debugPrint(
        '🌐🌐🌐 [API] registerDriver - ========== INÍCIO DA CHAMADA ==========');
    debugPrint('🌐 [API] registerDriver - URL: $apiUrl');
    debugPrint('🌐 [API] registerDriver - Método: POST');

    final response = http.MultipartRequest(
      'POST',
      Uri.parse(apiUrl),
    );

    response.headers.addAll({'Content-Type': 'application/json'});
    debugPrint('🌐 [API] registerDriver - Headers: ${response.headers}');

    if (proImageFile1 != null) {
      response.files.add(
        await http.MultipartFile.fromPath('profile_picture', proImageFile1),
      );
      debugPrint(
          '🌐 [API] registerDriver - Arquivo de imagem anexado: $proImageFile1');
    } else {
      debugPrint('🌐 [API] registerDriver - Nenhuma imagem de perfil anexada');
    }

    final fields = <String, String>{
      "name": name.toString(),
      "mobile": phnumber.toString(),
      "email": email.toString(),
      "device_token": fcm.toString(),
      "country": countries[phcode]['dial_code'].toString(),
      "service_location_id": myServiceId.toString(),
      "login_by": kIsWeb
          ? 'android' // Backend não aceita 'web', usar 'android' como fallback
          : (platform == TargetPlatform.android)
              ? 'android'
              : 'ios',
      // "vehicle_type": myVehicleId.toString(),
      "vehicle_types": jsonEncode(vehicletypelist),
      "car_make": vehicleMakeId.toString(),
      "car_model": vehicleModelId.toString(),
      "car_color": vehicleColor.toString(),
      "car_number": vehicleNumber.toString(),
      "vehicle_year": modelYear.toString(),
      'lang': choosenLanguage.toString(),
      'transport_type': transportType.toString(),
      'custom_make': mycustommake.toString(),
      'custom_model': mycustommodel.toString(),
      // Cadastro: CPF enviado como document para a API
      'document': userCpf.toString(),
      'birth_date': userBirthDate.toString(),
      'postal_code': userCep.toString(),
      'gender': userGender.toString(),
      'passenger_preference': userPassengerPreference.toString(),
      'address': userAddress.toString(),
      'address_number': userNumber.toString(),
      'complement': userComplement.toString(),
      'neighborhood': userNeighborhood.toString(),
      'city': userCity.toString(),
      'state': userState.toString(),
    };

    debugPrint(
        '🌐🌐🌐 [API] registerDriver - ========== BODY DA REQUISIÇÃO ==========');
    debugPrint('🌐 [API] registerDriver - name: ${fields["name"]}');
    debugPrint('🌐 [API] registerDriver - mobile: ${fields["mobile"]}');
    debugPrint('🌐 [API] registerDriver - email: ${fields["email"]}');
    debugPrint(
        '🌐 [API] registerDriver - device_token: ${fields["device_token"]}');
    debugPrint('🌐 [API] registerDriver - country: ${fields["country"]}');
    debugPrint(
        '🌐 [API] registerDriver - service_location_id: ${fields["service_location_id"]}');
    debugPrint('🌐 [API] registerDriver - login_by: ${fields["login_by"]}');
    debugPrint(
        '🌐 [API] registerDriver - vehicle_types: ${fields["vehicle_types"]}');
    debugPrint('🌐 [API] registerDriver - car_make: ${fields["car_make"]}');
    debugPrint('🌐 [API] registerDriver - car_model: ${fields["car_model"]}');
    debugPrint('🌐 [API] registerDriver - car_color: ${fields["car_color"]}');
    debugPrint('🌐 [API] registerDriver - car_number: ${fields["car_number"]}');
    debugPrint(
        '🌐 [API] registerDriver - vehicle_year: ${fields["vehicle_year"]}');
    debugPrint('🌐 [API] registerDriver - lang: ${fields["lang"]}');
    debugPrint(
        '🌐 [API] registerDriver - transport_type: ${fields["transport_type"]}');
    debugPrint(
        '🌐 [API] registerDriver - custom_make: ${fields["custom_make"]}');
    debugPrint(
        '🌐 [API] registerDriver - custom_model: ${fields["custom_model"]}');
    debugPrint('🌐 [API] registerDriver - gender: ${fields["gender"]}');
    debugPrint(
        '🌐 [API] registerDriver - passenger_preference: ${fields["passenger_preference"]}');
    debugPrint(
        '🌐🌐🌐 [API] registerDriver - ========== FIM DO BODY ==========');

    response.fields.addAll(fields);
    // Garantir que gender e passenger_preference sejam sempre enviados
    response.fields['gender'] = userGender.toString();
    response.fields['passenger_preference'] = userPassengerPreference.toString();

    debugPrint(
        '🌐🌐🌐 [API] registerDriver - ========== ENVIANDO REQUISIÇÃO ==========');
    var request = await response.send();
    var respon = await http.Response.fromStream(request);

    debugPrint(
        '🌐🌐🌐 [API] registerDriver - ========== RESPOSTA RECEBIDA ==========');
    debugPrint('🌐 [API] registerDriver - Status Code: ${request.statusCode}');
    debugPrint('🌐 [API] registerDriver - Response Headers: ${respon.headers}');
    debugPrint(
        '🌐 [API] registerDriver - Response Body (primeiros 500 chars): ${respon.body.length > 500 ? respon.body.substring(0, 500) + '...' : respon.body}');
    if (respon.body.length > 500) {
      debugPrint(
          '🌐 [API] registerDriver - Response Body completo (${respon.body.length} chars)');
    }

    if (request.statusCode == 200) {
      var jsonVal = jsonDecode(respon.body);
      debugPrint(
          '🌐 [API] registerDriver - Token recebido: ${jsonVal['token_type']}');
      debugPrint(
          '🌐 [API] registerDriver - Access token: ${jsonVal['access_token']?.substring(0, 20)}...');

      // No web, não chamar métodos nativos
      if (ischeckownerordriver == 'driver' && !kIsWeb) {
        try {
          platforms.invokeMethod('login');
        } catch (e) {
          debugPrint(
              '🌐 [API] registerDriver - Erro ao chamar método nativo login: $e');
        }
      }
      bearerToken.add(
        BearerClass(
          type: jsonVal['token_type'].toString(),
          token: jsonVal['access_token'].toString(),
        ),
      );
      pref.setString('Bearer', bearerToken[0].token);
      debugPrint('🌐 [API] registerDriver - Token salvo no SharedPreferences');

      await getUserDetails();
      // No web, não atualizar Firebase Database com package info
      if (!kIsWeb) {
        if (platform == TargetPlatform.android && package != null) {
          try {
            debugPrint(
                '🔥 [FIREBASE] registerDriver - Atualizando driver_package_name: ${package.packageName}');
            await FirebaseDatabase.instance.ref().update({
              'driver_package_name': package.packageName.toString(),
            });
          } catch (e) {
            debugPrint(
                '🔥 [FIREBASE] registerDriver - Erro ao atualizar package_name: $e');
          }
        } else if (package != null) {
          try {
            debugPrint(
                '🔥 [FIREBASE] registerDriver - Atualizando driver_bundle_id: ${package.packageName}');
            await FirebaseDatabase.instance.ref().update({
              'driver_bundle_id': package.packageName.toString(),
            });
          } catch (e) {
            debugPrint(
                '🔥 [FIREBASE] registerDriver - Erro ao atualizar bundle_id: $e');
          }
        }
      } else {
        debugPrint(
            '🔥 [FIREBASE] registerDriver - Web detectado, pulando atualização de package info');
      }
      result = 'true';
      debugPrint('🌐 [API] registerDriver - Registro realizado com sucesso');
    } else if (respon.statusCode == 422) {
      debugPrint('🌐 [API] registerDriver - ERRO 422 (Validation Error)');
      debugPrint('🌐 [API] registerDriver - Response: ${respon.body}');
      try {
        final body = jsonDecode(respon.body);
        result = formatValidationErrors(
          body['errors'],
          fallbackMessage: body['message']?.toString() ?? 'Os dados enviados são inválidos.',
        );
      } catch (_) {
        result = 'Os dados enviados são inválidos.';
      }
    } else {
      debugPrint('🌐 [API] registerDriver - ERRO ${respon.statusCode} (ex: 400)');
      debugPrint('🌐 [API] registerDriver - Response: ${respon.body}');
      try {
        final body = jsonDecode(respon.body);
        result = body['message']?.toString() ?? 'Erro ao realizar cadastro.';
      } catch (_) {
        result = 'Erro ao realizar cadastro.';
      }
    }
  } catch (e) {
    debugPrint('🌐 [API] registerDriver - EXCEÇÃO: $e');
    debugPrint('🌐 [API] registerDriver - Tipo: ${e.runtimeType}');
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
      debugPrint('🌐 [API] registerDriver - SocketException: Sem internet');
    } else {
      // Para web, pode ser erro de Firebase ou outros, mas não deve bloquear
      debugPrint('🌐 [API] registerDriver - Erro geral: $e');
      // Se for erro de Firebase no web, tentar continuar mesmo assim
      if (kIsWeb && e.toString().contains('Firebase')) {
        debugPrint(
            '🌐 [API] registerDriver - Erro de Firebase no web, continuando...');
        // Não definir result como erro, deixar que a API responda
      } else {
        result = 'Erro ao registrar: $e';
      }
    }
  }
  debugPrint('🌐 [API] registerDriver - Resultado final: $result');
  return result;
}

addDriver() async {
  dynamic result;
  try {
    final response = await http.post(
      Uri.parse('${url}api/v1/owner/add-fleet'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${bearerToken[0].token}',
      },
      body: jsonEncode({
        "vehicle_type": vehicletypelist[0],
        "car_make": vehicleMakeId,
        "car_model": vehicleModelId,
        "car_color": vehicleColor,
        "car_number": vehicleNumber,
        'custom_make': mycustommake,
        'custom_model': mycustommodel,
      }),
    );

    if (response.statusCode == 200) {
      result = 'true';
    } else if (response.statusCode == 422) {
      debugPrint(response.body);
      var error = jsonDecode(response.body)['errors'];
      result = error[error.keys.toList()[0]]
          .toString()
          .replaceAll('[', '')
          .replaceAll(']', '')
          .toString();
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

//register owner

registerOwner() async {
  bearerToken.clear();
  dynamic result;
  try {
    var token = await FirebaseMessaging.instance.getToken();
    var fcm = token.toString();
    final response = http.MultipartRequest(
      'POST',
      Uri.parse('${url}api/v1/owner/register'),
    );
    response.headers.addAll({'Content-Type': 'application/json'});
    if (proImageFile1 != null) {
      response.files.add(
        await http.MultipartFile.fromPath('profile_picture', proImageFile1),
      );
    }
    response.fields.addAll({
      "name": name,
      "mobile": phnumber,
      "email": email,
      "address": companyAddress,
      "postal_code": postalCode,
      "city": city,
      "tax_number": taxNumber,
      "company_name": companyName,
      "device_token": fcm,
      "country": countries[phcode]['dial_code'],
      "service_location_id": myServiceId.toString(),
      "login_by": kIsWeb
          ? 'android' // Backend não aceita 'web', usar 'android' como fallback
          : (platform == TargetPlatform.android)
              ? 'android'
              : 'ios',
      'lang': choosenLanguage,
      'transport_type': transportType,
    });
    var request = await response.send();
    var respon = await http.Response.fromStream(request);

    if (respon.statusCode == 200) {
      var jsonVal = jsonDecode(respon.body);

      bearerToken.add(
        BearerClass(
          type: jsonVal['token_type'].toString(),
          token: jsonVal['access_token'].toString(),
        ),
      );
      pref.setString('Bearer', bearerToken[0].token);
      await getUserDetails();
      if (platform == TargetPlatform.android && package != null) {
        await FirebaseDatabase.instance.ref().update({
          'driver_package_name': package.packageName.toString(),
        });
      } else if (package != null) {
        await FirebaseDatabase.instance.ref().update({
          'driver_bundle_id': package.packageName.toString(),
        });
      }
      result = 'true';
    } else if (respon.statusCode == 422) {
      debugPrint(respon.body);
      var error = jsonDecode(respon.body)['errors'];
      result = error[error.keys.toList()[0]]
          .toString()
          .replaceAll('[', '')
          .replaceAll(']', '')
          .toString();
    } else {
      debugPrint(respon.body);
      result = jsonDecode(respon.body)['message'];
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

List fleetdriverList = [];
fleetDriverDetails({fleetid, bool? isassigndriver}) async {
  dynamic result;
  fleetdriverList.clear();
  try {
    var response = await http.get(
      Uri.parse(
        isassigndriver == true
            ? '${url}api/v1/owner/list-drivers?fleet_id=$fleetid'
            : '${url}api/v1/owner/list-drivers',
      ),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      fleetdriverList = jsonDecode(response.body)['data'];
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

assignDriver(driverid, fleet) async {
  dynamic result;
  try {
    final response = await http.post(
      Uri.parse('${url}api/v1/owner/assign-driver/$fleet'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'driver_id': driverid}),
    );

    if (response.statusCode == 200) {
      var jsonVal = jsonDecode(response.body);

      bearerToken.add(
        BearerClass(
          type: jsonVal['token_type'].toString(),
          token: jsonVal['access_token'].toString(),
        ),
      );
      pref.setString('Bearer', bearerToken[0].token);
      result = 'true';
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
      // notificationHistory = jsonDecode(response.body)['data'];
      // notificationHistoryPage = jsonDecode(response.body)['meta'];
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

fleetDriver(Map<String, dynamic> map) async {
  dynamic result;
  try {
    final response = await http.post(
      Uri.parse('${url}api/v1/owner/add-drivers'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(map),
    );

    if (response.statusCode == 200) {
      var jsonVal = jsonDecode(response.body);

      bearerToken.add(
        BearerClass(
          type: jsonVal['token_type'].toString(),
          token: jsonVal['access_token'].toString(),
        ),
      );
      pref.setString('Bearer', bearerToken[0].token);
      result = 'true';
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

//update referral code

updateReferral(referral) async {
  dynamic result;
  try {
    var response = await http.post(
      Uri.parse('${url}api/v1/update/driver/referral'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({"refferal_code": referral}),
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
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

//get documents needed

List documentsNeeded = [];
bool enableDocumentSubmit = false;

getDocumentsNeeded() async {
  dynamic result;
  try {
    final apiUrl = '${url}api/v1/driver/documents/needed';
    debugPrint(
        '📄📄📄 [API] getDocumentsNeeded - ========== INÍCIO DA CHAMADA ==========');
    debugPrint('📄 [API] getDocumentsNeeded - URL: $apiUrl');
    debugPrint('📄 [API] getDocumentsNeeded - Método: GET');

    final bearerTokenValue =
        bearerToken.isNotEmpty ? bearerToken[0].token : 'N/A';
    debugPrint(
        '📄 [API] getDocumentsNeeded - Bearer Token: ${bearerTokenValue.length > 20 ? bearerTokenValue.substring(0, 20) + '...' : bearerTokenValue}');

    final headers = {
      'Authorization': 'Bearer ${bearerToken[0].token}',
      'Content-Type': 'application/json',
    };
    debugPrint('📄 [API] getDocumentsNeeded - Headers: $headers');

    debugPrint(
        '📄📄📄 [API] getDocumentsNeeded - ========== ENVIANDO REQUISIÇÃO ==========');
    final response = await http.get(
      Uri.parse(apiUrl),
      headers: headers,
    );

    debugPrint(
        '📄📄📄 [API] getDocumentsNeeded - ========== RESPOSTA RECEBIDA ==========');
    debugPrint(
        '📄 [API] getDocumentsNeeded - Status Code: ${response.statusCode}');
    debugPrint(
        '📄 [API] getDocumentsNeeded - Response Headers: ${response.headers}');
    debugPrint(
        '📄 [API] getDocumentsNeeded - Response Body (primeiros 500 chars): ${response.body.length > 500 ? response.body.substring(0, 500) + '...' : response.body}');
    if (response.body.length > 500) {
      debugPrint(
          '📄 [API] getDocumentsNeeded - Response Body completo (${response.body.length} chars)');
    }

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      documentsNeeded = jsonResponse['data'] ?? [];
      enableDocumentSubmit = jsonResponse['enable_submit_button'] ?? false;

      debugPrint('📄 [API] getDocumentsNeeded - ✅ Sucesso');
      debugPrint(
          '📄 [API] getDocumentsNeeded - documentsNeeded.length: ${documentsNeeded.length}');
      debugPrint(
          '📄 [API] getDocumentsNeeded - enable_submit_button: $enableDocumentSubmit');

      if (documentsNeeded.isNotEmpty) {
        debugPrint(
            '📄 [API] getDocumentsNeeded - Primeiro documento: ${documentsNeeded[0]}');
      }

      result = 'success';
    } else if (response.statusCode == 401) {
      debugPrint('📄 [API] getDocumentsNeeded - ❌ ERRO 401 (Unauthorized)');
      result = 'logout';
    } else {
      debugPrint('📄 [API] getDocumentsNeeded - ❌ ERRO ${response.statusCode}');
      debugPrint(
          '📄 [API] getDocumentsNeeded - Response completa: ${response.body}');
      result = 'failure';
    }
  } catch (e, stackTrace) {
    debugPrint('📄📄📄 [API] getDocumentsNeeded - ❌❌❌ EXCEÇÃO: $e');
    debugPrint('📄 [API] getDocumentsNeeded - Tipo: ${e.runtimeType}');
    debugPrint('📄 [API] getDocumentsNeeded - Stack trace: $stackTrace');
    if (e is SocketException) {
      result = 'no internet';
      internet = false;
      debugPrint('📄 [API] getDocumentsNeeded - SocketException: Sem internet');
    } else {
      result = 'Erro ao buscar documentos: $e';
    }
  }
  debugPrint('📄📄📄 [API] getDocumentsNeeded - Resultado final: $result');
  debugPrint(
      '📄📄📄 [API] getDocumentsNeeded - ========== FIM DA CHAMADA ==========');
  return result;
}

List fleetdocumentsNeeded = [];
bool enablefleetDocumentSubmit = false;

getFleetDocumentsNeeded(fleetid) async {
  dynamic result;
  try {
    final response = await http.get(
      Uri.parse('${url}api/v1/owner/fleet/documents/needed?fleet_id=$fleetid'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      fleetdocumentsNeeded = jsonDecode(response.body)['data'];
      enablefleetDocumentSubmit = jsonDecode(
        response.body,
      )['enable_submit_button'];
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

//call firebase otp

// Classe auxiliar para criar um DataSnapshot simulado quando o nó não existe
class _DefaultOtpSnapshot {
  final dynamic value;
  final bool exists;
  final String? key;

  _DefaultOtpSnapshot(this.value, this.exists, this.key);
}

// Função auxiliar para criar um DataSnapshot padrão
dynamic _createDefaultOtpSnapshot(bool defaultValue) {
  return _DefaultOtpSnapshot(defaultValue, false, 'call_FB_OTP');
}

otpCall() async {
  dynamic result;
  try {
    debugPrint('🔥 [FIREBASE] otpCall - Iniciando verificação de call_FB_OTP');

    final database = getFirebaseDatabase();
    debugPrint('🔥 [FIREBASE] otpCall - Database URL: ${database.databaseURL}');

    final ref = database.ref();

    // Adicionar timeout de 10 segundos
    debugPrint(
        '🔥 [FIREBASE] otpCall - Fazendo requisição com timeout de 10s...');
    var otp = await ref.child('call_FB_OTP').get().timeout(
          const Duration(seconds: 10),
        );

    debugPrint('🔥 [FIREBASE] otpCall - Resposta recebida');
    debugPrint('🔥 [FIREBASE] otpCall - Existe: ${otp.exists}');
    debugPrint('🔥 [FIREBASE] otpCall - Valor: ${otp.value}');
    debugPrint('🔥 [FIREBASE] otpCall - Key: ${otp.key}');

    if (!otp.exists || otp.value == null) {
      debugPrint(
          '🔥 [FIREBASE] otpCall - AVISO: Nó call_FB_OTP não existe no Firebase');
      debugPrint(
          '🔥 [FIREBASE] otpCall - Verifique se o nó foi criado no Firebase Console');
      debugPrint(
          '🔥 [FIREBASE] otpCall - Usando valor padrão: false (OTP via Firebase desabilitado)');
      debugPrint('🔥 [FIREBASE] otpCall - INSTRUÇÕES:');
      debugPrint(
          '🔥 [FIREBASE] otpCall - 1. Acesse https://console.firebase.google.com/');
      debugPrint('🔥 [FIREBASE] otpCall - 2. Selecione o projeto: goin-7372e');
      debugPrint('🔥 [FIREBASE] otpCall - 3. Vá em Realtime Database > Data');
      debugPrint(
          '🔥 [FIREBASE] otpCall - 4. Clique em "+" e adicione: call_FB_OTP = true ou false');
      // Criar um DataSnapshot wrapper que retorna false quando não existe
      // O código que usa otpCall() espera um objeto com .value
      result = _createDefaultOtpSnapshot(false);
    } else {
      result = otp;
    }
  } on TimeoutException {
    debugPrint(
        '🔥 [FIREBASE] otpCall - TIMEOUT: Não recebeu resposta em 10 segundos');
    debugPrint('🔥 [FIREBASE] otpCall - Possíveis causas:');
    debugPrint('🔥 [FIREBASE] otpCall - 1. Problema de conectividade');
    debugPrint(
        '🔥 [FIREBASE] otpCall - 2. Regras de segurança do Firebase bloqueando');
    debugPrint('🔥 [FIREBASE] otpCall - 3. Firebase Database não acessível');
    result = 'timeout';
  } catch (e) {
    debugPrint('🔥 [FIREBASE] otpCall - ERRO: $e');
    debugPrint('🔥 [FIREBASE] otpCall - Tipo do erro: ${e.runtimeType}');
    debugPrint('🔥 [FIREBASE] otpCall - Stack trace: ${StackTrace.current}');

    // Verificar tipos específicos de erro
    final errorString = e.toString();
    if (errorString.contains('PERMISSION_DENIED')) {
      debugPrint(
          '🔥 [FIREBASE] otpCall - ERRO DE PERMISSÃO: As regras do Firebase estão bloqueando o acesso');
      debugPrint(
          '🔥 [FIREBASE] otpCall - Verifique as regras do Firebase Realtime Database');
      debugPrint(
          '🔥 [FIREBASE] otpCall - O nó call_FB_OTP precisa estar acessível');
      debugPrint(
          '🔥 [FIREBASE] otpCall - Regra sugerida: {".read": true, ".write": false}');
    } else if (errorString.contains('UNAVAILABLE')) {
      debugPrint(
          '🔥 [FIREBASE] otpCall - ERRO: Firebase Database não está disponível');
    } else if (errorString.contains('NETWORK')) {
      debugPrint(
          '🔥 [FIREBASE] otpCall - ERRO DE REDE: Problema de conectividade');
    }

    if (e is SocketException) {
      internet = false;
      result = 'no Internet';
      debugPrint('🔥 [FIREBASE] otpCall - SocketException: Sem internet');
      valueNotifierHome.incrementNotifier();
    } else {
      result = 'error';
      debugPrint('🔥 [FIREBASE] otpCall - Erro desconhecido, retornando error');
    }
  }
  return result;
}

// verify user already exist

String enabledModule = '';

verifyUser(String number) async {
  dynamic val;
  try {
    // value == 0 significa login com celular, value == 1 significa login com email
    // Quando for email, o parâmetro 'number' na verdade contém o email
    final Map<String, dynamic> requestBody = (value == 0)
        ? {"mobile": number, "role": ischeckownerordriver}
        : {"email": number, "role": ischeckownerordriver};
    if (loginReferralCode.trim().isNotEmpty) {
      requestBody['referral_code'] = loginReferralCode.trim();
    }
    final requestUrl = '${url}api/v1/driver/validate-mobile-for-login';

    debugPrint('🌐 [API] verifyUser - URL: $requestUrl');
    debugPrint(
        '🌐 [API] verifyUser - Tipo de login: ${value == 0 ? "CELULAR" : "EMAIL"}');
    debugPrint('🌐 [API] verifyUser - Body: $requestBody');
    debugPrint(
        '🌐 [API] verifyUser - Parâmetro recebido (number/email): $number');
    debugPrint(
        '🌐 [API] verifyUser - value: $value, ischeckownerordriver: $ischeckownerordriver');

    // Enviar como JSON
    var response = await http.post(
      Uri.parse(requestUrl),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestBody),
    );

    debugPrint('🌐 [API] verifyUser - Status Code: ${response.statusCode}');
    debugPrint('🌐 [API] verifyUser - Response Body: ${response.body}');

    if (response.statusCode == 200) {
      val = jsonDecode(response.body)['success'];
      debugPrint('🌐 [API] verifyUser - success: $val');
      if (val == true) {
        debugPrint('🌐 [API] verifyUser - Usuário válido, fazendo login...');
        var check = await driverLogin();
        debugPrint('🌐 [API] verifyUser - driverLogin result: $check');
        if (check == true) {
          var uCheck = await getUserDetails();
          debugPrint('🌐 [API] verifyUser - getUserDetails result: $uCheck');
          val = uCheck;
        } else {
          debugPrint('🌐 [API] verifyUser - driverLogin falhou');
          val = false;
        }
      } else {
        enabledModule = jsonDecode(response.body)['enabled_module'];
        debugPrint('🌐 [API] verifyUser - enabledModule: $enabledModule');
        if (enabledModule != 'both') {
          transportType = enabledModule;
        } else {
          transportType = '';
        }
        val = false;
      }
    } else if (response.statusCode == 422) {
      debugPrint('🌐 [API] verifyUser - Erro 422 (Validation Error)');
      debugPrint('🌐 [API] verifyUser - Response: ${response.body}');
      try {
        final body = jsonDecode(response.body);
        val = formatValidationErrors(
          body['errors'],
          fallbackMessage: body['message']?.toString() ?? 'Os dados enviados são inválidos.',
        );
      } catch (_) {
        val = 'Os dados enviados são inválidos.';
      }
    } else {
      debugPrint('🌐 [API] verifyUser - Erro ${response.statusCode} (ex: 400)');
      debugPrint('🌐 [API] verifyUser - Response: ${response.body}');
      try {
        final body = jsonDecode(response.body);
        val = body['message']?.toString() ?? 'Erro na validação.';
      } catch (_) {
        val = 'Erro na validação.';
      }
    }
  } catch (e) {
    debugPrint('🌐 [API] verifyUser - EXCEÇÃO: $e');
    debugPrint('🌐 [API] verifyUser - Tipo: ${e.runtimeType}');
    if (e is SocketException) {
      val = 'no internet';
      internet = false;
      debugPrint('🌐 [API] verifyUser - SocketException: Sem internet');
    }
  }
  debugPrint('🌐 [API] verifyUser - Resultado final: $val');
  return val;
}

//driver login
driverLogin() async {
  bearerToken.clear();
  dynamic result;
  try {
    debugPrint('🌐 [API] driverLogin - Iniciando login do driver');
    var token = await FirebaseMessaging.instance.getToken();
    var fcm = token.toString();
    final requestBody = {
      "mobile": phnumber,
      'device_token': fcm,
      "login_by": kIsWeb
          ? 'android' // Backend não aceita 'web', usar 'android' como fallback
          : (platform == TargetPlatform.android)
              ? 'android'
              : 'ios',
      "role": ischeckownerordriver,
    };
    final requestUrl = '${url}api/v1/driver/login';

    debugPrint('🌐 [API] driverLogin - URL: $requestUrl');
    debugPrint('🌐 [API] driverLogin - Body: $requestBody');
    debugPrint('🌐 [API] driverLogin - phnumber: $phnumber');
    debugPrint('🌐 [API] driverLogin - FCM Token: $fcm');
    debugPrint('🌐 [API] driverLogin - platform: $platform');
    debugPrint('🌐 [API] driverLogin - role: $ischeckownerordriver');

    var response = await http.post(
      Uri.parse(requestUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    debugPrint('🌐 [API] driverLogin - Status Code: ${response.statusCode}');
    debugPrint('🌐 [API] driverLogin - Response Body: ${response.body}');

    if (response.statusCode == 200) {
      var jsonVal = jsonDecode(response.body);
      debugPrint(
          '🌐 [API] driverLogin - Token recebido: ${jsonVal['token_type']}');
      debugPrint(
          '🌐 [API] driverLogin - Access token: ${jsonVal['access_token']?.substring(0, 20)}...');

      if (ischeckownerordriver == 'driver' && !kIsWeb) {
        platforms.invokeMethod('login');
      }
      bearerToken.add(
        BearerClass(
          type: jsonVal['token_type'].toString(),
          token: jsonVal['access_token'].toString(),
        ),
      );
      result = true;
      pref.setString('Bearer', bearerToken[0].token);
      debugPrint('🌐 [API] driverLogin - Token salvo no SharedPreferences');

      if (!kIsWeb) {
        package = await PackageInfo.fromPlatform();
        if (platform == TargetPlatform.android && package != null) {
          debugPrint(
              '🔥 [FIREBASE] driverLogin - Atualizando driver_package_name: ${package.packageName}');
          await FirebaseDatabase.instance.ref().update({
            'driver_package_name': package.packageName.toString(),
          });
        } else if (package != null) {
          debugPrint(
              '🔥 [FIREBASE] driverLogin - Atualizando driver_bundle_id: ${package.packageName}');
          await FirebaseDatabase.instance.ref().update({
            'driver_bundle_id': package.packageName.toString(),
          });
        }
      } else {
        debugPrint(
            '🌐 [API] driverLogin - Web detectado - pulando atualização de package/bundle');
      }
      debugPrint('🌐 [API] driverLogin - Login realizado com sucesso');
    } else {
      debugPrint('🌐 [API] driverLogin - ERRO ${response.statusCode}');
      debugPrint('🌐 [API] driverLogin - Response: ${response.body}');
      result = false;
    }
  } catch (e) {
    debugPrint('🌐 [API] driverLogin - EXCEÇÃO: $e');
    debugPrint('🌐 [API] driverLogin - Tipo: ${e.runtimeType}');
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
      debugPrint('🌐 [API] driverLogin - SocketException: Sem internet');
    }
  }
  debugPrint('🌐 [API] driverLogin - Resultado final: $result');
  return result;
}

// void printWrapped(String text) {
//   final pattern = RegExp('.{1,800}'); // 800 is the size of each chunk
//   pattern.allMatches(text).forEach((match) => debugPrint(match.group(0)));
// }

Map<String, dynamic> userDetails = {};
List tripStops = [];
bool isBackground = false;
bool screenOn = false;
bool updateAvailable = false;
dynamic package;

//user current state
getUserDetails() async {
  dynamic result;
  try {
    final requestUrl = '${url}api/v1/user';
    final authToken =
        bearerToken.isNotEmpty ? bearerToken[0].token : 'NO_TOKEN';

    debugPrint('🌐 [API] getUserDetails - ========== BUSCAR PERFIL ==========');
    debugPrint('🌐 [API] getUserDetails - URL: $requestUrl');
    debugPrint('🌐 [API] getUserDetails - Método: GET');
    debugPrint('🌐 [API] getUserDetails - Headers: Authorization: Bearer ${authToken.substring(0, 20)}...');
    debugPrint('🌐 [API] getUserDetails - (GET não envia body)');

    var response = await http.get(
      Uri.parse(requestUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${bearerToken[0].token}',
      },
    );

    debugPrint('🌐 [API] getUserDetails - Status Code: ${response.statusCode}');
    debugPrint('🌐 [API] getUserDetails - Response Body: ${response.body}');

    if (response.statusCode == 200) {
      userDetails = jsonDecode(response.body)['data'];
      debugPrint('🌐 [API] getUserDetails - ✅ Status 200 - Perfil recebido');
      debugPrint('🌐 [API] getUserDetails - userDetails ID: ${userDetails['id']}');
      debugPrint('🌐 [API] getUserDetails - userDetails role: ${userDetails['role']}');
      debugPrint('🌐 [API] getUserDetails - userDetails name: ${userDetails['name']}');
      debugPrint('🌐 [API] getUserDetails - userDetails email: ${userDetails['email']}');
      debugPrint('🌐 [API] getUserDetails - userDetails mobile: ${userDetails['mobile']}');
      debugPrint('🌐 [API] getUserDetails - userDetails document (CPF): ${userDetails['document']}');
      debugPrint('🌐 [API] getUserDetails - userDetails birth_date: ${userDetails['birth_date']}');
      debugPrint('🌐 [API] getUserDetails - userDetails gender: ${userDetails['gender']}');
      debugPrint('🌐 [API] getUserDetails - userDetails passenger_preference: ${userDetails['passenger_preference']}');
      debugPrint('🌐 [API] getUserDetails - userDetails postal_code: ${userDetails['postal_code']}');
      debugPrint('🌐 [API] getUserDetails - userDetails address: ${userDetails['address']}');
      debugPrint('🌐 [API] getUserDetails - userDetails address_number: ${userDetails['address_number']}');
      debugPrint('🌐 [API] getUserDetails - userDetails complement: ${userDetails['complement']}');
      debugPrint('🌐 [API] getUserDetails - userDetails neighborhood: ${userDetails['neighborhood']}');
      debugPrint('🌐 [API] getUserDetails - userDetails city: ${userDetails['city']}');
      debugPrint('🌐 [API] getUserDetails - userDetails state: ${userDetails['state']}');
      debugPrint('🌐 [API] getUserDetails - userDetails active: ${userDetails['active']}');
      debugPrint('🌐 [API] getUserDetails - userDetails approve: ${userDetails['approve']}');

      if (userDetails['notifications_count'] != 0 &&
          userDetails['notifications_count'] != null) {
        valueNotifierNotification.incrementNotifier();
      }
      transportType = userDetails['transport_type'];
      debugPrint('🌐 [API] getUserDetails - transportType: $transportType');
      if (userDetails['role'] != 'owner') {
        if (userDetails['sos'] != null && userDetails['sos']['data'] != null) {
          sosData = userDetails['sos']['data'];
        }
        if (userDetails['onTripRequest'] != null) {
          driverReq = userDetails['onTripRequest']['data'];

          if (payby == 0 && driverReq['is_paid'] == 1) {
            payby = 1;
            //audioPlayer.play(audio);
          }
          if (driverReq['is_driver_arrived'] == 1 &&
              driverReq['is_trip_start'] == 0 &&
              arrivedTimer == null &&
              driverReq['is_rental'] != true &&
              driverReq['is_bid_ride'] != 1) {
            waitingBeforeStart();
          }
          if (driverReq['is_completed'] == 0 &&
              driverReq['is_trip_start'] == 1 &&
              rideTimer == null &&
              driverReq['is_rental'] != true &&
              driverReq['is_bid_ride'] != 1) {
            waitingAfterStart();
          }

          if (driverReq['accepted_at'] != null) {
            getCurrentMessages();
          }
          final reqStops = userDetails['onTripRequest']?['data']?['requestStops']?['data'];
          tripStops = reqStops ?? tripStops;

          valueNotifierHome.incrementNotifier();
        } else if (userDetails['metaRequest'] != null) {
          driverReject = false;
          userReject = false;
          driverReq = userDetails['metaRequest']['data'];
          final metaStops = userDetails['metaRequest']?['data']?['requestStops']?['data'];
          tripStops = metaStops ?? tripStops;

          if (duration == 0 || duration == 0.0) {
            if (isBackground == true &&
                platform == TargetPlatform.android &&
                !kIsWeb) {
              platforms.invokeMethod('awakeapp');
            }
            duration = double.parse(
              userDetails['trip_accept_reject_duration_for_driver'].toString(),
            );
            sound();
          }
        } else {
          // printWrapped(userDetails['metaRequest']['data'].toString());
          duration = 0;
          if (driverReq.isNotEmpty) {
            //audioPlayer.play(audio);
          }
          chatList.clear();
          tripStops.clear();
          driverReq = {};
          valueNotifierHome.incrementNotifier();
        }
        if (userDetails['active'] == false) {
          isActive = 'false';
        } else {
          if (screenOn == false) {
            if (platform == TargetPlatform.android && !kIsWeb) {
              platforms.invokeMethod('keepon');
            }
            screenOn = true;
          }
          isActive = 'true';
        }
      }
      result = true;
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = false;
    }
  } catch (e) {
    debugPrint('🌐 [API] getUserDetails - EXCEÇÃO: $e');
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    } else {
      result = false;
    }
  }
  return result;
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
bool userReject = false;

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
    value.value++;
  }
}

class ValueNotifyingNotification {
  ValueNotifier value = ValueNotifier(0);

  void incrementNotifier() {
    value.value++;
  }
}

class ValueNotifyingTimer {
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

class ValueNotifyingChat {
  ValueNotifier value = ValueNotifier(0);

  void incrementNotifier() {
    value.value++;
  }
}

ValueNotifying valueNotifierHome = ValueNotifying();
ValueNotifying valueNotifiercheck = ValueNotifying();
ValueNotifyingNotification valueNotifierNotification =
    ValueNotifyingNotification();
ValueNotifyingTimer valueNotifierTimer = ValueNotifyingTimer();
ValueNotifyingLogin valueNotifierLogin = ValueNotifyingLogin();
ValueNotifyingChat valueNotifierChat = ValueNotifyingChat();

//driver online offline status
driverStatus() async {
  dynamic result;
  try {
    var response = await http.post(
      Uri.parse('${url}api/v1/driver/online-offline'),
      headers: {'Authorization': 'Bearer ${bearerToken[0].token}'},
    );
    if (response.statusCode == 200) {
      userDetails = jsonDecode(response.body)['data'];
      result = true;
      if (userDetails['active'] == false) {
        if (screenOn == true) {
          if (platform == TargetPlatform.android && !kIsWeb) {
            platforms.invokeMethod('keepoff');
            screenOn = false;
          }
        }

        rideStart?.cancel();
        rideStart = null;
        userInactive();
      } else {
        if (screenOn == false) {
          if (platform == TargetPlatform.android && !kIsWeb) {
            platforms.invokeMethod('keepon');
            screenOn = true;
          }
        }
        userActive();
      }
      valueNotifierHome.incrementNotifier();
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

const platforms = MethodChannel('flutter.app/awake');

//update driver location in firebase

Location location = Location();

currentPositionUpdate() async {
  geolocs.LocationPermission permission;
  GeoHasher geo = GeoHasher();

  Timer.periodic(const Duration(seconds: 5), (timer) async {
    if (userDetails.isNotEmpty && userDetails['role'] == 'driver') {
      serviceEnabled =
          await geolocs.GeolocatorPlatform.instance.isLocationServiceEnabled();
      permission = await geolocs.GeolocatorPlatform.instance.checkPermission();

      if (userDetails['active'] == true &&
          serviceEnabled == true &&
          permission != geolocs.LocationPermission.denied &&
          permission != geolocs.LocationPermission.deniedForever) {
        if (driverReq.isEmpty) {
          if (requestStreamStart == null ||
              requestStreamStart?.isPaused == true) {
            streamRequest();
          }

          if ((rideStart == null || rideStart?.isPaused == true) &&
              (center != null)) {
            rideRequest();
          }
        } else if (driverReq.isNotEmpty && driverReq['accepted_at'] != null) {
          if (rideStreamStart == null ||
              rideStreamStart?.isPaused == true ||
              rideStreamChanges == null ||
              rideStreamChanges?.isPaused == true) {
            streamRide();
          }
        }

        if (positionStream == null || positionStream!.isPaused) {
          positionStreamData();
        }

        final firebase = FirebaseDatabase.instance.ref();

        try {
          firebase.child('drivers/driver_${userDetails['id']}').update({
            'bearing': heading,
            'date': DateTime.now().toString(),
            'id': userDetails['id'],
            'g': geo.encode(
              double.parse(center.longitude.toString()),
              double.parse(center.latitude.toString()),
            ),
            'is_active': userDetails['active'] == true ? 1 : 0,
            'is_available': userDetails['available'],
            'l': {'0': center.latitude, '1': center.longitude},
            'mobile': userDetails['mobile'],
            'name': userDetails['name'],
            'vehicle_type_icon': userDetails['vehicle_type_icon_for'],
            'updated_at': ServerValue.timestamp,
            'vehicle_number': userDetails['car_number'],
            'vehicle_type_name': userDetails['car_make_name'],
            'vehicle_type': userDetails['vehicle_type_id'],
            'vehicle_types': userDetails['vehicle_types'],
            'ownerid': userDetails['owner_id'],
            'service_location_id': userDetails['service_location_id'],
            'transport_type': userDetails['transport_type'],
          });
          if (driverReq.isNotEmpty) {
            if (driverReq['accepted_at'] != null &&
                driverReq['is_completed'] == 0) {
              requestDetailsUpdate(
                double.parse(heading.toString()),
                double.parse(center.latitude.toString()),
                double.parse(center.longitude.toString()),
              );
            }
          }

          valueNotifierHome.incrementNotifier();
        } catch (e) {
          if (e is SocketException) {
            internet = false;
            valueNotifierHome.incrementNotifier();
          }
        }
      } else if (userDetails['active'] == false &&
          serviceEnabled == true &&
          permission != geolocs.LocationPermission.denied &&
          permission != geolocs.LocationPermission.deniedForever) {
        if (positionStream == null || positionStream!.isPaused) {
          positionStreamData();
        }
      } else if (serviceEnabled == false && userDetails['active'] == true) {
        await driverStatus();
        // await location.requestService();
        await geolocs.Geolocator.getCurrentPosition(
          desiredAccuracy: geolocs.LocationAccuracy.low,
        );
      }
      if (userDetails['role'] == 'driver') {
        var driverState = await FirebaseDatabase.instance
            .ref('drivers/driver_${userDetails['id']}')
            .get();
        if (driverState.child('approve').value == 0 &&
            userDetails['approve'] == true) {
          await getUserDetails();
          if (userDetails['active'] == true) {
            await driverStatus();
          }
          valueNotifierHome.incrementNotifier();
          //audioPlayer.play(audio);
        } else if (driverState.child('approve').value == 1 &&
            userDetails['approve'] == false) {
          await getUserDetails();
          valueNotifierHome.incrementNotifier();

          //audioPlayer.play(audio);
        }
        if (driverState.child('fleet_changed').value == 1) {
          FirebaseDatabase.instance
              .ref()
              .child('drivers/driver_${userDetails['id']}')
              .update({'fleet_changed': 0});
          await getUserDetails();
          valueNotifierHome.incrementNotifier();

          //audioPlayer.play(audio);
        }
        if (driverState.child('is_deleted').value == 1) {
          FirebaseDatabase.instance
              .ref()
              .child('drivers/driver_${userDetails['id']}')
              .remove();
          await getUserDetails();
          valueNotifierHome.incrementNotifier();
        }
        if (driverState.key!.contains('vehicle_type_icon')) {
          if (driverState.child('vehicle_type_icon') !=
              userDetails['vehicle_type_icon_for']) {
            FirebaseDatabase.instance
                .ref()
                .child('drivers/driver_${userDetails['id']}')
                .update({
              'vehicle_type_icon': userDetails['vehicle_type_icon_for'],
            });
          }
        } else {
          FirebaseDatabase.instance
              .ref()
              .child('drivers/driver_${userDetails['id']}')
              .update({
            'vehicle_type_icon': userDetails['vehicle_type_icon_for'],
          });
        }
      }
    } else if (userDetails['role'] == 'owner') {
      var ownerStatus = await FirebaseDatabase.instance
          .ref('owners/owner_${userDetails['id']}')
          .get();
      if (ownerStatus.child('approve').value == 0 &&
          userDetails['approve'] == true) {
        await getUserDetails();

        valueNotifierHome.incrementNotifier();
      } else if (ownerStatus.child('approve').value == 1 &&
          userDetails['approve'] == false) {
        await getUserDetails();
        valueNotifierHome.incrementNotifier();
      }
    }
  });
}

//add request details in firebase realtime database

List latlngArray = [];
dynamic lastLat;
dynamic lastLong;
dynamic totalDistance;

requestDetailsUpdate(double bearing, double lat, double lng) async {
  final firebase = FirebaseDatabase.instance.ref();
  if (driverReq['is_trip_start'] == 1 && driverReq['is_completed'] == 0) {
    if (totalDistance == null) {
      var dist = await FirebaseDatabase.instance
          .ref('requests/${driverReq['id']}')
          .get();
      var array = await FirebaseDatabase.instance
          .ref('requests/${driverReq['id']}')
          .get();
      if (dist.child('distance').value != null) {
        totalDistance = dist.child('distance').value;
      }
      if (array.child('lat_lng_array').value != null) {
        latlngArray = jsonDecode(
          jsonEncode(array.child('lat_lng_array').value),
        );
        lastLat = latlngArray[latlngArray.length - 1]['lat'];
        lastLong = latlngArray[latlngArray.length - 1]['lng'];
      }
    }
    if (latlngArray.isEmpty) {
      latlngArray.add({'lat': lat, 'lng': lng});
      lastLat = lat;
      lastLong = lng;
    } else {
      var distance = await calculateDistance(lastLat, lastLong, lat, lng);
      if (distance >= 150.0) {
        latlngArray.add({'lat': lat, 'lng': lng});
        lastLat = lat;
        lastLong = lng;

        if (totalDistance == null) {
          totalDistance = distance / 1000;
        } else {
          totalDistance = ((totalDistance * 1000) + distance) / 1000;
        }
      }
    }
  }

  try {
    firebase.child('requests/${driverReq['id']}').update({
      'bearing': bearing,
      'distance': (totalDistance == null) ? 0.0 : totalDistance,
      'driver_id': userDetails['id'],
      'user_id': driverReq['userDetail']['data']['id'],
      'is_cancelled': (driverReq['is_cancelled'] == 0) ? false : true,
      'is_completed': (driverReq['is_completed'] == 0) ? false : true,
      'lat': lat,
      'lng': lng,
      'lat_lng_array': latlngArray,
      'request_id': driverReq['id'],
      'trip_arrived': (driverReq['is_driver_arrived'] == 0) ? "0" : "1",
      'trip_start': (driverReq['is_trip_start'] == 0) ? "0" : "1",
      'vehicle_type_icon': userDetails['vehicle_type_icon_for'],
      'transport_type': userDetails['transport_type'],
    });
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      valueNotifierHome.incrementNotifier();
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

userInactive() {
  final firebase = FirebaseDatabase.instance.ref();
  firebase.child('drivers/driver_${userDetails['id']}').update({
    'is_active': 0,
  });
}

userActive() {
  final firebase = FirebaseDatabase.instance.ref();
  firebase.child('drivers/driver_${userDetails['id']}').update({
    'is_active': 1,
    'l': {'0': center.latitude, '1': center.longitude},
    'updated_at': ServerValue.timestamp,
    'is_available': userDetails['available'],
  });
}

calculateIdleDistance(lat1, lon1, lat2, lon2) {
  var p = 0.017453292519943295;
  var a = 0.5 -
      cos((lat2 - lat1) * p) / 2 +
      cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
  var val = (12742 * asin(sqrt(a))) * 1000;
  return val;
}

//driver request accept

requestAccept() async {
  dynamic result;
  try {
    var response = await http.post(
      Uri.parse('${url}api/v1/request/respond'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'request_id': driverReq['id'], 'is_accept': 1}),
    );

    if (response.statusCode == 200) {
      FirebaseDatabase.instance.ref('request-meta/${driverReq['id']}').remove();
      driverReq.clear();

      // AwesomeNotifications().cancel(7425);

      if (jsonDecode(response.body)['message'] == 'success') {
        if (audioPlayers.state != PlayerState.stopped) {
          audioPlayers.stop();
          // audioPlayers.dispose();
        }
        dropDistance = '';

        await getUserDetails();

        if (driverReq.isNotEmpty) {
          FirebaseDatabase.instance
              .ref()
              .child('drivers/driver_${userDetails['id']}')
              .update({'is_available': false});
          duration = 0;
          _cancelRequestStreams();
          requestStreamEnd?.cancel();
          requestStreamEnd = null;
          if (rideStreamStart == null ||
              rideStreamStart?.isPaused == true ||
              rideStreamChanges == null ||
              rideStreamChanges?.isPaused == true) {
            streamRide();
          }
          requestDetailsUpdate(
            double.parse(heading.toString()),
            center.latitude,
            center.longitude,
          );
        }
        valueNotifierHome.incrementNotifier();
      }
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
      valueNotifierHome.incrementNotifier();
    }
  }
}

//driver request reject

bool driverReject = false;

requestReject() async {
  dynamic result;

  try {
    var response = await http.post(
      Uri.parse('${url}api/v1/request/respond'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'request_id': driverReq['id'], 'is_accept': 0}),
    );

    if (response.statusCode == 200) {
      requestStreamEnd?.cancel();
      requestStreamEnd = null;
      // AwesomeNotifications().cancel(7425);
      if (jsonDecode(response.body)['message'] == 'success') {
        if (audioPlayers.state != PlayerState.stopped) {
          audioPlayers.stop();
          // audioPlayers.dispose();
        }
        final firebase = FirebaseDatabase.instance.ref();
        firebase.child('request-meta/${driverReq['id']}/driver_id').remove();
        driverReject = true;
        driverReq.clear();
        // await getUserDetails();
        duration = 0;
        userActive();
        valueNotifierHome.incrementNotifier();
      }
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
      valueNotifierHome.incrementNotifier();
    }
  }
}

audioPlay() async {
  audioPlayers.play(AssetSource('audio/request_sound.mp3'));
  // audioPlayers = await audioPlayer.play('audio/request_sound.mp3');
}

//sound

sound() async {
  audioPlay();
  Timer.periodic(const Duration(seconds: 1), (timer) async {
    if (duration > 0.0 &&
        driverReq['accepted_at'] == null &&
        driverReq.isNotEmpty) {
      duration--;

      if (audioPlayers.state == PlayerState.completed) {
        audioPlay();
      }
      valueNotifierHome.incrementNotifier();
    } else if (driverReq.isNotEmpty &&
        driverReq['accepted_at'] == null &&
        duration <= 0.0) {
      timer.cancel();
      if (audioPlayers.state != PlayerState.stopped) {
        audioPlayers.stop();
        // audioPlayers.dispose();
      }
      Future.delayed(const Duration(seconds: 2), () {
        requestReject();
      });
      duration = 0;
    } else {
      if (audioPlayers.state != PlayerState.stopped) {
        audioPlayers.stop();
        // audioPlayers.dispose();
      }
      timer.cancel();
      duration = 0;
    }
  });
}

//driver arrived

driverArrived() async {
  dynamic result;
  try {
    var response = await http.post(
      Uri.parse('${url}api/v1/request/arrived'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'request_id': driverReq['id']}),
    );
    if (response.statusCode == 200) {
      if (jsonDecode(response.body)['message'] == 'driver_arrived') {
        waitingBeforeTime = 0;
        waitingTime = 0;
        await getUserDetails();
        FirebaseDatabase.instance.ref('requests').child(driverReq['id']).update(
          {'trip_arrived': '1'},
        );
        valueNotifierHome.incrementNotifier();
      }
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
      valueNotifierHome.incrementNotifier();
    }
  }
}

//opening google map

openMap(lat, lng) async {
  try {
    String googleUrl =
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng';

    // ignore: deprecated_member_use
    if (await canLaunch(googleUrl)) {
      // ignore: deprecated_member_use
      await launch(googleUrl);
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

//trip start with otp

tripStart() async {
  dynamic result;
  try {
    var response = await http.post(
      Uri.parse('${url}api/v1/request/started'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'request_id': driverReq['id'],
        'pick_lat': driverReq['pick_lat'],
        'pick_lng': driverReq['pick_lng'],
        'ride_otp': driverOtp,
      }),
    );
    if (response.statusCode == 200) {
      result = 'success';
      await getUserDetails();
      FirebaseDatabase.instance.ref('requests').child(driverReq['id']).update({
        'trip_start': '1',
      });
      valueNotifierHome.incrementNotifier();
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

//trip start without otp

tripStartDispatcher() async {
  dynamic result;
  try {
    var response = await http.post(
      Uri.parse('${url}api/v1/request/started'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'request_id': driverReq['id'],
        'pick_lat': driverReq['pick_lat'],
        'pick_lng': driverReq['pick_lng'],
      }),
    );
    if (response.statusCode == 200) {
      result = 'success';
      await getUserDetails();
      FirebaseDatabase.instance.ref('requests').child(driverReq['id']).update({
        'trip_start': '1',
      });
      valueNotifierHome.incrementNotifier();
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

class AddressList {
  String address;
  LatLng latlng;
  String id;

  AddressList({required this.id, required this.address, required this.latlng});
}

Map etaDetails = {};

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
      body: jsonEncode({
        'pick_lat':
            addressList.firstWhere((e) => e.id == 'pickup').latlng.latitude,
        'pick_lng':
            addressList.firstWhere((e) => e.id == 'pickup').latlng.longitude,
        'drop_lat':
            addressList.firstWhere((e) => e.id == 'drop').latlng.latitude,
        'drop_lng':
            addressList.firstWhere((e) => e.id == 'drop').latlng.longitude,
        'ride_type': 1,
      }),
    );

    if (response.statusCode == 200) {
      etaDetails = jsonDecode(response.body)['data'];
      result = true;
      valueNotifierHome.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint('🌐 [API] etaRequest - Erro ${response.statusCode}');
      debugPrint('🌐 [API] etaRequest - Response: ${response.body}');
      try {
        var errorBody = jsonDecode(response.body);
        if (errorBody['message'] != null) {
          result = errorBody['message'];
        } else if (errorBody['errors'] != null) {
          // Se houver erros de validação, pegar o primeiro
          var errors = errorBody['errors'];
          if (errors is Map && errors.isNotEmpty) {
            var firstError = errors.values.first;
            if (firstError is List && firstError.isNotEmpty) {
              result = firstError[0].toString();
            } else {
              result = firstError.toString();
            }
          } else {
            result = 'Erro ao processar solicitação';
          }
        } else {
          result = 'Erro ao processar solicitação';
        }

        if (errorBody['message'] ==
            "service not available with this location") {
          serviceNotAvailable = true;
        }
      } catch (e) {
        debugPrint('🌐 [API] etaRequest - Erro ao decodificar resposta: $e');
        result = 'Erro ao processar solicitação';
      }
    }
    return result;
  } catch (e) {
    debugPrint('🌐 [API] etaRequest - EXCEÇÃO: $e');
    if (e is SocketException) {
      internet = false;
      result = 'Sem conexão com a internet';
    } else {
      result = 'Erro ao processar solicitação: $e';
    }
    return result;
  }
}

//geocodeing location

geoCodingForLatLng(placeid) async {
  dynamic location;
  try {
    var response = await http.get(
      Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json?placeid=$placeid&key=$mapkey',
      ),
    );

    if (response.statusCode == 200) {
      var val = jsonDecode(response.body)['result']['geometry']['location'];
      location = LatLng(val['lat'], val['lng']);
    } else {
      debugPrint(response.body);
    }
    return location;
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

//create instant ride

//create request

createRequest(name, phone) async {
  dynamic result;
  try {
    var response = await http.post(
      Uri.parse('${url}api/v1/request/create-instant-ride'),
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
        'ride_type': 1,
        'pick_address': addressList.firstWhere((e) => e.id == 'pickup').address,
        'drop_address': addressList.firstWhere((e) => e.id == 'drop').address,
        'name': name,
        'mobile': phone,
      }),
    );
    if (response.statusCode == 200) {
      // print(response.body);
      await getUserDetails();
      result = 'success';
      // valueNotifierHome.incrementNotifier();
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

//get auto fill address

List storedAutoAddress = [];
List addAutoFill = [];

getAutoAddress(input, sessionToken, lat, lng) async {
  dynamic response;
  var countryCode = userDetails['country_code'];
  try {
    if (userDetails['enable_country_restrict_on_map'] == '1' &&
        userDetails['country_code'] != null) {
      response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&library=places&location=$lat%2C$lng&radius=2000&components=country:$countryCode&key=$mapkey&sessiontoken=$sessionToken',
        ),
      );
    } else {
      response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&library=places&key=$mapkey&sessiontoken=$sessionToken',
        ),
      );
    }
    if (response.statusCode == 200) {
      addAutoFill = jsonDecode(response.body)['predictions'];
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
      pref.setString('autoAddress', jsonEncode(storedAutoAddress).toString());
      valueNotifierHome.incrementNotifier();
    } else {
      debugPrint(response.body);
      valueNotifierHome.incrementNotifier();
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

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

//ending trip

endTrip() async {
  dynamic result;
  try {
    await requestDetailsUpdate(
      double.parse(heading.toString()),
      center.latitude,
      center.longitude,
    );
    var dropAddress = await geoCoding(center.latitude, center.longitude);
    var db = await FirebaseDatabase.instance
        .ref('requests/${driverReq['id']}')
        .get();

    double dist = double.parse(
      double.parse(db.child('distance').value.toString()).toStringAsFixed(2),
    );
    var reqId = driverReq['id'];

    final firebase = FirebaseDatabase.instance.ref();
    firebase.child('requests/${driverReq['id']}').update({
      'bearing': heading,
      'is_cancelled': (driverReq['is_cancelled'] == 0) ? false : true,
      'is_completed': false,
      'lat': center.latitude,
      'lng': center.longitude,
      'lat_lng_array': latlngArray,
      'request_id': driverReq['id'],
      'trip_arrived': "1",
      'trip_start': "1",
    });

    var response = await http.post(
      Uri.parse('${url}api/v1/request/end'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'request_id': driverReq['id'],
        'distance': dist,
        'before_arrival_waiting_time': 0,
        'after_arrival_waiting_time': 0,
        'drop_lat': center.latitude,
        'drop_lng': center.longitude,
        'drop_address': dropAddress,
        'before_trip_start_waiting_time': (waitingBeforeTime != null &&
                waitingBeforeTime > 60 &&
                driverReq['is_rental'] != true)
            ? (waitingBeforeTime / 60).toInt()
            : 0,
        'after_trip_start_waiting_time': (waitingAfterTime != null &&
                waitingAfterTime > 60 &&
                driverReq['is_rental'] != true)
            ? (waitingAfterTime / 60).toInt()
            : 0,
      }),
    );
    if (response.statusCode == 200) {
      await getUserDetails();
      FirebaseDatabase.instance.ref('requests').child(reqId).update({
        'is_completed': true,
      });
      totalDistance = null;
      lastLat = null;
      lastLong = null;
      waitingTime = null;
      waitingBeforeTime = null;
      waitingAfterTime = null;
      latlngArray.clear();
      polyList.clear();
      chatList.clear();
      driverOtp = '';
      waitingAfterTime = null;
      waitingBeforeTime = null;
      waitingTime = null;
      result = 'success';
      valueNotifierHome.incrementNotifier();
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

// upload drop goods image

uploadSignatureImage() async {
  dynamic result;

  try {
    var response = http.MultipartRequest(
      'POST',
      Uri.parse('${url}api/v1/request/upload-proof'),
    );
    response.headers.addAll({
      'Authorization': 'Bearer ${bearerToken[0].token}',
    });
    response.files.add(
      await http.MultipartFile.fromPath('proof_image', signatureFile.path),
    );
    response.fields['after_unload'] = '1';
    response.fields['request_id'] = driverReq['id'];
    var request = await response.send();
    var respon = await http.Response.fromStream(request);
    final val = jsonDecode(respon.body);
    if (request.statusCode == 200) {
      await endTrip();
      result = 'success';
    } else if (request.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(val);
      result = 'failed';
    }
  } catch (e) {
    if (e is SocketException) {
      result = 'no internet';
      internet = false;
    }
  }
  return result;
}

dynamic heading = 0.0;

//get polylines

List<LatLng> polyList = [];
String dropDistance = '';

getPolylines() async {
  polyList.clear();
  String pickLat;
  String pickLng;
  String dropLat;
  String dropLng;
  if (tripStops.isEmpty) {
    if (driverReq.isNotEmpty) {
      pickLat = driverReq['pick_lat'].toString();
      pickLng = driverReq['pick_lng'].toString();
      dropLat = driverReq['drop_lat'].toString();
      dropLng = driverReq['drop_lng'].toString();
    } else {
      pickLat = choosenRide[0]['pick_lat'].toString();
      pickLng = choosenRide[0]['pick_lng'].toString();
      dropLat = choosenRide[0]['drop_lat'].toString();
      dropLng = choosenRide[0]['drop_lng'].toString();
    }
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
  } else {
    for (var i = 0; i < tripStops.length; i++) {
      if (i == 0) {
        if (driverReq.isNotEmpty) {
          pickLat = driverReq['pick_lat'].toString();
          pickLng = driverReq['pick_lng'].toString();
        } else {
          pickLat = choosenRide[0]['pick_lat'].toString();
          pickLng = choosenRide[0]['pick_lng'].toString();
        }
        dropLat = tripStops[i]['latitude'].toString();
        dropLng = tripStops[i]['longitude'].toString();
      } else {
        pickLat = tripStops[i - 1]['latitude'].toString();
        pickLng = tripStops[i - 1]['longitude'].toString();
        dropLat = tripStops[i]['latitude'].toString();
        dropLng = tripStops[i]['longitude'].toString();
      }
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
  }

  return polyList;
}

//polyline decode

Set<Polyline> polyline = {};

List<PointLatLng> decodeEncodedPolyline(String encoded) {
  polyline.clear();
  List<PointLatLng> poly = [];
  int index = 0, len = encoded.length;
  int lat = 0, lng = 0;

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
      visible: true,
      color: const Color(0xffFD9898),
      width: 4,
      points: polyList,
    ),
  );
  valueNotifierHome.incrementNotifier();
  return poly;
}

/// Note instead of using the class,
/// you can use Google LatLng() by importing it from their library.
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
        'request_id': driverReq['id'],
        'rating': review,
        'comment': feedback,
      }),
    );
    if (response.statusCode == 200) {
      FirebaseDatabase.instance
          .ref()
          .child('drivers/driver_${userDetails['id']}')
          .update({'is_available': true});
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

//making call to user

makingPhoneCall(phnumber) async {
  var mobileCall = 'tel:$phnumber';
  // ignore: deprecated_member_use
  if (await canLaunch(mobileCall)) {
    // ignore: deprecated_member_use
    await launch(mobileCall);
  } else {
    throw 'Could not launch $mobileCall';
  }
}

//request cancel by driver

cancelRequestDriver(reason) async {
  dynamic result;
  try {
    var response = await http.post(
      Uri.parse('${url}api/v1/request/cancel/by-driver'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'request_id': driverReq['id'],
        'custom_reason': reason,
      }),
    );

    if (response.statusCode == 200) {
      if (jsonDecode(response.body)['success'] == true) {
        await FirebaseDatabase.instance
            .ref()
            .child('requests/${driverReq['id']}')
            .update({'cancelled_by_driver': true});
        result = true;
        await getUserDetails();
        userActive();
        valueNotifierHome.incrementNotifier();
      } else {
        result = false;
      }
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

//sos data
List sosData = [];

//get current ride messages

List chatList = [];

getCurrentMessages() async {
  dynamic result;
  try {
    var response = await http.get(
      Uri.parse('${url}api/v1/request/chat-history/${driverReq['id']}'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      if (jsonDecode(response.body)['success'] == true) {
        if (chatList.where((element) => element['from_type'] == 1).length !=
            jsonDecode(
              response.body,
            )['data']
                .where((element) => element['from_type'] == 1)
                .length) {
          //audioPlayer.play(audio);
        }
        chatList = jsonDecode(response.body)['data'];
        valueNotifierHome.incrementNotifier();
      }
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

//send chat

sendMessage(chat) async {
  dynamic result;
  try {
    var response = await http.post(
      Uri.parse('${url}api/v1/request/send'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'request_id': driverReq['id'], 'message': chat}),
    );
    if (response.statusCode == 200) {
      getCurrentMessages();
      FirebaseDatabase.instance.ref('requests/${driverReq['id']}').update({
        'message_by_driver': chatList.length,
      });
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

//message seen

messageSeen() async {
  var response = await http.post(
    Uri.parse('${url}api/v1/request/seen'),
    headers: {
      'Authorization': 'Bearer ${bearerToken[0].token}',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({'request_id': driverReq['id']}),
  );
  if (response.statusCode == 200) {
    getCurrentMessages();
  } else {
    debugPrint(response.body);
  }
}

//cancellation reason
List cancelReasonsList = [];
cancelReason(reason) async {
  dynamic result;
  try {
    var response = await http.get(
      Uri.parse(
        '${url}api/v1/common/cancallation/reasons?arrived=$reason&transport_type=${driverReq['transport_type']}',
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

//open url in browser

openBrowser(browseUrl) async {
  try {
    // ignore: deprecated_member_use
    if (await canLaunch(browseUrl)) {
      // ignore: deprecated_member_use
      await launch(browseUrl);
    } else {
      throw 'Could not launch $browseUrl';
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

//manage vehicle

List vehicledata = [];

getVehicleInfo() async {
  dynamic result;
  try {
    var response = await http.get(
      Uri.parse('${url}api/v1/owner/list-fleets'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      result = 'success';
      vehicledata = jsonDecode(response.body)['data'];
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(vehicledata.toString());
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

deletefleetdriver(driverid) async {
  dynamic result;
  try {
    var response = await http.get(
      Uri.parse('${url}api/v1/owner/delete-driver/$driverid'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      FirebaseDatabase.instance.ref().child('drivers/driver_$driverid').update({
        'is_deleted': 1,
      });
      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(vehicledata.toString());
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

//update driver vehicle

updateVehicle() async {
  dynamic result;
  try {
    var response = await http.post(
      Uri.parse('${url}api/v1/user/driver-profile'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "service_location_id": myServiceId,
        "is_company_driver": false,
        "vehicle_types": jsonEncode(vehicletypelist),
        "car_make": vehicleMakeId,
        "car_model": vehicleModelId,
        "car_color": vehicleColor,
        "car_number": vehicleNumber,
        "vehicle_year": modelYear,
        'custom_make': mycustommake,
        'custom_model': mycustommodel,
      }),
    );

    if (response.statusCode == 200) {
      await getUserDetails();
      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else if (response.statusCode == 422) {
      debugPrint(response.body);
      try {
        final errBody = jsonDecode(response.body);
        result = formatValidationErrors(
          errBody['errors'],
          fallbackMessage: errBody['message']?.toString() ?? 'Os dados enviados são inválidos.',
        );
      } catch (_) {
        result = 'Os dados enviados são inválidos.';
      }
    } else {
      debugPrint(response.body);
      try {
        final errBody = jsonDecode(response.body);
        result = errBody['message']?.toString() ?? 'Erro ao atualizar veículo.';
      } catch (_) {
        result = 'failure';
      }
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

//edit user profile

updateProfile(name, email) async {
  dynamic result;
  try {
    var response = http.MultipartRequest(
      'POST',
      Uri.parse('${url}api/v1/user/driver-profile'),
    );
    response.headers.addAll({
      'Authorization': 'Bearer ${bearerToken[0].token}',
    });
    if (proImageFile != null) {
      response.files.add(
        await http.MultipartFile.fromPath('profile_picture', proImageFile),
      );
    }

    response.fields['email'] = email;
    response.fields['name'] = name;
    response.fields['birth_date'] = userBirthDate.toString();
    response.fields['gender'] = userGender.toString();
    response.fields['passenger_preference'] = userPassengerPreference.toString();
    response.fields['postal_code'] = userCep.toString();
    response.fields['address'] = userAddress.toString();
    response.fields['address_number'] = userNumber.toString();
    response.fields['complement'] = userComplement.toString();
    response.fields['neighborhood'] = userNeighborhood.toString();
    response.fields['city'] = userCity.toString();
    response.fields['state'] = userState.toString();

    debugPrint('🌐 [API] updateProfile - ========== ATUALIZAR PERFIL (com imagem?) ==========');
    debugPrint('🌐 [API] updateProfile - URL: ${url}api/v1/user/driver-profile');
    debugPrint('🌐 [API] updateProfile - Método: POST (multipart/form-data)');
    debugPrint('🌐 [API] updateProfile - Parâmetros enviados:');
    for (final entry in response.fields.entries) {
      debugPrint('🌐 [API] updateProfile -   ${entry.key}: ${entry.value}');
    }
    debugPrint('🌐 [API] updateProfile - profile_picture: ${proImageFile != null ? "arquivo anexado ($proImageFile)" : "não enviado"}');

    var request = await response.send();
    var respon = await http.Response.fromStream(request);
    final val = jsonDecode(respon.body);
    debugPrint('🌐 [API] updateProfile - Status Code: ${request.statusCode}');
    debugPrint('🌐 [API] updateProfile - Response: ${respon.body.length > 300 ? respon.body.substring(0, 300) + "..." : respon.body}');
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
      Uri.parse('${url}api/v1/user/driver-profile'),
    );
    response.headers.addAll({
      'Authorization': 'Bearer ${bearerToken[0].token}',
    });
    response.fields['email'] = email;
    response.fields['name'] = name;
    response.fields['birth_date'] = userBirthDate.toString();
    response.fields['gender'] = userGender.toString();
    response.fields['passenger_preference'] = userPassengerPreference.toString();
    response.fields['postal_code'] = userCep.toString();
    response.fields['address'] = userAddress.toString();
    response.fields['address_number'] = userNumber.toString();
    response.fields['complement'] = userComplement.toString();
    response.fields['neighborhood'] = userNeighborhood.toString();
    response.fields['city'] = userCity.toString();
    response.fields['state'] = userState.toString();

    debugPrint('🌐 [API] updateProfileWithoutImage - ========== ATUALIZAR PERFIL (sem imagem) ==========');
    debugPrint('🌐 [API] updateProfileWithoutImage - URL: ${url}api/v1/user/driver-profile');
    debugPrint('🌐 [API] updateProfileWithoutImage - Método: POST (multipart/form-data)');
    debugPrint('🌐 [API] updateProfileWithoutImage - Parâmetros enviados:');
    for (final entry in response.fields.entries) {
      debugPrint('🌐 [API] updateProfileWithoutImage -   ${entry.key}: ${entry.value}');
    }

    var request = await response.send();
    var respon = await http.Response.fromStream(request);
    final val = jsonDecode(respon.body);
    debugPrint('🌐 [API] updateProfileWithoutImage - Status Code: ${request.statusCode}');
    debugPrint('🌐 [API] updateProfileWithoutImage - Response: ${respon.body.length > 300 ? respon.body.substring(0, 300) + "..." : respon.body}');
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
      debugPrint(respon.body);
      result = jsonDecode(respon.body)['message'];
    }
  } catch (e) {
    if (e is SocketException) {
      result = 'no internet';
    }
  }
  return result;
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

//get wallet history

Map<String, dynamic> walletBalance = {};
List walletHistory = [];
Map<String, dynamic> walletPages = {};

getWalletHistory() async {
  walletBalance.clear();
  walletHistory.clear();
  walletPages.clear();
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
      internet = false;
      result = 'no internet';
      valueNotifierHome.incrementNotifier();
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
      internet = false;
      result = 'no internet';
      valueNotifierHome.incrementNotifier();
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
      valueNotifierHome.incrementNotifier();
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

//paystack payment
Map<String, dynamic> paystackCode = {};

getPaystackPayment(money) async {
  dynamic results;
  paystackCode.clear();
  try {
    var response = await http.post(
      Uri.parse('${url}api/v1/payment/paystack/initialize'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'amount': money}),
    );
    if (response.statusCode == 200) {
      if (jsonDecode(response.body)['status'] == false) {
        results = jsonDecode(response.body)['message'];
      } else {
        results = 'success';
        paystackCode = jsonDecode(response.body)['data'];
      }
    } else if (response.statusCode == 401) {
      results = 'logout';
    } else {
      debugPrint(response.body);
      results = jsonDecode(response.body)['message'];
    }
  } catch (e) {
    if (e is SocketException) {
      results = 'no internet';
      internet = false;
    }
  }
  return results;
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

//razorpay

addMoneyRazorpay(amount, nonce) async {
  dynamic result;
  try {
    var response = await http.post(
      Uri.parse('${url}api/v1/payment/razerpay/add-money'),
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

//cashfree

Map<String, dynamic> cftToken = {};

getCfToken(money, currency) async {
  cftToken.clear();
  cfSuccessList.clear();
  dynamic result;
  try {
    var response = await http.post(
      Uri.parse('${url}api/v1/payment/cashfree/generate-cftoken'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'order_amount': money, 'order_currency': currency}),
    );
    if (response.statusCode == 200) {
      if (jsonDecode(response.body)['status'] == 'OK') {
        cftToken = jsonDecode(response.body);
        result = 'success';
      } else {
        debugPrint(response.body);
        result = 'failure';
      }
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

Map<String, dynamic> cfSuccessList = {};

cashFreePaymentSuccess() async {
  dynamic result;
  try {
    var response = await http.post(
      Uri.parse('${url}api/v1/payment/cashfree/add-money-to-wallet-webhooks'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'orderId': cfSuccessList['orderId'],
        'orderAmount': cfSuccessList['orderAmount'],
        'referenceId': cfSuccessList['referenceId'],
        'txStatus': cfSuccessList['txStatus'],
        'paymentMode': cfSuccessList['paymentMode'],
        'txMsg': cfSuccessList['txMsg'],
        'txTime': cfSuccessList['txTime'],
        'signature': cfSuccessList['signature'],
      }),
    );
    if (response.statusCode == 200) {
      if (jsonDecode(response.body)['success'] == true) {
        result = 'success';
        await getWalletHistory();
        await getUserDetails();
      } else {
        debugPrint(response.body);
        result = 'failure';
      }
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

//user logout

userLogout() async {
  dynamic result;
  var id = userDetails['id'];
  var role = userDetails['role'];
  try {
    var response = await http.post(
      Uri.parse('${url}api/v1/logout'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      if (!kIsWeb) {
        platforms.invokeMethod('logout');
      }
      // print(id);
      if (role != 'owner') {
        final position = FirebaseDatabase.instance.ref();
        position.child('drivers/driver_$id').update({'is_active': 0});
      }
      rideStreamStart?.cancel();
      rideStreamChanges?.cancel();
      requestStreamEnd?.cancel();
      _cancelRequestStreams();
      rideStreamStart = null;
      rideStreamChanges = null;
      requestStreamEnd = null;
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

//check internet connection

checkInternetConnection() async {
  Connectivity().onConnectivityChanged.listen((connectionState) {
    if (connectionState == ConnectivityResult.none) {
      internet = false;
      valueNotifierHome.incrementNotifier();
      valueNotifierHome.incrementNotifier();
    } else {
      internet = true;

      valueNotifierHome.incrementNotifier();
      valueNotifierHome.incrementNotifier();
    }
  });
}

//internet true
internetTrue() {
  internet = true;
  valueNotifierHome.incrementNotifier();
}

//driver earnings

Map<String, dynamic> driverTodayEarnings = {};
Map<String, dynamic> driverWeeklyEarnings = {};
Map<String, dynamic> weekDays = {};
Map<String, dynamic> driverReportEarnings = {};

driverTodayEarning() async {
  dynamic result;
  try {
    var response = await http.get(
      Uri.parse('${url}api/v1/driver/today-earnings'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      result = 'success';
      driverTodayEarnings = jsonDecode(response.body)['data'];
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

driverWeeklyEarning() async {
  dynamic result;
  try {
    var response = await http.get(
      Uri.parse('${url}api/v1/driver/weekly-earnings'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      result = 'success';
      driverWeeklyEarnings = jsonDecode(response.body)['data'];
      weekDays = jsonDecode(response.body)['data']['week_days'];
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

driverEarningReport(fromdate, todate) async {
  dynamic result;
  try {
    var response = await http.get(
      Uri.parse('${url}api/v1/driver/earnings-report/$fromdate/$todate'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      driverReportEarnings = jsonDecode(response.body)['data'];
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

//withdraw request

requestWithdraw(amount) async {
  dynamic result;
  try {
    var response = await http.post(
      Uri.parse('${url}api/v1/payment/wallet/request-for-withdrawal'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'requested_amount': amount}),
    );
    if (response.statusCode == 200) {
      await getWithdrawList();
      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
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

//withdraw list

Map<String, dynamic> withDrawList = {};
List withDrawHistory = [];
Map<String, dynamic> withDrawHistoryPages = {};

getWithdrawList() async {
  dynamic result;
  try {
    var response = await http.get(
      Uri.parse('${url}api/v1/payment/wallet/withdrawal-requests'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      withDrawList = jsonDecode(response.body);
      withDrawHistory = jsonDecode(response.body)['withdrawal_history']['data'];
      withDrawHistoryPages = jsonDecode(
        response.body,
      )['withdrawal_history']['meta']['pagination'];
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

getWithdrawListPages(page) async {
  dynamic result;
  try {
    var response = await http.get(
      Uri.parse('${url}api/v1/payment/wallet/withdrawal-requests?page=$page'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      withDrawList = jsonDecode(response.body);
      List val = jsonDecode(response.body)['withdrawal_history']['data'];
      // ignore: avoid_function_literals_in_foreach_calls
      val.forEach((element) {
        withDrawHistory.add(element);
      });
      withDrawHistoryPages = jsonDecode(
        response.body,
      )['withdrawal_history']['meta']['pagination'];
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
      bankData = jsonDecode(response.body)['data'];
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

addBankData(accName, accNo, bankCode, bankName) async {
  dynamic result;
  try {
    var response = await http.post(
      Uri.parse('${url}api/v1/user/update-bank-info'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'account_name': accName,
        'account_no': accNo,
        'bank_code': bankCode,
        'bank_name': bankName,
      }),
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

//sos admin notification

notifyAdmin() async {
  var db = FirebaseDatabase.instance.ref();
  dynamic result;
  try {
    await db.child('SOS/${driverReq['id']}').update({
      "is_driver": "1",
      "is_user": "0",
      "req_id": driverReq['id'],
      "serv_loc_id": driverReq['service_location_id'],
      "updated_at": ServerValue.timestamp,
    });
    result = true;
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = false;
    }
  }
  return result;
}

//make complaint

List generalComplaintList = [];
getGeneralComplaint(type) async {
  dynamic result;
  try {
    var response = await http.get(
      Uri.parse(
        '${url}api/v1/common/complaint-titles?complaint_type=$type&transport_type=${userDetails['transport_type']}',
      ),
      headers: {'Authorization': 'Bearer ${bearerToken[0].token}'},
    );
    if (response.statusCode == 200) {
      generalComplaintList = jsonDecode(response.body)['data'];
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

makeGeneralComplaint(complaintDesc) async {
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

//waiting time

//waiting before start
dynamic waitingTime;
dynamic waitingBeforeTime;
dynamic waitingAfterTime;
dynamic arrivedTimer;
dynamic rideTimer;
waitingBeforeStart() async {
  var bWaitingTimes = await FirebaseDatabase.instance
      .ref('requests/${driverReq['id']}')
      // .child('waiting_time_before_start')
      .get();
  var waitingTimes = await FirebaseDatabase.instance
      .ref('requests/${driverReq['id']}')
      // .child('total_waiting_time')
      .get();
  if (bWaitingTimes.child('waiting_time_before_start').value != null) {
    waitingBeforeTime = bWaitingTimes.child('waiting_time_before_start').value;
  } else {
    waitingBeforeTime = 0;
  }
  if (waitingTimes.child('total_waiting_time').value != null) {
    waitingTime = waitingTimes.child('total_waiting_time').value;
  } else {
    waitingTime = 0;
  }
  await Future.delayed(const Duration(seconds: 10), () {});

  arrivedTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
    if (driverReq['is_driver_arrived'] == 1 &&
        driverReq['is_trip_start'] == 0) {
      waitingBeforeTime++;
      waitingTime++;
      if (waitingTime % 60 == 0) {
        FirebaseDatabase.instance
            .ref()
            .child('requests/${driverReq['id']}')
            .update({
          'waiting_time_before_start': waitingBeforeTime,
          'total_waiting_time': waitingTime,
        });
      }
      valueNotifierHome.incrementNotifier();
    } else {
      timer.cancel();
      arrivedTimer = null;
    }
  });
}

dynamic currentRidePosition;

dynamic startTimer;

waitingAfterStart() async {
  var bWaitingTimes = await FirebaseDatabase.instance
      .ref('requests/${driverReq['id']}')
      // .child('waiting_time_before_start')
      .get();
  var waitingTimes = await FirebaseDatabase.instance
      .ref('requests/${driverReq['id']}')
      // .child('total_waiting_time')
      .get();
  var aWaitingTimes = await FirebaseDatabase.instance
      .ref('requests/${driverReq['id']}')
      // .child('waiting_time_after_start')
      .get();
  if (bWaitingTimes.child('waiting_time_before_start').value != null &&
      waitingBeforeTime == null) {
    waitingBeforeTime = bWaitingTimes.child('waiting_time_before_start').value;
  }
  if (waitingTimes.child('total_waiting_time').value != null) {
    waitingTime = waitingTimes.child('total_waiting_time').value;
    // ignore: prefer_conditional_assignment
  } else if (waitingTime == null) {
    waitingTime = 0;
  }
  if (aWaitingTimes.child('waiting_time_after_start').value != null) {
    waitingAfterTime = aWaitingTimes.child('waiting_time_after_start').value;
  } else {
    waitingAfterTime = 0;
  }
  await Future.delayed(const Duration(seconds: 10), () {});
  rideTimer = Timer.periodic(const Duration(seconds: 60), (timer) async {
    if (currentRidePosition == null &&
        driverReq['is_completed'] == 0 &&
        driverReq['is_trip_start'] == 1) {
      currentRidePosition = center;
    } else if (currentRidePosition != null &&
        driverReq['is_completed'] == 0 &&
        driverReq['is_trip_start'] == 1) {
      var dist = await calculateIdleDistance(
        currentRidePosition.latitude,
        currentRidePosition.longitude,
        center.latitude,
        center.longitude,
      );
      if (dist < 150) {
        waitingAfterTime = waitingAfterTime + 60;
        waitingTime = waitingTime + 60;
        if (waitingTime % 60 == 0) {
          FirebaseDatabase.instance
              .ref()
              .child('requests/${driverReq['id']}')
              .update({
            'waiting_time_after_start': waitingAfterTime,
            'total_waiting_time': waitingTime,
          });
        }
        valueNotifierHome.incrementNotifier();
      } else {
        currentRidePosition = center;
      }
    } else {
      timer.cancel();
      rideTimer = null;
    }
  });
}

//requestStream
StreamSubscription<DatabaseEvent>? requestStreamStart;
StreamSubscription<DatabaseEvent>? requestStreamStartStr;
StreamSubscription<DatabaseEvent>? requestStreamEnd;
StreamSubscription<DatabaseEvent>? rideStreamStart;
StreamSubscription<DatabaseEvent>? rideStreamChanges;
StreamSubscription<DatabaseEvent>? rideStart;

void _cancelRequestStreams() {
  requestStreamStart?.cancel();
  requestStreamStartStr?.cancel();
  requestStreamStart = null;
  requestStreamStartStr = null;
}

streamRequest() {
  rideStreamStart?.cancel();
  rideStreamChanges?.cancel();
  requestStreamEnd?.cancel();
  _cancelRequestStreams();
  rideStreamStart = null;
  rideStreamChanges = null;
  requestStreamEnd = null;
  final driverId = userDetails['id'];
  final driverIdInt = driverId is int ? driverId : (int.tryParse(driverId.toString()) ?? 0);
  final driverIdStr = driverId.toString();
  debugPrint('🔔 [OMNY Driver] streamRequest iniciado – driver_id como número ($driverIdInt) e como string ("$driverIdStr")');
  void onRequestReceived(DatabaseEvent event) async {
    final key = event.snapshot.key.toString();
    debugPrint('🔔 [OMNY Driver] request-meta onChildAdded – request_id = $key');
    if (driverReq.isEmpty) {
      _cancelRequestStreams();
      streamEnd(key);
      await getUserDetails();
      valueNotifierHome.incrementNotifier();
    }
  }
  requestStreamStart = FirebaseDatabase.instance
      .ref('request-meta')
      .orderByChild('driver_id')
      .equalTo(driverIdInt)
      .onChildAdded
      .handleError((onError) {
    debugPrint('🔔 [OMNY Driver] streamRequest (número) ERRO: $onError');
    _cancelRequestStreams();
  }).listen(onRequestReceived);
  requestStreamStartStr = FirebaseDatabase.instance
      .ref('request-meta')
      .orderByChild('driver_id')
      .equalTo(driverIdStr)
      .onChildAdded
      .handleError((onError) {
    debugPrint('🔔 [OMNY Driver] streamRequest (string) ERRO: $onError');
    _cancelRequestStreams();
  }).listen(onRequestReceived);
}

bool summma = false;
streamEnd(id) {
  requestStreamEnd = FirebaseDatabase.instance
      .ref('request-meta')
      .child(id)
      .onChildRemoved
      .handleError((onError) {
    requestStreamEnd?.cancel();
  }).listen((event) {
    if (driverReject != true && driverReq['accepted_at'] == null) {
      driverReq.clear();
      getUserDetails();
    }
  });
}

streamRide() {
  requestStreamEnd?.cancel();
  _cancelRequestStreams();
  rideStreamStart?.cancel();
  rideStreamChanges?.cancel();
  requestStreamEnd = null;
  rideStreamStart = null;
  rideStreamChanges = null;
  rideStreamChanges = FirebaseDatabase.instance
      .ref('requests/${driverReq['id']}')
      .onChildChanged
      .handleError((onError) {
    rideStreamChanges?.cancel();
  }).listen((DatabaseEvent event) {
    if (event.snapshot.key.toString() == 'cancelled_by_user') {
      getUserDetails();
      if (driverReq.isEmpty) {
        userReject = true;
      }
    } else if (event.snapshot.key.toString() == 'message_by_user') {
      getCurrentMessages();
    } else if (event.snapshot.key.toString() == 'is_paid' ||
        event.snapshot.key.toString() == 'modified_by_user') {
      getUserDetails();
    }
  });
  rideStreamStart = FirebaseDatabase.instance
      .ref('requests/${driverReq['id']}')
      .onChildAdded
      .handleError((onError) {
    rideStreamChanges?.cancel();
  }).listen((DatabaseEvent event) async {
    if (event.snapshot.key.toString() == 'cancelled_by_user') {
      getUserDetails();

      userReject = true;
    } else if (event.snapshot.key.toString() == 'message_by_user') {
      getCurrentMessages();
    } else if (event.snapshot.key.toString() == 'is_paid' ||
        event.snapshot.key.toString() == 'modified_by_user') {
      getUserDetails();
    }
  });
}

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
    if (value['to_id'].toString() == userDetails['user_id'].toString()) {
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
        'from_id': userDetails['user_id'],
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

//location stream
bool positionStreamStarted = false;
StreamSubscription<geolocs.Position>? positionStream;

geolocs.LocationSettings locationSettings = (platform == TargetPlatform.android)
    ? geolocs.AndroidSettings(
        accuracy: geolocs.LocationAccuracy.high,
        distanceFilter: 50,
        foregroundNotificationConfig:
            const geolocs.ForegroundNotificationConfig(
          notificationText:
              "product.name will continue to receive your location in background",
          notificationTitle: "Location background service running",
          enableWakeLock: true,
        ),
      )
    : geolocs.AppleSettings(
        accuracy: geolocs.LocationAccuracy.high,
        activityType: geolocs.ActivityType.otherNavigation,
        distanceFilter: 50,
        showBackgroundLocationIndicator: true,
      );

//after load image
uploadLoadingImage(image) async {
  dynamic result;

  try {
    var response = http.MultipartRequest(
      'POST',
      Uri.parse('${url}api/v1/request/upload-proof'),
    );
    response.headers.addAll({
      'Authorization': 'Bearer ${bearerToken[0].token}',
    });
    response.files.add(await http.MultipartFile.fromPath('proof_image', image));
    response.fields['before_load'] = '1';
    response.fields['request_id'] = driverReq['id'];
    var request = await response.send();
    var respon = await http.Response.fromStream(request);
    final val = jsonDecode(respon.body);
    if (request.statusCode == 200) {
      debugPrint('testing $val');
      result = 'success';
    } else if (request.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(respon.body);
      result = 'failed';
    }
  } catch (e) {
    if (e is SocketException) {
      result = 'no internet';
      internet = false;
    }
  }
  return result;
}

// unload image
uploadUnloadingImage(image) async {
  dynamic result;

  try {
    var response = http.MultipartRequest(
      'POST',
      Uri.parse('${url}api/v1/request/upload-proof'),
    );
    response.headers.addAll({
      'Authorization': 'Bearer ${bearerToken[0].token}',
    });
    response.files.add(await http.MultipartFile.fromPath('proof_image', image));
    response.fields['after_load'] = '1';
    response.fields['request_id'] = driverReq['id'];
    var request = await response.send();
    var respon = await http.Response.fromStream(request);
    final val = jsonDecode(respon.body);
    if (request.statusCode == 200) {
      debugPrint('testing $val');
      result = 'success';
    } else if (request.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(val);
      result = 'failed';
    }
  } catch (e) {
    if (e is SocketException) {
      result = 'no internet';
      internet = false;
    }
  }
  return result;
}

dynamic testDistance = 0;
// Location location = Location();

positionStreamData() {
  positionStream =
      geolocs.Geolocator.getPositionStream(locationSettings: locationSettings)
          .handleError((error) {
    positionStream = null;
    positionStream?.cancel();
  }).listen((geolocs.Position? position) {
    if (position != null) {
      center = LatLng(position.latitude, position.longitude);
    } else {
      positionStream!.cancel();
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

addHomeAddress(lat, lng, add) async {
  dynamic result;
  try {
    var response = await http.post(
      Uri.parse('${url}api/v1/driver/add-my-route-address'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'my_route_lat': lat,
        'my_route_lng': lng,
        'my_route_address': add,
      }),
    );
    if (response.statusCode == 200) {
      await getUserDetails();
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

enableMyRouteBookings(lat, lng) async {
  dynamic result;
  try {
    var response = await http.post(
      Uri.parse('${url}api/v1/driver/enable-my-route-booking'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'is_enable': (userDetails['enable_my_route_booking'] == 1) ? 0 : 1,
        'current_lat': lat,
        'current_lng': lng,
      }),
    );
    if (response.statusCode == 200) {
      await getUserDetails();
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

List rideList = [];
List waitingList = [];
int choosenDistance = 1;

rideRequest() {
  GeoHasher geo = GeoHasher();
  double lat = 0.0144927536231884;
  double lon = 0.0181818181818182;
  rideStart?.cancel();
  rideStart = null;
  rideStart = FirebaseDatabase.instance
      .ref()
      .child('bid-meta')
      .orderByChild('g')
      .startAt(
        geo.encode(
          center.longitude -
              (lon *
                  double.parse(
                    distanceBetween[choosenDistance]['value'].toString(),
                  )),
          center.latitude -
              (lat *
                  double.parse(
                    distanceBetween[choosenDistance]['value'].toString(),
                  )),
        ),
      )
      .endAt(
        geo.encode(
          center.longitude +
              (lon *
                  double.parse(
                    distanceBetween[choosenDistance]['value'].toString(),
                  )),
          center.latitude +
              (lat *
                  double.parse(
                    distanceBetween[choosenDistance]['value'].toString(),
                  )),
        ),
      )
      .onValue
      .handleError((onError) {
    rideStart?.cancel();
  }).listen((DatabaseEvent event) {
    rideList.clear();
    waitingList.clear();
    if (event.snapshot.value != null) {
      Map list = jsonDecode(jsonEncode(event.snapshot.value));
      list.forEach((key, value) {
        if (value['drivers'] != null &&
            (userDetails['vehicle_type_id'] == value['vehicle_type'] ||
                userDetails['vehicle_types'].contains(
                  value['vehicle_type'],
                ))) {
          if (value['drivers']['driver_${userDetails["id"]}'] != null) {
            if (value['drivers']['driver_${userDetails["id"]}']
                    ["is_rejected"] ==
                'none') {
              rideList.add(value);

              waitingList.add(value);
            } else if (value['drivers']['driver_${userDetails["id"]}']
                    ["is_rejected"] !=
                'by_driver') {
              rideList.add(value);
            }
          } else {
            rideList.add(value);
          }
          if (value['drivers']['driver_${userDetails["id"]}'] != null) {
            if (value['drivers']['driver_${userDetails["id"]}']
                    ["is_rejected"] !=
                'by_driver') {
              if ((waitingList.isEmpty ||
                  waitingList[0]['is_rejected'] == 'by_user')) {
                audioPlayers.play(AssetSource(audio));
              }
            }
          }
        } else if (userDetails['vehicle_type_id'] == value['vehicle_type'] ||
            userDetails['vehicle_types'].contains(value['vehicle_type'])) {
          rideList.add(value);
          if ((waitingList.isEmpty ||
              waitingList[0]['is_rejected'] == 'by_user')) {
            audioPlayers.play(AssetSource(audio));
          }
        }
      });
      if (rideList.isNotEmpty) {
        rideList.sort((a, b) => b['updated_at'].compareTo(a["updated_at"]));
      }
    }

    valueNotifierHome.incrementNotifier();
  });
  if (waitingList.isEmpty) {
    isAvailable = null;
  }
}

dynamic isAvailable;

sendOTPtoEmail(String email) async {
  dynamic result;
  try {
    var response = await http.post(
      Uri.parse('${url}api/v1/send-mail-otp'),
      body: {'email': email},
    );
    if (response.statusCode == 200) {
      if (jsonDecode(response.body)['success'] == true) {
        result = 'success';
      } else {
        debugPrint(response.body);
        result = 'failed';
      }
    }
    return result;
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
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

// void printWrapped(String text) {
//   final pattern = RegExp('.{1,800}'); // 800 is the size of each chunk
//   pattern.allMatches(text).forEach((match) => debugPrint(match.group(0)));
// }

paymentReceived() async {
  dynamic result;
  try {
    var response = await http.post(
      Uri.parse('${url}api/v1/request/payment-confirm'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'request_id': driverReq['id']}),
    );
    if (response.statusCode == 200) {
      // printWrapped(response.body);
      // userCancelled = true;
      FirebaseDatabase.instance.ref('requests').child(driverReq['id']).update({
        'modified_by_driver': ServerValue.timestamp,
      });
      await getUserDetails();
      result = 'success';
      valueNotifierHome.incrementNotifier();
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

String ownermodule = '1';
String isemailmodule = '1';
getOwnermodule() async {
  dynamic res;

  debugPrint('🌐 [API] getOwnermodule - Iniciando chamada');
  debugPrint('🌐 [API] getOwnermodule - URL: ${url}api/v1/common/modules');

  try {
    final response = await http.get(Uri.parse('${url}api/v1/common/modules'));

    debugPrint('🌐 [API] getOwnermodule - Status Code: ${response.statusCode}');
    debugPrint('🌐 [API] getOwnermodule - Response: ${response.body}');

    if (response.statusCode == 200) {
      try {
        final jsonResponse = jsonDecode(response.body);
        ownermodule = jsonResponse['enable_owner_login'];
        isemailmodule = jsonResponse['enable_email_otp'];
        debugPrint('🌐 [API] getOwnermodule - ownermodule: $ownermodule');
        debugPrint('🌐 [API] getOwnermodule - isemailmodule: $isemailmodule');
        res = 'success';
      } catch (e) {
        debugPrint('🌐 [API] getOwnermodule - ERRO ao decodificar JSON: $e');
        res = 'failed';
      }
    } else {
      logApiError('getOwnermodule', response.statusCode, response.body);
      res = 'failed';
    }
  } catch (e) {
    debugPrint('🌐 [API] getOwnermodule - EXCEÇÃO: $e');
    debugPrint('🌐 [API] getOwnermodule - Tipo: ${e.runtimeType}');
    if (e is SocketException) {
      internet = false;
      res = 'no internet';
      debugPrint('🌐 [API] getOwnermodule - SocketException: Sem internet');
    } else {
      res = 'failed';
    }
  }

  debugPrint('🌐 [API] getOwnermodule - Resultado final: $res');
  return res;
}
