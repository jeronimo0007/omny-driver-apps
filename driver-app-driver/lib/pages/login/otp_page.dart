import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_driver/pages/onTripPage/map_page.dart';
import 'package:flutter_driver/pages/onTripPage/rides.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import '../../config/api_config.dart';
import '../../styles/styles.dart';
import '../../functions/functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:math' as math;
import '../../translation/translation.dart';
import '../../widgets/widgets.dart';
import '../noInternet/nointernet.dart';
import 'login.dart';
import 'namepage.dart';
import 'requiredinformation.dart';

class Otp extends StatefulWidget {
  final dynamic from;

  const Otp({Key? key, this.from}) : super(key: key);

  @override
  State<Otp> createState() => _OtpState();
}

class _OtpState extends State<Otp> with TickerProviderStateMixin {
  String otpNumber = ''; //otp number

  final _pinPutController2 = TextEditingController();
  dynamic aController;
  bool _resend = false;
  String _error = '';
  String _successMessage = '';
  int _resendDuration = 90; // Primeiro tempo: 90 segundos
  int _resendCountToday = 0;
  static const int _maxResendPerDay = 6;

  String get timerString {
    Duration duration = aController.duration * aController.value;
    return '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  Future<void> _loadResendCount() async {
    final prefs = pref ?? await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final savedDate = prefs.getString('otp_resend_date');
    if (savedDate == today) {
      if (mounted) {
        setState(() {
          _resendCountToday = prefs.getInt('otp_resend_count') ?? 0;
        });
      }
    } else {
      await prefs.setString('otp_resend_date', today);
      await prefs.setInt('otp_resend_count', 0);
      if (mounted) setState(() => _resendCountToday = 0);
    }
  }

  Future<void> _saveResendCount() async {
    final prefs = pref ?? await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await prefs.setString('otp_resend_date', today);
    await prefs.setInt('otp_resend_count', _resendCountToday);
  }

  @override
  void initState() {
    super.initState();
    aController = AnimationController(
        vsync: this, duration: Duration(seconds: _resendDuration));
    aController.reverse(from: _resendDuration.toDouble());
    _loadResendCount();
    otpFalse();
  }

  @override
  void dispose() {
    _error = '';
    aController.dispose();
    super.dispose();
  }

//navigate
  navigate(verify) {
    if (verify == true) {
      final uploadedDoc = userDetails['uploaded_document'];
      final approve = userDetails['approve'];
      if (uploadedDoc == false || uploadedDoc == null) {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (context) => const RequiredInformation()),
            (route) => false);
      } else if (uploadedDoc == true && approve == false) {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const RequiredInformation(),
            ),
            (route) => false);
      } else {
        // uploadedDoc == true && (approve == true ou approve null/outro) → tela principal
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
    } else if (verify == false) {
      if (isverifyemail == true) {
        currentPage = 3;
      } else {
        currentPage = 2;
      }
      valueNotifierLogin.incrementNotifier();
    } else {
      // verify é a mensagem de erro da API (ex: "O número de celular fornecido já está em uso.")
      setState(() {
        _error = verify is String ? verify : verify.toString();
      });
    }
    loginLoading = false;
    valueNotifierLogin.incrementNotifier();
  }

  otpFalse() async {
    // Quando login é por e-mail/senha (auth), só usamos validateOtpAuth (validate-otp). Nunca verifyUser.
    if (loginEmailPswd == 1) {
      return;
    }
    if (widget.from == 'email' || authTempTokenForOtp != null) {
      return;
    }
    // Não validar automaticamente no fluxo de celular: usuário deve digitar o código SMS
    if (phoneAuthCheck == false && isverifyemail == true) {
      emaillogin();
    }
  }

  normallogin() async {
    var verify = await verifyUser(phnumber);
    navigate(verify);
  }

  emaillogin() async {
    var verify = await verifyUser(phnumber);
    if (verify == false) {
      _pinPutController2.text = '123456';
      otpNumber = _pinPutController2.text;
      navigate(verify);
    } else {
      setState(() {
        _pinPutController2.text = '';
        _error = verify is String
            ? verify
            : ((languages[choosenLanguage] ??
                    languages['en'])?['text_mobile_already_taken'] ??
                'Mobile number already taken');
      });
    }
  }

