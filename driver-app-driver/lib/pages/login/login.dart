import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../config/api_config.dart';
import '../../styles/styles.dart';
import '../../functions/functions.dart';
import '../../translation/translation.dart';
import '../../widgets/widgets.dart';
import 'dart:math' as math;
import '../loadingPage/loading.dart';
import '../noInternet/nointernet.dart';
import 'agreement.dart';
import 'forgot_password.dart';
import 'namepage.dart';
import 'otp_page.dart';
import 'requiredinformation.dart';
import '../onTripPage/map_page.dart';
import '../onTripPage/rides.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

//code as int for getting phone dial code of choosen country
String phnumber = ''; // phone number as string entered in input field
// String phone = '';
List pages = [1, 2, 3, 4];
int currentPage = 0;
bool loginLoading = true;
var value = 0;
bool isfromomobile = true;
bool isLoginemail = false;

class _LoginState extends State<Login> with TickerProviderStateMixin {
  TextEditingController controller = TextEditingController();
  // final _pinPutController2 = TextEditingController();
  dynamic aController;
  String _error = '';
  // bool _resend = false;
  MaskTextInputFormatter? _phoneMaskFormatter;
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  bool _isPhoneFocused = false;
  bool _isEmailFocused = false;
  // Novo fluxo login e-mail/senha (loginEmailPswd == 1)
  final TextEditingController _emailAuthController = TextEditingController();
  final TextEditingController _passwordAuthController = TextEditingController();
  String _errorAuth = '';
  bool _loadingAuth = false;

  // Callback para atualizar o estado quando o texto mudar
  void _onTextChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  String get timerString {
    Duration duration = aController.duration * aController.value;
    return '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
  }

//  void nextPage(){
//     setState(() {
//   if(currentPage < 4){
//     print('add current pae');
//     currentPage = currentPage + 1;
//   }else{
//     currentPage = currentPage - 1;
//   }
//       });
// }
  bool terms = true; //terms and conditions true or false

