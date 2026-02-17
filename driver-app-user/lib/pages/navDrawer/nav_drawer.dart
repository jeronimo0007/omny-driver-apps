import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import '../../functions/functions.dart';
import '../../styles/styles.dart';
import '../../translations/translation.dart';
import '../../widgets/widgets.dart';
import '../NavigatorPages/adminchatpage.dart';
import '../NavigatorPages/editprofile.dart';
import '../NavigatorPages/faq.dart';
import '../NavigatorPages/favourite.dart';
import '../NavigatorPages/history.dart';
import '../NavigatorPages/makecomplaint.dart';
import '../NavigatorPages/referral.dart';
import '../NavigatorPages/selectlanguage.dart';
import '../NavigatorPages/sos.dart';
import '../NavigatorPages/bankdetails.dart';
import '../NavigatorPages/walletpage.dart';
import '../onTripPage/map_page.dart';

class NavDrawer extends StatefulWidget {
  const NavDrawer({Key? key}) : super(key: key);
  @override
  State<NavDrawer> createState() => _NavDrawerState();
}

class _NavDrawerState extends State<NavDrawer> {
  darkthemefun() async {
    if (isDarkTheme) {
      isDarkTheme = false;
      page = Colors.white;
      textColor = Colors.black;
      buttonColor = theme;
      loaderColor = theme;
      hintColor = const Color(0xff12121D).withOpacity(0.3);
    } else {
      isDarkTheme = true;
      page = Colors.black;
      textColor = Colors.white.withOpacity(0.9);
      buttonColor = theme; // Roxo: Color.fromARGB(255, 154, 3, 233)
      loaderColor = theme; // Roxo
      hintColor = Colors.white.withOpacity(0.3);
    }
    await getDetailsOfDevice();

    pref.setBool('isDarkTheme', isDarkTheme);

    valueNotifierHome.incrementNotifier();
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return ValueListenableBuilder(
        valueListenable: valueNotifierHome.value,
        builder: (context, value, child) {
          return Directionality(
            textDirection: (languageDirection == 'rtl')
                ? TextDirection.rtl
                : TextDirection.ltr,
            child: Drawer(
              backgroundColor: page,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.only(
                              top: MediaQuery.of(context).padding.top +
                                  media.width * 0.05,
                              left: media.width * 0.05,
                              right: media.width * 0.05,
                              bottom: media.width * 0.05,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  children: [
                                    InkWell(
                                      splashColor: Colors.transparent,
                                      highlightColor: Colors.transparent,
                                      onTap: () async {
                                        var val = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    const EditProfile()));
                                        if (val == true) {
                                          setState(() {});
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        height: media.width * 0.2,
                                        width: media.width * 0.2,
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            image: (userDetails['profile_picture'] !=
                                                        null &&
                                                    userDetails['profile_picture']
                                                        .toString()
                                                        .isNotEmpty)
                                                ? DecorationImage(
                                                    image: NetworkImage(
                                                        userDetails['profile_picture']
                                                            .toString()),
                                                    fit: BoxFit.cover)
                                                : null,
                                            color: (userDetails[
                                                            'profile_picture'] ==
                                                        null ||
                                                    userDetails['profile_picture']
                                                        .toString()
                                                        .isEmpty)
                                                ? Colors.grey.withOpacity(0.3)
                                                : null),
                                        child: (userDetails[
                                                        'profile_picture'] ==
                                                    null ||
                                                userDetails['profile_picture']
                                                    .toString()
                                                    .isEmpty)
                                            ? Icon(Icons.person,
                                                size: media.width * 0.1,
                                                color:
                                                    textColor.withOpacity(0.5))
                                            : null,
                                      ),
                                    ),
                                    SizedBox(height: media.width * 0.015),
                                    InkWell(
                                      splashColor: Colors.transparent,
                                      highlightColor: Colors.transparent,
                                      onTap: () async {
                                        var val = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    const EditProfile()));
                                        if (val == true) {
                                          setState(() {});
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: media.width * 0.03,
                                          vertical: media.width * 0.015,
                                        ),
                                        decoration: BoxDecoration(
                                          color: textColor.withOpacity(0.05),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.edit_outlined,
                                              size: media.width * sixteen,
                                              color: textColor.withOpacity(0.7),
                                            ),
                                            SizedBox(
                                                width: media.width * 0.015),
                                            MyText(
                                              text: languages[choosenLanguage]
                                                  ['text_edit'],
                                              size: media.width * fourteen,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              color: textColor.withOpacity(0.7),
                                              fontweight: FontWeight.w500,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(width: media.width * 0.025),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      MyText(
                                        text: userDetails['name']?.toString() ??
                                            '',
                                        size: media.width * eighteen,
                                        fontweight: FontWeight.w600,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: media.width * 0.01),
                                      MyText(
                                        text:
                                            userDetails['mobile']?.toString() ??
                                                '',
                                        size: media.width * fourteen,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: media.width * 0.02),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: RichText(
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              text: TextSpan(
                                                style: getGoogleFontStyle(
                                                  fontSize: media.width * twelve,
                                                  color: textColor,
                                                ),
                                                children: [
                                                  TextSpan(
                                                    text: '${languages[choosenLanguage]['text_referral_earn_code'] ?? 'Código de indicação'}: ',
                                                  ),
                                                  TextSpan(
                                                    text: myReferralCode['refferal_code']?.toString() ?? '—',
                                                    style: getGoogleFontStyle(
                                                      fontSize: media.width * twelve,
                                                      color: textColor,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () async {
                                              if ((myReferralCode['refferal_code']?.toString() ?? '').isEmpty) {
                                                await getReferral();
                                                if (mounted) setState(() {});
                                              }
                                              final code = myReferralCode['refferal_code']?.toString() ?? '';
                                              if (code.isNotEmpty) {
                                                String storeText = '';
                                                if (defaultTargetPlatform == TargetPlatform.android) {
                                                  final package = await PackageInfo.fromPlatform();
                                                  storeText = '\n\n${languages[choosenLanguage]['text_download_app'] ?? 'Baixe o app'}: https://play.google.com/store/apps/details?id=${package.packageName}';
                                                } else {
                                                  storeText = '\n\n${languages[choosenLanguage]['text_available_app_store'] ?? 'Disponível na App Store.'}';
                                                }
                                                await Share.share(
                                                  '${languages[choosenLanguage]['text_referral_earn_code'] ?? 'Meu código de indicação'}: $code$storeText',
                                                );
                                              }
                                            },
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(horizontal: media.width * 0.02),
                                              child: Icon(Icons.share, size: media.width * 0.06, color: buttonColor),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: media.width * 0.05,
                            ),
                            child: Column(
                              children: [
                                // 1 - Carteira e Saldo
                                NavMenu(
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => const WalletPage()));
                                  },
                                  text: languages[choosenLanguage]['text_enable_wallet'],
                                  image: 'assets/images/walletIcon.png',
                                ),
                                // 2 - Dados bancários
                                NavMenu(
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => const BankDetails()));
                                  },
                                  text: languages[choosenLanguage]['text_bankDetails'],
                                  icon: Icons.account_balance_outlined,
                                ),
                                // 3 - Favoritos
                                NavMenu(
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => const Favorite()));
                                  },
                                  text: languages[choosenLanguage]['text_favourites'],
                                  icon: Icons.bookmark,
                                ),
                                // 4 - Minhas viagens
                                NavMenu(
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => const History()));
                                  },
                                  text: languages[choosenLanguage]['text_my_orders'],
                                  image: 'assets/images/history.png',
                                ),
                                // 5 - Indicações
                                NavMenu(
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => const ReferralPage()));
                                  },
                                  text: languages[choosenLanguage]['text_enable_referal'],
                                  image: 'assets/images/referral.png',
                                ),
                                // 6 - SOS
                                NavMenu(
                                  onTap: () async {
                                    var nav = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => const Sos()));
                                    if (nav) setState(() {});
                                  },
                                  text: languages[choosenLanguage]['text_sos'],
                                  image: 'assets/images/sos.png',
                                ),
                                // 7 - Conversar conosco
                                ValueListenableBuilder(
                                  valueListenable: valueNotifierChat.value,
                                  builder: (context, value, child) {
                                    return InkWell(
                                      splashColor: Colors.transparent,
                                      highlightColor: Colors.transparent,
                                      onTap: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) => const AdminChatPage()));
                                      },
                                      child: Container(
                                        padding: EdgeInsets.only(top: media.width * 0.025),
                                        child: Column(
                                          children: [
                                            Row(
                                              children: [
                                                Icon(Icons.chat, size: media.width * 0.075, color: textColor.withOpacity(0.8)),
                                                SizedBox(width: media.width * 0.025),
                                                Expanded(
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Expanded(
                                                        child: MyText(
                                                          text: languages[choosenLanguage]['text_chat_us'],
                                                          overflow: TextOverflow.ellipsis,
                                                          size: media.width * sixteen,
                                                          color: textColor.withOpacity(0.8),
                                                        ),
                                                      ),
                                                      Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          (unSeenChatCount == '0') ? Container() : Container(
                                                            height: 20,
                                                            width: 20,
                                                            alignment: Alignment.center,
                                                            decoration: BoxDecoration(shape: BoxShape.circle, color: buttonColor),
                                                            child: Text(unSeenChatCount.isNotEmpty ? unSeenChatCount : '0', style: getGoogleFontStyle(fontSize: media.width * fourteen, color: buttonText)),
                                                          ),
                                                          SizedBox(width: media.width * 0.01),
                                                          Icon(Icons.arrow_forward_ios_outlined, size: media.width * 0.05, color: textColor.withOpacity(0.8)),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              ],
                                            ),
                                            Container(
                                              alignment: Alignment.centerRight,
                                              padding: EdgeInsets.only(top: media.width * 0.01, left: media.width * 0.09),
                                              child: Container(
                                                color: buttonColor.withOpacity(0.5),
                                                height: 1,
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                // 8 - Perguntas Frequentes
                                NavMenu(
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => const Faq()));
                                  },
                                  text: languages[choosenLanguage]['text_faq'],
                                  image: 'assets/images/faq.png',
                                ),
                                // 9 - Fazer reclamação
                                NavMenu(
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => MakeComplaint(fromPage: 1)));
                                  },
                                  text: languages[choosenLanguage]['text_make_complaints'],
                                  image: 'assets/images/makecomplaint.png',
                                ),
                                // 10 - Política de privacidade
                                NavMenu(
                                  onTap: () {
                                    openBrowser('${url}privacy');
                                  },
                                  text: languages[choosenLanguage]['text_privacy'],
                                  image: 'assets/images/privacy_policy.png',
                                ),
                                // 11 - Alterar idioma
                                NavMenu(
                                  onTap: () async {
                                    var nav = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => const SelectLanguage()));
                                    if (nav) setState(() {});
                                  },
                                  text: languages[choosenLanguage]['text_change_language'],
                                  image: 'assets/images/changeLanguage.png',
                                ),
                                // 12 - Selecionar tema (ícone alinhado à esquerda)
                                InkWell(
                                  splashColor: Colors.transparent,
                                  highlightColor: Colors.transparent,
                                  onTap: () async {
                                    darkthemefun();
                                  },
                                  child: Container(
                                    padding: EdgeInsets.only(top: media.width * 0.025),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              isDarkTheme ? Icons.brightness_4_outlined : Icons.brightness_3_rounded,
                                              size: media.width * 0.075,
                                              color: textColor.withOpacity(0.8),
                                            ),
                                            SizedBox(width: media.width * 0.025),
                                            Expanded(
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      languages[choosenLanguage]['text_select_theme'],
                                                      style: getGoogleFontStyle(
                                                          fontSize: media.width * sixteen,
                                                          color: textColor.withOpacity(0.8)),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Switch(
                                                    value: isDarkTheme,
                                                    activeThumbColor: theme,
                                                    onChanged: (toggle) async {
                                                      darkthemefun();
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          alignment: Alignment.centerRight,
                                          padding: EdgeInsets.only(top: media.width * 0.01, left: media.width * 0.09),
                                          child: Container(
                                            height: 1,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.centerLeft,
                                                end: Alignment.centerRight,
                                                colors: [
                                                  (isDarkTheme ? theme : buttonColor).withOpacity(0.7),
                                                  (isDarkTheme ? theme : buttonColor).withOpacity(0.0),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: media.width * 0.05,
                      vertical: media.width * 0.025,
                    ),
                    child: InkWell(
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () {
                        setState(() {
                          logout = true;
                        });
                        valueNotifierHome.incrementNotifier();
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: media.width * 0.05,
                          vertical: media.width * 0.04,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout,
                                size: media.width * 0.05, color: textColor),
                            SizedBox(
                              width: media.width * 0.025,
                            ),
                            MyText(
                              text: languages[choosenLanguage]['text_sign_out'],
                              size: media.width * sixteen,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).padding.bottom +
                        media.width * 0.05,
                  )
                ],
              ),
            ),
          );
        });
  }
}
