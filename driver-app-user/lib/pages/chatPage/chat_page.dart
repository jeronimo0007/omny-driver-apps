import 'package:flutter/material.dart';
import '../../functions/functions.dart';
import '../../styles/styles.dart';
import '../../translations/translation.dart';
import '../../widgets/widgets.dart';
import '../loadingPage/loading.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  TextEditingController chatText = TextEditingController();
  ScrollController controller = ScrollController();
  bool _sendingMessage = false;
  @override
  void initState() {
    super.initState();
    //get messages
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('💬 ChatPage: Inicializando...');
    debugPrint('───────────────────────────────────────────────────────────');
    try {
      if (userRequestData.isEmpty) {
        debugPrint('⚠️ ChatPage: userRequestData está vazio!');
      } else {
        debugPrint('✅ ChatPage: userRequestData encontrado');
        debugPrint('   Request ID: ${userRequestData['id']}');
        debugPrint(
            '   Driver: ${userRequestData['driverDetail']?['data']?['name'] ?? 'N/A'}');
      }
      getCurrentMessages();
    } catch (e, stackTrace) {
      debugPrint('❌ ChatPage: Erro ao inicializar: $e');
      debugPrint('Stack trace: $stackTrace');
    }
    debugPrint('═══════════════════════════════════════════════════════════');
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return PopScope(
      canPop: true,
      // onWillPop: () async {
      //   Navigator.pop(context, true);
      //   return true;
      // },
      child: Material(
        child: Scaffold(
          body: ValueListenableBuilder(
              valueListenable: valueNotifierBook.value,
              builder: (context, value, child) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  controller.animateTo(controller.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.ease);
                });
                //call for message seen
                messageSeen();

                return Directionality(
                  textDirection: (languageDirection == 'rtl')
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                  child: Stack(
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
                      Container(
                        padding: EdgeInsets.fromLTRB(
                            media.width * 0.05,
                            MediaQuery.of(context).padding.top +
                                media.width * 0.15 +
                                media.width * 0.05,
                            media.width * 0.05,
                            media.width * 0.05),
                        height: media.height * 1,
                        width: media.width * 1,
                        color: page,
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                Container(
                                    width: media.width * 0.9,
                                    alignment: Alignment.center,
                                    child: Column(
                                      children: [
                                        MyText(
                                          text: userRequestData['driverDetail']
                                                      ?['data']?['name']
                                                  ?.toString() ??
                                              'Motorista',
                                          size: media.width * sixteen,
                                          fontweight: FontWeight.bold,
                                        ),
                                        SizedBox(
                                          height: media.width * 0.025,
                                        ),
                                        SizedBox(
                                          width: media.width * 0.4,
                                          child: MyText(
                                            text:
                                                '${userRequestData['driverDetail']?['data']?['car_color'] ?? ''} ${userRequestData['driverDetail']?['data']?['car_make_name'] ?? ''} ${userRequestData['driverDetail']?['data']?['car_model_name'] ?? ''}'
                                                    .trim(),
                                            size: media.width * fourteen,
                                            textAlign: TextAlign.end,
                                            maxLines: 1,
                                            color: const Color(0xff8A8A8A),
                                          ),
                                        ),
                                      ],
                                    )),
                                Positioned(
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.pop(context, true);
                                    },
                                    child: Container(
                                      height: media.width * 0.1,
                                      width: media.width * 0.1,
                                      alignment: Alignment.center,
                                      child: Icon(Icons.arrow_back_ios,
                                          color: textColor),
                                    ),
                                  ),
                                )
                              ],
                            ),
                            SizedBox(
                              height: media.width * 0.05,
                            ),
                            Expanded(
                                child: SingleChildScrollView(
                              controller: controller,
                              child: Column(
                                children: chatList
                                    .asMap()
                                    .map((i, value) {
                                      return MapEntry(
                                          i,
                                          Container(
                                            padding: EdgeInsets.only(
                                                top: media.width * 0.025),
                                            width: media.width * 0.9,
                                            alignment:
                                                (chatList[i]['from_type'] == 1)
                                                    ? Alignment.centerRight
                                                    : Alignment.centerLeft,
                                            child: Column(
                                              crossAxisAlignment: (chatList[i]
                                                          ['from_type'] ==
                                                      1)
                                                  ? CrossAxisAlignment.end
                                                  : CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  width: media.width * 0.5,
                                                  padding: EdgeInsets.all(
                                                      media.width * 0.04),
                                                  decoration: BoxDecoration(
                                                      borderRadius: (chatList[i]
                                                                  [
                                                                  'from_type'] ==
                                                              1)
                                                          ? BorderRadius
                                                              .circular(8)
                                                          : BorderRadius
                                                              .circular(8),
                                                      color: (chatList[i][
                                                                  'from_type'] ==
                                                              1)
                                                          ? buttonColor
                                                          : const Color(
                                                              0xffE7EDEF)),
                                                  child: MyText(
                                                    text: chatList[i]
                                                        ['message'],
                                                    size:
                                                        media.width * fourteen,
                                                    color: (isDarkTheme == true)
                                                        ? Colors.black
                                                        : textColor,
                                                  ),
                                                ),
                                                SizedBox(
                                                  height: media.width * 0.015,
                                                ),
                                                MyText(
                                                  text: chatList[i]
                                                      ['converted_created_at'],
                                                  size: media.width * twelve,
                                                )
                                              ],
                                            ),
                                          ));
                                    })
                                    .values
                                    .toList(),
                              ),
                            )),

                            //text field
                            Container(
                              margin: EdgeInsets.only(top: media.width * 0.025),
                              padding: EdgeInsets.fromLTRB(
                                  media.width * 0.025,
                                  media.width * 0.01,
                                  media.width * 0.025,
                                  media.width * 0.01),
                              width: media.width * 0.9,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: borderLines, width: 1.2),
                                  color: page),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  SizedBox(
                                    width: media.width * 0.7,
                                    child: TextField(
                                      controller: chatText,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        hintText: languages[choosenLanguage]
                                            ['text_entermessage'],
                                        hintStyle: getGoogleFontStyle(
                                          color: textColor.withOpacity(0.4),
                                          fontSize: media.width * twelve,
                                        ),
                                      ),
                                      style: getGoogleFontStyle(
                                        fontSize: media.width * fourteen,
                                        color: textColor,
                                      ),
                                      minLines: 1,
                                      maxLines: 4,
                                      onChanged: (val) {},
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () async {
                                      debugPrint(
                                          '═══════════════════════════════════════════════════════════');
                                      debugPrint(
                                          '💬 ChatPage: Enviando mensagem...');
                                      debugPrint(
                                          '───────────────────────────────────────────────────────────');
                                      debugPrint(
                                          '   Mensagem: ${chatText.text}');
                                      debugPrint(
                                          '   Request ID: ${userRequestData['id']}');

                                      FocusManager.instance.primaryFocus
                                          ?.unfocus();

                                      if (chatText.text.trim().isEmpty) {
                                        debugPrint(
                                            '⚠️ ChatPage: Mensagem vazia, ignorando envio');
                                        return;
                                      }

                                      setState(() {
                                        _sendingMessage = true;
                                      });

                                      try {
                                        var result =
                                            await sendMessage(chatText.text);
                                        debugPrint(
                                            '📤 ChatPage: Resultado do envio: $result');

                                        if (result == 'success') {
                                          debugPrint(
                                              '✅ ChatPage: Mensagem enviada com sucesso');
                                          chatText.clear();
                                        } else if (result == 'logout') {
                                          debugPrint(
                                              '⚠️ ChatPage: Sessão expirada, redirecionando para login');
                                        } else {
                                          debugPrint(
                                              '❌ ChatPage: Falha ao enviar mensagem: $result');
                                        }
                                      } catch (e, stackTrace) {
                                        debugPrint(
                                            '❌ ChatPage: Erro ao enviar mensagem: $e');
                                        debugPrint('Stack trace: $stackTrace');
                                      } finally {
                                        setState(() {
                                          _sendingMessage = false;
                                        });
                                      }
                                      debugPrint(
                                          '═══════════════════════════════════════════════════════════');
                                    },
                                    child: Image.asset(
                                      'assets/images/send.png',
                                      fit: BoxFit.contain,
                                      width: media.width * 0.075,
                                      color: textColor,
                                    ),
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                      //loader
                      (_sendingMessage == true)
                          ? const Positioned(top: 0, child: Loading())
                          : Container()
                    ],
                  ),
                );
              }),
        ),
      ),
    );
  }
}
