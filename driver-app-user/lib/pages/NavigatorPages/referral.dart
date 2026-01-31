import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import '../../functions/functions.dart';
import '../../styles/styles.dart';
import '../../translations/translation.dart';
import '../../widgets/widgets.dart';
import '../loadingPage/loading.dart';
import '../noInternet/noInternet.dart';

class ReferralPage extends StatefulWidget {
  const ReferralPage({Key? key}) : super(key: key);

  @override
  State<ReferralPage> createState() => _ReferralPageState();
}

class _ReferralPageState extends State<ReferralPage> {
  bool _isLoading = true;
  bool _showToast = false;
  dynamic _package;
  // ignore: prefer_typing_uninitialized_variables
  var androidUrl;
  // ignore: prefer_typing_uninitialized_variables
  var iosUrl;

  @override
  void initState() {
    _getReferral();
    super.initState();
  }

//get referral code
  _getReferral() async {
    await getReferral();
    _package = await PackageInfo.fromPlatform();
    androidUrl = 'android - '
        'https://play.google.com/store/apps/details?id=${_package.packageName}';
    iosUrl = 'ios - '
        'http://itunes.apple.com/lookup?bundleId=${_package.packageName}';
    setState(() {
      _isLoading = false;
    });
  }

//show toast for copied
  showToast() {
    setState(() {
      _showToast = true;
    });
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _showToast = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Material(
      child: ValueListenableBuilder(
          valueListenable: valueNotifierHome.value,
          builder: (context, value, child) {
            return Directionality(
              textDirection: (languageDirection == 'rtl')
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height:
                        MediaQuery.of(context).padding.top + media.width * 0.15,
                    width: media.width * 1,
                    margin: EdgeInsets.zero,
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 10,
                      right: 20,
                    ),
                    alignment: Alignment.topRight,
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: media.width * 0.12,
                      height: media.width * 0.12,
                      fit: BoxFit.contain,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(media.width * 0.05),
                    height: media.height * 1,
                    width: media.width * 1,
                    color: page,
                    child: (myReferralCode.isNotEmpty)
                        ? Column(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    SizedBox(
                                        height:
                                            MediaQuery.of(context).padding.top +
                                                media.width * 0.15),
                                    Stack(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.only(
                                              bottom: media.width * 0.05),
                                          width: media.width * 1,
                                          alignment: Alignment.center,
                                          child: MyText(
                                            text: '',
                                            size: media.width * twenty,
                                          ),
                                        ),
                                        Positioned(
                                            child: InkWell(
                                                onTap: () {
                                                  Navigator.pop(context);
                                                },
                                                child: Icon(
                                                    Icons.arrow_back_ios,
                                                    color: (isDarkTheme == true) ? theme : textColor)))
                                      ],
                                    ),
                                    SizedBox(
                                      height: media.width * 0.05,
                                    ),
                                    Row(
                                      children: [
                                        MyText(
                                          text: languages[choosenLanguage]
                                                  ['text_enable_referal']
                                              .toString()
                                              .toUpperCase(),
                                          size: media.width * sixteen,
                                          fontweight: FontWeight.w700,
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      height: media.width * 0.03,
                                    ),
                                    SizedBox(
                                      width: media.width * 0.9,
                                      height: media.height * 0.16,
                                      child: Image.asset(
                                        'assets/images/referralpage.png',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    SizedBox(
                                      height: media.width * 0.1,
                                    ),
                                    /*
                                    Row(
                                      children: [
                                        MyText(
                                          text: myReferralCode[
                                              'referral_comission_string'],
                                          size: media.width * sixteen,
                                          textAlign: TextAlign.center,
                                          fontweight: FontWeight.w600,
                                        ),
                                      ],
                                    ),
                                    */
                                    Row(
                                      children: [
                                        Expanded(
                                          child: MyText(
                                            text: (languages[choosenLanguage][
                                                        'text_referral_earn_code'] ??
                                                    'Your Referral Code')
                                                .toString(),
                                            size: media.width * sixteen,
                                            textAlign: TextAlign.center,
                                            fontweight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      height: media.width * 0.05,
                                    ),
                                    Container(
                                        width: media.width * 0.9,
                                        padding:
                                            EdgeInsets.all(media.width * 0.05),
                                        decoration: BoxDecoration(
                                            border: Border.all(
                                                color: (isDarkTheme == true) ? theme.withOpacity(0.3) : borderLines, width: 1.2),
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            MyText(
                                              text: myReferralCode[
                                                  'refferal_code'],
                                              size: media.width * sixteen,
                                              fontweight: FontWeight.w600,
                                              color: textColor.withOpacity(0.5),
                                            ),
                                            InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    Clipboard.setData(ClipboardData(
                                                        text: myReferralCode[
                                                            'refferal_code']));
                                                  });
                                                  showToast();
                                                },
                                                child: Icon(Icons.copy,
                                                    color: (isDarkTheme == true) ? theme : textColor))
                                          ],
                                        )),
                                    SizedBox(
                                      height: media.width * 0.05,
                                    ),
                                    Container(
                                      width: media.width * 0.9,
                                      padding:
                                          EdgeInsets.all(media.width * 0.04),
                                      decoration: BoxDecoration(
                                        color: (isDarkTheme == true) ? theme : topBar,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: MyText(
                                        text: languages[choosenLanguage]
                                            ['text_referral_earn_message'],
                                        size: media.width * twelve,
                                        textAlign: TextAlign.center,
                                        color: (isDarkTheme == true) ? Colors.white : textColor.withOpacity(0.8),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.only(
                                    top: media.width * 0.05,
                                    bottom: media.width * 0.05),
                                child: Button(
                                    onTap: () async {
                                      await Share.share(
                                          // ignore: prefer_interpolation_to_compose_strings
                                          languages[choosenLanguage]
                                                      ['text_invitation_1']
                                                  .toString()
                                                  .replaceAll(
                                                      '55', _package.appName) +
                                              ' ' +
                                              myReferralCode['refferal_code'] +
                                              ' ' +
                                              languages[choosenLanguage]
                                                  ['text_invitation_2'] +
                                              ' \n \n ' +
                                              androidUrl +
                                              '\n \n  ' +
                                              iosUrl);
                                    },
                                    text: languages[choosenLanguage]
                                        ['text_invite']),
                              )
                            ],
                          )
                        : Container(),
                  ),
                  (internet == false)
                      ? Positioned(
                          top: 0,
                          child: NoInternet(
                            onTap: () {
                              setState(() {
                                internetTrue();
                                _isLoading = true;
                                getReferral();
                              });
                            },
                          ))
                      : Container(),

                  //loader
                  (_isLoading == true)
                      ? const Positioned(top: 0, child: Loading())
                      : Container(),

                  //display toast
                  (_showToast == true)
                      ? Positioned(
                          bottom: media.height * 0.2,
                          child: Container(
                            padding: EdgeInsets.all(media.width * 0.025),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: (isDarkTheme == true) ? Colors.black.withOpacity(0.8) : Colors.transparent.withOpacity(0.6)),
                            child: MyText(
                              text: languages[choosenLanguage]
                                  ['text_code_copied'],
                              size: media.width * twelve,
                              color: (isDarkTheme == true) ? theme : topBar,
                            ),
                          ))
                      : Container()
                ],
              ),
            );
          }),
    );
  }
}
