import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'functions/functions.dart';
import 'functions/notifications.dart';
import 'pages/loadingPage/loadingpage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Evita erro "Unable to load asset: AssetManifest.json" (google_fonts usa manifest; permitir fetch em runtime)
  GoogleFonts.config.allowRuntimeFetching = true;

  // Apenas definir orientação em plataformas móveis (não funciona no web)
  if (!kIsWeb) {
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  }

  // Inicializar Firebase com tratamento de erros
  try {
    debugPrint('🔥 [FIREBASE INIT] Iniciando Firebase...');
    debugPrint('🔥 [FIREBASE INIT] Plataforma: ${kIsWeb ? "WEB" : "MOBILE"}');
    if (kIsWeb) {
      // Web exige FirebaseOptions (mesma config do index.html)
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyCceQTKfoIsPblC4vWMyxC8HfaVUKc0U5U',
          authDomain: 'goin-7372e.firebaseapp.com',
          databaseURL: 'https://goin-7372e-default-rtdb.firebaseio.com',
          projectId: 'goin-7372e',
          storageBucket: 'goin-7372e.firebasestorage.app',
          messagingSenderId: '725859983456',
          appId: '1:725859983456:web:7d738c80d0d3e3376c2305',
          measurementId: 'G-RX7QR1W5W8',
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
    debugPrint('🔥 [FIREBASE INIT] Firebase inicializado com sucesso');
    
    // Verificar conexão com Firebase Database (apenas se não for web ou se Firebase Database suportar web)
    if (!kIsWeb) {
      await verifyFirebaseConnection();
    } else {
      debugPrint('🔥 [FIREBASE INIT] Web detectado - pulando verificação de Database (pode não ser suportado)');
    }
  } catch (e) {
    debugPrint('🔥 [FIREBASE INIT] ERRO ao inicializar Firebase: $e');
    debugPrint('🔥 [FIREBASE INIT] Tipo do erro: ${e.runtimeType}');
    // Continuar mesmo com erro para não travar o app
  }

  // Inicializar mensagens (pode não funcionar no web)
  if (!kIsWeb) {
  initMessaging();
  } else {
    debugPrint('🌐 [INIT] Web detectado - pulando initMessaging (não suportado no web)');
  }
  
  checkInternetConnection();

  // Atualizar posição (pode não funcionar no web sem permissões)
  if (!kIsWeb) {
  currentPositionUpdate();
  } else {
    debugPrint('🌐 [INIT] Web detectado - pulando currentPositionUpdate (requer permissões específicas)');
  }
  
  runApp(const MyApp());
}

// Função para verificar conexão com Firebase
Future<void> verifyFirebaseConnection() async {
  try {
    debugPrint(
        '🔥 [FIREBASE CHECK] Verificando conexão com Firebase Database...');
    
    // Configurar Database com URL explícita se necessário
    const databaseURL = 'https://goin-7372e-default-rtdb.firebaseio.com';
    final database = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: databaseURL,
    );

    debugPrint('🔥 [FIREBASE CHECK] Database URL: ${database.databaseURL}');

    // Verificar se o nó call_FB_OTP existe
    try {
      final otpRef = database.ref().child('call_FB_OTP');
      final otpSnapshot = await otpRef.get().timeout(
            const Duration(seconds: 5),
          );

      if (otpSnapshot.exists) {
        debugPrint(
            '🔥 [FIREBASE CHECK] Nó call_FB_OTP existe: ${otpSnapshot.value}');
        debugPrint('🔥 [FIREBASE CHECK] Conexão com Firebase Database: OK');
      } else {
        debugPrint(
            '🔥 [FIREBASE CHECK] AVISO: Nó call_FB_OTP não existe no Firebase');
        debugPrint(
            '🔥 [FIREBASE CHECK] Verifique se o nó foi criado no Firebase Console');
      }
    } on TimeoutException {
      debugPrint('🔥 [FIREBASE CHECK] TIMEOUT ao verificar call_FB_OTP');
      debugPrint(
          '🔥 [FIREBASE CHECK] Possível problema de conectividade ou regras do Firebase');
    } catch (e) {
      debugPrint('🔥 [FIREBASE CHECK] ERRO ao verificar call_FB_OTP: $e');
      debugPrint('🔥 [FIREBASE CHECK] Tipo do erro: ${e.runtimeType}');
    }
  } catch (e) {
    debugPrint('🔥 [FIREBASE CHECK] ERRO na verificação: $e');
    debugPrint('🔥 [FIREBASE CHECK] Tipo do erro: ${e.runtimeType}');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    platform = Theme.of(context).platform;
    return GestureDetector(
      onTap: () {
        //remove keyboard on touching anywhere on the screen.
        FocusScopeNode currentFocus = FocusScope.of(context);

        if (!currentFocus.hasPrimaryFocus) {
          currentFocus.unfocus();
          FocusManager.instance.primaryFocus?.unfocus();
        }
      },
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Omny Driver',
        theme: ThemeData(),
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [
          Locale('pt', 'BR'),
          Locale('en', 'US'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const LoadingPage(),
      ),
    );
  }
}
