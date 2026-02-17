import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import '../../functions/functions.dart';
import '../../styles/styles.dart';
import '../../translation/translation.dart';
import '../../widgets/widgets.dart';
import '../NavigatorPages/adminchatpage.dart';
import '../NavigatorPages/bankdetails.dart';
import '../NavigatorPages/driverdetails.dart';
import '../NavigatorPages/driverearnings.dart';
import '../NavigatorPages/editprofile.dart';
import '../NavigatorPages/faq.dart';
import '../NavigatorPages/history.dart';
import '../NavigatorPages/makecomplaint.dart';
import '../NavigatorPages/managevehicles.dart';
import '../NavigatorPages/referral.dart';
import '../NavigatorPages/sos.dart';
import '../NavigatorPages/walletpage.dart';
import '../login/landingpage.dart';
import '../onTripPage/map_page.dart';

class NavDrawer extends StatefulWidget {
  const NavDrawer({Key? key}) : super(key: key);
  @override
  State<NavDrawer> createState() => _NavDrawerState();
}

class _NavDrawerState extends State<NavDrawer> {
  // ignore: unused_field
  final bool _isLoading = false;
  // ignore: unused_field
  final String _error = '';
  final bool _isAccountExpanded = false;

  themefun() async {
    if (isDarkTheme) {
      isDarkTheme = false;
      page = Colors.white;
      backgroundColor = const Color(0xffe5e5e5);
      topBar = const Color(0xffF8F8F8);
      textColor = Colors.black;
      buttonColor = theme;
      loaderColor = theme;
      hintColor = const Color(0xff12121D).withOpacity(0.3);
      borderLines = const Color(0xffE5E5E5);
      backIcon = const Color(0xff12121D);
      underline = const Color(0xff12121D).withOpacity(0.3);
      inputUnderline = const Color(0xff12121D).withOpacity(0.3);
      inputfocusedUnderline = const Color(0xff12121D);
    } else {
      isDarkTheme = true;
      page = Colors.black;
      backgroundColor = Colors.black;
      topBar = Colors.black;
      textColor = Colors.white;
      buttonColor = theme; // Roxo original
      loaderColor = theme; // Roxo original
      hintColor = Colors.white.withOpacity(0.5);
      borderLines = const Color.fromARGB(255, 154, 3, 233)
          .withOpacity(0.3); // Roxo transparente
      backIcon = Colors.white;
      underline = theme.withOpacity(0.5); // Roxo transparente
      inputUnderline = theme.withOpacity(0.3); // Roxo transparente
      inputfocusedUnderline = theme; // Roxo
    }
    await getDetailsOfDevice();

    pref.setBool('isDarkTheme', isDarkTheme);

    valueNotifierHome.incrementNotifier();
  }

