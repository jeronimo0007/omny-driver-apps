import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// Removido import direto do google_fonts - usando função helper com fallback
import 'package:pinput/pinput.dart';
import '../../config/api_config.dart';
import '../../styles/styles.dart';
import '../../functions/functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;
import '../../translations/translation.dart';
import '../../widgets/widgets.dart';
import '../noInternet/nointernet.dart';
import '../onTripPage/booking_confirmation.dart';
import '../onTripPage/invoice.dart';
import '../onTripPage/map_page.dart';
import 'login.dart';
import 'namepage.dart';

class Otp extends StatefulWidget {
  final dynamic from;

  const Otp({Key? key, this.from}) : super(key: key);

  @override
  State<Otp> createState() => _OtpState();
}

class _OtpState extends State<Otp> with TickerProviderStateMixin {
  String otpNumber = ''; //otp number

  final _pinPutController2 = TextEditingController();
  final _pinPutFocusNode = FocusNode(); // FocusNode para controlar o foco
  dynamic aController;
  bool _resend = false;
  String _error = '';
  String _successMessage = '';
  bool _isVerifying = false; // Flag para evitar verificação duplicada
  bool _autoVerifying = false; // Flag para evitar auto-verificação múltipla
  StreamSubscription? _credentialsSubscription;
  int _resendDuration = 90; // Primeiro tempo: 90 segundos

  String get timerString {
    Duration duration = aController.duration * aController.value;
    return '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    aController = AnimationController(
        vsync: this, duration: Duration(seconds: _resendDuration));
    aController.reverse(
        from: aController.value == 0.0
            ? _resendDuration.toDouble()
            : aController.value);

    // Listener para truncar cola a 6 dígitos (sem auto-verificar; usuário deve tocar em Continuar)
    _pinPutController2.addListener(() {
      final text = _pinPutController2.text;
      if (text.length > 6) {
        final digitsOnly = text.replaceAll(RegExp(r'[^0-9]'), '');
        if (digitsOnly.length > 6) {
          _pinPutController2.text = digitsOnly.substring(0, 6);
          _pinPutController2.selection = TextSelection.fromPosition(
            const TextPosition(offset: 6),
          );
          otpNumber = _pinPutController2.text;
        }
      }
    });

    otpFalse();
    super.initState();
  }

  @override
  void dispose() {
    _error = '';
    _isVerifying = false;
    _autoVerifying = false;
    _credentialsSubscription?.cancel();
    _pinPutFocusNode.dispose();
    _pinPutController2.dispose();
    aController.dispose();
    super.dispose();
  }

//navigate
  navigate(verify) {
    if (verify == true) {
      if (userRequestData.isNotEmpty && userRequestData['is_completed'] == 1) {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const Invoice()),
            (route) => false);
      } else if (userRequestData.isNotEmpty &&
          userRequestData['is_completed'] != 1) {
        Future.delayed(const Duration(seconds: 2), () {
          if (userRequestData['is_rental'] == true) {
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (context) => BookingConfirmation(
                          type: 1,
                        )),
                (route) => false);
          } else {
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => BookingConfirmation()),
                (route) => false);
          }
        });
      } else {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const Maps()),
            (route) => false);
      }
    } else if (verify == false) {
      if (isverifyemail == true) {
        currentPage = 3;
        valueNotifierLogin.incrementNotifier();
      } else {
        setState(() {
          currentPage = 2;
        });
        valueNotifierLogin.incrementNotifier();
      }
    } else {
      _error = verify.toString();
    }
    loginLoading = false;
    valueNotifierLogin.incrementNotifier();
  }

  bool _otpFalseCalled = false; // Flag para evitar chamadas duplicadas

  otpFalse() async {
    // Evitar chamadas duplicadas
    if (_otpFalseCalled) {
      debugPrint('⚠️ otpFalse já foi chamado, ignorando chamada duplicada');
      return;
    }
    _otpFalseCalled = true;

    // Quando login é por e-mail/senha (auth), só usamos validateOtpAuth (validate-otp). Nunca verifyUser.
    if (loginEmailPswd == 1) {
      return;
    }
    if (widget.from == 'email' || authTempTokenForOtp != null) {
      return;
    }

    if (phoneAuthCheck == false) {
      if (isverifyemail == false) {
        _pinPutController2.text = '123456';
        otpNumber = _pinPutController2.text;
        normallogin();
      } else {
        emaillogin();
      }
    }
  }

  normallogin() async {
    var verify = await verifyUser(phnumber);
    navigate(verify);
  }

  emaillogin() async {
    var verify = await verifyUser(phnumber);
    // var register = await registerUser();
    if (verify == false) {
      _pinPutController2.text = '123456';
      otpNumber = _pinPutController2.text;
      //referral page
      navigate(verify);
    } else {
      setState(() {
        _pinPutController2.text = '';
        _error = languages[choosenLanguage]['text_mobile_already_taken'];
      });
    }
  }

