import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../functions/functions.dart';
import '../../styles/styles.dart';
import '../../translation/translation.dart';
import '../../widgets/widgets.dart';
import 'carinformation.dart';

class AggreementPage extends StatefulWidget {
  const AggreementPage({Key? key}) : super(key: key);

  @override
  State<AggreementPage> createState() => _AggreementPageState();
}

class _AggreementPageState extends State<AggreementPage> {
  //navigate
  navigate() {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => CarInformation(frompage: 1)));
  }

  bool ischeck = false;

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Material(
      color: page,
      child: Directionality(
        textDirection: (languageDirection == 'rtl')
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com safe area, botão voltar e logo
            Container(
              color: page,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + media.width * 0.03,
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
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                  left: media.width * 0.06,
                  right: media.width * 0.06,
                  bottom: media.height * 0.06,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: media.height * 0.02),
                    Container(
                      padding: const EdgeInsets.only(top: 15, bottom: 15),
                      child: MyText(
                        text: languages[choosenLanguage]['text_accept_head'],
                        size: media.width * twenty,
                        fontweight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      height: media.width * 0.416,
                      width: media.width * 0.416,
                      decoration: const BoxDecoration(
                          image: DecorationImage(
                              image: AssetImage('assets/images/privacyimage.png'),
                              fit: BoxFit.contain)),
                    ),
                    const SizedBox(height: 20),
                    RichText(
                        text: TextSpan(
                          // text: 'Hello ',
                          style: choosenLanguage == 'ar'
                              ? GoogleFonts.cairo(
                                  color: textColor,
                                  fontSize: media.width * fourteen,
                                )
                              : GoogleFonts.poppins(
                                  color: textColor,
                                  fontSize: media.width * fourteen,
                                ),
                          children: [
                            TextSpan(
                                text: languages[choosenLanguage]
                                    ['text_agree_text1']),
                            TextSpan(
                                text: languages[choosenLanguage]
                                    ['text_terms_of_use'],
                                style: choosenLanguage == 'ar'
                                    ? GoogleFonts.cairo(
                                        color: buttonColor,
                                        fontSize: media.width * fourteen,
                                      )
                                    : GoogleFonts.poppins(
                                        color: buttonColor,
                                        fontSize: media.width * fourteen,
                                      ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    openBrowser(
                                        'https://driver.omny.app.br/privacy');
                                  }),
                            TextSpan(
                                text: languages[choosenLanguage]
                                    ['text_agree_text2']),
                            TextSpan(
                                text: languages[choosenLanguage]
                                    ['text_privacy'],
                                style: choosenLanguage == 'ar'
                                    ? GoogleFonts.cairo(
                                        color: buttonColor,
                                        fontSize: media.width * fourteen,
                                      )
                                    : GoogleFonts.poppins(
                                        color: buttonColor,
                                        fontSize: media.width * fourteen,
                                      ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    openBrowser(
                                        'https://driver.omny.app.br/privacy-policy');
                                  }),
                          ],
                        ),
                      ),
                    Container(
                    padding: const EdgeInsets.only(top: 15, bottom: 15),
                    child: Row(
                      children: [
                        MyText(
                            text: languages[choosenLanguage]['text_iagree'],
                            size: media.width * sixteen),
                        SizedBox(
                          width: media.width * 0.05,
                        ),
                        InkWell(
                          onTap: () {
                            if (ischeck == false) {
                              setState(() {
                                ischeck = true;
                              });
                            } else {
                              setState(() {
                                ischeck = false;
                              });
                            }
                          },
                          child: Container(
                            height: media.width * 0.05,
                            width: media.width * 0.05,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                                border:
                                    Border.all(color: buttonColor, width: 2)),
                            child: ischeck == false
                                ? null
                                : Icon(
                                    Icons.done,
                                    size: media.width * 0.04,
                                    color: buttonColor,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
            ischeck == true
                ? Padding(
                    padding: EdgeInsets.only(
                      top: 15,
                      bottom: MediaQuery.of(context).padding.bottom + 15,
                      left: media.width * 0.06,
                      right: media.width * 0.06,
                    ),
                    child: Button(
                        onTap: () async {
                          navigate();
                        },
                        text: languages[choosenLanguage]['text_next']),
                  )
                : Padding(
                    padding: EdgeInsets.only(
                      top: 15,
                      bottom: MediaQuery.of(context).padding.bottom + 15,
                      left: media.width * 0.06,
                      right: media.width * 0.06,
                    ),
                    child: Button(
                        onTap: () async {},
                        text: languages[choosenLanguage]['text_next'],
                        color: Colors.grey,
                        textcolor: textColor.withOpacity(0.5)),
                  )
          ],
        ),
      ),
    );
  }
}
