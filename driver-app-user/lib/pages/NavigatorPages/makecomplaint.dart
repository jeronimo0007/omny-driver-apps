import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../functions/functions.dart';
import '../../styles/styles.dart';
import '../../translations/translation.dart';
import '../../widgets/widgets.dart';
import '../loadingPage/loading.dart';
import '../noInternet/noInternet.dart';

// ignore: must_be_immutable
class MakeComplaint extends StatefulWidget {
  int fromPage;
  // ignore: use_key_in_widget_constructors
  MakeComplaint({required this.fromPage});

  @override
  State<MakeComplaint> createState() => _MakeComplaintState();
}

int complaintType = 0;

// Função para traduzir títulos de reclamação comuns
String translateComplaintTitle(String title) {
  // Normalizar o texto: remover espaços extras e converter para minúsculas
  String lowerTitle =
      title.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');

  // Mapeamento de traduções comuns (português)
  Map<String, String> ptTranslations = {
    'driver behavior': 'Comportamento do Motorista',
    'vehicle condition': 'Condição do Veículo',
    'route issue': 'Problema com a Rota',
    'payment issue': 'Problema com Pagamento',
    'service quality': 'Qualidade do Serviço',
    'safety concern': 'Preocupação com Segurança',
    'delay': 'Atraso',
    'cancellation': 'Cancelamento',
    'other': 'Outro',
    'rude driver': 'Motorista Grosseiro',
    'unsafe driving': 'Direção Perigosa',
    'rash driving': 'Direção Perigosa',
    'driver rash driving': 'Direção Perigosa do Motorista',
    'dirty vehicle': 'Veículo Sujo',
    'wrong route': 'Rota Incorreta',
    'payment problem': 'Problema de Pagamento',
    'poor service': 'Serviço Ruim',
    'bad driver': 'Motorista Ruim',
    'driver not following route': 'Motorista Não Seguiu a Rota',
    'vehicle cleanliness': 'Limpeza do Veículo',
    'driver attitude': 'Atitude do Motorista',
    'late arrival': 'Chegada Tardia',
    'app issue': 'Problema com o Aplicativo',
    'account issue': 'Problema com a Conta',
    'suggestion': 'Sugestão',
    'complaint': 'Reclamação',
  };

  // Se o idioma escolhido for português, traduzir
  if (choosenLanguage == 'pt' || choosenLanguage == 'pt_BR') {
    // Verificar correspondência exata primeiro
    if (ptTranslations.containsKey(lowerTitle)) {
      return ptTranslations[lowerTitle]!;
    }

    // Traduções específicas para padrões comuns (verificar primeiro os casos mais específicos)
    // Verificar "driver rash driving" primeiro (mais específico)
    if ((lowerTitle.contains('driver') &&
            lowerTitle.contains('rash') &&
            lowerTitle.contains('driv')) ||
        lowerTitle == 'driver rash driving') {
      return 'Direção Perigosa do Motorista';
    }
    if (lowerTitle.contains('driver') && lowerTitle.contains('rash')) {
      return 'Direção Perigosa do Motorista';
    }
    if (lowerTitle.contains('rash') &&
        (lowerTitle.contains('driv') || lowerTitle.contains('driving'))) {
      return 'Direção Perigosa';
    }

    // Verificar correspondência parcial (contém) - depois das verificações específicas
    for (var key in ptTranslations.keys) {
      if (lowerTitle.contains(key) || key.contains(lowerTitle)) {
        return ptTranslations[key]!;
      }
    }
    if (lowerTitle.contains('driver') && lowerTitle.contains('behavior')) {
      return 'Comportamento do Motorista';
    }
    if (lowerTitle.contains('vehicle') &&
        (lowerTitle.contains('condition') || lowerTitle.contains('clean'))) {
      return 'Condição do Veículo';
    }
    if (lowerTitle.contains('route') || lowerTitle.contains('direção')) {
      return 'Problema com a Rota';
    }
    if (lowerTitle.contains('payment') || lowerTitle.contains('pagamento')) {
      return 'Problema com Pagamento';
    }
    if (lowerTitle.contains('delay') || lowerTitle.contains('atraso')) {
      return 'Atraso';
    }
    if (lowerTitle.contains('safety') || lowerTitle.contains('segurança')) {
      return 'Preocupação com Segurança';
    }
    if (lowerTitle.contains('service') || lowerTitle.contains('serviço')) {
      return 'Qualidade do Serviço';
    }
    if (lowerTitle.contains('app') || lowerTitle.contains('aplicativo')) {
      return 'Problema com o Aplicativo';
    }
    if (lowerTitle.contains('account') || lowerTitle.contains('conta')) {
      return 'Problema com a Conta';
    }
    if (lowerTitle.contains('suggestion') || lowerTitle.contains('sugestão')) {
      return 'Sugestão';
    }
    if (lowerTitle.contains('other') || lowerTitle.contains('outro')) {
      return 'Outro';
    }
  }

  // Se não encontrar tradução, retornar o título original
  return title;
}

