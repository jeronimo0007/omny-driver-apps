import 'dart:async';
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_driver/pages/onTripPage/map_page.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../styles/styles.dart';
import '../../functions/functions.dart';
import 'package:http/http.dart' as http;
import '../../widgets/widgets.dart';
import '../login/landingpage.dart';
import '../login/login.dart';
import '../login/requiredinformation.dart';
import '../noInternet/nointernet.dart';
import '../onTripPage/rides.dart';
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

  var demopage = TextEditingController();

  //navigate
  navigate() {
    if (userDetails['uploaded_document'] == true &&
        userDetails['approve'] == true) {
      //status approved
      if (userDetails['role'] != 'owner') {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const RidePage()),
            (route) => false);
      } else {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const Maps()),
            (route) => false);
      }
    } else {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => const RequiredInformation()));
    }
  }

  @override
  void initState() {
    super.initState();
    // Carregar módulo do owner primeiro, depois processar navegação
    getOwnermodule().then((_) {
      debugPrint('🌐 [LOADING] getOwnermodule concluído, iniciando getLanguageDone');
      getLanguageDone();
    }).catchError((e) {
      debugPrint('🌐 [LOADING] ERRO em getOwnermodule: $e');
      // Continuar mesmo com erro
      getLanguageDone();
    });
  }

  getData() async {
    for (var i = 0; _error == true; i++) {
      await getLanguageDone();
    }
  }

//get language json and data saved in local (bearer token , choosen language) and find users current status
  getLanguageDone() async {
    _error = false;
    
    // No web, pular verificação de versão mas continuar o fluxo
    if (kIsWeb) {
      debugPrint('🌐 [LOADING] Web detectado - pulando verificação de versão');
      if (mounted) {
        setState(() {
          updateAvailable = false;
        });
      }
      // Continuar o fluxo normalmente
      await getDetailsOfDevice();
      if (internet == true) {
        debugPrint('🌐 [LOADING] Web - Continuando com getLocalData()...');
        var val = await getLocalData();
        debugPrint('🌐 [LOADING] Web - Resultado getLocalData: $val');

        //if user is login and check waiting for approval status and send accordingly
        if (val == '3') {
          debugPrint('🌐 [LOADING] Web - Navegando para tela principal (usuário logado)');
          navigate();
        } else if (val == '2') {
          debugPrint('🌐 [LOADING] Web - Navegando para login (usuário não logado)');
          Future.delayed(const Duration(seconds: 2), () {
            if (ownermodule == '1') {
              Future.delayed(const Duration(seconds: 2), () {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LandingPage()));
              });
            } else {
              ischeckownerordriver == 'driver';
              Future.delayed(const Duration(seconds: 2), () {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => const Login()));
              });
            }
          });
        } else {
          debugPrint('🌐 [LOADING] Web - Navegando para login/landing (primeiro acesso)');
          // Idioma já está definido como pt_BR por padrão, não precisa mostrar tela de seleção
          Future.delayed(const Duration(seconds: 2), () {
            if (ownermodule == '1') {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const LandingPage()));
            } else {
              ischeckownerordriver == 'driver';
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => const Login()));
            }
          });
        }
        if (mounted) {
          setState(() {});
        }
      } else {
        debugPrint('🌐 [LOADING] Web - Sem internet');
        if (mounted) {
          setState(() {});
        }
      }
      return;
    }
    
    // Código original para mobile
    _package = await PackageInfo.fromPlatform();
    try {
      if (platform == TargetPlatform.android) {
        _version = await FirebaseDatabase.instance
            .ref()
            .child('driver_android_version')
            .get();
      } else {
        _version = await FirebaseDatabase.instance
            .ref()
            .child('driver_ios_version')
            .get();
      }
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
        await getDetailsOfDevice();
        if (internet == true) {
          var val = await getLocalData();

          //if user is login and check waiting for approval status and send accordingly
          if (val == '3') {
            navigate();
          } else if (val == '2') {
            Future.delayed(const Duration(seconds: 2), () {
              if (ownermodule == '1') {
                Future.delayed(const Duration(seconds: 2), () {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LandingPage()));
                });
              } else {
                ischeckownerordriver == 'driver';
                Future.delayed(const Duration(seconds: 2), () {
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (context) => const Login()));
                });
              }
            });
          } else {
            // Idioma já está definido como pt_BR por padrão, não precisa mostrar tela de seleção
            Future.delayed(const Duration(seconds: 2), () {
              if (ownermodule == '1') {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LandingPage()));
              } else {
                ischeckownerordriver == 'driver';
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => const Login()));
              }
            });
          }
          setState(() {});
        }
      }
    } catch (e) {
      debugPrint('🌐 [LOADING] ERRO em getLanguageDone: $e');
      if (internet == true) {
        if (_error == false) {
          setState(() {
            _error = true;
          });
          getData();
        }
      } else {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Material(
      child: Scaffold(
        body: Stack(
          children: [
            Container(
              height: media.height * 1,
              width: media.width * 1,
              decoration: BoxDecoration(color: page
                  // color: Color(0xff000000),
                  ),
              child: Container(
                decoration: const BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage('assets/images/landimage.png'),
                        fit: BoxFit.cover)),
              ),
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
                                                    response.body)['results'][0]
                                                ['trackViewUrl']);
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
            //internet is not connected
            (internet == false)
                ? Positioned(
                    top: 0,
                    child: NoInternet(
                      onTap: () {
                        //try again
                        setState(() {
                          internetTrue();
                          getLanguageDone();
                        });
                      },
                    ))
                : Container(),

            //loader
            (_isLoading == true && internet == true)
                ? const Positioned(top: 0, child: Loading())
                : Container(),
          ],
        ),
      ),
    );
  }
}