//auto verify otp

  verifyOtp() async {
    // Evitar verificação duplicada
    if (_isVerifying || _autoVerifying) {
      debugPrint('⚠️ Verificação já em andamento, ignorando chamada duplicada');
      return;
    }

    _isVerifying = true;
    _autoVerifying = true;
    FocusManager.instance.primaryFocus?.unfocus();

    try {
      // Se temos credentials (auto-verificação), usar eles
      if (credentials != null) {
        debugPrint('🔐 Auto-verificando com credentials');
        try {
          var userCredential =
              await FirebaseAuth.instance.signInWithCredential(credentials);
          // Pequeno delay para garantir que o Firebase termine de processar
          await Future.delayed(const Duration(milliseconds: 500));
          debugPrint(
              '✅ Login Firebase concluído, usuário: ${userCredential.user?.uid ?? 'N/A'}');
        } catch (e, stackTrace) {
          debugPrint('❌ Erro ao fazer login no Firebase: $e');
          debugPrint('Stack trace: $stackTrace');
          _isVerifying = false;
          _autoVerifying = false;
          if (mounted) {
            setState(() {
              _pinPutController2.clear();
              _error = languages[choosenLanguage]['text_otp_error'] ??
                  'Erro ao verificar código';
            });
          }
          return;
        }

        try {
          var verify = await verifyUser(phnumber);
          credentials = null;
          _isVerifying = false;
          _autoVerifying = false;
          if (mounted) {
            navigate(verify);
          }
        } catch (e) {
          debugPrint('❌ Erro ao verificar usuário: $e');
          _isVerifying = false;
          _autoVerifying = false;
          if (mounted) {
            setState(() {
              _error = languages[choosenLanguage]['text_otp_error'] ??
                  'Erro ao validar usuário';
            });
          }
        }
        return;
      }

      // Se não temos credentials mas temos verificationId e código, usar código manual
      if (verId.isNotEmpty && otpNumber.length == 6) {
        debugPrint('🔐 Verificando com código manual');
        PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: verId,
          smsCode: otpNumber,
        );

        try {
          var userCredential =
              await FirebaseAuth.instance.signInWithCredential(credential);
          // Pequeno delay para garantir que o Firebase termine de processar
          await Future.delayed(const Duration(milliseconds: 500));
          debugPrint(
              '✅ Credencial verificada com sucesso, usuário: ${userCredential.user?.uid ?? 'N/A'}');
        } catch (e, stackTrace) {
          debugPrint('❌ Erro ao verificar credencial: $e');
          debugPrint('Stack trace: $stackTrace');
          _isVerifying = false;
          _autoVerifying = false;
          if (mounted) {
            setState(() {
              _pinPutController2.clear();
              _error = languages[choosenLanguage]['text_otp_error'] ??
                  'Erro ao verificar código';
            });
          }
          return;
        }

        try {
          var verify = await verifyUser(phnumber);
          _isVerifying = false;
          _autoVerifying = false;
          if (mounted) {
            navigate(verify);
          }
        } catch (e) {
          debugPrint('❌ Erro ao verificar usuário: $e');
          _isVerifying = false;
          _autoVerifying = false;
          if (mounted) {
            setState(() {
              _error = languages[choosenLanguage]['text_otp_error'] ??
                  'Erro ao validar usuário';
            });
          }
        }
        return;
      }

      // Se não temos nem credentials nem código válido
      debugPrint('⚠️ Não há credentials nem código válido para verificar');
      _isVerifying = false;
      _autoVerifying = false;
    } on FirebaseAuthException catch (error) {
      _isVerifying = false;
      _autoVerifying = false;
      debugPrint('❌ Erro Firebase Auth: ${error.code} - ${error.message}');

      if (mounted) {
        setState(() {
          if (error.code == 'invalid-verification-code') {
            _pinPutController2.clear();
            otpNumber = '';
            _error = languages[choosenLanguage]['text_otp_error'] ??
                'Código inválido';
          } else if (error.code == 'session-expired') {
            _error = 'Sessão expirada. Solicite um novo código.';
          } else {
            _error = languages[choosenLanguage]['text_otp_error'] ??
                'Erro na verificação';
          }
        });
      }
    } catch (e) {
      _isVerifying = false;
      _autoVerifying = false;
      debugPrint('❌ Erro ao verificar OTP: $e');
      if (mounted) {
        setState(() {
          _error = languages[choosenLanguage]['text_otp_error'] ??
              'Erro na verificação';
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
    final prefix = languages[choosenLanguage]['text_enter_otp_at'] ?? 'Digite o código enviado para ';
    // Fluxo auth (e-mail): priorizar e-mail; senão celular; senão email do cadastro
    final otpSubtitle = (widget.from == 'email' || authTempTokenForOtp != null) &&
            authEmailOrMobileForOtp != null &&
            authEmailOrMobileForOtp!.isNotEmpty
        ? prefix + authEmailOrMobileForOtp!
        : isfromomobile == true
            ? prefix + countries[phcode]['dial_code'] + phnumber
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
                                  focusNode: _pinPutFocusNode,
                                  // Não focar automaticamente ao entrar na tela
                                  autofocus: false,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  defaultPinTheme: PinTheme(
                                    width: media.width * 0.15,
                                    height: media.width * 0.15,
                                    textStyle: getGoogleFontStyle(
                                        fontSize: media.width * twenty,
                                        fontWeight: FontWeight.w700,
                                        color: buttonColor),
                                    decoration: BoxDecoration(
                                      color: page,
                                      border: Border.all(
                                          color: textColor.withOpacity(0.3)),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  focusedPinTheme: PinTheme(
                                    width: media.width * 0.15,
                                    height: media.width * 0.15,
                                    textStyle: getGoogleFontStyle(
                                        fontSize: media.width * twenty,
                                        fontWeight: FontWeight.w700,
                                        color: buttonColor),
                                    decoration: BoxDecoration(
                                      color: page,
                                      border: Border.all(
                                          color: buttonColor, width: 2),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: buttonColor.withOpacity(0.3),
                                          spreadRadius: 2,
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                  submittedPinTheme: PinTheme(
                                    width: media.width * 0.15,
                                    height: media.width * 0.15,
                                    textStyle: getGoogleFontStyle(
                                        fontSize: media.width * twenty,
                                        fontWeight: FontWeight.w700,
                                        color: buttonColor),
                                    decoration: BoxDecoration(
                                      color: page,
                                      border: Border.all(
                                          color: buttonColor, width: 2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                InkWell(
                                    onTap: (_resend == true)
                                        ? () async {
                                            loginLoading = true;
                                            valueNotifierLogin
                                                .incrementNotifier();

                                            // Dobrar o tempo para o próximo reenvio
                                            _resendDuration =
                                                _resendDuration * 2;

                                            // Atualizar o AnimationController com o novo tempo
                                            aController.dispose();
                                            aController = AnimationController(
                                              vsync: this,
                                              duration: Duration(
                                                  seconds: _resendDuration),
                                            );

                                            if (loginEmailPswd != 1 &&
                                                isfromomobile == true) {
                                              var verify =
                                                  await verifyUser(phnumber);
                                              if (verify == false) {
                                                setState(() {
                                                  _error = '';
                                                  _pinPutController2.text = '';
                                                  _resend = false;
                                                });
                                                phoneAuth(countries[phcode]
                                                        ['dial_code'] +
                                                    phnumber);
                                                aController.reverse(
                                                    from: _resendDuration
                                                        .toDouble());
                                              } else {
                                                setState(() {
                                                  _pinPutController2.text = '';

                                                  _error =
                                                      'mobile or already taken';
                                                });
                                              }
                                            } else if (loginEmailPswd == 1 &&
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
                                                  });
                                                  Future.delayed(const Duration(seconds: 3), () {
                                                    if (mounted) setState(() => _successMessage = '');
                                                  });
                                                  aController.reverse(
                                                      from: _resendDuration
                                                          .toDouble());
                                                } else {
                                                  setState(() {
                                                    _error = sendResult;
                                                  });
                                                }
                                            } else {
                                              if (authTempTokenForOtp != null) {
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
                                                  });
                                                  Future.delayed(const Duration(seconds: 3), () {
                                                    if (mounted) setState(() => _successMessage = '');
                                                  });
                                                  aController.reverse(
                                                      from: _resendDuration
                                                          .toDouble());
                                                } else {
                                                  setState(() {
                                                    _error = sendResult;
                                                  });
                                                }
                                              } else {
                                                var verify =
                                                    await verifyUser(email);
                                                if (verify == false) {
                                                  loginLoading = true;

                                                  phoneAuthCheck = true;
                                                  var sendResult =
                                                      await sendOTPtoEmail(email);
                                                  setState(() {
                                                    loginLoading = false;
                                                  });
                                                  if (sendResult == 'success') {
                                                    aController.reverse(
                                                        from: _resendDuration
                                                            .toDouble());
                                                  } else {
                                                    setState(() {
                                                      _error = serverErrorMessage
                                                              .isNotEmpty
                                                          ? serverErrorMessage
                                                          : (sendResult
                                                                  ?.toString() ??
                                                              'Erro ao enviar OTP');
                                                    });
                                                  }
                                                } else {
                                                  setState(() {
                                                    _pinPutController2.text = '';
                                                    _error =
                                                        'email already taken';
                                                  });
                                                }
                                              }
                                            }
                                            // var register = await registerUser();
                                            loginLoading = false;
                                            valueNotifierLogin
                                                .incrementNotifier();
                                          }
                                        : null,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: media.width * 0.05,
                                        vertical: media.width * 0.03,
                                      ),
                                      decoration: BoxDecoration(
                                        color: (_resend == false)
                                            ? buttonColor.withOpacity(0.1)
                                            : buttonColor,
                                        borderRadius: BorderRadius.circular(25),
                                        border: Border.all(
                                          color: (_resend == false)
                                              ? buttonColor.withOpacity(0.3)
                                              : buttonColor,
                                          width: 2,
                                        ),
                                      ),
                                      child: MyText(
                                        text: languages[choosenLanguage]
                                            ['text_resend_otp'],
                                        size: media.width * sixteen,
                                        fontweight: FontWeight.bold,
                                        color: (_resend == false)
                                            ? buttonColor.withOpacity(0.5)
                                            : buttonText,
                                      ),
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
                            // Sempre exigir código OTP (igual app do motorista)
                            if (phoneAuthCheck == false) {
                              setState(() {
                                _error = languages[choosenLanguage]
                                        ['text_otp_error'] ??
                                    'Digite o código de verificação para continuar';
                              });
                              loginLoading = false;
                              valueNotifierLogin.incrementNotifier();
                              return;
                            }
                            // firebase code send true
                            // Evitar verificação duplicada
                            if (_isVerifying) {
                              debugPrint(
                                  '⚠️ Verificação já em andamento, ignorando chamada duplicada');
                              loginLoading = false;
                              valueNotifierLogin.incrementNotifier();
                              return;
                            }

                            // Verificar se o código OTP foi preenchido
                            if (otpNumber.isEmpty || otpNumber.length != 6) {
                              debugPrint(
                                  '⚠️ Código OTP inválido: ${otpNumber.length} dígitos');
                              setState(() {
                                _error = languages[choosenLanguage]
                                        ['text_otp_error'] ??
                                    'Código inválido';
                              });
                              loginLoading = false;
                              valueNotifierLogin.incrementNotifier();
                              return;
                            }

                            // Verificar se temos verificationId
                            if (verId.isEmpty) {
                              debugPrint('❌ VerificationId não disponível');
                              setState(() {
                                _error = languages[choosenLanguage]
                                        ['text_otp_error'] ??
                                    'Erro na verificação';
                              });
                              loginLoading = false;
                              valueNotifierLogin.incrementNotifier();
                              return;
                            }

                            _isVerifying = true;
                            try {
                              debugPrint(
                                  '═══════════════════════════════════════════════════════════');
                              debugPrint('🔐 VERIFICANDO CÓDIGO OTP');
                              debugPrint(
                                  '───────────────────────────────────────────────────────────');
                              debugPrint('📱 Número: $phnumber');
                              debugPrint(
                                  '🔢 Código: ${otpNumber.replaceAll(RegExp(r'.'), '*')}');
                              debugPrint(
                                  '🆔 VerificationId: ${verId.substring(0, 20)}...');
                              debugPrint(
                                  '═══════════════════════════════════════════════════════════');

                              PhoneAuthCredential credential =
                                  PhoneAuthProvider.credential(
                                      verificationId: verId,
                                      smsCode: otpNumber);

                              // Sign the user in (or link) with the credential
                              try {
                                var userCredential = await FirebaseAuth.instance
                                    .signInWithCredential(credential);
                                // Pequeno delay para garantir que o Firebase termine de processar
                                await Future.delayed(
                                    const Duration(milliseconds: 500));
                                debugPrint(
                                    '✅ Credencial verificada com sucesso, usuário: ${userCredential.user?.uid ?? 'N/A'}');
                              } catch (e, stackTrace) {
                                debugPrint(
                                    '❌ Erro ao verificar credencial: $e');
                                debugPrint('Stack trace: $stackTrace');
                                _isVerifying = false;
                                loginLoading = false;
                                valueNotifierLogin.incrementNotifier();
                                if (mounted) {
                                  setState(() {
                                    _pinPutController2.clear();
                                    _error = languages[choosenLanguage]
                                            ['text_otp_error'] ??
                                        'Erro ao verificar código';
                                  });
                                }
                                return;
                              }

                              try {
                                var verify = await verifyUser(phnumber);
                                _isVerifying = false;

                                debugPrint('✅ Resultado da validação: $verify');
                                navigate(verify);
                              } catch (e) {
                                debugPrint('❌ Erro ao verificar usuário: $e');
                                _isVerifying = false;
                                loginLoading = false;
                                valueNotifierLogin.incrementNotifier();
                                if (mounted) {
                                  setState(() {
                                    _error = languages[choosenLanguage]
                                            ['text_otp_error'] ??
                                        'Erro ao validar usuário';
                                  });
                                }
                              }

                              value = 0;
                            } on FirebaseAuthException catch (error) {
                              _isVerifying = false;
                              debugPrint(
                                  '❌ Erro Firebase Auth: ${error.code} - ${error.message}');

                              if (error.code == 'invalid-verification-code') {
                                setState(() {
                                  _pinPutController2.clear();
                                  otpNumber = '';
                                  _error = languages[choosenLanguage]
                                          ['text_otp_error'] ??
                                      'Código inválido';
                                });
                              } else if (error.code == 'session-expired') {
                                setState(() {
                                  _error =
                                      'Sessão expirada. Solicite um novo código.';
                                });
                              } else {
                                setState(() {
                                  _error = languages[choosenLanguage]
                                          ['text_otp_error'] ??
                                      'Erro na verificação';
                                });
                              }
                              loginLoading = false;
                              valueNotifierLogin.incrementNotifier();
                            } catch (e) {
                              _isVerifying = false;
                              debugPrint('❌ Erro ao verificar OTP: $e');
                              setState(() {
                                _error = languages[choosenLanguage]
                                        ['text_otp_error'] ??
                                    'Erro na verificação';
                              });
                              loginLoading = false;
                              valueNotifierLogin.incrementNotifier();
                            }
                            loginLoading = false;
                            valueNotifierLogin.incrementNotifier();
                          }
                        },
                        text: languages[choosenLanguage]['text_verify'] ??
                            'Verificar',
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
                      border:
                          Border.all(color: Colors.red.shade300, width: 1.5),
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