// Opções padrão de reclamação caso a API retorne poucas
List<Map<String, dynamic>> getDefaultComplaintOptions(String type) {
  List<Map<String, dynamic>> defaults = [];

  if (type == "request") {
    defaults = [
      {
        'id': 'default_1',
        'title': languages[choosenLanguage]['text_complaint_driver_behavior'] ??
            'Comportamento do Motorista'
      },
      {
        'id': 'default_2',
        'title': languages[choosenLanguage]['text_complaint_vehicle'] ??
            'Condição do Veículo'
      },
      {
        'id': 'default_3',
        'title': languages[choosenLanguage]['text_complaint_route'] ??
            'Problema com a Rota'
      },
      {
        'id': 'default_4',
        'title': languages[choosenLanguage]['text_complaint_delay'] ?? 'Atraso'
      },
      {
        'id': 'default_5',
        'title': languages[choosenLanguage]['text_complaint_safety'] ??
            'Preocupação com Segurança'
      },
      {
        'id': 'default_6',
        'title': languages[choosenLanguage]['text_complaint_other'] ?? 'Outro'
      },
    ];
  } else {
    defaults = [
      {
        'id': 'default_1',
        'title': languages[choosenLanguage]['text_complaint_service'] ??
            'Qualidade do Serviço'
      },
      {
        'id': 'default_2',
        'title': languages[choosenLanguage]['text_complaint_payment'] ??
            'Problema com Pagamento'
      },
      {
        'id': 'default_3',
        'title': languages[choosenLanguage]['text_complaint_app'] ??
            'Problema com o Aplicativo'
      },
      {
        'id': 'default_4',
        'title': languages[choosenLanguage]['text_complaint_account'] ??
            'Problema com a Conta'
      },
      {
        'id': 'default_5',
        'title': languages[choosenLanguage]['text_complaint_suggestion'] ??
            'Sugestão'
      },
      {
        'id': 'default_6',
        'title': languages[choosenLanguage]['text_complaint_other'] ?? 'Outro'
      },
    ];
  }

  return defaults;
}

class _MakeComplaintState extends State<MakeComplaint> {
  bool _isLoading = true;
  bool _showOptions = false;
  TextEditingController complaintText = TextEditingController();
  bool _success = false;
  String complaintDesc = '';
  String _error = '';

  @override
  void initState() {
    getData();
    super.initState();
  }

