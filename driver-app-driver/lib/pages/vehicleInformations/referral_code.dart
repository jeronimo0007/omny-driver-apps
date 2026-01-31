// import 'package:flutter/material.dart';
// import '../../functions/functions.dart';
// import '../../styles/styles.dart';
// import '../../translation/translation.dart';
// import '../../widgets/widgets.dart';
// import '../loadingPage/loading.dart';
// import '../login/landingpage.dart';
// import '../noInternet/nointernet.dart';
// import 'upload_docs.dart';

// class Referral extends StatefulWidget {
//   const Referral({Key? key}) : super(key: key);

//   @override
//   State<Referral> createState() => _ReferralState();
// }

// dynamic referralCode;

// class _ReferralState extends State<Referral> {
//   bool _loading = false;
//   String _error = '';
//   TextEditingController controller = TextEditingController();

//   navigate() {
//     Navigator.pushReplacement(
//         context, MaterialPageRoute(builder: (context) => Docs()));
//   }

//   navigateLogout() {
//     Navigator.pushReplacement(
//         context, MaterialPageRoute(builder: (context) => const LandingPage()));
//   }

//   @override
//   void initState() {
//     referralCode = '';
//     super.initState();
//   }

//   @override
//   Widget build(BuildContext context) {
//     var media = MediaQuery.of(context).size;

//     return Material(
//       child: Directionality(
//         textDirection: (languageDirection == 'rtl')
//             ? TextDirection.rtl
//             : TextDirection.ltr,
//         child: Stack(
//           children: [
//             Container(
//               padding: EdgeInsets.only(
//                   left: media.width * 0.08, right: media.width * 0.08),
//               height: media.height * 1,
//               width: media.width * 1,
//               color: page,
//               child: Column(
//                 children: [
//                   Container(
//                     alignment: Alignment.bottomLeft,
//                     height: media.height * 0.12,
//                     width: media.width * 1,
//                     color: topBar,
//                   ),
//                   SizedBox(
//                     height: media.height * 0.04,
//                   ),
//                   SizedBox(
//                       width: media.width * 1,
//                       child: MyText(
//                         text: languages[choosenLanguage]['text_apply_referral'],
//                         size: media.width * twenty,
//                         fontweight: FontWeight.bold,
//                       )),
//                   const SizedBox(height: 10),
//                   InputField(
//                     text: languages[choosenLanguage]['text_enter_referral'],
//                     textController: controller,
//                     onTap: (val) {
//                       setState(() {
//                         referralCode = controller.text;
//                       });
//                     },
//                     color: (_error == '') ? null : Colors.red,
//                   ),
//                   (_error != '')
//                       ? Container(
//                           margin: EdgeInsets.only(top: media.height * 0.02),
//                           child: MyText(
//                             text: _error,
//                             size: media.width * sixteen,
//                             color: Colors.red,
//                           ),
//                         )
//                       : Container(),
//                   const SizedBox(
//                     height: 40,
//                   ),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       //skip button
//                       Button(
//                           onTap: () {
//                             FocusManager.instance.primaryFocus?.unfocus();
//                             _error = '';

//                             Navigator.pushReplacement(
//                                 context,
//                                 MaterialPageRoute(
//                                     builder: (context) => Docs()));
//                           },
//                           text: languages[choosenLanguage]['text_skip']),
//                       //apply button
//                       Button(
//                         onTap: () async {
//                           if (controller.text.isNotEmpty) {
//                             FocusManager.instance.primaryFocus?.unfocus();
//                             setState(() {
//                               _error = '';
//                               _loading = true;
//                             });
//                             var result = await updateReferral('er');
//                             if (result == 'true') {
//                               navigate();
//                             } else if (result == 'logout') {
//                               navigateLogout();
//                             } else {
//                               setState(() {
//                                 _error = languages[choosenLanguage]
//                                     ['text_referral_code'];
//                               });
//                             }
//                             setState(() {
//                               _loading = false;
//                             });
//                           }
//                         },
//                         text: languages[choosenLanguage]['text_apply'],
//                         color: (controller.text.isNotEmpty)
//                             ? buttonColor
//                             : Colors.grey,
//                       )
//                     ],
//                   )
//                 ],
//               ),
//             ),

//             //no internet
//             (internet == false)
//                 ? Positioned(
//                     top: 0,
//                     child: NoInternet(
//                       onTap: () {
//                         setState(() {
//                           internetTrue();
//                         });
//                       },
//                     ))
//                 : Container(),

//             //loader
//             (_loading == true)
//                 ? const Positioned(top: 0, child: Loading())
//                 : Container()
//           ],
//         ),
//       ),
//     );
//   }
// }
