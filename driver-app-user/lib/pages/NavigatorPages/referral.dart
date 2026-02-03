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

  Widget _buildReferralsTable(Size media) {
    final referrals = myReferralCode['referrals'];
    final list = referrals is List ? referrals : <dynamic>[];
    return Container(
      width: media.width * 0.9,
      decoration: BoxDecoration(
        border: Border.all(color: (isDarkTheme == true) ? theme.withOpacity(0.3) : borderLines, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Table(
        columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1)},
        border: TableBorder.symmetric(
          inside: BorderSide(color: (isDarkTheme == true) ? theme.withOpacity(0.2) : borderLines),
        ),
        children: [
          TableRow(
            decoration: BoxDecoration(color: (isDarkTheme == true) ? theme.withOpacity(0.15) : topBar),
            children: [
              Padding(
                padding: EdgeInsets.all(media.width * 0.03),
                child: MyText(
                  text: languages[choosenLanguage]['text_referral_table_name'] ?? 'Nome',
                  size: media.width * twelve,
                  fontweight: FontWeight.w700,
                ),
              ),
              Padding(
                padding: EdgeInsets.all(media.width * 0.03),
                child: MyText(
                  text: languages[choosenLanguage]['text_referral_table_active'] ?? 'Ativo',
                  size: media.width * twelve,
                  fontweight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (list.isEmpty)
            TableRow(
              children: [
                Padding(
                  padding: EdgeInsets.all(media.width * 0.04),
                  child: MyText(
                    text: languages[choosenLanguage]['text_referral_no_list'] ?? 'Nenhuma indicação ainda',
                    size: media.width * twelve,
                    color: hintColor,
                  ),
                ),
                const Padding(padding: EdgeInsets.all(8), child: SizedBox.shrink()),
              ],
            )
          else
            ...list.asMap().entries.map((e) {
              final item = e.value;
              final name = item is Map ? (item['name']?.toString() ?? '—') : '—';
              final active = item is Map ? (item['active'] == true) : false;
              return TableRow(
                children: [
                  Padding(
                    padding: EdgeInsets.all(media.width * 0.03),
                    child: MyText(text: name, size: media.width * twelve),
                  ),
                  Padding(
                    padding: EdgeInsets.all(media.width * 0.03),
                    child: Icon(
                      active ? Icons.check_circle : Icons.cancel,
                      size: media.width * 0.05,
                      color: active ? Colors.green : (isDarkTheme ? Colors.red.shade300 : Colors.red),
                    ),
                  ),
                ],
              );
            }),
        ],
      ),
    );
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
                              SizedBox(
                                  height: MediaQuery.of(context).padding.top + media.width * 0.12),
                              Stack(
                                children: [
                                  Container(
                                    padding: EdgeInsets.only(bottom: media.width * 0.05),
                                    width: media.width * 1,
                                    alignment: Alignment.center,
                                    child: const SizedBox.shrink(),
                                  ),
                                  Positioned(
                                    child: InkWell(
                                      onTap: () => Navigator.pop(context),
                                      child: Icon(Icons.arrow_back_ios, color: (isDarkTheme == true) ? theme : textColor),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: media.width * 0.03),
                              // Título
                              Align(
                                alignment: Alignment.centerLeft,
                                child: MyText(
                                  text: (languages[choosenLanguage]['text_enable_referal'] ?? 'Indicações').toString().toUpperCase(),
                                  size: media.width * sixteen,
                                  fontweight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: media.width * 0.05),
                              // Conteúdo (referral_comission_string)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: MyText(
                                  text: myReferralCode['referral_comission_string']?.toString() ?? '',
                                  size: media.width * fourteen,
                                  textAlign: TextAlign.left,
                                  fontweight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: media.width * 0.06),
                              // Linha: código + ícone compartilhar (mesma ação de convidar)
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: media.width * 0.04, vertical: media.width * 0.035),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: (isDarkTheme == true) ? theme.withOpacity(0.3) : borderLines, width: 1.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: MyText(
                                        text: myReferralCode['refferal_code']?.toString() ?? '—',
                                        size: media.width * sixteen,
                                        fontweight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: media.width * 0.03),
                                  InkWell(
                                    onTap: () async {
                                      await Share.share(
                                        (languages[choosenLanguage]['text_invitation_1'] ?? '').toString().replaceAll('55', _package?.appName ?? '') +
                                            ' ' + (myReferralCode['refferal_code']?.toString() ?? '') +
                                            ' ' + (languages[choosenLanguage]['text_invitation_2'] ?? '') +
                                            ' \n \n ' + (androidUrl ?? '') + '\n \n ' + (iosUrl ?? ''),
                                      );
                                    },
                                    child: Container(
                                      padding: EdgeInsets.all(media.width * 0.04),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: (isDarkTheme == true) ? theme : borderLines, width: 1.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(Icons.share, color: (isDarkTheme == true) ? theme : textColor, size: media.width * 0.07),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: media.width * 0.06),
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: _buildReferralsTable(media),
                                ),
                              ),
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
