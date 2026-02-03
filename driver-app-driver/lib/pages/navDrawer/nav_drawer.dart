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
import '../NavigatorPages/myroutebookings.dart';
import '../NavigatorPages/notification.dart';
import '../NavigatorPages/referral.dart';
import '../NavigatorPages/selectlanguage.dart';
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
  bool _isLoading = false;
  // ignore: unused_field
  String _error = '';
  bool _isAccountExpanded = false;

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
                                              Container(
                                                padding: EdgeInsets.only(
                                                    top: media.width * 0.025),
                                                child: Row(
                                                  children: [
                                                    MyText(
                                                      text: languages[
                                                                  choosenLanguage]
                                                              ['text_general']
                                                          .toString()
                                                          .toUpperCase(),
                                                      size: media.width *
                                                          fourteen,
                                                      fontweight:
                                                          FontWeight.w700,
                                                      color: _isAccountExpanded
                                                          ? textColor
                                                              .withOpacity(0.3)
                                                          : textColor,
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              //Notifications (mais usado)
                                              (userDetails['role'] != 'owner')
                                                  ? ValueListenableBuilder(
                                                      valueListenable:
                                                          valueNotifierNotification
                                                              .value,
                                                      builder: (context, value,
                                                          child) {
                                                        return InkWell(
                                                          onTap: () {
                                                            Navigator.push(
                                                                context,
                                                                MaterialPageRoute(
                                                                    builder:
                                                                        (context) =>
                                                                            const NotificationPage()));
                                                            setState(() {
                                                              userDetails[
                                                                  'notifications_count'] = 0;
                                                            });
                                                          },
                                                          child: Container(
                                                            padding:
                                                                EdgeInsets.only(
                                                                    top: media
                                                                            .width *
                                                                        0.025),
                                                            child: Column(
                                                              children: [
                                                                Row(
                                                                  children: [
                                                                    Image.asset(
                                                                      'assets/images/notification.png',
                                                                      fit: BoxFit
                                                                          .contain,
                                                                      width: media
                                                                              .width *
                                                                          0.075,
                                                                      color: textColor
                                                                          .withOpacity(
                                                                              0.8),
                                                                    ),
                                                                    SizedBox(
                                                                      width: media
                                                                              .width *
                                                                          0.025,
                                                                    ),
                                                                    Row(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .spaceBetween,
                                                                      children: [
                                                                        SizedBox(
                                                                          width: (userDetails['notifications_count'] == 0)
                                                                              ? media.width * 0.55
                                                                              : media.width * 0.495,
                                                                          child:
                                                                              MyText(
                                                                            text:
                                                                                languages[choosenLanguage]['text_notification'].toString(),
                                                                            overflow:
                                                                                TextOverflow.ellipsis,
                                                                            size:
                                                                                media.width * sixteen,
                                                                            color:
                                                                                textColor.withOpacity(0.8),
                                                                          ),
                                                                        ),
                                                                        Row(
                                                                          children: [
                                                                            (userDetails['notifications_count'] == 0)
                                                                                ? Container()
                                                                                : Container(
                                                                                    height: 20,
                                                                                    width: 20,
                                                                                    alignment: Alignment.center,
                                                                                    decoration: BoxDecoration(
                                                                                      shape: BoxShape.circle,
                                                                                      color: buttonColor,
                                                                                    ),
                                                                                    child: Text(
                                                                                      userDetails['notifications_count'].toString(),
                                                                                      style: GoogleFonts.poppins(fontSize: media.width * fourteen, color: buttonText),
                                                                                    ),
                                                                                  ),
                                                                            Icon(
                                                                              Icons.arrow_forward_ios_outlined,
                                                                              size: media.width * 0.05,
                                                                              color: textColor.withOpacity(0.8),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ],
                                                                    )
                                                                  ],
                                                                ),
                                                                Container(
                                                                  alignment:
                                                                      Alignment
                                                                          .centerRight,
                                                                  padding:
                                                                      EdgeInsets
                                                                          .only(
                                                                    top: media
                                                                            .width *
                                                                        0.01,
                                                                    left: media
                                                                            .width *
                                                                        0.09,
                                                                  ),
                                                                  child:
                                                                      Container(
                                                                    height: 1.5,
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      gradient:
                                                                          LinearGradient(
                                                                        colors: [
                                                                          buttonColor,
                                                                          buttonColor
                                                                              .withOpacity(0.8),
                                                                          buttonColor
                                                                              .withOpacity(0.4),
                                                                          buttonColor
                                                                              .withOpacity(0.0),
                                                                        ],
                                                                        stops: const [
                                                                          0.0,
                                                                          0.3,
                                                                          0.6,
                                                                          1.0
                                                                        ],
                                                                        begin: Alignment
                                                                            .centerLeft,
                                                                        end: Alignment
                                                                            .centerRight,
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

                                              //Histórico
                                              NavMenu(
                                                onTap: () {
                                                  Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              const History()));
                                                },
                                                text: languages[choosenLanguage]
                                                    ['text_enable_history'],
                                                image:
                                                    'assets/images/history.png',
                                              ),

                                              //Earnings
                                              NavMenu(
                                                onTap: () {
                                                  Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              const DriverEarnings()));
                                                },
                                                text: languages[choosenLanguage]
                                                    ['text_earnings'],
                                                image:
                                                    'assets/images/earing.png',
                                              ),

                                              //wallet page
                                              userDetails['owner_id'] == null &&
                                                      userDetails[
                                                              'show_wallet_feature_on_mobile_app'] ==
                                                          '1'
                                                  ? NavMenu(
                                                      onTap: () {
                                                        Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                                builder:
                                                                    (context) =>
                                                                        const WalletPage()));
                                                      },
                                                      text: languages[
                                                              choosenLanguage][
                                                          'text_enable_wallet'],
                                                      image:
                                                          'assets/images/walletIcon.png',
                                                    )
                                                  : Container(),

                                              //My Route Booking
                                              userDetails['role'] != 'owner' &&
                                                      userDetails[
                                                              'enable_my_route_booking_feature'] ==
                                                          '1' &&
                                                      userDetails[
                                                              'transport_type'] !=
                                                          'delivery'
                                                  ? InkWell(
                                                      onTap: () async {
                                                        var nav = await Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                                builder:
                                                                    (context) =>
                                                                        const MyRouteBooking()));
                                                        if (nav != null) {
                                                          if (nav) {
                                                            setState(() {});
                                                          }
                                                        }
                                                      },
                                                      child: Row(
                                                        children: [
                                                          Container(
                                                            padding: EdgeInsets
                                                                .fromLTRB(
                                                                    media.width *
                                                                        0.01,
                                                                    media.width *
                                                                        0.025,
                                                                    media.width *
                                                                        0.025,
                                                                    media.width *
                                                                        0.025),
                                                            child: Row(
                                                              children: [
                                                                Image.asset(
                                                                  'assets/images/myroute.png',
                                                                  fit: BoxFit
                                                                      .contain,
                                                                  width: media
                                                                          .width *
                                                                      0.06,
                                                                  color: textColor
                                                                      .withOpacity(
                                                                          0.8),
                                                                ),
                                                                SizedBox(
                                                                  width: media
                                                                          .width *
                                                                      0.025,
                                                                ),
                                                                SizedBox(
                                                                  width: media
                                                                          .width *
                                                                      0.45,
                                                                  child: Text(
                                                                    languages[
                                                                            choosenLanguage]
                                                                        [
                                                                        'text_my_route'],
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                    style: GoogleFonts.poppins(
                                                                        fontSize:
                                                                            media.width *
                                                                                sixteen,
                                                                        color: textColor
                                                                            .withOpacity(0.8)),
                                                                  ),
                                                                )
                                                              ],
                                                            ),
                                                          ),

                                                          // SizedBox(width: media.width*0.05,),
                                                          if (userDetails[
                                                                  'my_route_address'] !=
                                                              null)
                                                            InkWell(
                                                              onTap: () async {
                                                                setState(() {
                                                                  _isLoading =
                                                                      true;
                                                                });
                                                                var dist = calculateDistance(
                                                                    center
                                                                        .latitude,
                                                                    center
                                                                        .longitude,
                                                                    double.parse(
                                                                        userDetails['my_route_lat']
                                                                            .toString()),
                                                                    double.parse(
                                                                        userDetails['my_route_lng']
                                                                            .toString()));

                                                                if (dist >
                                                                        5000.0 ||
                                                                    userDetails[
                                                                            'enable_my_route_booking'] ==
                                                                        "1") {
                                                                  var val = await enableMyRouteBookings(
                                                                      center
                                                                          .latitude,
                                                                      center
                                                                          .longitude);
                                                                  if (val ==
                                                                      'logout') {
                                                                    navigateLogout();
                                                                  } else if (val !=
                                                                      'success') {
                                                                    setState(
                                                                        () {
                                                                      _error =
                                                                          val;
                                                                    });
                                                                  }
                                                                } else {
                                                                  _error = languages[
                                                                          choosenLanguage]
                                                                      [
                                                                      'text_myroute_warning'];
                                                                }

                                                                setState(() {
                                                                  _isLoading =
                                                                      false;
                                                                });
                                                              },
                                                              child: Container(
                                                                padding: EdgeInsets.only(
                                                                    left: media
                                                                            .width *
                                                                        0.005,
                                                                    right: media
                                                                            .width *
                                                                        0.005),
                                                                height: media
                                                                        .width *
                                                                    0.05,
                                                                width: media
                                                                        .width *
                                                                    0.1,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                          media.width *
                                                                              0.025),
                                                                  color: (userDetails[
                                                                              'enable_my_route_booking'] ==
                                                                          1)
                                                                      ? Colors
                                                                          .green
                                                                          .withOpacity(
                                                                              0.4)
                                                                      : Colors
                                                                          .grey
                                                                          .withOpacity(
                                                                              0.6),
                                                                ),
                                                                child: Row(
                                                                  mainAxisAlignment: (userDetails[
                                                                              'enable_my_route_booking'] ==
                                                                          1)
                                                                      ? MainAxisAlignment
                                                                          .end
                                                                      : MainAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    Container(
                                                                      height: media
                                                                              .width *
                                                                          0.045,
                                                                      width: media
                                                                              .width *
                                                                          0.045,
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        shape: BoxShape
                                                                            .circle,
                                                                        color: (userDetails['enable_my_route_booking'] ==
                                                                                1)
                                                                            ? Colors.green
                                                                            : Colors.grey,
                                                                      ),
                                                                    )
                                                                  ],
                                                                ),
                                                              ),
                                                            )
                                                        ],
                                                      ),
                                                    )
                                                  : Container(),

                                              //Linha de separação após My Route Booking
                                              userDetails['role'] != 'owner' &&
                                                      userDetails[
                                                              'enable_my_route_booking_feature'] ==
                                                          '1' &&
                                                      userDetails[
                                                              'transport_type'] !=
                                                          'delivery'
                                                  ? Container(
                                                      alignment:
                                                          Alignment.centerRight,
                                                      padding: EdgeInsets.only(
                                                        top: media.width * 0.01,
                                                        left:
                                                            media.width * 0.09,
                                                      ),
                                                      child: Container(
                                                        height: 1.5,
                                                        decoration:
                                                            BoxDecoration(
                                                          gradient:
                                                              LinearGradient(
                                                            colors: [
                                                              buttonColor,
                                                              buttonColor
                                                                  .withOpacity(
                                                                      0.8),
                                                              buttonColor
                                                                  .withOpacity(
                                                                      0.4),
                                                              buttonColor
                                                                  .withOpacity(
                                                                      0.0),
                                                            ],
                                                            stops: const [
                                                              0.0,
                                                              0.3,
                                                              0.6,
                                                              1.0
                                                            ],
                                                            begin: Alignment
                                                                .centerLeft,
                                                            end: Alignment
                                                                .centerRight,
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                  : Container(),

                                              //sos
                                              userDetails['role'] != 'owner'
                                                  ? NavMenu(
                                                      onTap: () async {
                                                        var nav = await Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                                builder:
                                                                    (context) =>
                                                                        const Sos()));
                                                        if (nav) {
                                                          setState(() {});
                                                        }
                                                      },
                                                      text: languages[
                                                              choosenLanguage]
                                                          ['text_sos'],
                                                      image:
                                                          'assets/images/sos.png',
                                                      textcolor: buttonColor,
                                                    )
                                                  : Container(),

                                              //referral page (menos usado)
                                              userDetails['owner_id'] == null &&
                                                      userDetails['role'] ==
                                                          'driver'
                                                  ? NavMenu(
                                                      onTap: () {
                                                        Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                                builder:
                                                                    (context) =>
                                                                        const ReferralPage()));
                                                      },
                                                      text: languages[
                                                              choosenLanguage][
                                                          'text_enable_referal'],
                                                      image:
                                                          'assets/images/referral.png',
                                                    )
                                                  : Container(),
                                            ],
                                          ),
                                        ),

                                        InkWell(
                                          onTap: () {
                                            setState(() {
                                              _isAccountExpanded =
                                                  !_isAccountExpanded;
                                            });
                                          },
                                          child: Container(
                                            padding: EdgeInsets.only(
                                                top: media.width * 0.03),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                MyText(
                                                  text:
                                                      languages[choosenLanguage]
                                                              ['text_account']
                                                          .toString()
                                                          .toUpperCase(),
                                                  size: media.width * fourteen,
                                                  fontweight: FontWeight.w700,
                                                ),
                                                Icon(
                                                  _isAccountExpanded
                                                      ? Icons.expand_less
                                                      : Icons.expand_more,
                                                  color: textColor,
                                                  size: media.width * 0.06,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),

                                        AnimatedSize(
                                          duration:
                                              const Duration(milliseconds: 300),
                                          curve: Curves.easeInOut,
                                          child: _isAccountExpanded
                                              ? Column(
                                                  children: [
                                                    //Admin chat (mais usado)
                                                    ValueListenableBuilder(
                                                        valueListenable:
                                                            valueNotifierChat
                                                                .value,
                                                        builder: (context,
                                                            value, child) {
                                                          return InkWell(
                                                            onTap: () {
                                                              Navigator.push(
                                                                  context,
                                                                  MaterialPageRoute(
                                                                      builder:
                                                                          (context) =>
                                                                              const AdminChatPage()));
                                                            },
                                                            child: Container(
                                                              padding: EdgeInsets
                                                                  .only(
                                                                      top: media
                                                                              .width *
                                                                          0.025),
                                                              child: Column(
                                                                children: [
                                                                  Row(
                                                                    children: [
                                                                      Icon(
                                                                          Icons
                                                                              .chat,
                                                                          size: media.width *
                                                                              0.075,
                                                                          color:
                                                                              textColor.withOpacity(0.8)),
                                                                      SizedBox(
                                                                        width: media.width *
                                                                            0.025,
                                                                      ),
                                                                      Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.spaceBetween,
                                                                        children: [
                                                                          SizedBox(
                                                                            width: (unSeenChatCount == '0')
                                                                                ? media.width * 0.55
                                                                                : media.width * 0.495,
                                                                            child:
                                                                                MyText(
                                                                              text: languages[choosenLanguage]['text_chat_us'],
                                                                              overflow: TextOverflow.ellipsis,
                                                                              size: media.width * sixteen,
                                                                              color: textColor.withOpacity(0.8),
                                                                            ),
                                                                          ),
                                                                          Row(
                                                                            children: [
                                                                              (unSeenChatCount == '0')
                                                                                  ? Container()
                                                                                  : Container(
                                                                                      height: 20,
                                                                                      width: 20,
                                                                                      alignment: Alignment.center,
                                                                                      decoration: BoxDecoration(
                                                                                        shape: BoxShape.circle,
                                                                                        color: buttonColor,
                                                                                      ),
                                                                                      child: Text(
                                                                                        unSeenChatCount,
                                                                                        style: GoogleFonts.poppins(fontSize: media.width * fourteen, color: buttonText),
                                                                                      ),
                                                                                    ),
                                                                              Icon(
                                                                                Icons.arrow_forward_ios_outlined,
                                                                                size: media.width * 0.05,
                                                                                color: textColor.withOpacity(0.8),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        ],
                                                                      )
                                                                    ],
                                                                  ),
                                                                  Container(
                                                                    alignment:
                                                                        Alignment
                                                                            .centerRight,
                                                                    padding:
                                                                        EdgeInsets
                                                                            .only(
                                                                      top: media
                                                                              .width *
                                                                          0.01,
                                                                      left: media
                                                                              .width *
                                                                          0.09,
                                                                    ),
                                                                    child:
                                                                        Container(
                                                                      height:
                                                                          1.5,
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        gradient:
                                                                            LinearGradient(
                                                                          colors: [
                                                                            buttonColor,
                                                                            buttonColor.withOpacity(0.8),
                                                                            buttonColor.withOpacity(0.4),
                                                                            buttonColor.withOpacity(0.0),
                                                                          ],
                                                                          stops: const [
                                                                            0.0,
                                                                            0.3,
                                                                            0.6,
                                                                            1.0
                                                                          ],
                                                                          begin:
                                                                              Alignment.centerLeft,
                                                                          end: Alignment
                                                                              .centerRight,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  )
                                                                ],
                                                              ),
                                                            ),
                                                          );
                                                        }),

                                                    //change language
                                                    NavMenu(
                                                      onTap: () async {
                                                        var nav = await Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                                builder:
                                                                    (context) =>
                                                                        const SelectLanguage()));
                                                        if (nav) {
                                                          setState(() {});
                                                        }
                                                      },
                                                      text: languages[
                                                              choosenLanguage][
                                                          'text_change_language'],
                                                      image:
                                                          'assets/images/changeLanguage.png',
                                                    ),

                                                    //FAQ
                                                    NavMenu(
                                                      onTap: () {
                                                        Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                                builder:
                                                                    (context) =>
                                                                        const Faq()));
                                                      },
                                                      text: languages[
                                                              choosenLanguage]
                                                          ['text_faq'],
                                                      image:
                                                          'assets/images/faq.png',
                                                    ),

                                                    //bank details (sempre visível para cadastrar/editar dados bancários)
                                                    NavMenu(
                                                      onTap: () {
                                                        Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                                builder:
                                                                    (context) =>
                                                                        const BankDetails()));
                                                      },
                                                      text: languages[
                                                              choosenLanguage][
                                                          'text_updateBank'],
                                                      icon: Icons
                                                          .account_balance_outlined,
                                                    ),

                                                    //manage vehicle
                                                    userDetails['role'] ==
                                                            'owner'
                                                        ? NavMenu(
                                                            onTap: () {
                                                              Navigator.push(
                                                                  context,
                                                                  MaterialPageRoute(
                                                                      builder:
                                                                          (context) =>
                                                                              const ManageVehicles()));
                                                            },
                                                            text: languages[
                                                                    choosenLanguage]
                                                                [
                                                                'text_manage_vehicle'],
                                                            image:
                                                                'assets/images/updateVehicleInfo.png',
                                                          )
                                                        : Container(),

                                                    //manage Driver
                                                    userDetails['role'] ==
                                                            'owner'
                                                        ? NavMenu(
                                                            onTap: () {
                                                              Navigator.push(
                                                                  context,
                                                                  MaterialPageRoute(
                                                                      builder:
                                                                          (context) =>
                                                                              const DriverList()));
                                                            },
                                                            text: languages[
                                                                    choosenLanguage]
                                                                [
                                                                'text_manage_drivers'],
                                                            image:
                                                                'assets/images/managedriver.png',
                                                          )
                                                        : Container(),

                                                    //Make Complaint
                                                    NavMenu(
                                                      onTap: () {
                                                        Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                                builder: (context) =>
                                                                    MakeComplaint(
                                                                        fromPage:
                                                                            2)));
                                                      },
                                                      text: languages[
                                                              choosenLanguage][
                                                          'text_make_complaints'],
                                                      image:
                                                          'assets/images/makecomplaint.png',
                                                    ),

                                                    //privacy policy
                                                    NavMenu(
                                                      onTap: () {
                                                        openBrowser(
                                                            'https://driver.app.br/privacy');
                                                      },
                                                      text: languages[
                                                              choosenLanguage]
                                                          ['text_privacy'],
                                                      image:
                                                          'assets/images/privacy_policy.png',
                                                    ),

                                                    // delete account (menos usado)
                                                    userDetails['owner_id'] ==
                                                            null
                                                        ? NavMenu(
                                                            onTap: () {
                                                              setState(() {
                                                                deleteAccount =
                                                                    true;
                                                              });
                                                              valueNotifierHome
                                                                  .incrementNotifier();
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                            text: languages[
                                                                    choosenLanguage]
                                                                [
                                                                'text_delete_account'],
                                                            icon: Icons
                                                                .delete_forever,
                                                          )
                                                        : Container(),
                                                  ],
                                                )
                                              : const SizedBox.shrink(),
                                        ),

                                        //logout
                                      ],
                                    ),
                                  )
                                ]),
                          ),
                        ),
                        InkWell(
                          onTap: () async {
                            themefun();
                          },
                          child: Container(
                            padding: EdgeInsets.only(
                              left: media.width * 0.05,
                              right: media.width * 0.05,
                              top: media.width * 0.025,
                              bottom: media.width * 0.025,
                            ),
                            width: media.width * 0.7,
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      isDarkTheme
                                          ? Icons.brightness_4_outlined
                                          : Icons.brightness_3_rounded,
                                      size: media.width * 0.075,
                                      color: textColor.withOpacity(0.8),
                                    ),
                                    SizedBox(
                                      width: media.width * 0.025,
                                    ),
                                    Expanded(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              languages[choosenLanguage]
                                                  ['text_select_theme'],
                                              style: GoogleFonts.poppins(
                                                  fontSize:
                                                      media.width * sixteen,
                                                  color: textColor
                                                      .withOpacity(0.8)),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          SizedBox(width: media.width * 0.02),
                                          Switch(
                                              value: isDarkTheme,
                                              onChanged: (toggle) async {
                                                themefun();
                                              }),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  alignment: Alignment.centerRight,
                                  padding: EdgeInsets.only(
                                    top: media.width * 0.01,
                                    left: media.width * 0.09,
                                  ),
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
                                )
                              ],
                            ),
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
