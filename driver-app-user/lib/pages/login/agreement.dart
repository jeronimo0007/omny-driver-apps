import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../functions/functions.dart';
import '../../styles/styles.dart';
import '../../translations/translation.dart';
import '../../widgets/widgets.dart';
import '../referralcode/referral_code.dart';
import 'login.dart' show phnumber, loginLoading;
import 'namepage.dart' show name, email;

class AggreementPage extends StatefulWidget {
  const AggreementPage({Key? key}) : super(key: key);

  @override
  State<AggreementPage> createState() => _AggreementPageState();
}

class _AggreementPageState extends State<AggreementPage> {
  //navigate
  navigate() {
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Referral()),
        (route) => false);
  }

  bool ischeck = false;
  // ignore: unused_field
  String _error = '';
  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Material(
      color: page,
      child: Directionality(
        textDirection: (languageDirection == 'rtl')
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
                child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  SizedBox(
                    height: media.height * 0.01,
                  ),
                  Container(
                    padding: const EdgeInsets.only(top: 15, bottom: 15),
                    child: MyText(
                      text: languages[choosenLanguage]['text_accept_head'],
                      size: media.width * twenty,
                      fontweight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    height: media.width * 0.416,
                    width: media.width * 0.416,
                    decoration: const BoxDecoration(
                        image: DecorationImage(
                            image: AssetImage('assets/images/privacyimage.png'),
                            fit: BoxFit.contain)),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  SizedBox(
                      width: media.width * 0.9,
                      child: RichText(
                        text: TextSpan(
                          // text: 'Hello ',
                          style: getGoogleFontStyle(
                              color: textColor,
                              fontSize: media.width * fourteen,
                            ),
                          children: [
                            TextSpan(
                                text: languages[choosenLanguage]
                                    ['text_agree_text1']),
                            TextSpan(
                                text: languages[choosenLanguage]
                                    ['text_terms_of_use'],
                                style: getGoogleFontStyle(
                                    color: buttonColor,
                                    fontSize: media.width * fourteen,
                                  ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    openBrowser(
                                        'https://driver.omny.app.br/privacy-policy');
                                  }),
                            TextSpan(
                                text: languages[choosenLanguage]
                                    ['text_agree_text2']),
                            TextSpan(
                                text: languages[choosenLanguage]
                                    ['text_privacy'],
                                style: getGoogleFontStyle(
                                    color: buttonColor,
                                    fontSize: media.width * fourteen,
                                  ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    openBrowser(
                                        'https://driver.omny.app.br/privacy-policy');
                                  }),
                          ],
                        ),
                      )),
                  Container(
                    padding: const EdgeInsets.only(top: 15, bottom: 15),
                    child: Row(
                      children: [
                        MyText(
                            text: languages[choosenLanguage]['text_iagree'],
                            size: media.width * sixteen),
                        SizedBox(
                          width: media.width * 0.05,
                        ),
                        InkWell(
                          onTap: () {
                            if (ischeck == false) {
                              setState(() {
                                ischeck = true;
                              });
                            } else {
                              setState(() {
                                ischeck = false;
                              });
                            }
                          },
                          child: Container(
                            height: media.width * 0.05,
                            width: media.width * 0.05,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                                border:
                                    Border.all(color: buttonColor, width: 2)),
                            child: ischeck == false
                                ? null
                                : Icon(
                                    Icons.done,
                                    size: media.width * 0.04,
                                    color: buttonColor,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Exibir mensagem de erro se houver
                  if (_error.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 15, bottom: 15),
                      padding: EdgeInsets.symmetric(
                          horizontal: media.width * 0.04,
                          vertical: media.width * 0.035),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                                blurRadius: 2.0,
                                spreadRadius: 2.0,
                                color: Colors.black.withOpacity(0.2))
                          ],
                          color: verifyDeclined,
                          border: Border.all(
                              color: Colors.red.shade300, width: 1.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              color: Colors.white, size: media.width * 0.06),
                          SizedBox(width: media.width * 0.02),
                          Expanded(
                            child: Text(
                              _error,
                              textAlign: TextAlign.center,
                              style: getGoogleFontStyle(
                                  fontSize: media.width * fourteen,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            )),
            ischeck == true
                ? Padding(
                    padding: const EdgeInsets.only(top: 15, bottom: 15),
                    child: Button(
                        onTap: () async {
                          // Validar campos antes de registrar
                          debugPrint('═══════════════════════════════════════════════════════════');
                          debugPrint('📋 agreement.dart: Valores antes de registrar:');
                          debugPrint('   name: "$name"');
                          debugPrint('   email: "$email"');
                          debugPrint('   phnumber: "$phnumber"');
                          debugPrint('═══════════════════════════════════════════════════════════');
                          
                          if (name.isEmpty || email.isEmpty || phnumber.isEmpty) {
                            setState(() {
                              _error = 'Por favor, preencha todos os campos obrigatórios';
                            });
                            return;
                          }
                          
                          loginLoading = true;
                          _error = '';
                          valueNotifierLogin.incrementNotifier();
                          // Limpar mensagem de erro anterior
                          serverErrorMessage = '';
                          try {
                            var register = await registerUser();
                            debugPrint('📋 agreement.dart: Resultado do registro: $register');
                            if (register != null && register.toString() == 'true') {
                              // Aguardar um pouco para garantir que getUserDetails terminou
                              await Future.delayed(const Duration(milliseconds: 500));
                              //referral page
                              debugPrint('✅ agreement.dart: Navegando para Referral');
                              navigate();
                            } else {
                              setState(() {
                                // Usar serverErrorMessage se disponível, senão usar o retorno da função
                                _error = serverErrorMessage.isNotEmpty 
                                  ? serverErrorMessage 
                                  : (register?.toString() ?? 'Erro ao registrar usuário');
                              });
                            }
                          } catch (e) {
                            debugPrint('❌ agreement.dart: Erro ao registrar: $e');
                            setState(() {
                              _error = 'Erro ao registrar: ${e.toString()}';
                            });
                          }
                          loginLoading = false;
                          valueNotifierLogin.incrementNotifier();
                        },
                        text: languages[choosenLanguage]['text_next']),
                  )
                : Padding(
                    padding: const EdgeInsets.only(top: 15, bottom: 15),
                    child: Button(
                        onTap: () async {},
                        text: languages[choosenLanguage]['text_next'],
                        color: Colors.grey,
                        textcolor: textColor.withOpacity(0.5)),
                  )
          ],
        ),
      ),
    );
  }
}