  @override
  void initState() {
    currentPage = 0;
    controller.text = '';
    aController =
        AnimationController(vsync: this, duration: const Duration(seconds: 60));

    // Garantir que o idioma esteja definido antes de renderizar
    if (choosenLanguage.isEmpty) {
      choosenLanguage = 'pt_BR';
      languageDirection = 'ltr';
      debugPrint('🌐 [LOGIN] Idioma definido como pt_BR no initState');
    }

    // Inicializar o formatter de máscara
    _updatePhoneMaskFormatter();

    // Adicionar listeners para mudança de foco
    _phoneFocusNode.addListener(() {
      setState(() {
        _isPhoneFocused = _phoneFocusNode.hasFocus;
      });
    });

    _emailFocusNode.addListener(() {
      setState(() {
        _isEmailFocused = _emailFocusNode.hasFocus;
      });
    });

    // Adicionar listener ao controller para atualizar o botão quando o texto mudar
    controller.addListener(_onTextChanged);

    countryCode();
    super.initState();

    // Focar no campo apropriado após a tela carregar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && currentPage == 0) {
        if (isLoginemail) {
          _emailFocusNode.requestFocus();
        } else {
          _phoneFocusNode.requestFocus();
        }
      }
    });
  }

  @override
  void dispose() {
    _emailAuthController.dispose();
    _passwordAuthController.dispose();
    controller.removeListener(_onTextChanged);
    _phoneFocusNode.dispose();
    _emailFocusNode.dispose();
    controller.dispose();
    super.dispose();
  }

  /// Tela de login e-mail/senha (quando loginEmailPswd == 1)
  Widget _buildEmailPasswordLogin(Size media) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: media.height * 0.02),
          MyText(
            text: languages[choosenLanguage]['text_login'] ?? 'Entrar',
            size: media.width * 0.06,
            fontweight: FontWeight.bold,
          ),
          SizedBox(height: media.height * 0.02),
          MyText(
            text: languages[choosenLanguage]['text_enter_email'] ?? 'E-mail',
            size: media.width * 0.035,
            color: textColor.withOpacity(0.8),
          ),
          SizedBox(height: media.height * 0.01),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: textColor.withOpacity(0.3)),
            ),
            child: TextField(
              controller: _emailAuthController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: languages[choosenLanguage]['text_enter_email'] ?? 'Digite seu e-mail',
                hintStyle: GoogleFonts.poppins(color: hintColor, fontSize: media.width * 0.035),
                contentPadding: EdgeInsets.symmetric(horizontal: media.width * 0.04, vertical: media.height * 0.02),
                border: InputBorder.none,
              ),
              style: GoogleFonts.poppins(color: textColor, fontSize: media.width * 0.04),
            ),
          ),
          SizedBox(height: media.height * 0.02),
          MyText(
            text: languages[choosenLanguage]['text_password'] ?? 'Senha',
            size: media.width * 0.035,
            color: textColor.withOpacity(0.8),
          ),
          SizedBox(height: media.height * 0.01),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: textColor.withOpacity(0.3)),
            ),
            child: TextField(
              controller: _passwordAuthController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: languages[choosenLanguage]['text_password'] ?? 'Digite sua senha',
                hintStyle: GoogleFonts.poppins(color: hintColor, fontSize: media.width * 0.035),
                contentPadding: EdgeInsets.symmetric(horizontal: media.width * 0.04, vertical: media.height * 0.02),
                border: InputBorder.none,
              ),
              style: GoogleFonts.poppins(color: textColor, fontSize: media.width * 0.04),
            ),
          ),
          if (_errorAuth.isNotEmpty) ...[
            SizedBox(height: media.height * 0.015),
            Text(_errorAuth, style: GoogleFonts.poppins(color: Colors.red, fontSize: media.width * 0.032)),
          ],
          SizedBox(height: media.height * 0.03),
          Button(
            onTap: _loadingAuth
                ? null
                : () async {
                    final email = _emailAuthController.text.trim();
                    final password = _passwordAuthController.text;
                    if (email.isEmpty || password.isEmpty) {
                      setState(() => _errorAuth = languages[choosenLanguage]['text_fill_form'] ?? 'Preencha e-mail e senha');
                      return;
                    }
                    setState(() {
                      _errorAuth = '';
                      _loadingAuth = true;
                      loginLoading = true;
                    });
                    valueNotifierLogin.incrementNotifier();
                    final result = await driverLoginEmailPassword(email, password);
                    if (!mounted) return;
                    setState(() {
                      _loadingAuth = false;
                      loginLoading = false;
                    });
                    valueNotifierLogin.incrementNotifier();
                    if (result == 'token') {
                      var val = await getUserDetails();
                      if (val == 'logout') return;
                      if (!mounted) return;
                      final uploadedDoc = userDetails['uploaded_document'];
                      final approve = userDetails['approve'];
                      if (uploadedDoc == false || uploadedDoc == null) {
                        Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const RequiredInformation()),
                            (route) => false);
                      } else if (uploadedDoc == true && approve == false) {
                        Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const RequiredInformation()),
                            (route) => false);
                      } else {
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
                      }
                    } else if (result == 'otp_required') {
                      Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const Otp(from: 'email')));
                    } else {
                      setState(() => _errorAuth = result?.toString() ?? 'Erro no login');
                    }
                  },
            text: languages[choosenLanguage]['text_login'] ?? 'Entrar',
          ),
          SizedBox(height: media.height * 0.02),
          InkWell(
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (context) => const ForgotPassword())),
            child: Center(
              child: Text(
                languages[choosenLanguage]['text_forgot_password'] ?? 'Esqueci minha senha',
                style: GoogleFonts.poppins(
                  color: buttonColor,
                  fontSize: media.width * 0.035,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          SizedBox(height: media.height * 0.015),
          InkWell(
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (context) => const NamePage())),
            child: Center(
              child: Text(
                languages[choosenLanguage]['text_sign_up'] ?? 'Cadastrar',
                style: GoogleFonts.poppins(
                  color: buttonColor,
                  fontSize: media.width * 0.035,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Atualiza o formatter de máscara quando o país muda
  void _updatePhoneMaskFormatter() {
    _phoneMaskFormatter = MaskTextInputFormatter(
      mask: _getPhoneMask(),
      filter: {"#": RegExp(r'[0-9]')},
      type: MaskAutoCompletionType.lazy,
    );
  }

  countryCode() async {
    isverifyemail = false;
    isLoginemail = false;
    isfromomobile = true;
    await getCountryCode();
    // Atualiza a máscara de telefone quando os países estiverem carregados
    // (evita perder a máscara ao deslogar ou voltar para a tela de login)
    _updatePhoneMaskFormatter();
    if (mounted) {
      setState(() {
        loginLoading = false;
      });
    }
  }

  //navigate
  navigate() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => const Otp()));
  }

  // Função para obter a máscara de telefone baseada no país
  String _getPhoneMask() {
    if (countries.isNotEmpty && phcode != null && countries[phcode] != null) {
      int maxLength = countries[phcode]['dial_max_length'] ?? 11;

      // Máscaras comuns por tamanho
      if (maxLength <= 8) {
        return '####-####';
      } else if (maxLength == 9) {
        return '#####-####';
      } else if (maxLength == 10) {
        return '(##) ####-####'; // DDD + 8 dígitos
      } else if (maxLength == 11) {
        return '(##) #####-####'; // (99) 99999-9999 - celular Brasil
      } else {
        return '(##) #####-####';
      }
    }
    // Padrão brasileiro: (99) 99999-9999
    return '(##) #####-####';
  }

  // Função para obter o hint do telefone
  String _getPhoneHint() {
    if (countries.isNotEmpty && phcode != null && countries[phcode] != null) {
      int maxLength = countries[phcode]['dial_max_length'] ?? 11;

      if (maxLength <= 8) {
        return '1234-5678';
      } else if (maxLength == 9) {
        return '12345-6789';
      } else if (maxLength == 10) {
        return '(11) 9123-4567';
      } else if (maxLength == 11) {
        return '(11) 91234-5678';
      } else {
        return '(11) 91234-5678';
      }
    }
    return '(11) 91234-5678';
  }

  var verifyEmailError = '';
  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    // Garantir que choosenLanguage e languageDirection não sejam null ou vazios
    if (choosenLanguage.isEmpty || choosenLanguage == '') {
      choosenLanguage = 'pt_BR';
      languageDirection = 'ltr';
      // Salvar no SharedPreferences se disponível
      if (pref != null) {
        pref.setString('choosenLanguage', choosenLanguage);
        pref.setString('languageDirection', languageDirection);
      }
      debugPrint('🌐 [LOGIN BUILD] Idioma definido como pt_BR no build');
    }
    if (languageDirection.isEmpty || languageDirection == '') {
      languageDirection = 'ltr';
      if (pref != null) {
        pref.setString('languageDirection', languageDirection);
      }
    }

    debugPrint(
        '🌐 [LOGIN BUILD] Idioma atual: $choosenLanguage, Direção: $languageDirection');

    return Material(
      child: Directionality(
          textDirection: (languageDirection == 'rtl')
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: ValueListenableBuilder(
              valueListenable: valueNotifierLogin.value,
              builder: (context, value, child) {
                return Stack(
                  children: [
                    Container(
                      color: page,
                      padding: EdgeInsets.only(
                          // top: media.width * 0.02,
                          //  MediaQuery.of(context).padding.top,
                          left: media.width * 0.05,
                          right: media.width * 0.05),
                      // height: media.height * 1,
                      width: media.width * 1,
                      height: media.height * 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header com logo centralizado
                          Container(
                            padding: EdgeInsets.only(
                              top: MediaQuery.of(context).padding.top +
                                  media.width * 0.05,
                              bottom: media.width * 0.05,
                            ),
                            width: media.width * 1,
                            alignment: Alignment.center,
                            child: Container(
                              padding: EdgeInsets.all(media.width * 0.01),
                              width: media.width * 0.12,
                              height: media.width * 0.14,
                              decoration: const BoxDecoration(
                                image: DecorationImage(
                                  image:
                                      AssetImage('assets/images/logo_mini.png'),
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: media.width * 0.02),
                          if (loginEmailPswd == 1) ...[
                            InkWell(
                              onTap: () => Navigator.pop(context),
                              child: Icon(
                                Icons.arrow_back_ios,
                                color: textColor,
                                size: media.height * eighteen,
                              ),
                            ),
                            SizedBox(height: media.height * 0.03),
                            Expanded(child: _buildEmailPasswordLogin(media)),
                          ] else ...[
                          InkWell(
                              onTap: () {
                                if (currentPage == 0) {
                                  if (Navigator.canPop(context)) {
                                    Navigator.pop(context);
                                  }
                                } else if (currentPage == 2) {
                                  setState(() {
                                    controller.text = '';
                                    currentPage = 0;
                                    isverifyemail = false;
                                    isLoginemail = false;
                                    isfromomobile = true;
                                  });
                                } else if (currentPage == 1) {
                                  if (currentPage == 1 && isverifyemail) {
                                    setState(() {
                                      isfromomobile = false;
                                      currentPage = 2;
                                    });
                                  } else {
                                    setState(() {
                                      currentPage = currentPage - 1;
                                    });
                                  }
                                } else {
                                  if (currentPage == 3 &&
                                      isverifyemail &&
                                      isLoginemail) {
                                    setState(() {
                                      isfromomobile = false;
                                    });
                                  }
                                  setState(() {
                                    currentPage = currentPage - 1;
                                  });
                                }
                              },
                              child: Icon(
                                Icons.arrow_back_ios,
                                color: textColor,
                                size: media.height * eighteen,
                              )),
                          SizedBox(
                            height: media.height * 0.05,
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 1000),
                            margin: EdgeInsets.only(
                                left: (languageDirection == 'rtl')
                                    ? 0
                                    : (media.width * 0.25) * currentPage,
                                right: (languageDirection == 'ltr')
                                    ? 0
                                    : (media.width * 0.25) * currentPage),
                            child: Image.asset(
                              (languageDirection == 'ltr')
                                  ? 'assets/images/car.png'
                                  : 'assets/images/car_rtl.png',
                              width: media.width * 0.15,
                            ),
                          ),
                          Row(
                            children: pages
                                .asMap()
                                .map((key, value) {
                                  return MapEntry(
                                    key,
                                    Row(
                                      children: [
                                        Column(
                                          children: [
                                            AnimatedContainer(
                                              duration: const Duration(
                                                  milliseconds: 1000),
                                              height:
                                                  (media.width * 0.9 / 4) / 8,
                                              width:
                                                  (media.width * 0.9 / 4) / 8,
                                              color: (currentPage >= key)
                                                  ? const Color(0xff000000)
                                                  : const Color(0xff000000)
                                                      .withOpacity(0.4),
                                            ),
                                            AnimatedContainer(
                                              duration: const Duration(
                                                  milliseconds: 1000),
                                              height:
                                                  (media.width * 0.9 / 4) / 8,
                                              width:
                                                  (media.width * 0.9 / 4) / 8,
                                              color: (currentPage >= key)
                                                  ? buttonColor
                                                  : buttonColor
                                                      .withOpacity(0.4),
                                            )
                                          ],
                                        ),
                                        Column(
                                          children: [
                                            AnimatedContainer(
                                              duration: const Duration(
                                                  milliseconds: 1000),
                                              height:
                                                  (media.width * 0.9 / 4) / 8,
                                              width:
                                                  (media.width * 0.9 / 4) / 8,
                                              color: (currentPage >= key)
                                                  ? const Color(0xffFFFFFF)
                                                  : const Color(0xffFFFFFF)
                                                      .withOpacity(0.4),
                                            ),
                                            AnimatedContainer(
                                              duration: const Duration(
                                                  milliseconds: 1000),
                                              height:
                                                  (media.width * 0.9 / 4) / 8,
                                              width:
                                                  (media.width * 0.9 / 4) / 8,
                                              color: (currentPage >= key)
                                                  ? const Color(0xff000000)
                                                  : const Color(0xff000000)
                                                      .withOpacity(0.4),
                                            )
                                          ],
                                        ),
                                        Column(
                                          children: [
                                            AnimatedContainer(
                                              duration: const Duration(
                                                  milliseconds: 1000),
                                              height:
                                                  (media.width * 0.9 / 4) / 8,
                                              width:
                                                  (media.width * 0.9 / 4) / 8,
                                              color: (currentPage >= key)
                                                  ? const Color(0xff000000)
                                                  : const Color(0xff000000)
                                                      .withOpacity(0.4),
                                            ),
                                            AnimatedContainer(
                                              duration: const Duration(
                                                  milliseconds: 1000),
                                              height:
                                                  (media.width * 0.9 / 4) / 8,
                                              width:
                                                  (media.width * 0.9 / 4) / 8,
                                              color: (currentPage >= key)
                                                  ? const Color(0xffFFFFFF)
                                                  : const Color(0xffFFFFFF)
                                                      .withOpacity(0.4),
                                            )
                                          ],
                                        ),
                                        Column(
                                          children: [
                                            AnimatedContainer(
                                              duration: const Duration(
                                                  milliseconds: 1000),
                                              height:
                                                  (media.width * 0.9 / 4) / 8,
                                              width:
                                                  (media.width * 0.9 / 4) / 8,
                                              color: (currentPage >= key)
                                                  ? buttonColor
                                                  : buttonColor
                                                      .withOpacity(0.4),
                                            ),
                                            AnimatedContainer(
                                              duration: const Duration(
                                                  milliseconds: 1000),
                                              height:
                                                  (media.width * 0.9 / 4) / 8,
                                              width:
                                                  (media.width * 0.9 / 4) / 8,
                                              color: (currentPage >= key)
                                                  ? const Color(0xff000000)
                                                  : const Color(0xff000000)
                                                      .withOpacity(0.4),
                                            )
                                          ],
                                        ),
                                        Column(
                                          children: [
                                            AnimatedContainer(
                                              duration: const Duration(
                                                  milliseconds: 1000),
                                              height:
                                                  (media.width * 0.9 / 4) / 8,
                                              width:
                                                  (media.width * 0.9 / 4) / 8,
                                              color: (currentPage >= key)
                                                  ? const Color(0xff000000)
                                                  : const Color(0xff000000)
                                                      .withOpacity(0.4),
                                            ),
                                            AnimatedContainer(
                                              duration: const Duration(
                                                  milliseconds: 1000),
                                              height:
                                                  (media.width * 0.9 / 4) / 8,
                                              width:
                                                  (media.width * 0.9 / 4) / 8,
                                              color: (currentPage >= key)
                                                  ? buttonColor
                                                  : buttonColor
                                                      .withOpacity(0.4),
                                            )
                                          ],
                                        ),
                                        Column(
                                          children: [
                                            AnimatedContainer(
                                              duration: const Duration(
                                                  milliseconds: 1000),
                                              height:
                                                  (media.width * 0.9 / 4) / 8,
                                              width:
                                                  (media.width * 0.9 / 4) / 8,
                                              color: (currentPage >= key)
                                                  ? const Color(0xffFFFFFF)
                                                  : const Color(0xffFFFFFF)
                                                      .withOpacity(0.4),
                                            ),
                                            AnimatedContainer(
                                              duration: const Duration(
                                                  milliseconds: 1000),
                                              height:
                                                  (media.width * 0.9 / 4) / 8,
                                              width:
                                                  (media.width * 0.9 / 4) / 8,
                                              color: (currentPage >= key)
                                                  ? const Color(0xff000000)
                                                  : const Color(0xff000000)
                                                      .withOpacity(0.4),
                                            )
                                          ],
                                        ),
                                        Column(
                                          children: [
                                            AnimatedContainer(
                                              duration: const Duration(
                                                  milliseconds: 1000),
                                              height:
                                                  (media.width * 0.9 / 4) / 8,
                                              width:
                                                  (media.width * 0.9 / 4) / 8,
                                              color: (currentPage >= key)
                                                  ? const Color(0xff000000)
                                                  : const Color(0xff000000)
                                                      .withOpacity(0.4),
                                            ),
                                            AnimatedContainer(
                                              duration: const Duration(
                                                  milliseconds: 1000),
                                              height:
                                                  (media.width * 0.9 / 4) / 8,
                                              width:
                                                  (media.width * 0.9 / 4) / 8,
                                              color: (currentPage >= key)
                                                  ? const Color(0xffFFFFFF)
                                                  : const Color(0xffFFFFFF)
                                                      .withOpacity(0.4),
                                            )
                                          ],
                                        ),
                                        Column(
                                          children: [
                                            AnimatedContainer(
                                              duration: const Duration(
                                                  milliseconds: 1000),
                                              height:
                                                  (media.width * 0.9 / 4) / 8,
                                              width:
                                                  (media.width * 0.9 / 4) / 8,
                                              color: (currentPage >= key)
                                                  ? buttonColor
                                                  : buttonColor
                                                      .withOpacity(0.4),
                                            ),
                                            AnimatedContainer(
                                              duration: const Duration(
                                                  milliseconds: 1000),
                                              height:
                                                  (media.width * 0.9 / 4) / 8,
                                              width:
                                                  (media.width * 0.9 / 4) / 8,
                                              color: (currentPage >= key)
                                                  ? const Color(0xff000000)
                                                  : const Color(0xff000000)
                                                      .withOpacity(0.4),
                                            )
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                })
                                .values
                                .toList(),
                          ),
                          SizedBox(
                            height: media.height * 0.05,
                          ),
                          (countries.isNotEmpty && currentPage == 0)
                              ? (isLoginemail == false)
                                  ? Column(
                                      children: [
                                        MyText(
                                          text: (languages[choosenLanguage] ??
                                                      languages['en'])?[
                                                  'text_what_mobilenum'] ??
                                              'What\'s your mobile number?',
                                          size: media.width * twenty,
                                          fontweight: FontWeight.bold,
                                        ),
                                        SizedBox(
                                          height: media.height * 0.02,
                                        ),
                                        Container(
                                          padding: const EdgeInsets.fromLTRB(
                                              10, 0, 10, 0),
                                          height: 55,
                                          width: media.width * 0.9,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                              color: _isPhoneFocused
                                                  ? const Color(
                                                      0xFF9A03E9) // Roxo
                                                  : textColor,
                                              width:
                                                  _isPhoneFocused ? 2.0 : 1.0,
                                            ),
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              // País fixo: Brasil (seleção bloqueada)
                                              Container(
                                                height: 50,
                                                alignment: Alignment.center,
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Image.network(
                                                      (countries.isNotEmpty &&
                                                              phcode != null &&
                                                              countries[
                                                                      phcode] !=
                                                                  null &&
                                                              countries[phcode][
                                                                      'flag'] !=
                                                                  null
                                                          ? countries[phcode]
                                                              ['flag']
                                                          : 'https://flagcdn.com/w40/br.png'),
                                                      width: 24,
                                                      height: 24,
                                                      fit: BoxFit.contain,
                                                    ),
                                                    SizedBox(
                                                        width:
                                                            media.width * 0.02),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Container(
                                                width: 1,
                                                height: 35,
                                                color: underline,
                                              ),
                                              const SizedBox(width: 10),
                                              // Código do país - centralizado verticalmente
                                              Container(
                                                height: 50,
                                                alignment: Alignment.center,
                                                child: MyText(
                                                  text: (countries.isNotEmpty &&
                                                          phcode != null &&
                                                          countries[phcode] !=
                                                              null &&
                                                          countries[phcode][
                                                                  'dial_code'] !=
                                                              null)
                                                      ? countries[phcode]
                                                              ['dial_code']
                                                          .toString()
                                                      : '+55',
                                                  size: media.width * sixteen,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              // Campo de texto com máscara - centralizado verticalmente
                                              Expanded(
                                                child: Container(
                                                  height: 50,
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: TextFormField(
                                                    textAlign: TextAlign.start,
                                                    controller: controller,
                                                    focusNode: _phoneFocusNode,
                                                    inputFormatters:
                                                        _phoneMaskFormatter !=
                                                                null
                                                            ? [
                                                                _phoneMaskFormatter!
                                                              ]
                                                            : [],
                                                    onChanged: (val) {
                                                      // Remove caracteres não numéricos para armazenar apenas números
                                                      String digitsOnly =
                                                          val.replaceAll(
                                                              RegExp(r'[^\d]'),
                                                              '');
                                                      phnumber = digitsOnly;
                                                      int maxLength = (countries
                                                                  .isNotEmpty &&
                                                              phcode != null &&
                                                              countries[
                                                                      phcode] !=
                                                                  null
                                                          ? countries[phcode][
                                                                  'dial_max_length'] ??
                                                              10
                                                          : 10);
                                                      if (digitsOnly.length >=
                                                          maxLength) {
                                                        FocusManager.instance
                                                            .primaryFocus
                                                            ?.unfocus();
                                                      }
                                                      // Atualizar a UI para mostrar/esconder o botão
                                                      setState(() {});
                                                    },
                                                    style: choosenLanguage ==
                                                            'ar'
                                                        ? GoogleFonts.cairo(
                                                            color: textColor,
                                                            fontSize:
                                                                media.width *
                                                                    sixteen,
                                                            letterSpacing: 1,
                                                            height: 1.0,
                                                          )
                                                        : GoogleFonts.poppins(
                                                            color: textColor,
                                                            fontSize:
                                                                media.width *
                                                                    sixteen,
                                                            letterSpacing: 1,
                                                            height: 1.0,
                                                          ),
                                                    keyboardType:
                                                        TextInputType.number,
                                                    decoration: InputDecoration(
                                                      counterText: '',
                                                      hintText: _getPhoneHint(),
                                                      hintStyle:
                                                          choosenLanguage ==
                                                                  'ar'
                                                              ? GoogleFonts
                                                                  .cairo(
                                                                  color: textColor
                                                                      .withOpacity(
                                                                          0.7),
                                                                  fontSize: media
                                                                          .width *
                                                                      sixteen,
                                                                )
                                                              : GoogleFonts
                                                                  .poppins(
                                                                  color: textColor
                                                                      .withOpacity(
                                                                          0.7),
                                                                  fontSize: media
                                                                          .width *
                                                                      sixteen,
                                                                ),
                                                      border: InputBorder.none,
                                                      enabledBorder:
                                                          InputBorder.none,
                                                      contentPadding:
                                                          const EdgeInsets
                                                              .symmetric(
                                                              vertical: 0),
                                                      isDense: true,
                                                    ),
                                                  ),
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: media.height * 0.02),
                                        MyText(
                                          text: (languages[choosenLanguage] ??
                                                      languages['en'])?[
                                                  'text_you_get_otp'] ??
                                              'You will get a sms for Verification',
                                          size: media.width * fourteen,
                                          color: textColor.withOpacity(0.5),
                                        ),
                                        SizedBox(height: media.height * 0.03),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            InkWell(
                                              onTap: () {
                                                controller.clear();
                                                if (isLoginemail == false) {
                                                  setState(() {
                                                    _error = '';
                                                    isLoginemail = true;
                                                  });
                                                } else {
                                                  setState(() {
                                                    _error = '';
                                                    isLoginemail = false;
                                                  });
                                                }
                                              },
                                              child: Text(
                                                ((languages[choosenLanguage] ??
                                                                languages[
                                                                    'en'])?[
                                                            'text_continue_with'] ??
                                                        'Continue with') +
                                                    ' ' +
                                                    ((languages[choosenLanguage] ??
                                                                languages[
                                                                    'en'])?[
                                                            'text_email'] ??
                                                        'Email'),
                                                style: GoogleFonts.poppins(
                                                  color: textColor
                                                      .withOpacity(0.7),
                                                  fontSize:
                                                      media.width * sixteen,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: media.width * 0.02),
                                            Icon(Icons.email_outlined,
                                                size: media.width * eighteen,
                                                color:
                                                    textColor.withOpacity(0.7)),
                                          ],
                                        ),
                                        SizedBox(
                                          height: media.height * 0.03,
                                        ),
                                        if (_error != '')
                                          Column(
                                            children: [
                                              SizedBox(
                                                  width: media.width * 0.9,
                                                  child: MyText(
                                                    text: _error,
                                                    color: Colors.red,
                                                    size:
                                                        media.width * fourteen,
                                                    textAlign: TextAlign.center,
                                                  )),
                                              SizedBox(
                                                height: media.width * 0.025,
                                              )
                                            ],
                                          ),
                                        (controller.text.length >=
                                                (countries.isNotEmpty &&
                                                        phcode != null &&
                                                        countries[phcode] !=
                                                            null
                                                    ? countries[phcode][
                                                            'dial_min_length'] ??
                                                        8
                                                    : 8))
                                            ? Container(
                                                width: media.width * 1 -
                                                    media.width * 0.08,
                                                alignment: Alignment.center,
                                                child: Button(
                                                  onTap: () async {
                                                    // Verificar se está fazendo login com email - se sim, não executar lógica de telefone
                                                    if (isLoginemail == true) {
                                                      return; // Não fazer nada se estiver em modo email
                                                    }

                                                    if (controller.text.length >=
                                                        (countries.isNotEmpty &&
                                                                phcode !=
                                                                    null &&
                                                                countries[
                                                                        phcode] !=
                                                                    null
                                                            ? countries[phcode][
                                                                    'dial_min_length'] ??
                                                                8
                                                            : 8)) {
                                                      _error = '';
                                                      FocusManager
                                                          .instance.primaryFocus
                                                          ?.unfocus();
                                                      setState(() {
                                                        loginLoading = true;
                                                      });
                                                      // Sempre usar Firebase OTP para celular: envia SMS e exige código
                                                      phoneAuthCheck = true;
                                                      await phoneAuth((countries[
                                                                      phcode]?[
                                                                  'dial_code'] ??
                                                              '') +
                                                          phnumber);
                                                      value = 0;
                                                      currentPage = 1;
                                                      loginLoading = false;
                                                      setState(() {});
                                                      // setState(() {

                                                      // });
                                                    }
                                                    //  else {
                                                    //   var snackdemo =
                                                    //       SnackBar(
                                                    //     content: MyText(
                                                    //         textAlign:
                                                    //             TextAlign
                                                    //                 .center,
                                                    //         text:
                                                    //             'Mobile Number Must be ${countries[phcode]['dial_min_length']} Digits',
                                                    //         size: fourteen),
                                                    //     backgroundColor:
                                                    //         verifyDeclined,
                                                    //     elevation: 10,
                                                    //     behavior:
                                                    //         SnackBarBehavior
                                                    //             .floating,
                                                    //     margin:
                                                    //         EdgeInsets.all(
                                                    //             media.width *
                                                    //                 0.05),
                                                    //   );
                                                    //   ScaffoldMessenger.of(
                                                    //           context)
                                                    //       .showSnackBar(
                                                    //           snackdemo);
                                                    // }
                                                  },
                                                  text:
                                                      (languages[choosenLanguage] ??
                                                                  languages[
                                                                      'en'])?[
                                                              'text_login'] ??
                                                          'Login',
                                                ),
                                              )
                                            : Container(),
                                      ],
                                    )
                                  : Column(
                                      children: [
                                        MyText(
                                          text: (languages[choosenLanguage] ??
                                                      languages['en'])?[
                                                  'text_what_email'] ??
                                              'What\'s Your Email?',
                                          size: media.width * twenty,
                                          fontweight: FontWeight.bold,
                                        ),
                                        SizedBox(
                                          height: media.height * 0.02,
                                        ),
                                        Container(
                                            height: media.width * 0.13,
                                            decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                    color: _isEmailFocused
                                                        ? const Color(
                                                            0xFF9A03E9) // Roxo
                                                        : (isDarkTheme == true)
                                                            ? textColor
                                                                .withOpacity(
                                                                    1.0)
                                                            : const Color(
                                                                    0xff12121D)
                                                                .withOpacity(
                                                                    0.6),
                                                    width: _isEmailFocused
                                                        ? 2.0
                                                        : 1.5),
                                                color: (isDarkTheme == true)
                                                    ? page
                                                    : const Color(0xffF8F8F8)),
                                            padding: const EdgeInsets.only(
                                                left: 5, right: 5),
                                            child: MyTextField(
                                              textController: controller,
                                              focusNode: _emailFocusNode,
                                              hinttext:
                                                  (languages[choosenLanguage] ??
                                                              languages['en'])?[
                                                          'text_enter_email'] ??
                                                      'Enter Your Email Address',
                                              contentpadding:
                                                  EdgeInsets.symmetric(
                                                vertical: (media.width * 0.13 -
                                                        media.width *
                                                            fourteen *
                                                            1.5) /
                                                    2,
                                                horizontal: 0,
                                              ),
                                              onTap: (val) {
                                                setState(() {
                                                  email = controller.text;
                                                });
                                              },
                                            )),
                                        SizedBox(height: media.height * 0.02),
                                        MyText(
                                          text: (languages[choosenLanguage] ??
                                                      languages['en'])?[
                                                  'text_you_get_otp_email'] ??
                                              'You will get a sms for Verification',
                                          size: media.width * fourteen,
                                          color: textColor.withOpacity(0.5),
                                        ),
                                        SizedBox(height: media.height * 0.05),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            InkWell(
                                              onTap: () {
                                                controller.clear();
                                                if (isLoginemail == false) {
                                                  setState(() {
                                                    _error = '';
                                                    isLoginemail = true;
                                                  });
                                                } else {
                                                  setState(() {
                                                    _error = '';
                                                    isLoginemail = false;
                                                  });
                                                }
                                              },
                                              child: Text(
                                                ((languages[choosenLanguage] ??
                                                                languages[
                                                                    'en'])?[
                                                            'text_continue_with'] ??
                                                        'Continue with') +
                                                    ' ' +
                                                    ((languages[choosenLanguage] ??
                                                                languages[
                                                                    'en'])?[
                                                            'text_mob_num'] ??
                                                        'Mobile Number'),
                                                style: GoogleFonts.poppins(
                                                  color: textColor
                                                      .withOpacity(0.7),
                                                  fontSize:
                                                      media.width * sixteen,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: media.width * 0.03,
                                            ),
                                            Icon(Icons.call,
                                                size: media.width * eighteen,
                                                color:
                                                    textColor.withOpacity(0.7)),
                                            // SizedBox(
                                            //     width: media.width * 0.03),
                                          ],
                                        ),
                                        SizedBox(
                                          height: media.height * 0.05,
                                        ),
                                        if (_error != '')
                                          Column(
                                            children: [
                                              SizedBox(
                                                  width: media.width * 0.9,
                                                  child: MyText(
                                                    text: _error,
                                                    color: Colors.red,
                                                    size:
                                                        media.width * fourteen,
                                                    textAlign: TextAlign.center,
                                                  )),
                                              SizedBox(
                                                height: media.width * 0.025,
                                              )
                                            ],
                                          ),
                                        (controller.text.isNotEmpty)
                                            ? Container(
                                                width: media.width * 1,
                                                alignment: Alignment.center,
                                                child: Button(
                                                    onTap: () async {
                                                      setState(() {
                                                        _error = '';
                                                      });
                                                      String pattern =
                                                          r"^[a-zA-Z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?\.)+[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])*$";
                                                      RegExp regex =
                                                          RegExp(pattern);
                                                      if (regex.hasMatch(
                                                          controller.text)) {
                                                        FocusManager.instance
                                                            .primaryFocus
                                                            ?.unfocus();

                                                        setState(() {
                                                          verifyEmailError = '';
                                                          loginLoading = true;
                                                        });

                                                        phoneAuthCheck =
                                                            false; // Não usar phoneAuth quando for email
                                                        await sendOTPtoEmail(
                                                            email);
                                                        value = 1;
                                                        isfromomobile = false;
                                                        currentPage = 1;

                                                        // navigate();

                                                        setState(() {
                                                          loginLoading = false;
                                                        });
                                                      } else {
                                                        setState(() {
                                                          loginLoading = false;
                                                          _error = (languages[
                                                                          choosenLanguage] ??
                                                                      languages[
                                                                          'en'])?[
                                                                  'text_email_validation'] ??
                                                              'Please enter valid email address';
                                                        });
                                                        // var snackdemo =
                                                        //     SnackBar(
                                                        //   content: Text(
                                                        //     languages[
                                                        //             choosenLanguage]
                                                        //         [
                                                        //         'text_email_validation'],
                                                        //     textAlign:
                                                        //         TextAlign
                                                        //             .center,
                                                        //     style: GoogleFonts.poppins(
                                                        //         fontSize: media
                                                        //                 .width *
                                                        //             fourteen,
                                                        //         fontWeight:
                                                        //             FontWeight
                                                        //                 .w600,
                                                        //         color:
                                                        //             textColor),
                                                        //   ),
                                                        //   // MyText(
                                                        //   //     color: topBar,
                                                        //   //     textAlign:
                                                        //   //         TextAlign
                                                        //   //             .center,
                                                        //   //     text: languages[
                                                        //   //             choosenLanguage]
                                                        //   //         [
                                                        //   //         'text_email_validation'],
                                                        //   //     size: fourteen),
                                                        //   backgroundColor:
                                                        //       verifyDeclined,
                                                        //   elevation: 10,
                                                        //   behavior:
                                                        //       SnackBarBehavior
                                                        //           .floating,
                                                        //   margin: EdgeInsets
                                                        //       .all(media
                                                        //               .width *
                                                        //           0.05),
                                                        // );
                                                        // ScaffoldMessenger.of(
                                                        //         context)
                                                        //     .showSnackBar(
                                                        //         snackdemo);
                                                      }
                                                    },
                                                    text:
                                                        (languages[choosenLanguage] ??
                                                                    languages[
                                                                        'en'])?[
                                                                'text_login'] ??
                                                            'Login'))
                                            : Container(),
                                      ],
                                    )
                              : (currentPage == 1)
                                  ? const Expanded(child: Otp())
                                  : (currentPage == 2)
                                      ? const Expanded(child: NamePage())
                                      : (currentPage == 3)
                                          ? const Expanded(
                                              child: AggreementPage())
                                          : Container(),
                        ],
                        ],
                      ),
                    ),
                    //No internet
                    (internet == false)
                        ? Positioned(
                            top: 0,
                            child: NoInternet(onTap: () {
                              setState(() {
                                loginLoading = true;
                                internet = true;
                                countryCode();
                              });
                            }))
                        : Container(),

                    //loader
                    (loginLoading == true)
                        ? const Positioned(top: 0, child: Loading())
                        : Container()
                  ],
                );
              })),
    );
  }
}

class CustomTimerPainter extends CustomPainter {
  CustomTimerPainter({
    required this.animation,
    required this.backgroundColor,
    required this.color,
  }) : super(repaint: animation);

  final Animation<double> animation;
  final Color backgroundColor, color;

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = backgroundColor
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.butt
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(size.center(Offset.zero), size.width / 2.0, paint);
    paint.color = color;
    double progress = (1.0 - animation.value) * 2 * math.pi;
    canvas.drawArc(Offset.zero & size, math.pi * 1.5, -progress, false, paint);
  }

  @override
  bool shouldRepaint(CustomTimerPainter oldDelegate) {
    return animation.value != oldDelegate.animation.value ||
        color != oldDelegate.color ||
        backgroundColor != oldDelegate.backgroundColor;
  }
}