  getData() async {
    setState(() {
      complaintType = 0;
      complaintDesc = '';
      generalComplaintList = [];
    });
    String type = widget.fromPage == 1 ? "request" : "general";
    await getGeneralComplaint(type);

    // Se a API retornar poucas opções (menos de 3), adicionar opções padrão
    if (generalComplaintList.length < 3) {
      List<Map<String, dynamic>> defaults = getDefaultComplaintOptions(type);
      // Adicionar apenas se não existirem já na lista
      for (var defaultOption in defaults) {
        bool exists = generalComplaintList.any((item) =>
            translateComplaintTitle(item['title'].toString().toLowerCase()) ==
            defaultOption['title'].toString().toLowerCase());
        if (!exists) {
          generalComplaintList.add(defaultOption);
        }
      }
    }

    setState(() {
      _isLoading = false;
      if (generalComplaintList.isNotEmpty) {
        complaintType = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return PopScope(
      canPop: true,
      // onWillPop: () async {
      //   Navigator.pop(context, false);
      //   return true;
      // },
      child: Material(
        child: Directionality(
          textDirection: (languageDirection == 'rtl')
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: Stack(
            children: [
              Container(
                height: MediaQuery.of(context).padding.top + media.width * 0.15,
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
                height: media.height * 1,
                width: media.width * 1,
                color: page,
                padding: EdgeInsets.only(
                    left: media.width * 0.05, right: media.width * 0.05),
                child: Column(
                  children: [
                    SizedBox(
                        height: MediaQuery.of(context).padding.top +
                            media.width * 0.15 +
                            media.width * 0.05),
                    Stack(
                      children: [
                        Container(
                          padding: EdgeInsets.only(bottom: media.width * 0.05),
                          width: media.width * 1,
                          alignment: Alignment.center,
                          child: MyText(
                            text: languages[choosenLanguage]
                                ['text_make_complaints'],
                            size: media.width * twenty,
                            fontweight: FontWeight.w600,
                          ),
                        ),
                        Positioned(
                            child: InkWell(
                                onTap: () {
                                  Navigator.pop(context, false);
                                },
                                child: Icon(Icons.arrow_back_ios,
                                    color: textColor)))
                      ],
                    ),
                    SizedBox(
                      height: media.width * 0.05,
                    ),
                    (generalComplaintList.isNotEmpty)
                        ? Expanded(
                            child: Column(children: [
                            InkWell(
                              onTap: () {
                                setState(() {
                                  if (_showOptions == false) {
                                    _showOptions = true;
                                  } else {
                                    _showOptions = false;
                                  }
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.only(
                                    left: media.width * 0.05,
                                    right: media.width * 0.05),
                                height: media.width * 0.12,
                                width: media.width * 0.8,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: borderLines, width: 1.2)),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    MyText(
                                        text: translateComplaintTitle(
                                            generalComplaintList[complaintType]
                                                ['title']),
                                        size: media.width * twelve),
                                    RotatedBox(
                                      quarterTurns:
                                          (_showOptions == true) ? 2 : 0,
                                      child: Container(
                                        height: media.width * 0.08,
                                        width: media.width * 0.08,
                                        decoration: const BoxDecoration(
                                            image: DecorationImage(
                                          image: AssetImage(
                                              'assets/images/chevron-down.png'),
                                          fit: BoxFit.contain,
                                        )),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                            (_showOptions == true)
                                ? Column(
                                    children: [
                                      SizedBox(
                                        height: media.width * 0.05,
                                      ),
                                      Container(
                                        padding:
                                            EdgeInsets.all(media.width * 0.025),
                                        height: media.width * 0.3,
                                        width: media.width * 0.8,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              width: 1.2, color: borderLines),
                                          color: page,
                                        ),
                                        child: SingleChildScrollView(
                                          physics:
                                              const BouncingScrollPhysics(),
                                          child: Column(
                                            children: generalComplaintList
                                                .asMap()
                                                .map((i, value) {
                                                  return MapEntry(
                                                      i,
                                                      InkWell(
                                                        onTap: () {
                                                          setState(() {
                                                            complaintType = i;
                                                            _showOptions =
                                                                false;
                                                          });
                                                        },
                                                        child: Container(
                                                          width:
                                                              media.width * 0.7,
                                                          padding: EdgeInsets.only(
                                                              top: media.width *
                                                                  0.025,
                                                              bottom:
                                                                  media.width *
                                                                      0.025),
                                                          decoration: BoxDecoration(
                                                              border: Border(
                                                                  bottom: BorderSide(
                                                                      width:
                                                                          1.1,
                                                                      color: (i ==
                                                                              generalComplaintList.length -
                                                                                  1)
                                                                          ? Colors
                                                                              .transparent
                                                                          : borderLines))),
                                                          child: MyText(
                                                              text: translateComplaintTitle(
                                                                  generalComplaintList[
                                                                          i][
                                                                      'title']),
                                                              size:
                                                                  media.width *
                                                                      twelve),
                                                        ),
                                                      ));
                                                })
                                                .values
                                                .toList(),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Container(),
                            SizedBox(
                              height: media.width * 0.08,
                            ),
                            Container(
                              padding: EdgeInsets.all(media.width * 0.025),
                              width: media.width * 0.8,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: (_error == '')
                                          ? borderLines
                                          : Colors.red,
                                      width: 1.2)),
                              child: TextField(
                                controller: complaintText,
                                minLines: 5,
                                maxLines: 5,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintStyle: choosenLanguage == 'ar'
                                      ? GoogleFonts.cairo(
                                          color: textColor.withOpacity(0.4),
                                          fontSize: media.width * fourteen,
                                        )
                                      : GoogleFonts.poppins(
                                          color: textColor.withOpacity(0.4),
                                          fontSize: media.width * fourteen,
                                        ),
                                  hintText: languages[choosenLanguage]
                                          ['text_complaint_2'] +
                                      ' (' +
                                      languages[choosenLanguage]
                                          ['text_complaint_3'] +
                                      ')',
                                ),
                                onChanged: (val) {
                                  complaintDesc = val;
                                  if (val.length >= 10 && _error != '') {
                                    setState(() {
                                      _error = '';
                                    });
                                  }
                                },
                                style: choosenLanguage == 'ar'
                                    ? GoogleFonts.cairo(
                                        color: textColor,
                                      )
                                    : GoogleFonts.poppins(color: textColor),
                              ),
                            ),
                            if (_error != '')
                              Container(
                                width: media.width * 0.8,
                                padding: EdgeInsets.only(
                                    top: media.width * 0.025,
                                    bottom: media.width * 0.025),
                                child: MyText(
                                  text: _error,
                                  size: media.width * fourteen,
                                  color: Colors.red,
                                ),
                              ),
                          ]))
                        : Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  alignment: Alignment.center,
                                  height: media.width * 0.5,
                                  width: media.width * 0.5,
                                  decoration: const BoxDecoration(
                                      image: DecorationImage(
                                          image: AssetImage(
                                              'assets/images/nodatafound.png'),
                                          fit: BoxFit.contain)),
                                ),
                                SizedBox(
                                  height: media.width * 0.07,
                                ),
                                SizedBox(
                                  width: media.width * 0.8,
                                  child: MyText(
                                      text: languages[choosenLanguage]
                                          ['text_noDataFound'],
                                      textAlign: TextAlign.center,
                                      fontweight: FontWeight.w800,
                                      size: media.width * sixteen),
                                ),
                              ],
                            ),
                          ),
                    (generalComplaintList.isNotEmpty)
                        ? Container(
                            padding: EdgeInsets.all(media.width * 0.05),
                            child: Button(
                                onTap: () async {
                                  if (complaintText.text.length >= 10) {
                                    setState(() {
                                      _isLoading = true;
                                    });
                                    dynamic result;

                                    // Verificar se é uma opção padrão (sem ID válido da API)
                                    String? complaintTitleId;
                                    if (generalComplaintList[complaintType]
                                            ['id']
                                        .toString()
                                        .startsWith('default_')) {
                                      // Para opções padrão, usar null ou o título como descrição adicional
                                      complaintTitleId = null;
                                    } else {
                                      complaintTitleId =
                                          generalComplaintList[complaintType]
                                                  ['id']
                                              .toString();
                                    }

                                    result = await makeGeneralComplaint(
                                        complaintDesc, complaintTitleId);

                                    setState(() {
                                      if (result == 'success') {
                                        _success = true;
                                      }

                                      _isLoading = false;
                                    });
                                  } else {
                                    setState(() {
                                      _error = languages[choosenLanguage]
                                          ['text_complaint_text_error'];
                                    });
                                  }
                                },
                                text: languages[choosenLanguage]
                                    ['text_submit']),
                          )
                        : Container()
                  ],
                ),
              ),

              (_success == true)
                  ? Positioned(
                      child: Container(
                      height: media.height * 1,
                      width: media.width * 1,
                      color: Colors.transparent.withOpacity(0.6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(media.width * 0.05),
                            width: media.width * 0.9,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(width: 1.2, color: borderLines),
                              color: page,
                            ),
                            child: Column(
                              children: [
                                Container(
                                  alignment: Alignment.center,
                                  width: media.width * 0.7,
                                  child: MyText(
                                    text: languages[choosenLanguage]
                                        ['text_complaint_success'],
                                    size: media.width * sixteen,
                                    fontweight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(
                                  height: media.width * 0.025,
                                ),
                                Container(
                                  alignment: Alignment.center,
                                  width: media.width * 0.7,
                                  child: MyText(
                                    text: languages[choosenLanguage]
                                        ['text_complaint_success_2'],
                                    size: media.width * sixteen,
                                    fontweight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(
                                  height: media.width * 0.05,
                                ),
                                Button(
                                    onTap: () {
                                      Navigator.pop(context, true);
                                    },
                                    text: languages[choosenLanguage]
                                        ['text_thankyou'])
                              ],
                            ),
                          )
                        ],
                      ),
                    ))
                  : Container(),
              //loader
              (_isLoading == true)
                  ? const Positioned(top: 0, child: Loading())
                  : Container(),

              //no internet
              (internet == false)
                  ? Positioned(
                      top: 0,
                      child: NoInternet(
                        onTap: () {
                          internetTrue();
                        },
                      ))
                  : Container(),
            ],
          ),
        ),
      ),
    );
  }
}