//auto verify otp

  verifyOtp() async {
    FocusManager.instance.primaryFocus?.unfocus();
    try {
      // Sign the user in (or link) with the credential
      await FirebaseAuth.instance.signInWithCredential(credentials);

      var verify = await verifyUser(phnumber);
      credentials = null;
      navigate(verify);
    } on FirebaseAuthException catch (error) {
      if (error.code == 'invalid-verification-code') {
        setState(() {
          _pinPutController2.clear();
          _error = (languages[choosenLanguage] ??
                  languages['en'])?['text_otp_error'] ??
              'Please enter correct Otp or resend';
        });
      }
    }
  }

  showToast() {
    setState(() {
      showtoast = true;
    });
    Future.delayed(const Duration(seconds: 4), () {
      setState(() {
        showtoast = false;
      });
    });
  }

  bool showtoast = false;

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    final paddingH = media.width * 0.06;
    final prefix = (languages[choosenLanguage] ?? languages['en'])?['text_enter_otp_at'] ?? 'Digite o código enviado para ';
    // Fluxo auth (e-mail): priorizar e-mail; senão celular; senão email do cadastro
    final otpSubtitle = (widget.from == 'email' || authTempTokenForOtp != null) &&
            authEmailOrMobileForOtp != null &&
            authEmailOrMobileForOtp!.isNotEmpty
        ? prefix + authEmailOrMobileForOtp!
        : isfromomobile == true
            ? prefix + (countries[phcode]?['dial_code'] ?? '') + phnumber
            : prefix + email;

    return Material(
      color: page,
      child: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header com botão voltar e logo
                Container(
                  color: page,
                  padding: EdgeInsets.only(
                    top: media.width * 0.03,
                    left: media.width * 0.05,
                    right: media.width * 0.05,
                    bottom: media.width * 0.03,
                  ),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        child: Icon(
                          Icons.arrow_back_ios,
                          color: textColor,
                          size: media.height * 0.024,
                        ),
                      ),
                      Expanded(
                        child: Container(
                          alignment: Alignment.center,
                          child: Image.asset(
                            'assets/images/logo_mini.png',
                            width: media.width * 0.12,
                            height: media.width * 0.12,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                      ),
                      SizedBox(width: media.height * 0.024),
                    ],
                  ),
                ),
                Expanded(
                  child: AnimatedBuilder(
                      animation: aController,
                      builder: (context, child) {
                        if (timerString == "0:00") {
                          _resend = true;
                        }
                        return SingleChildScrollView(
                          padding: EdgeInsets.symmetric(horizontal: paddingH, vertical: media.height * 0.02),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              MyText(
                                text: otpSubtitle,
                                size: media.width * twenty,
                                fontweight: FontWeight.bold,
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: media.height * 0.02),
                              Pinput(
                                  length: 6,
                                  onChanged: (val) {
                                    otpNumber = _pinPutController2.text;
                                  },
                                  // onSubmitted: (String val) {},
                                  controller: _pinPutController2,
                                  defaultPinTheme: PinTheme(
                                    width: media.width * 0.15,
                                    height: media.width * 0.15,
                                    textStyle: GoogleFonts.poppins(
                                        fontSize: media.width * twenty,
                                        fontWeight: FontWeight.w700,
                                        color: textColor),
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFF9A03E9)
                                            .withOpacity(0.3),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  focusedPinTheme: PinTheme(
                                    width: media.width * 0.15,
                                    height: media.width * 0.15,
                                    textStyle: GoogleFonts.poppins(
                                        fontSize: media.width * twenty,
                                        fontWeight: FontWeight.w700,
                                        color: textColor),
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFF9A03E9),
                                        width: 2.0,
                                      ),
                                    ),
                                  ),
                                  submittedPinTheme: PinTheme(
                                    width: media.width * 0.15,
                                    height: media.width * 0.15,
                                    textStyle: GoogleFonts.poppins(
                                        fontSize: media.width * twenty,
                                        fontWeight: FontWeight.w700,
                                        color: textColor),
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFF9A03E9),
                                        width: 2.0,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                TextButton(
                                    onPressed: (_resend &&
                                            _resendCountToday <
                                                _maxResendPerDay)
                                        ? () async {
                                            loginLoading = true;
                                            valueNotifierLogin
                                                .incrementNotifier();
                                            if (loginEmailPswd == 1 &&
                                                authTempTokenForOtp != null) {
                                              var sendResult =
                                                  await sendOtpAuth();
                                              setState(() {
                                                _error = '';
                                                _pinPutController2.text = '';
                                                _resend = false;
                                              });
                                              if (sendResult == 'success') {
                                                setState(() {
                                                  _successMessage = languages[choosenLanguage]['text_otp_resent'] ?? 'Código reenviado! Verifique seu e-mail.';
                                                  _error = '';
                                                });
                                                Future.delayed(const Duration(seconds: 3), () {
                                                  if (mounted) setState(() => _successMessage = '');
                                                });
                                                _resendDuration =
                                                    _resendDuration * 2;
                                                aController.dispose();
                                                aController =
                                                    AnimationController(
                                                        vsync: this,
                                                        duration: Duration(
                                                            seconds:
                                                                _resendDuration));
                                                aController.reverse(
                                                    from: _resendDuration
                                                        .toDouble());
                                              } else {
                                                setState(() =>
                                                    _error = sendResult);
                                              }
                                            } else if (loginEmailPswd != 1 &&
                                                isfromomobile == true) {
                                              var verify =
                                                  await verifyUser(phnumber);
                                              if (verify == false) {
                                                await phoneAuth(
                                                    countries[phcode]
                                                            ['dial_code'] +
                                                        phnumber);
                                                setState(() {
                                                  _error = '';
                                                  _pinPutController2.text = '';
                                                  _resend = false;
                                                  _resendCountToday++;
                                                  _resendDuration =
                                                      _resendDuration * 2;
                                                });
                                                await _saveResendCount();
                                                aController.dispose();
                                                aController =
                                                    AnimationController(
                                                        vsync: this,
                                                        duration: Duration(
                                                            seconds:
                                                                _resendDuration));
                                                aController.reverse(
                                                    from: _resendDuration
                                                        .toDouble());
                                                if (mounted) setState(() {});
                                              } else {
                                                setState(() {
                                                  _pinPutController2.text = '';
                                                  _error = verify is String
                                                      ? verify
                                                      : (languages[
                                                                  choosenLanguage]
                                                              ?[
                                                              'text_mobile_already_taken'] ??
                                                          'O número de celular já está em uso.');
                                                });
                                              }
                                            }
                                            loginLoading = false;
                                            valueNotifierLogin
                                                .incrementNotifier();
                                          }
                                        : null,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        MyText(
                                          text: languages[choosenLanguage]
                                              ['text_resend_otp'],
                                          size: media.width * sixteen,
                                          color: (_resend &&
                                                  _resendCountToday <
                                                      _maxResendPerDay)
                                              ? buttonColor
                                              : buttonColor.withOpacity(0.4),
                                        ),
                                        if (_resendCountToday >=
                                            _maxResendPerDay)
                                          Padding(
                                            padding: EdgeInsets.only(
                                                top: media.width * 0.02),
                                            child: MyText(
                                              text: languages[choosenLanguage][
                                                      'text_max_resend_per_day'] ??
                                                  'Máximo de 6 reenvios por dia.',
                                              size: media.width * twelve,
                                              color: Colors.red,
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                      ],
                                    )),
                                SizedBox(height: media.height * 0.02),
                                Container(
                                  width: media.width * 0.9,
                                  alignment: Alignment.center,
                                  child: SizedBox(
                                    height: 55,
                                    width: 55,
                                    child: CustomPaint(
                                        // ignore: sort_child_properties_last
                                        child: Center(
                                          child: MyText(
                                            text: timerString,
                                            size: media.width * fourteen,
                                            fontweight: FontWeight.bold,
                                          ),
                                        ),
                                        painter: CustomTimerPainter(
                                            animation: aController,
                                            backgroundColor: buttonColor,
                                            color: const Color(0xffEDF0F4))),
                                  ),
                                ),
                              ],
                            ),
                          );
                    }),
              ),
              if (_successMessage != '')
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: paddingH, vertical: media.width * 0.02),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: media.width * 0.04,
                      vertical: media.width * 0.035,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.shade300,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          color: Colors.green.shade700,
                          size: media.width * 0.065,
                        ),
                        SizedBox(width: media.width * 0.03),
                        Expanded(
                          child: MyText(
                            text: _successMessage,
                            color: Colors.green.shade800,
                            size: media.width * fourteen,
                            textAlign: TextAlign.start,
                            fontweight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_error != '')
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: paddingH, vertical: media.width * 0.02),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: media.width * 0.04,
                      vertical: media.width * 0.035,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red.shade300,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: Colors.red.shade700,
                          size: media.width * 0.065,
                        ),
                        SizedBox(width: media.width * 0.03),
                        Expanded(
                          child: MyText(
                            text: _error,
                            color: Colors.red.shade800,
                            size: media.width * fourteen,
                            textAlign: TextAlign.start,
                            fontweight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              (isfromomobile == true && loginEmailPswd != 1)
                  ? Container(
                      alignment: Alignment.center,
                      child: Button(
                        onTap: () async {
                          if (_pinPutController2.length == 6) {
                            setState(() {
                              _error = '';
                            });
                            loginLoading = true;

                            valueNotifierLogin.incrementNotifier();
                            //firebase code send false
                            if (phoneAuthCheck == false) {
                              var verify = await verifyUser(phnumber);
                              value = 0;
                              navigate(verify);
                            } else {
                              // Web: se Firebase não foi inicializado, orientar a usar e-mail
                              if (kIsWeb && Firebase.apps.isEmpty) {
                                setState(() {
                                  _error =
                                      'Login por telefone não disponível na web. Use login por e-mail.';
                                });
                                loginLoading = false;
                                valueNotifierLogin.incrementNotifier();
                                return;
                              }
                              // firebase code send true
                              try {
                                PhoneAuthCredential credential =
                                    PhoneAuthProvider.credential(
                                        verificationId: verId,
                                        smsCode: otpNumber);

                                // Sign the user in (or link) with the credential
                                await FirebaseAuth.instance
                                    .signInWithCredential(credential);

                                var verify = await verifyUser(phnumber);
                                navigate(verify);

                                value = 0;
                              } on FirebaseAuthException catch (error) {
                                if (error.code == 'invalid-verification-code') {
                                  setState(() {
                                    _pinPutController2.clear();
                                    otpNumber = '';
                                    _error = languages[choosenLanguage]
                                        ['text_otp_error'];
                                  });
                                }
                              }
                            }

                            loginLoading = false;
                            valueNotifierLogin.incrementNotifier();
                          }
                        },
                        text: languages[choosenLanguage]['text_verify'],
                      ),
                    )
                  : Container(
                      alignment: Alignment.center,
                      child: Button(
                          onTap: () async {
                            if (_pinPutController2.length == 6) {
                              setState(() {
                                _error = '';
                              });
                              loginLoading = true;

                              valueNotifierLogin.incrementNotifier();
                              if (authTempTokenForOtp != null ||
                                  loginEmailPswd == 1) {
                                if (authTempTokenForOtp == null ||
                                    authEmailOrMobileForOtp == null ||
                                    authEmailOrMobileForOtp!.isEmpty) {
                                  setState(() {
                                    _error = languages[choosenLanguage]
                                            ['text_otp_error'] ??
                                        'Sessão expirada. Faça login novamente.';
                                  });
                                  loginLoading = false;
                                  valueNotifierLogin.incrementNotifier();
                                  return;
                                }
                                var ok = await validateOtpAuth(otpNumber);
                                if (ok) {
                                  isfromomobile = false;
                                  _error = '';
                                  var u = await getUserDetails();
                                  if (u == 'logout') return;
                                  value = 1;
                                  navigate(true);
                                } else {
                                  setState(() {
                                    _pinPutController2.clear();
                                    otpNumber = '';
                                    _error = languages[choosenLanguage]
                                            ['text_otp_error'] ??
                                        'Código inválido';
                                  });
                                }
                              } else {
                                var result =
                                    await emailVerify(email, otpNumber);

                                if (result == 'success') {
                                  isfromomobile = false;
                                  _error = '';
                                  var verify = await verifyUser(email);
                                  value = 1;
                                  navigate(verify);
                                } else {
                                  setState(() {
                                    _pinPutController2.clear();
                                    otpNumber = '';
                                    _error = languages[choosenLanguage]
                                        ['text_otp_error'];
                                  });
                                }
                              }
                            }
                            loginLoading = false;
                            valueNotifierLogin.incrementNotifier();
                          },
                          text: languages[choosenLanguage]['text_verify']),
                    ),
              const SizedBox(
                height: 25,
              )
            ],
          ),
          //no internet
          (internet == false)
              ? Positioned(
                  top: 0,
                  child: NoInternet(
                    onTap: () {
                      setState(() {
                        internetTrue();
                      });
                    },
                  ))
              : Container(),

          //display toast
          (showtoast == true)
              ? Positioned(
                  bottom: media.width * 0.1,
                  left: media.width * 0.06,
                  right: media.width * 0.06,
                  child: Container(
                    padding: EdgeInsets.all(media.width * 0.04),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                              blurRadius: 2.0,
                              spreadRadius: 2.0,
                              color: Colors.black.withOpacity(0.2))
                        ],
                        color: verifyDeclined),
                    child: Text(
                      _error,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                          fontSize: media.width * fourteen,
                          fontWeight: FontWeight.w600,
                          color: textColor),
                    ),
                  ))
              : Container()
        ],
      ),
      ),
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
