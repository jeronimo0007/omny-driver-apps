import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../styles/styles.dart';
import '../../functions/functions.dart';
import '../../translations/translation.dart';
import '../../widgets/widgets.dart';
import 'dart:math' as math;
import '../loadingPage/loading.dart';
import '../noInternet/nointernet.dart';
import '../language/languages.dart';
import 'agreement.dart';
import 'namepage.dart';
import 'otp_page.dart';

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
  FocusNode phoneFocus = FocusNode();
  FocusNode emailFocus = FocusNode();

  String get timerString {
    Duration duration = aController.duration * aController.value;
    return '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  bool terms = true; //terms and conditions true or false

  @override
  void initState() {
    currentPage = 0;
    controller.text = '';
    aController =
        AnimationController(vsync: this, duration: const Duration(seconds: 60));

    phoneFocus.addListener(() {
      setState(() {});
    });
    emailFocus.addListener(() {
      setState(() {});
    });

    countryCode();
    super.initState();
  }

  @override
  void dispose() {
    phoneFocus.dispose();
    emailFocus.dispose();
    super.dispose();
  }

  countryCode() async {
    isverifyemail = false;
    isLoginemail = false;
    isfromomobile = true;
    var result = await getCountryCode();
    if (result == 'success') {
      setState(() {
        loginLoading = false;
      });
    } else {
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

  var verifyEmailError = '';
  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

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
                    Column(
                      children: [
                        Container(
                          height: MediaQuery.of(context).padding.top +
                              media.width * 0.15,
                          width: media.width * 1,
                          margin: EdgeInsets.zero,
                          padding: EdgeInsets.only(
                            top: MediaQuery.of(context).padding.top + 10,
                            right: 20,
                          ),
                          alignment: Alignment.topCenter,
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: media.width * 0.12,
                            height: media.width * 0.12,
                            fit: BoxFit.contain,
                          ),
                        ),
                        Expanded(
                          child: Container(
                            color: page,
                            padding: EdgeInsets.only(
                                left: media.width * 0.05,
                                right: media.width * 0.05),
                            width: media.width * 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: media.height * 0.02),
                                InkWell(
                                    onTap: () {
                                      if (currentPage == 0) {
                                        Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    const Languages()));
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
                                      color: buttonColor,
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
                                                    height: (media.width *
                                                            0.9 /
                                                            4) /
                                                        8,
                                                    width: (media.width *
                                                            0.9 /
                                                            4) /
                                                        8,
                                                    color: (currentPage >= key)
                                                        ? const Color(
                                                            0xff000000)
                                                        : const Color(
                                                                0xff000000)
                                                            .withOpacity(0.4),
                                                  ),
                                                  AnimatedContainer(
                                                    duration: const Duration(
                                                        milliseconds: 1000),
                                                    height: (media.width *
                                                            0.9 /
                                                            4) /
                                                        8,
                                                    width: (media.width *
                                                            0.9 /
                                                            4) /
                                                        8,
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
                                                    height: (media.width *
                                                            0.9 /
                                                            4) /
                                                        8,
                                                    width: (media.width *
                                                            0.9 /
                                                            4) /
                                                        8,
                                                    color: (currentPage >= key)
                                                        ? const Color(
                                                            0xffFFFFFF)
                                                        : const Color(
                                                                0xffFFFFFF)
                                                            .withOpacity(0.4),
                                                  ),
                                                  AnimatedContainer(
                                                    duration: const Duration(
                                                        milliseconds: 1000),
                                                    height: (media.width *
                                                            0.9 /
                                                            4) /
                                                        8,
                                                    width: (media.width *
                                                            0.9 /
                                                            4) /
                                                        8,
                                                    color: (currentPage >= key)
                                                        ? const Color(
                                                            0xff000000)
                                                        : const Color(
                                                                0xff000000)
                                                            .withOpacity(0.4),
                                                  )
                                                ],
                                              ),
                                              Column(
                                                children: [
                                                  AnimatedContainer(
                                                    duration: const Duration(
                                                        milliseconds: 1000),
                                                    height: (media.width *
                                                            0.9 /
                                                            4) /
                                                        8,
                                                    width: (media.width *
                                                            0.9 /
                                                            4) /
                                                        8,
                                                    color: (currentPage >= key)
                                                        ? const Color(
                                                            0xff000000)
                                                        : const Color(
                                                                0xff000000)
                                                            .withOpacity(0.4),
                                                  ),
                                                  AnimatedContainer(
                                                    duration: const Duration(
                                                        milliseconds: 1000),
                                                    height: (media.width *
                                                            0.9 /
                                                            4) /
                                                        8,
                                                    width: (media.width *
                                                            0.9 /
                                                            4) /
                                                        8,
                                                    color: (currentPage >= key)
                                                        ? const Color(
                                                            0xffFFFFFF)
                                                        : const Color(
                                                                0xffFFFFFF)
                                                            .withOpacity(0.4),
                                                  )
                                                ],
                                              ),
                                              Column(
                                                children: [
                                                  AnimatedContainer(
                                                    duration: const Duration(
                                                        milliseconds: 1000),
                                                    height: (media.width *
                                                            0.9 /
                                                            4) /
                                                        8,
                                                    width: (media.width *
                                                            0.9 /
                                                            4) /
                                                        8,
                                                    color: (currentPage >= key)
                                                        ? buttonColor
                                                        : buttonColor
                                                            .withOpacity(0.4),
                                                  ),
                                                  AnimatedContainer(
                                                    duration: const Duration(
                                                        milliseconds: 1000),
                                                    height: (media.width *
                                                            0.9 /
                                                            4) /
                                                        8,
                                                    width: (media.width *
                                                            0.9 /
                                                            4) /
                                                        8,
                                                    color: (currentPage >= key)
                                                        ? const Color(
                                                            0xff000000)
                                                        : const Color(
                                                                0xff000000)
                                                            .withOpacity(0.4),
                                                  )
                                                ],
                                              ),
                                              Column(
                                                children: [
                                                  AnimatedContainer(
                                                    duration: const Duration(
                                                        milliseconds: 1000),
                                                    height: (media.width *
                                                            0.9 /
                                                            4) /
                                                        8,
                                                    width: (media.width *
                                                            0.9 /
                                                            4) /
                                                        8,
                                                    color: (currentPage >= key)
                                                        ? const Color(
                                                            0xff000000)
                                                        : const Color(
                                                                0xff000000)
                                                            .withOpacity(0.4),
                                                  ),
                                                  AnimatedContainer(
                                                    duration: const Duration(
                                                        milliseconds: 1000),
                                                    height: (media.width *
                                                            0.9 /
                                                            4) /
                                                        8,
                                                    width: (media.width *
                                                            0.9 /
                                                            4) /
                                                        8,
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
                                                    height: (media.width *
                                                            0.9 /
                                                            4) /
                                                        8,
                                                    width: (media.width *
                                                            0.9 /
                                                            4) /
                                                        8,
                                                    color: (currentPage >= key)
                                                        ? const Color(
                                                            0xffFFFFFF)
                                                        : const Color(
                                                                0xffFFFFFF)
                                                            .withOpacity(0.4),
                                                  ),
                                                  AnimatedContainer(
                                                    duration: const Duration(
                                                        milliseconds: 1000),
                                                    height: (media.width *
                                                            0.9 /
                                                            4) /
                                                        8,
                                                    width: (media.width *
                                                            0.9 /
                                                            4) /
                                                        8,
                                                    color: (currentPage >= key)
                                                        ? const Color(
                                                            0xff000000)
                                                        : const Color(
                                                                0xff000000)
                                                            .withOpacity(0.4),
                                                  )
                                                ],
                                              ),
                                              Column(
                                                children: [
                                                  AnimatedContainer(
                                                    duration: const Duration(
                                                        milliseconds: 1000),
                                                    height: (media.width *
                                                            0.9 /
                                                            4) /
                                                        8,
                                                    width: (media.width *
                                                            0.9 /
                                                            4) /
                                                        8,
                                                    color: (currentPage >= key)
                                                        ? const Color(
                                                            0xff000000)
                                                        : const Color(
                                                                0xff000000)
                                                            .withOpacity(0.4),
                                                  ),
                                                  AnimatedContainer(
                                                    duration: const Duration(
                                                        milliseconds: 1000),
                                                    height: (media.width *
                                                            0.9 /
                                                            4) /
                                                        8,
                                                    width: (media.width *
                                                            0.9 /
                                                            4) /
                                                        8,
                                                    color: (currentPage >= key)
                                                        ? const Color(
                                                            0xffFFFFFF)
                                                        : const Color(
                                                                0xffFFFFFF)
                                                            .withOpacity(0.4),
                                                  )
                                                ],
                                              ),
                                              Column(
                                                children: [
                                                  AnimatedContainer(
                                                    duration: const Duration(
                                                        milliseconds: 1000),
                                                    height: (media.width *
                                                            0.9 /
                                                            4) /
                                                        8,
                                                    width: (media.width *
                                                            0.9 /
                                                            4) /
                                                        8,
                                                    color: (currentPage >= key)
                                                        ? buttonColor
                                                        : buttonColor
                                                            .withOpacity(0.4),
                                                  ),
                                                  AnimatedContainer(
                                                    duration: const Duration(
                                                        milliseconds: 1000),
                                                    height: (media.width *
                                                            0.9 /
                                                            4) /
                                                        8,
                                                    width: (media.width *
                                                            0.9 /
                                                            4) /
                                                        8,
                                                    color: (currentPage >= key)
                                                        ? const Color(
                                                            0xff000000)
                                                        : const Color(
                                                                0xff000000)
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
                                                text: languages[choosenLanguage]
                                                    ['text_what_mobilenum'],
                                                size: media.width * twenty,
                                                fontweight: FontWeight.bold,
                                              ),
                                              SizedBox(
                                                height: media.height * 0.02,
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                        10, 0, 10, 0),
                                                height: 55,
                                                width: media.width * 0.9,
                                                decoration: BoxDecoration(
                                                  color: page,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  border: Border.all(
                                                    color: phoneFocus.hasFocus
                                                        ? buttonColor
                                                        : textColor,
                                                    width: phoneFocus.hasFocus
                                                        ? 2
                                                        : 1,
                                                  ),
                                                  boxShadow: phoneFocus.hasFocus
                                                      ? [
                                                          BoxShadow(
                                                            color: buttonColor
                                                                .withOpacity(
                                                                    0.3),
                                                            spreadRadius: 2,
                                                            blurRadius: 8,
                                                            offset:
                                                                const Offset(
                                                                    0, 2),
                                                          ),
                                                        ]
                                                      : null,
                                                ),
                                                child: Row(
                                                  children: [
                                                    InkWell(
                                                      onTap: () async {
                                                        // País fixo Brasil: sem opção de trocar (useApiCountries = false)
                                                        if (!useApiCountries) {
                                                          return;
                                                        }
                                                        if (countries
                                                            .isNotEmpty) {
                                                          //dialod box for select country for dial code
                                                          await showDialog(
                                                              context: context,
                                                              builder:
                                                                  (context) {
                                                                var searchVal =
                                                                    '';
                                                                return AlertDialog(
                                                                  backgroundColor:
                                                                      page,
                                                                  insetPadding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                          10),
                                                                  content: StatefulBuilder(
                                                                      builder:
                                                                          (context,
                                                                              setState) {
                                                                    return Container(
                                                                      width: media
                                                                              .width *
                                                                          0.9,
                                                                      color:
                                                                          page,
                                                                      child:
                                                                          Directionality(
                                                                        textDirection: (languageDirection ==
                                                                                'rtl')
                                                                            ? TextDirection.rtl
                                                                            : TextDirection.ltr,
                                                                        child:
                                                                            Column(
                                                                          children: [
                                                                            Container(
                                                                              padding: const EdgeInsets.only(left: 20, right: 20),
                                                                              height: 40,
                                                                              width: media.width * 0.9,
                                                                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey, width: 1.5)),
                                                                              child: TextField(
                                                                                decoration: InputDecoration(contentPadding: (languageDirection == 'rtl') ? EdgeInsets.only(bottom: media.width * 0.035) : EdgeInsets.only(bottom: media.width * 0.04), border: InputBorder.none, hintText: languages[choosenLanguage]['text_search'], hintStyle: GoogleFonts.poppins(fontSize: media.width * sixteen, color: hintColor)),
                                                                                style: GoogleFonts.poppins(fontSize: media.width * sixteen, color: textColor),
                                                                                onChanged: (val) {
                                                                                  setState(() {
                                                                                    searchVal = val;
                                                                                  });
                                                                                },
                                                                              ),
                                                                            ),
                                                                            const SizedBox(height: 20),
                                                                            Expanded(
                                                                              child: SingleChildScrollView(
                                                                                child: Column(
                                                                                  children: countries
                                                                                      .asMap()
                                                                                      .map((i, value) {
                                                                                        return MapEntry(
                                                                                            i,
                                                                                            SizedBox(
                                                                                              width: media.width * 0.9,
                                                                                              child: (searchVal == '' && countries[i]['flag'] != null)
                                                                                                  ? InkWell(
                                                                                                      onTap: () {
                                                                                                        setState(() {
                                                                                                          phcode = i;
                                                                                                        });
                                                                                                        Navigator.pop(context);
                                                                                                      },
                                                                                                      child: Container(
                                                                                                        padding: const EdgeInsets.only(top: 10, bottom: 10),
                                                                                                        color: page,
                                                                                                        child: Row(
                                                                                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                                          children: [
                                                                                                            Row(
                                                                                                              children: [
                                                                                                                Image.network(countries[i]['flag']),
                                                                                                                SizedBox(
                                                                                                                  width: media.width * 0.02,
                                                                                                                ),
                                                                                                                SizedBox(
                                                                                                                  width: media.width * 0.4,
                                                                                                                  child: MyText(
                                                                                                                    text: countries[i]['name'],
                                                                                                                    size: media.width * sixteen,
                                                                                                                  ),
                                                                                                                ),
                                                                                                              ],
                                                                                                            ),
                                                                                                            MyText(text: countries[i]['dial_code'], size: media.width * sixteen)
                                                                                                          ],
                                                                                                        ),
                                                                                                      ))
                                                                                                  : (countries[i]['flag'] != null && countries[i]['name'].toLowerCase().contains(searchVal.toLowerCase()))
                                                                                                      ? InkWell(
                                                                                                          onTap: () {
                                                                                                            setState(() {
                                                                                                              phcode = i;
                                                                                                            });
                                                                                                            Navigator.pop(context);
                                                                                                          },
                                                                                                          child: Container(
                                                                                                            padding: const EdgeInsets.only(top: 10, bottom: 10),
                                                                                                            color: page,
                                                                                                            child: Row(
                                                                                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                                              children: [
                                                                                                                Row(
                                                                                                                  children: [
                                                                                                                    Image.network(countries[i]['flag']),
                                                                                                                    SizedBox(
                                                                                                                      width: media.width * 0.02,
                                                                                                                    ),
                                                                                                                    SizedBox(
                                                                                                                      width: media.width * 0.4,
                                                                                                                      child: MyText(text: countries[i]['name'], size: media.width * sixteen),
                                                                                                                    ),
                                                                                                                  ],
                                                                                                                ),
                                                                                                                MyText(text: countries[i]['dial_code'], size: media.width * sixteen)
                                                                                                              ],
                                                                                                            ),
                                                                                                          ))
                                                                                                      : Container(),
                                                                                            ));
                                                                                      })
                                                                                      .values
                                                                                      .toList(),
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    );
                                                                  }),
                                                                );
                                                              });
                                                        } else {
                                                          getCountryCode();
                                                        }
                                                        setState(() {});
                                                      },
                                                      //input field
                                                      child: Container(
                                                        height: 50,
                                                        alignment:
                                                            Alignment.center,
                                                        child: Row(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Image.network(
                                                                countries[
                                                                        phcode]
                                                                    ['flag']),
                                                            SizedBox(
                                                              width:
                                                                  media.width *
                                                                      0.02,
                                                            ),
                                                            const SizedBox(
                                                              width: 2,
                                                            ),
                                                            Icon(
                                                              Icons
                                                                  .arrow_drop_down,
                                                              size: 28,
                                                              color: textColor,
                                                            )
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Container(
                                                      width: 1,
                                                      height: 55,
                                                      color: underline,
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: Container(
                                                        alignment: Alignment
                                                            .bottomCenter,
                                                        height: 50,
                                                        child: TextFormField(
                                                          textAlign:
                                                              TextAlign.start,
                                                          controller:
                                                              controller,
                                                          focusNode: phoneFocus,
                                                          inputFormatters: [
                                                            PhoneDDDFormatter(
                                                              maxLength: countries[
                                                                      phcode][
                                                                  'dial_max_length'],
                                                            ),
                                                          ],
                                                          onChanged: (val) {
                                                            // Remove formatação para armazenar apenas números
                                                            String digitsOnly =
                                                                val.replaceAll(
                                                                    RegExp(
                                                                        r'[^\d]'),
                                                                    '');
                                                            setState(() {
                                                              phnumber =
                                                                  digitsOnly;
                                                            });
                                                            if (digitsOnly
                                                                    .length ==
                                                                countries[
                                                                        phcode][
                                                                    'dial_max_length']) {
                                                              FocusManager
                                                                  .instance
                                                                  .primaryFocus
                                                                  ?.unfocus();
                                                            }
                                                          },
                                                          style: choosenLanguage ==
                                                                  'ar'
                                                              ? GoogleFonts.cairo(
                                                                  color:
                                                                      textColor,
                                                                  fontSize: media
                                                                          .width *
                                                                      sixteen,
                                                                  letterSpacing:
                                                                      1)
                                                              : GoogleFonts.poppins(
                                                                  color:
                                                                      textColor,
                                                                  fontSize: media
                                                                          .width *
                                                                      sixteen,
                                                                  letterSpacing:
                                                                      1),
                                                          keyboardType:
                                                              TextInputType
                                                                  .number,
                                                          decoration:
                                                              InputDecoration(
                                                            counterText: '',
                                                            prefixText:
                                                                '${countries[phcode]['dial_code']} ',
                                                            prefixStyle: choosenLanguage ==
                                                                    'ar'
                                                                ? GoogleFonts.cairo(
                                                                    color:
                                                                        textColor,
                                                                    fontSize: media
                                                                            .width *
                                                                        sixteen,
                                                                    letterSpacing:
                                                                        1)
                                                                : GoogleFonts.poppins(
                                                                    color:
                                                                        textColor,
                                                                    fontSize: media
                                                                            .width *
                                                                        sixteen,
                                                                    letterSpacing:
                                                                        1),
                                                            hintStyle:
                                                                choosenLanguage ==
                                                                        'ar'
                                                                    ? GoogleFonts
                                                                        .cairo(
                                                                        color: textColor
                                                                            .withOpacity(0.7),
                                                                        fontSize:
                                                                            media.width *
                                                                                sixteen,
                                                                      )
                                                                    : GoogleFonts
                                                                        .poppins(
                                                                        color: textColor
                                                                            .withOpacity(0.7),
                                                                        fontSize:
                                                                            media.width *
                                                                                sixteen,
                                                                      ),
                                                            border: InputBorder
                                                                .none,
                                                            enabledBorder:
                                                                InputBorder
                                                                    .none,
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                  ],
                                                ),
                                              ),
                                              SizedBox(
                                                  height: media.height * 0.02),
                                              MyText(
                                                text: languages[choosenLanguage]
                                                    ['text_you_get_otp'],
                                                size: media.width * fourteen,
                                                color:
                                                    textColor.withOpacity(0.5),
                                              ),
                                              SizedBox(
                                                  height: media.height * 0.03),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  InkWell(
                                                    onTap: () {
                                                      controller.clear();
                                                      if (isLoginemail ==
                                                          false) {
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
                                                      languages[choosenLanguage]
                                                              [
                                                              'text_continue_with'] +
                                                          ' ' +
                                                          languages[
                                                                  choosenLanguage]
                                                              ['text_email'],
                                                      style:
                                                          GoogleFonts.poppins(
                                                        color: textColor
                                                            .withOpacity(0.7),
                                                        fontSize: media.width *
                                                            sixteen,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                      width:
                                                          media.width * 0.02),
                                                  Icon(Icons.email_outlined,
                                                      size: media.width *
                                                          eighteen,
                                                      color: textColor
                                                          .withOpacity(0.7)),
                                                ],
                                              ),
                                              SizedBox(
                                                height: media.height * 0.03,
                                              ),
                                              if (_error != '')
                                                Column(
                                                  children: [
                                                    Container(
                                                      width: media.width * 0.9,
                                                      padding: EdgeInsets
                                                          .symmetric(
                                                              horizontal:
                                                                  media.width *
                                                                      0.04,
                                                              vertical:
                                                                  media.width *
                                                                      0.03),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            Colors.red.shade50,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                        border: Border.all(
                                                            color: Colors
                                                                .red.shade300,
                                                            width: 1.5),
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          Icon(
                                                              Icons
                                                                  .error_outline,
                                                              color: Colors
                                                                  .red.shade700,
                                                              size:
                                                                  media.width *
                                                                      0.06),
                                                          SizedBox(
                                                              width:
                                                                  media.width *
                                                                      0.02),
                                                          Expanded(
                                                            child: MyText(
                                                              text: _error,
                                                              color: Colors
                                                                  .red.shade800,
                                                              size:
                                                                  media.width *
                                                                      fourteen,
                                                              textAlign:
                                                                  TextAlign
                                                                      .start,
                                                              fontweight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      height:
                                                          media.width * 0.025,
                                                    )
                                                  ],
                                                ),
                                              (phnumber.length >=
                                                      countries[phcode]
                                                          ['dial_min_length'])
                                                  ? Container(
                                                      width: media.width * 1 -
                                                          media.width * 0.08,
                                                      alignment:
                                                          Alignment.center,
                                                      child: Button(
                                                        onTap: () async {
                                                          if (phnumber.length >=
                                                              countries[phcode][
                                                                  'dial_min_length']) {
                                                            _error = '';
                                                            FocusManager
                                                                .instance
                                                                .primaryFocus
                                                                ?.unfocus();
                                                            setState(() {
                                                              loginLoading =
                                                                  true;
                                                            });
                                                            // Formatar número de telefone no formato internacional
                                                            String
                                                                fullPhoneNumber =
                                                                '${countries[phcode]['dial_code']}$phnumber';
                                                            // Remover espaços e caracteres especiais
                                                            fullPhoneNumber =
                                                                fullPhoneNumber
                                                                    .replaceAll(
                                                                        ' ', '')
                                                                    .replaceAll(
                                                                        '-', '')
                                                                    .replaceAll(
                                                                        '(', '')
                                                                    .replaceAll(
                                                                        ')',
                                                                        '');
                                                            debugPrint(
                                                                'Número formatado para verificação: $fullPhoneNumber');

                                                            //check if otp is true or false
                                                            var otpVal =
                                                                await otpCall();
                                                            //otp is true
                                                            if (otpVal !=
                                                                    null &&
                                                                otpVal.value ==
                                                                    true) {
                                                              phoneAuthCheck =
                                                                  true;
                                                              await phoneAuth(
                                                                  fullPhoneNumber);
                                                              value = 0;
                                                              // Aguardar um pouco para o SMS ser enviado antes de mudar a página
                                                              await Future.delayed(
                                                                  const Duration(
                                                                      milliseconds:
                                                                          500));
                                                              currentPage = 1;
                                                              loginLoading =
                                                                  false;
                                                              setState(() {});
                                                            }
                                                            // otp is false: mesmo assim enviar SMS e exigir código (igual motorista)
                                                            else if (otpVal !=
                                                                    null &&
                                                                otpVal.value ==
                                                                    false) {
                                                              phoneAuthCheck =
                                                                  true;
                                                              await phoneAuth(
                                                                  fullPhoneNumber);
                                                              value = 0;
                                                              await Future.delayed(
                                                                  const Duration(
                                                                      milliseconds:
                                                                          500));
                                                              currentPage = 1;
                                                              loginLoading =
                                                                  false;
                                                              setState(() {});
                                                            }
                                                            // Se otpCall retornar null ou erro, usar Firebase Auth por padrão
                                                            else {
                                                              debugPrint(
                                                                  'otpCall retornou null ou erro, usando Firebase Auth por padrão');
                                                              phoneAuthCheck =
                                                                  true;
                                                              await phoneAuth(
                                                                  fullPhoneNumber);
                                                              value = 0;
                                                              // Aguardar um pouco para o SMS ser enviado antes de mudar a página
                                                              await Future.delayed(
                                                                  const Duration(
                                                                      milliseconds:
                                                                          500));
                                                              currentPage = 1;
                                                              loginLoading =
                                                                  false;
                                                              setState(() {});
                                                            }
                                                          }
                                                        },
                                                        text: languages[
                                                                choosenLanguage]
                                                            ['text_login'],
                                                      ),
                                                    )
                                                  : Container(),
                                            ],
                                          )
                                        : Column(
                                            children: [
                                              MyText(
                                                text: languages[choosenLanguage]
                                                    ['text_what_email'],
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
                                                          BorderRadius.circular(
                                                              10),
                                                      border: Border.all(
                                                          color: emailFocus.hasFocus
                                                              ? buttonColor
                                                              : ((isDarkTheme ==
                                                                      true)
                                                                  ? textColor
                                                                      .withOpacity(
                                                                          0.4)
                                                                  : underline),
                                                          width: emailFocus
                                                                  .hasFocus
                                                              ? 2
                                                              : 1),
                                                      color: (isDarkTheme == true)
                                                          ? page
                                                          : const Color(
                                                              0xffF8F8F8),
                                                      boxShadow: emailFocus
                                                              .hasFocus
                                                          ? [
                                                              BoxShadow(
                                                                color: buttonColor
                                                                    .withOpacity(
                                                                        0.3),
                                                                spreadRadius: 2,
                                                                blurRadius: 8,
                                                                offset:
                                                                    const Offset(
                                                                        0, 2),
                                                              ),
                                                            ]
                                                          : null),
                                                  padding: const EdgeInsets.only(
                                                      left: 5, right: 5),
                                                  child: MyTextField(
                                                    textController: controller,
                                                    hinttext: languages[
                                                            choosenLanguage]
                                                        ['text_enter_email'],
                                                    focusNode: emailFocus,
                                                    onTap: (val) {
                                                      setState(() {
                                                        email = controller.text;
                                                      });
                                                    },
                                                  )),
                                              SizedBox(
                                                  height: media.height * 0.02),
                                              MyText(
                                                text: (languages[
                                                                choosenLanguage] !=
                                                            null &&
                                                        languages[choosenLanguage]
                                                                [
                                                                'text_you_get_otp_email'] !=
                                                            null)
                                                    ? languages[choosenLanguage]
                                                            [
                                                            'text_you_get_otp_email']
                                                        .toString()
                                                    : 'You will receive an OTP via email for verification',
                                                size: media.width * fourteen,
                                                color:
                                                    textColor.withOpacity(0.5),
                                              ),
                                              SizedBox(
                                                  height: media.height * 0.05),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  InkWell(
                                                    onTap: () {
                                                      controller.clear();
                                                      if (isLoginemail ==
                                                          false) {
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
                                                      languages[choosenLanguage]
                                                              [
                                                              'text_continue_with'] +
                                                          ' ' +
                                                          languages[
                                                                  choosenLanguage]
                                                              ['text_mob_num'],
                                                      style:
                                                          GoogleFonts.poppins(
                                                        color: textColor
                                                            .withOpacity(0.7),
                                                        fontSize: media.width *
                                                            sixteen,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: media.width * 0.03,
                                                  ),
                                                  Icon(Icons.call,
                                                      size: media.width *
                                                          eighteen,
                                                      color: textColor
                                                          .withOpacity(0.7)),
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
                                                    Container(
                                                      width: media.width * 0.9,
                                                      padding: EdgeInsets
                                                          .symmetric(
                                                              horizontal:
                                                                  media.width *
                                                                      0.04,
                                                              vertical:
                                                                  media.width *
                                                                      0.03),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            Colors.red.shade50,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                        border: Border.all(
                                                            color: Colors
                                                                .red.shade300,
                                                            width: 1.5),
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          Icon(
                                                              Icons
                                                                  .error_outline,
                                                              color: Colors
                                                                  .red.shade700,
                                                              size:
                                                                  media.width *
                                                                      0.06),
                                                          SizedBox(
                                                              width:
                                                                  media.width *
                                                                      0.02),
                                                          Expanded(
                                                            child: MyText(
                                                              text: _error,
                                                              color: Colors
                                                                  .red.shade800,
                                                              size:
                                                                  media.width *
                                                                      fourteen,
                                                              textAlign:
                                                                  TextAlign
                                                                      .start,
                                                              fontweight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      height:
                                                          media.width * 0.025,
                                                    )
                                                  ],
                                                ),
                                              (controller.text.isNotEmpty)
                                                  ? Container(
                                                      width: media.width * 1,
                                                      alignment:
                                                          Alignment.center,
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
                                                                controller
                                                                    .text)) {
                                                              FocusManager
                                                                  .instance
                                                                  .primaryFocus
                                                                  ?.unfocus();

                                                              setState(() {
                                                                verifyEmailError =
                                                                    '';
                                                                loginLoading =
                                                                    true;
                                                                _error = '';
                                                              });

                                                              phoneAuthCheck =
                                                                  true;
                                                              var sendResult =
                                                                  await sendOTPtoEmail(
                                                                      email);
                                                              setState(() {
                                                                loginLoading =
                                                                    false;
                                                              });
                                                              if (sendResult ==
                                                                  'success') {
                                                                value = 1;
                                                                isfromomobile =
                                                                    false;
                                                                currentPage = 1;
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
                                                                loginLoading =
                                                                    false;
                                                                _error = languages[
                                                                        choosenLanguage]
                                                                    [
                                                                    'text_email_validation'];
                                                              });
                                                            }
                                                          },
                                                          text: languages[
                                                                  choosenLanguage]
                                                              ['text_login']))
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
                            ),
                          ),
                        ),
                      ],
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

class PhoneDDDFormatter extends TextInputFormatter {
  final int maxLength;

  PhoneDDDFormatter({required this.maxLength});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove todos os caracteres não numéricos do texto antigo e novo
    String oldDigitsOnly = oldValue.text.replaceAll(RegExp(r'[^\d]'), '');
    String newDigitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    // Detecta se está deletando
    bool isDeleting = newDigitsOnly.length < oldDigitsOnly.length;

    // Limita ao tamanho máximo
    if (newDigitsOnly.length > maxLength) {
      newDigitsOnly = newDigitsOnly.substring(0, maxLength);
    }

    // Se não há dígitos, retorna vazio
    if (newDigitsOnly.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Se há apenas 1 dígito, retorna sem formatação
    if (newDigitsOnly.length == 1) {
      return TextEditingValue(
        text: newDigitsOnly,
        selection: const TextSelection.collapsed(offset: 1),
      );
    }

    // Se há 2 ou mais dígitos, formata com DDD entre parênteses
    String ddd = newDigitsOnly.substring(0, 2);
    String rest = newDigitsOnly.substring(2);

    String formatted = '($ddd)';
    if (rest.isNotEmpty) {
      formatted += ' $rest';
    }

    // Calcula a posição do cursor baseado no texto formatado anterior
    int cursorPosition;

    if (isDeleting) {
      // Quando deletando, usa a posição do cursor do texto antigo formatado
      // e ajusta baseado na quantidade de dígitos removidos
      int oldCursorOffset = oldValue.selection.baseOffset;
      String oldTextBeforeCursor = oldValue.text.substring(0, oldCursorOffset);
      int oldDigitsBeforeCursor =
          oldTextBeforeCursor.replaceAll(RegExp(r'[^\d]'), '').length;

      // Se deletou um dígito, reduz a contagem
      int newDigitsBeforeCursor =
          oldDigitsBeforeCursor > 0 ? oldDigitsBeforeCursor - 1 : 0;

      // Ajusta a posição no texto formatado
      if (newDigitsBeforeCursor == 0) {
        cursorPosition = 0;
      } else if (newDigitsBeforeCursor == 1) {
        cursorPosition = 1;
      } else if (newDigitsBeforeCursor == 2) {
        cursorPosition = 4; // Após '(DD)'
      } else {
        cursorPosition = newDigitsBeforeCursor + 3; // +3 para '(DD) '
      }
    } else {
      // Quando digitando, calcula baseado nos dígitos antes do cursor no novo texto
      int cursorOffset = newValue.selection.baseOffset;
      String textBeforeCursor = newValue.text.substring(0, cursorOffset);
      int digitsBeforeCursor =
          textBeforeCursor.replaceAll(RegExp(r'[^\d]'), '').length;

      // Ajusta a posição no texto formatado
      if (digitsBeforeCursor == 0) {
        cursorPosition = 0;
      } else if (digitsBeforeCursor == 1) {
        cursorPosition = 1;
      } else if (digitsBeforeCursor == 2) {
        cursorPosition = 4; // Após '(DD)'
      } else {
        cursorPosition = digitsBeforeCursor + 3; // +3 para '(DD) '
      }
    }

    // Limita o cursor ao tamanho do texto formatado
    if (cursorPosition > formatted.length) {
      cursorPosition = formatted.length;
    }
    if (cursorPosition < 0) {
      cursorPosition = 0;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorPosition),
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
