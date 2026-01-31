import 'package:flutter/material.dart';
import '../../functions/functions.dart';
import '../../styles/styles.dart';
import '../../translations/translation.dart';
import '../../widgets/widgets.dart';
import '../login/login.dart';

class Languages extends StatefulWidget {
  const Languages({Key? key}) : super(key: key);

  @override
  State<Languages> createState() => _LanguagesState();
}

class _LanguagesState extends State<Languages> {
  @override
  void initState() {
    choosenLanguage = 'pt-BR';
    languageDirection = 'ltr';
    super.initState();
  }

//navigate
  navigate() {
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => const Login()));
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Material(
        child: Directionality(
      textDirection:
          (languageDirection == 'rtl') ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        padding: EdgeInsets.fromLTRB(media.width * 0.05, media.width * 0.05,
            media.width * 0.05, media.width * 0.05),
        height: media.height * 1,
        width: media.width * 1,
        color: page,
        child: Column(
          children: [
            Container(
              height: MediaQuery.of(context).padding.top + media.width * 0.15,
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
            SizedBox(
              height: media.width * 0.05,
            ),
            SizedBox(
              width: media.width * 0.9,
              height: media.height * 0.16,
              child: Image.asset(
                'assets/images/selectLanguage.png',
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(
              height: media.width * 0.1,
            ),
            //languages list
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: languages.entries
                      .where((entry) =>
                          ['en', 'es', 'fr', 'pt', 'pt-BR'].contains(entry.key))
                      .map((entry) {
                    var i = entry.key;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          choosenLanguage = i;
                          if (choosenLanguage == 'ar' ||
                              choosenLanguage == 'ur' ||
                              choosenLanguage == 'iw') {
                            languageDirection = 'rtl';
                          } else {
                            languageDirection = 'ltr';
                          }
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.all(media.width * 0.025),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: (choosenLanguage == i)
                              ? LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    buttonColor,
                                    buttonColor.withOpacity(0.3),
                                    Colors.transparent,
                                  ],
                                )
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            MyText(
                              text: languagesCode
                                  .firstWhere((e) => e['code'] == i,
                                      orElse: () =>
                                          {'name': i, 'code': i})['name']
                                  .toString(),
                              size: media.width * sixteen,
                              color: (choosenLanguage == i)
                                  ? buttonText
                                  : textColor,
                            ),
                            Container(
                              height: media.width * 0.05,
                              width: media.width * 0.05,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: (choosenLanguage == i)
                                          ? buttonColor
                                          : const Color(0xff222222),
                                      width: 1.2)),
                              alignment: Alignment.center,
                              child: (choosenLanguage == i)
                                  ? Container(
                                      height: media.width * 0.03,
                                      width: media.width * 0.03,
                                      decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: buttonColor),
                                    )
                                  : Container(),
                            )
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            //button
            (choosenLanguage != '')
                ? Button(
                    onTap: () async {
                      await getlangid();
                      pref.setString('languageDirection', languageDirection);
                      pref.setString('choosenLanguage', choosenLanguage);
                      navigate();
                    },
                    text: languages[choosenLanguage]['text_confirm'])
                : Container(),
          ],
        ),
      ),
    ));
  }
}
