import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../styles/styles.dart';
import '../../functions/functions.dart';
import '../../translation/translation.dart';
import '../../widgets/widgets.dart';
import '../loadingPage/loading.dart';
import '../noInternet/nointernet.dart';
import 'login.dart';
import 'namepage.dart';
import 'otp_page.dart';

class SignInwithEmail extends StatefulWidget {
  const SignInwithEmail({Key? key}) : super(key: key);

  @override
  State<SignInwithEmail> createState() => _SignInwithEmailState();
}

class _SignInwithEmailState extends State<SignInwithEmail> {
  TextEditingController controller = TextEditingController();
  final TextEditingController _referralController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _referralFocusNode = FocusNode();
  bool _isEmailFocused = false;
  bool _isReferralFocused = false;

  bool terms = true; //terms and conditions true or false
  bool _isLoading = true;
  bool validate = false;
  var verifyEmailError = '';
  var _error = '';

  @override
  void initState() {
    _emailFocusNode.addListener(() {
      setState(() {
        _isEmailFocused = _emailFocusNode.hasFocus;
      });
    });
    _referralFocusNode.addListener(() {
      setState(() {
        _isReferralFocused = _referralFocusNode.hasFocus;
      });
    });
    countryCode();
    super.initState();
  }

  @override
  void dispose() {
    _emailFocusNode.dispose();
    _referralFocusNode.dispose();
    _referralController.dispose();
    super.dispose();
  }