  navigateLogout() {
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => const LandingPage()));
  }

  @override
  void initState() {
    if (userDetails['chat_id'] != null && chatStream == null) {
      streamAdminchat();
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return ValueListenableBuilder(
        valueListenable: valueNotifierHome.value,
        builder: (context, value, child) {
          return SizedBox(
            width: media.width * 0.8,
            child: Directionality(
              textDirection: (languageDirection == 'rtl')
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: Drawer(
                  backgroundColor: page,
                  child: SizedBox(
                    width: media.width * 0.7,
                    child: Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: media.width * 0.05 +
                                        MediaQuery.of(context).padding.top,
                                  ),
                                  SizedBox(
                                    width: media.width * 0.7,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            InkWell(
                                              onTap: () async {
                                                var val = await Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            const EditProfile()));
                                                if (val) {
                                                  setState(() {});
                                                }
                                              },
                                              child: Container(
                                                height: media.width * 0.2,
                                                width: media.width * 0.2,
                                                decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                    image: DecorationImage(
                                                        image: NetworkImage(
                                                            userDetails[
                                                                'profile_picture']),
                                                        fit: BoxFit.cover)),
                                              ),
                                            ),
                                            SizedBox(
                                              height: media.width * 0.02,
                                            ),
                                            InkWell(
                                              onTap: () async {
                                                var val = await Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            const EditProfile()));
                                                if (val) {
                                                  setState(() {});
                                                }
                                              },
                                              child: Container(
                                                padding: EdgeInsets.all(
                                                    media.width * 0.01),
                                                width: media.width * 0.2,
                                                decoration: BoxDecoration(
                                                    color: textColor
                                                        .withOpacity(0.1),
                                                    border: Border.all(
                                                        color: textColor
                                                            .withOpacity(0.15)),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            media.width *
                                                                0.01)),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.edit,
                                                        size: media.width *
                                                            fourteen,
                                                        color: textColor),
                                                    SizedBox(
                                                      width: media.width * 0.01,
                                                    ),
                                                    MyText(
                                                        text: languages[
                                                                choosenLanguage]
                                                            ['text_edit'],
                                                        size: media.width *
                                                            twelve,
                                                        maxLines: 1,
                                                        color: textColor),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(
                                          width: media.width * 0.025,
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            SizedBox(
                                              width: media.width * 0.45,
                                              child: MyText(
                                                text: userDetails['name'],
                                                size: media.width * eighteen,
                                                fontweight: FontWeight.w600,
                                                maxLines: 1,
                                              ),
                                            ),
                                            SizedBox(
                                              height: media.width * 0.01,
                                            ),
SizedBox(
                                              width: media.width * 0.45,
                                              child: MyText(
                                                text: userDetails['mobile'],
                                                size: media.width * fourteen,
                                                maxLines: 1,
                                              ),
                                            ),
                                            SizedBox(height: media.width * 0.02),
                                            SizedBox(
                                              width: media.width * 0.45,
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: MyText(
                                                      text: '${languages[choosenLanguage]['text_referral_earn_code'] ?? 'Código de indicação'}: ${myReferralCode['refferal_code']?.toString() ?? '—'}',
                                                      size: media.width * twelve,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: media.width * 0.1,
                                                    height: media.width * 0.1,
                                                    child: InkWell(
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
                                                      child: Icon(Icons.share, size: media.width * 0.06, color: buttonColor),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.only(
                                      top: media.width * 0.02),
                                    width: media.width * 0.7,
                                    child: Column(
                                      children: [
                                        AnimatedOpacity(
                                          duration:
                                              const Duration(milliseconds: 300),
                                          opacity:
                                              _isAccountExpanded ? 0.3 : 1.0,
                                          child: Column(
                                            children: [
                                              // 1 - Carteira e Saldo
                                              userDetails['owner_id'] == null &&
                                                      userDetails['show_wallet_feature_on_mobile_app'] == '1'
                                                  ? NavMenu(
                                                      onTap: () {
                                                        Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                                builder: (context) => const WalletPage()));
                                                      },
                                                      text: languages[choosenLanguage]['text_enable_wallet'],
                                                      image: 'assets/images/walletIcon.png',
                                                    )
                                                  : Container(),

                                              // 2 - Minhas viagens
                                              NavMenu(
                                                onTap: () {
                                                  Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) => const History()));
                                                },
                                                text: languages[choosenLanguage]['text_enable_history'],
                                                image: 'assets/images/history.png',
                                              ),

                                              // 3 - Relatório de viagens
                                              NavMenu(
                                                onTap: () {
                                                  Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) => const DriverEarnings()));
                                                },
                                                text: languages[choosenLanguage]['text_earnings'],
                                                image: 'assets/images/earing.png',
                                              ),

                                              // 4 - Indicações
                                              userDetails['owner_id'] == null && userDetails['role'] == 'driver'
                                                  ? NavMenu(
                                                      onTap: () {
                                                        Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                                builder: (context) => const ReferralPage()));
                                                      },
                                                      text: languages[choosenLanguage]['text_enable_referal'],
                                                      image: 'assets/images/referral.png',
                                                    )
                                                  : Container(),

                                              // 5 - Dados bancários
                                              NavMenu(
                                                onTap: () {
                                                  Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) => const BankDetails()));
                                                },
                                                text: languages[choosenLanguage]['text_updateBank'],
                                                icon: Icons.account_balance_outlined,
                                              ),

                                              // 6 - SOS
                                              userDetails['role'] != 'owner'
                                                  ? NavMenu(
                                                      onTap: () async {
                                                        var nav = await Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                                builder: (context) => const Sos()));
                                                        if (nav) setState(() {});
                                                      },
                                                      text: languages[choosenLanguage]['text_sos'],
                                                      image: 'assets/images/sos.png',
                                                      textcolor: buttonColor,
                                                    )
                                                  : Container(),

                                              // 7 - Conversar conosco
                                              userDetails['role'] != 'owner'
                                                  ? ValueListenableBuilder(
                                                      valueListenable: valueNotifierChat.value,
                                                      builder: (context, value, child) {
                                                        return InkWell(
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
                                                                    Row(
                                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                      children: [
                                                                        SizedBox(
                                                                          width: (unSeenChatCount == '0') ? media.width * 0.55 : media.width * 0.495,
                                                                          child: MyText(
                                                                            text: languages[choosenLanguage]['text_chat_us'],
                                                                            overflow: TextOverflow.ellipsis,
                                                                            size: media.width * sixteen,
                                                                            color: textColor.withOpacity(0.8),
                                                                          ),
                                                                        ),
                                                                        Row(
                                                                          children: [
                                                                            (unSeenChatCount == '0') ? Container() : Container(
                                                                              height: 20,
                                                                              width: 20,
                                                                              alignment: Alignment.center,
                                                                              decoration: BoxDecoration(shape: BoxShape.circle, color: buttonColor),
                                                                              child: Text(unSeenChatCount, style: GoogleFonts.poppins(fontSize: media.width * fourteen, color: buttonText)),
                                                                            ),
                                                                            Icon(Icons.arrow_forward_ios_outlined, size: media.width * 0.05, color: textColor.withOpacity(0.8)),
                                                                          ],
                                                                        ),
                                                                      ],
                                                                    )
                                                                  ],
                                                                ),
                                                                Container(
                                                                  alignment: Alignment.centerRight,
                                                                  padding: EdgeInsets.only(top: media.width * 0.01, left: media.width * 0.09),
                                                                  child: Container(
                                                                    height: 1.5,
                                                                    decoration: BoxDecoration(
                                                                      gradient: LinearGradient(
                                                                        colors: [buttonColor, buttonColor.withOpacity(0.8), buttonColor.withOpacity(0.4), buttonColor.withOpacity(0.0)],
                                                                        stops: const [0.0, 0.3, 0.6, 1.0],
                                                                        begin: Alignment.centerLeft,
                                                                        end: Alignment.centerRight,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                )
                                                              ],
                                                            ),
                                                          ),
                                                        );
                                                      })
                                                  : Container(),

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
                                                          builder: (context) => MakeComplaint(fromPage: 2)));
                                                },
                                                text: languages[choosenLanguage]['text_make_complaints'],
                                                image: 'assets/images/makecomplaint.png',
                                              ),

                                              // 10 - Política de privacidade
                                              NavMenu(
                                                onTap: () {
                                                  openBrowser('https://driver.app.br/privacy');
                                                },
                                                text: languages[choosenLanguage]['text_privacy'],
                                                image: 'assets/images/privacy_policy.png',
                                              ),

                                              // Selecionar tema (ícone alinhado à esquerda como os outros)
                                              InkWell(
                                                onTap: () async {
                                                  themefun();
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
                                                                    style: GoogleFonts.poppins(
                                                                        fontSize: media.width * sixteen,
                                                                        color: textColor.withOpacity(0.8)),
                                                                    overflow: TextOverflow.ellipsis,
                                                                  ),
                                                                ),
                                                                Switch(
                                                                  value: isDarkTheme,
                                                                  onChanged: (toggle) async {
                                                                    themefun();
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
                                                          height: 1.5,
                                                          decoration: BoxDecoration(
                                                            gradient: LinearGradient(
                                                              colors: [
                                                                buttonColor,
                                                                buttonColor.withOpacity(0.8),
                                                                buttonColor.withOpacity(0.4),
                                                                buttonColor.withOpacity(0.0),
                                                              ],
                                                              stops: const [0.0, 0.3, 0.6, 1.0],
                                                              begin: Alignment.centerLeft,
                                                              end: Alignment.centerRight,
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
                                        // Owner: gestão de frota (fora da lista Geral)
                                        if (userDetails['role'] == 'owner') ...[
                                          NavMenu(
                                            onTap: () {
                                              Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) => const ManageVehicles()));
                                            },
                                            text: languages[choosenLanguage]['text_manage_vehicle'],
                                            image: 'assets/images/updateVehicleInfo.png',
                                          ),
                                          NavMenu(
                                            onTap: () {
                                              Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) => const DriverList()));
                                            },
                                            text: languages[choosenLanguage]['text_manage_drivers'],
                                            image: 'assets/images/managedriver.png',
                                          ),
                                        ],
                                      ],
                                    ),
                                  )
                                ]),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            setState(() {
                              logout = true;
                            });
                            valueNotifierHome.incrementNotifier();
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: EdgeInsets.only(
                              left: media.width * 0.05,
                            ),
                            height: media.width * 0.13,
                            width: media.width * 0.7,
                            color: Colors.grey.withOpacity(0.3),
                            child: Row(
                              mainAxisAlignment: (languageDirection == 'ltr')
                                  ? MainAxisAlignment.start
                                  : MainAxisAlignment.end,
                              children: [
                                Icon(
                                  Icons.logout,
                                  size: media.width * 0.05,
                                  color: textColor,
                                ),
                                SizedBox(
                                  width: media.width * 0.025,
                                ),
                                MyText(
                                  text: languages[choosenLanguage]
                                      ['text_sign_out'],
                                  size: media.width * sixteen,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                )
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          height: media.width * 0.05,
                        )
                      ],
                    ),
                  )),
            ),
          );
        });
  }
}
