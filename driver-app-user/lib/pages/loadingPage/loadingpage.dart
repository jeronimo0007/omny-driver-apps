import 'dart:async';
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:package_info_plus/package_info_plus.dart';
import '../../styles/styles.dart';
import '../../functions/functions.dart';
import 'package:http/http.dart' as http;
import '../../widgets/widgets.dart';
import '../language/languages.dart';
import '../login/login.dart';
import '../noInternet/noInternet.dart';
import '../onTripPage/booking_confirmation.dart';
import '../onTripPage/invoice.dart';
import '../onTripPage/map_page.dart';
import 'loading.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({Key? key}) : super(key: key);

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

dynamic package;

class _LoadingPageState extends State<LoadingPage> {
  String dot = '.';
  bool updateAvailable = false;
  dynamic _package;
  dynamic _version;
  bool _error = false;
  bool _isLoading = false;

  // Método auxiliar para continuar a navegação após verificação de versão
  Future<void> _continueNavigation() async {
    debugPrint(
        '🔄 Atualização não disponível, carregando dados do dispositivo...');
    try {
      await getDetailsOfDevice().timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          debugPrint('⏱️ Timeout em getDetailsOfDevice()');
        },
      );

      if (internet == true) {
        debugPrint('🔄 Carregando dados locais...');
        var val = await getLocalData().timeout(
          const Duration(seconds: 25),
          onTimeout: () {
            debugPrint('⏱️ Timeout em getLocalData(), usando fallback');
            return '2'; // Fallback para página de login
          },
        );

        debugPrint('🔄 Resultado getLocalData(): $val');
        debugPrint('🔄 mounted: $mounted, choosenLanguage: $choosenLanguage');

        if (val == '3') {
          debugPrint('✅ Navegando para home (usuário autenticado)');
          debugPrint('🔄 Verificando mounted antes de navigate()...');
          if (mounted) {
            debugPrint('🔄 Chamando navigate()...');
            // Pequeno delay para garantir que o widget está pronto
            await Future.delayed(const Duration(milliseconds: 100));
            if (mounted) {
              navigate();
            }
          } else {
            debugPrint('⚠️ Widget não está mais montado, pulando navigate()');
          }
        } else if (choosenLanguage == '') {
          debugPrint(
              '🔄 Navegando para seleção de idioma (idioma não definido)');
          if (mounted) {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => const Languages()));
          }
        } else if (val == '2') {
          debugPrint('🔄 Navegando para login (usuário não autenticado)');
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => const Login()));
            }
          });
        } else {
          debugPrint('🔄 Navegando para seleção de idioma (fallback)');
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => const Languages()));
            }
          });
        }
      } else {
        debugPrint('⚠️ Sem internet, mostrando tela de sem internet');
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar dados: $e');
      // Fallback: ir para página de login
      if (mounted) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => const Login()));
          }
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Carregar módulos da API primeiro (enable_loginEmailPswd), depois idioma e navegação
    getOwnermodule().then((_) {
      debugPrint('🌐 [LOADING] getOwnermodule concluído, iniciando getLanguageDone');
      getLanguageDone();
    }).catchError((e) {
      debugPrint('🌐 [LOADING] ERRO em getOwnermodule: $e');
      getLanguageDone();
    });
  }

  //navigate
  navigate() {
    debugPrint('🚀 navigate() chamado');
    debugPrint('📋 userRequestData: $userRequestData');

    try {
      if (userRequestData.isNotEmpty && userRequestData['is_completed'] == 1) {
        //invoice page of ride
        debugPrint('📄 Navegando para Invoice');
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const Invoice()),
            (route) => false);
      } else if (userRequestData.isNotEmpty &&
          userRequestData['is_completed'] != 1) {
        //searching ride page
        if (userRequestData['is_rental'] == true) {
          debugPrint('🚗 Navegando para BookingConfirmation (rental)');
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (context) => BookingConfirmation(
                        type: 1,
                      )),
              (route) => false);
        } else {
          debugPrint('🚗 Navegando para BookingConfirmation');
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => BookingConfirmation()),
              (route) => false);
        }
      } else {
        //home page
        debugPrint('🏠 Navegando para Maps (home)');
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const Maps()),
            (route) => false);
      }
    } catch (e) {
      debugPrint('❌ Erro em navigate(): $e');
      // Fallback: tentar navegar para Maps
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Maps()),
          (route) => false);
    }
  }

  bool _isRetrying = false; // Flag para evitar retries múltiplos

  getData() async {
    // Evitar retries múltiplos simultâneos
    if (_isRetrying) {
      debugPrint('⚠️ Retry já em andamento, ignorando chamada duplicada');
      return;
    }
    _isRetrying = true;

    // Limitar tentativas a 3
    int maxRetries = 3;
    int retryCount = 0;

    while (_error == true && retryCount < maxRetries) {
      debugPrint('🔄 Tentativa de retry ${retryCount + 1}/$maxRetries');
      await Future.delayed(
          Duration(seconds: 2 * (retryCount + 1))); // Backoff exponencial
      await getLanguageDone();
      retryCount++;

      // Se o erro foi resolvido, sair do loop
      if (!_error) {
        break;
      }
    }

    _isRetrying = false;

    // Se ainda houver erro após todas as tentativas, continuar sem verificação de versão
    if (_error && retryCount >= maxRetries) {
      debugPrint(
          '⚠️ Não foi possível verificar versão após $maxRetries tentativas. Continuando sem verificação...');
      _error = false;
      updateAvailable = false;
      await getDetailsOfDevice();
      if (internet == true) {
        var val = await getLocalData();
        if (val == '3') {
          navigate();
        } else if (choosenLanguage == '') {
          if (mounted) {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => const Languages()));
          }
        } else if (val == '2') {
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => const Login()));
            }
          });
        } else {
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => const Languages()));
            }
          });
        }
      } else {
        if (mounted) {
          setState(() {});
        }
      }
    }
  }

