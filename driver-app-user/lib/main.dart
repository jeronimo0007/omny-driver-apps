import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'functions/functions.dart';
import 'functions/notifications.dart';
import 'pages/loadingPage/loadingpage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    // SystemChrome.setPreferredOrientations não é suportado no web
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  // Inicializar Firebase
  // No Android, o plugin do Google Services pode inicializar automaticamente,
  // então vamos tentar inicializar e ignorar erros de duplicação
  try {
    // Verificar se já existe uma instância do Firebase
    if (Firebase.apps.isNotEmpty) {
      debugPrint(
          '✅ Firebase já foi inicializado automaticamente (${Firebase.apps.length} instância(s))');
      // Verificar se a instância tem projectId configurado
      try {
        final app = Firebase.app();
        if (app.options.projectId.isEmpty) {
          debugPrint(
              '⚠️ Firebase inicializado mas sem projectId - tentando reinicializar...');
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
            name: '${Firebase.app().name}_retry',
          );
        }
      } catch (e) {
        debugPrint('ℹ️ Verificação de projectId ignorada: $e');
      }
    } else {
      debugPrint('🔄 Inicializando Firebase...');
      final options = DefaultFirebaseOptions.currentPlatform;
      if (options.projectId.isEmpty) {
        debugPrint(
            '❌ Firebase Options sem projectId! Verifique firebase_options.dart');
      } else {
        debugPrint('   ProjectId: ${options.projectId}');
      }
      await Firebase.initializeApp(
        options: options,
      );
      debugPrint('✅ Firebase inicializado com sucesso');
    }
  } catch (e) {
    // Se o erro for de duplicação, significa que o Firebase já foi inicializado
    // pelo plugin do Google Services (comportamento normal no Android)
    final errorString = e.toString();
    if (errorString.contains('duplicate-app') ||
        errorString.contains('already exists') ||
        errorString.contains('[DEFAULT]')) {
      debugPrint(
          'ℹ️ Firebase já foi inicializado automaticamente pelo plugin do Google Services');
      debugPrint('   (Isso é normal no Android e pode ser ignorado)');
    } else if (errorString.contains('project') ||
        errorString.contains('Project ID')) {
      debugPrint('❌ Erro de configuração do Firebase Project ID: $e');
      debugPrint(
          '   Verifique se firebase_options.dart está configurado corretamente');
      debugPrint(
          '   Continuando mesmo assim - algumas funcionalidades podem não funcionar');
    } else {
      // Para outros erros, logar mas continuar
      debugPrint('⚠️ Erro ao inicializar Firebase: $e');
      debugPrint('   Continuando mesmo assim...');
    }
  }

  checkInternetConnection();
  initMessaging();
  runApp(const MyApp());
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
      child: ValueListenableBuilder(
        valueListenable: valueNotifierBook.value,
        builder: (context, value, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Omny',
            theme: ThemeData(),
            home: const LoadingPage(),
          );
        },
      ),
    );
  }
}
