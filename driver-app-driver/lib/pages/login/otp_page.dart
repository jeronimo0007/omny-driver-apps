import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_driver/pages/onTripPage/map_page.dart';
import 'package:flutter_driver/pages/onTripPage/rides.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
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
      if (mounted) setState(() {
        _resendCountToday = prefs.getInt('otp_resend_count') ?? 0;
      });
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
      if (userDetails['uploaded_document'] == false) {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (context) => const RequiredInformation()),
            (route) => false);
      } else if (userDetails['uploaded_document'] == true &&
          userDetails['approve'] == false) {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const RequiredInformation(),
            ),
            (route) => false);
      } else if (userDetails['uploaded_document'] == true &&
          userDetails['approve'] == true) {
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
    return Material(
      color: page,
      child: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: AnimatedBuilder(
                    animation: aController,
                    builder: (context, child) {
                      if (timerString == "0:00") {
                        _resend = true;
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SingleChildScrollView(
                            child: Column(
                              children: [
                                (isfromomobile == true)
                                    ? SizedBox(
                                        child: MyText(
                                          // ignore: prefer_interpolation_to_compose_strings
                                          text: ((languages[choosenLanguage] ??
                                                          languages['en'])?[
                                                      'text_enter_otp_at'] ??
                                                  'Enter the OTP number send to you at ') +
                                              (countries[phcode]
                                                      ?['dial_code'] ??
                                                  '') +
                                              phnumber,
                                          size: media.width * twenty,
                                          fontweight: FontWeight.bold,
                                        ),
                                      )
                                    : SizedBox(
                                        child: MyText(
                                          // ignore: prefer_interpolation_to_compose_strings
                                          text: languages[choosenLanguage]
                                                  ['text_enter_otp_at'] +
                                              email,
                                          size: media.width * twenty,
                                          fontweight: FontWeight.bold,
                                        ),
                                      ),
                                const SizedBox(
                                  height: 10,
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
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
                                    onPressed: (_resend && _resendCountToday < _maxResendPerDay)
                                        ? () async {
                                            loginLoading = true;
                                            valueNotifierLogin.incrementNotifier();
                                            var verify = await verifyUser(phnumber);
                                            if (verify == false) {
                                              await phoneAuth(countries[phcode]['dial_code'] + phnumber);
                                              setState(() {
                                                _error = '';
                                                _pinPutController2.text = '';
                                                _resend = false;
                                                _resendCountToday++;
                                                _resendDuration = _resendDuration * 2;
                                              });
                                              await _saveResendCount();
                                              aController.dispose();
                                              aController = AnimationController(
                                                  vsync: this,
                                                  duration: Duration(seconds: _resendDuration));
                                              aController.reverse(from: _resendDuration.toDouble());
                                              if (mounted) setState(() {});
                                            } else {
                                              setState(() {
                                                _pinPutController2.text = '';
                                                _error = verify is String
                                                    ? verify
                                                    : (languages[choosenLanguage]?['text_mobile_already_taken'] ??
                                                        'O número de celular já está em uso.');
                                              });
                                            }
                                            loginLoading = false;
                                            valueNotifierLogin.incrementNotifier();
                                          }
                                        : null,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        MyText(
                                          text: languages[choosenLanguage]['text_resend_otp'],
                                          size: media.width * sixteen,
                                          color: (_resend && _resendCountToday < _maxResendPerDay)
                                              ? buttonColor
                                              : buttonColor.withOpacity(0.4),
                                        ),
                                        if (_resendCountToday >= _maxResendPerDay)
                                          Padding(
                                            padding: EdgeInsets.only(top: media.width * 0.02),
                                            child: MyText(
                                              text: languages[choosenLanguage]['text_max_resend_per_day'] ??
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
                          ),
                          SizedBox(
                            height: media.height * 0.05,
                          ),
                        ],
                      );
                    }),
              ),
              if (_error != '')
                Column(
                  children: [
                    SizedBox(
                        width: media.width * 0.9,
                        child: MyText(
                          text: _error,
                          color: Colors.red,
                          size: media.width * fourteen,
                          textAlign: TextAlign.center,
                        )),
                    SizedBox(
                      height: media.width * 0.025,
                    )
                  ],
                ),
              (isfromomobile == true)
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
                                  _error = 'Login por telefone não disponível na web. Use login por e-mail.';
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
                              var result = await emailVerify(email, otpNumber);

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