  countryCode() async {
    await getCountryCode();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  //navigate
  navigate() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => const Otp()));
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Material(
      child: Directionality(
        textDirection: (languageDirection == 'rtl')
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: Stack(
          children: [
            Container(
              color: page,
              padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top,
                  left: media.width * 0.08,
                  right: media.width * 0.08),
              height: media.height * 1,
              width: media.width * 1,
              child: Column(
                // crossAxisAlignment: CrossAxisAlignment.ce,
                children: [
                  SizedBox(height: media.height * 0.195),
                  Row(
                    children: [
                      MyText(
                        text: languages[choosenLanguage]['text_login'],
                        size: twentysix,
                        color: buttonColor,
                        fontweight: FontWeight.bold,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      MyText(
                        text: languages[choosenLanguage]['text_login_desc'],
                        size: fourteen,
                        color: hintColor,
                      ),
                    ],
                  ),
                  SizedBox(
                    height: media.height * 0.05,
                  ),
                  // Código de indicação (Opcional) - acima do email
                  MyText(
                    text: languages[choosenLanguage]
                            ['text_referral_optional'] ??
                        'Código de indicação (Opcional)',
                    size: fourteen,
                    color: hintColor,
                  ),
                  SizedBox(height: media.height * 0.01),
                  Container(
                    height: media.width * 0.12,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _isReferralFocused
                            ? const Color(0xFF9A03E9)
                            : (isDarkTheme == true)
                                ? textColor.withOpacity(0.4)
                                : underline,
                        width: _isReferralFocused ? 2.0 : 1.0,
                      ),
                      color: (isDarkTheme == true)
                          ? Colors.black
                          : const Color(0xffF8F8F8),
                    ),
                    padding: const EdgeInsets.only(left: 10, right: 10),
                    child: TextFormField(
                      controller: _referralController,
                      focusNode: _referralFocusNode,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: languages[choosenLanguage]
                                ['text_enter_referral'] ??
                            'Digite o código de indicação',
                        hintStyle: TextStyle(
                          fontSize: media.width * fourteen,
                          color: hintColor,
                        ),
                      ),
                      style: TextStyle(
                        fontSize: media.width * fourteen,
                        color: textColor,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  SizedBox(height: media.height * 0.02),
                  Container(
                      height: media.width * 0.13,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: _isEmailFocused
                                  ? const Color(0xFF9A03E9) // Roxo
                                  : (isDarkTheme == true)
                                      ? textColor.withOpacity(0.4)
                                      : underline,
                              width: _isEmailFocused ? 2.0 : 1.0),
                          color: (isDarkTheme == true)
                              ? Colors.black
                              : const Color(0xffF8F8F8)),
                      padding: const EdgeInsets.only(left: 5, right: 5),
                      child: MyTextField(
                        textController: controller,
                        focusNode: _emailFocusNode,
                        hinttext: languages[choosenLanguage]
                            ['text_enter_email'],
                        onTap: (val) {
                          setState(() {
                            email = controller.text;
                          });
                        },
                      )),
                  (_error != '')
                      ? Container(
                          width: media.width * 0.8,
                          margin: EdgeInsets.only(top: media.height * 0.02),
                          alignment: Alignment.center,
                          child: Text(
                            _error,
                            style: GoogleFonts.poppins(
                                fontSize: media.width * sixteen,
                                color: Colors.red),
                          ),
                        )
                      : Container(),
                  SizedBox(height: media.height * 0.05),
                  SizedBox(
                    height: media.height * 0.06,
                  ),
                  InkWell(
                    onTap: () {
                      controller.clear();
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const Login()));
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.phone,
                            size: media.width * eighteen,
                            color: textColor.withOpacity(0.7)),
                        SizedBox(width: media.width * 0.02),
                        MyText(
                          text: languages[choosenLanguage]
                              ['text_continue_with'],
                          size: sixteen,
                          fontweight: FontWeight.w400,
                          color: textColor.withOpacity(0.7),
                        ),
                        SizedBox(
                          width: media.width * 0.01,
                        ),
                        MyText(
                          text: languages[choosenLanguage]['text_phone_number'],
                          size: sixteen,
                          fontweight: FontWeight.w400,
                          color: buttonColor,
                        )
                      ],
                    ),
                  ),
                  SizedBox(
                    height: media.height * 0.1,
                  ),
                  (controller.text.isNotEmpty)
                      ? Container(
                          width: media.width * 1,
                          alignment: Alignment.center,
                          child: Button(
                              onTap: () async {
                                String pattern =
                                    r"^[a-zA-Z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?\.)+[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])*$";
                                RegExp regex = RegExp(pattern);
                                if (regex.hasMatch(controller.text)) {
                                  FocusManager.instance.primaryFocus?.unfocus();

                                  loginReferralCode =
                                      _referralController.text.trim();

                                  setState(() {
                                    verifyEmailError = '';
                                    _error = '';
                                    _isLoading = true;
                                  });

                                  phoneAuthCheck = true;
                                  await sendOTPtoEmail(email);
                                  value = 1;
                                  navigate();

                                  setState(() {
                                    _isLoading = false;
                                  });
                                } else {
                                  setState(() {
                                    verifyEmailError =
                                        languages[choosenLanguage]
                                            ['text_email_validation'];
                                    _error = languages[choosenLanguage]
                                        ['text_email_validation'];
                                  });
                                }
                              },
                              text: languages[choosenLanguage]['text_login']))
                      : Container(),
                ],
              ),
            ),

            Positioned(
                bottom: 10,
                right: 5,
                left: 5,
                child: Wrap(
                  alignment: WrapAlignment.center,
                  direction: Axis.horizontal,
                  children: [
                    InkWell(
                      onTap: () {
                        openBrowser(
                            'http://52.207.21.163/server-app/public/terms');
                      },
                      child: Text(
                        languages[choosenLanguage]['text_terms'],
                        style: GoogleFonts.poppins(
                            fontSize: media.width * sixteen,
                            color: buttonColor),
                      ),
                    ),
                    Text(
                      ' & ',
                      style: GoogleFonts.poppins(
                          fontSize: media.width * sixteen, color: buttonColor),
                    ),
                    InkWell(
                      onTap: () {
                        openBrowser(
                            'http://52.207.21.163/server-app/public/privacy');
                      },
                      child: Text(
                        languages[choosenLanguage]['text_privacy'],
                        style: GoogleFonts.poppins(
                            fontSize: media.width * sixteen,
                            color: buttonColor),
                      ),
                    ),
                  ],
                )),
            //No internet
            (internet == false)
                ? Positioned(
                    top: 0,
                    child: NoInternet(onTap: () {
                      setState(() {
                        _isLoading = true;
                        internet = true;
                        countryCode();
                      });
                    }))
                : Container(),

            //loader
            (_isLoading == true)
                ? const Positioned(top: 0, child: Loading())
                : Container(),
          ],
        ),
      ),
    );
  }
}