//get language json and data saved in local (bearer token , choosen language) and find users current status
  getLanguageDone() async {
    // Na web, pular verificação de versão e ir direto para navegação
    if (kIsWeb) {
      debugPrint('🌐 Web detectado, pulando verificação de versão');
      await _continueNavigation();
      return;
    }

    _package = await PackageInfo.fromPlatform();
    String versionNode = platform == TargetPlatform.android
        ? 'user_android_version'
        : 'user_ios_version';

    try {
      debugPrint('🔄 Verificando versão no Firebase...');

      // Adicionar timeout de 10 segundos para a chamada ao Firebase
      _version = await FirebaseDatabase.instance
          .ref()
          .child(versionNode)
          .get()
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('⏱️ Timeout ao buscar versão $versionNode do Firebase');
          throw TimeoutException('Timeout ao buscar versão do Firebase');
        },
      );

      // Verificar se o nó existe e tem valor
      if (!_version.exists || _version.value == null) {
        debugPrint('⚠️ Nó $versionNode não existe ou está vazio no Firebase');
        debugPrint('📝 Continuando sem verificação de versão');
        debugPrint(
            '💡 Para habilitar verificação de versão, crie o nó "$versionNode" no Firebase Realtime Database');
        debugPrint('   Exemplo: { "$versionNode": "1.0.0" }');
        _error = false;
        updateAvailable = false; // Não bloquear o app

        // Continuar com o fluxo de navegação mesmo sem verificação de versão
        await _continueNavigation();
        return;
      }

      debugPrint('✅ Versão obtida do Firebase: ${_version.value}');
      _error = false;
      if (_version.value != null) {
        var version = _version.value.toString().split('.');
        var package = _package.version.toString().split('.');

        for (var i = 0; i < version.length || i < package.length; i++) {
          if (i < version.length && i < package.length) {
            if (int.parse(package[i]) < int.parse(version[i])) {
              setState(() {
                updateAvailable = true;
              });
              break;
            } else if (int.parse(package[i]) > int.parse(version[i])) {
              setState(() {
                updateAvailable = false;
              });
              break;
            }
          } else if (i >= version.length && i < package.length) {
            setState(() {
              updateAvailable = false;
            });
            break;
          } else if (i < version.length && i >= package.length) {
            setState(() {
              updateAvailable = true;
            });
            break;
          }
        }
      }

      if (updateAvailable == false) {
        await _continueNavigation();
      }
    } catch (e) {
      debugPrint('❌ Erro ao verificar versão: $e');

      // Se o erro for porque o nó não existe, continuar normalmente
      String errorString = e.toString().toLowerCase();
      if (errorString.contains('permission') ||
          errorString.contains('not found') ||
          errorString.contains('does not exist')) {
        debugPrint('⚠️ Nó de versão não encontrado ou sem permissão');
        debugPrint('📝 Continuando sem verificação de versão');
        debugPrint(
            '💡 Para habilitar verificação de versão, crie o nó "$versionNode" no Firebase Realtime Database');
        _error = false;
        updateAvailable = false; // Não bloquear o app
        await _continueNavigation(); // Continuar com a navegação
        return;
      }

      if (internet == true) {
        if (_error == false) {
          setState(() {
            _error = true;
          });
          // Continuar sem verificação de versão
          debugPrint('⚠️ Continuando sem verificação de versão devido ao erro');
          _error = false;
          updateAvailable = false;
          await _continueNavigation();
        }
      } else {
        if (mounted) {
          setState(() {});
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      var media = MediaQuery.of(context).size;

      return Material(
        child: Scaffold(
          body: Stack(
            children: [
              Container(
                height: media.height * 1,
                width: media.width * 1,
                decoration: const BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage('assets/images/landimage.png'),
                        fit: BoxFit.cover)),
              ),

              //update available

              (updateAvailable == true)
                  ? Positioned(
                      top: 0,
                      child: Container(
                        height: media.height * 1,
                        width: media.width * 1,
                        color: Colors.transparent.withOpacity(0.6),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                                width: media.width * 0.9,
                                padding: EdgeInsets.all(media.width * 0.05),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: page,
                                ),
                                child: Column(
                                  children: [
                                    SizedBox(
                                        width: media.width * 0.8,
                                        child: MyText(
                                          text:
                                              'New version of this app is available in store, please update the app for continue using',
                                          size: media.width * sixteen,
                                          fontweight: FontWeight.w600,
                                        )),
                                    SizedBox(
                                      height: media.width * 0.05,
                                    ),
                                    Button(
                                        onTap: () async {
                                          if (platform ==
                                              TargetPlatform.android) {
                                            openBrowser(
                                                'https://play.google.com/store/apps/details?id=${_package.packageName}');
                                          } else {
                                            setState(() {
                                              _isLoading = true;
                                            });
                                            var response = await http.get(Uri.parse(
                                                'http://itunes.apple.com/lookup?bundleId=${_package.packageName}'));
                                            if (response.statusCode == 200) {
                                              openBrowser(jsonDecode(
                                                      response.body)['results']
                                                  [0]['trackViewUrl']);
                                            }

                                            setState(() {
                                              _isLoading = false;
                                            });
                                          }
                                        },
                                        text: 'Update')
                                  ],
                                ))
                          ],
                        ),
                      ))
                  : Container(),

              //loader
              (_isLoading == true && internet == true)
                  ? const Positioned(top: 0, child: Loading())
                  : Container(),

              //no internet
              (internet == false)
                  ? Positioned(
                      top: 0,
                      child: NoInternet(
                        onTap: () {
                          setState(() {
                            internetTrue();
                            getLanguageDone();
                          });
                        },
                      ))
                  : Container(),
            ],
          ),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Erro crítico no build da LoadingPage: $e');
      debugPrint('Stack trace: $stackTrace');
      // Retornar uma tela de erro simples ao invés de tela branca
      return Material(
        child: Scaffold(
          body: Container(
            color: Colors.white,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Erro ao carregar aplicativo',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Por favor, reinicie o aplicativo',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }
}
