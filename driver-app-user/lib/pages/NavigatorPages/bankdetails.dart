import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dropdown_search/dropdown_search.dart';

import '../../functions/functions.dart';
import '../../styles/styles.dart';
import '../../translations/translation.dart';
import '../../widgets/widgets.dart';
import '../loadingPage/loading.dart';
import '../login/login.dart';
import '../noInternet/nointernet.dart';

const String _bankOutrosKey = '__OUTROS__';

const List<Map<String, String>> _pixTypeOptions = [
  {'value': 'email', 'key': 'text_pix_email'},
  {'value': 'aleatoria', 'key': 'text_pix_aleatoria'},
  {'value': 'cpf', 'key': 'text_pix_cpf'},
  {'value': 'cnpj', 'key': 'text_pix_cnpj'},
  {'value': 'telefone', 'key': 'text_pix_telefone'},
];

const List<String> _bankNames = [
  'Banco do Brasil',
  'Caixa Econômica Federal',
  'Itaú Unibanco',
  'Bradesco',
  'Santander',
  'Nubank',
  'Banco Inter',
  'C6 Bank',
  'BTG Pactual',
  'Safra',
  'Citibank',
  'HSBC',
  'Banrisul',
  'Sicoob',
  'Sicredi',
  'Caja',
  'Banco Pan',
  'Neon',
  'PagBank',
  'Mercado Pago',
];

class BankDetails extends StatefulWidget {
  const BankDetails({Key? key}) : super(key: key);

  @override
  State<BankDetails> createState() => _BankDetailsState();
}

class _BankDetailsState extends State<BankDetails> {
  TextEditingController holderName = TextEditingController();
  TextEditingController bankOtherController = TextEditingController();
  TextEditingController accountNumber = TextEditingController();
  TextEditingController bankCode = TextEditingController();

  bool _isLoading = true;
  String _showError = '';
  bool _edit = false;
  String? _selectedPixType;
  String? _selectedBank;

  @override
  void initState() {
    getBankDetails();
    super.initState();
  }

  navigateLogout() {
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
        (route) => false);
  }

  getBankDetails() async {
    var val = await getBankInfo();
    if (val == 'logout') {
      navigateLogout();
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (bankData.isEmpty && _selectedPixType == null) _selectedPixType = 'email';
        if (bankData.isNotEmpty && bankData['type'] != null) _selectedPixType = bankData['type'].toString();
        if (bankData.isNotEmpty && bankData['bank_name'] != null) {
          final bn = bankData['bank_name'].toString();
          if (_bankNames.contains(bn)) {
            _selectedBank = bn;
          } else { _selectedBank = _bankOutrosKey; bankOtherController.text = bn; }
        }
      });
    }
  }

  _errorClear() async {
    Future.delayed(const Duration(seconds: 4), () {
      setState(() {
        _showError = '';
      });
    });
  }

  pop() {
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Material(
      child: Directionality(
        textDirection: (languageDirection == 'rtl')
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: Scaffold(
          body: Stack(
            children: [
              Container(
                height: media.height * 1,
                width: media.width * 1,
                color: page,
                padding: EdgeInsets.all(media.width * 0.05),
                child: Column(
                  children: [
                    SizedBox(height: MediaQuery.of(context).padding.top),
                    Stack(
                      children: [
                        Container(
                          padding: EdgeInsets.only(bottom: media.width * 0.05),
                          width: media.width * 1,
                          alignment: Alignment.center,
                          child: Text(
                            languages[choosenLanguage]['text_bankDetails'],
                            style: GoogleFonts.poppins(
                                fontSize: media.width * twenty,
                                fontWeight: FontWeight.w600,
                                color: textColor),
                          ),
                        ),
                        Positioned(
                            child: InkWell(
                                onTap: () {
                                  Navigator.pop(context);
                                },
                                child: Icon(Icons.arrow_back_ios,
                                    color: textColor)))
                      ],
                    ),
                    SizedBox(
                      height: media.width * 0.05,
                    ),
                    Expanded(
                        child: SingleChildScrollView(
                      child: (bankData.isEmpty || _edit == true)
                          ? Column(
                              children: [
                                DropdownSearch<String>(
                                  selectedItem: _pixTypeOptions.any((e) => e['value'] == _selectedPixType) ? _selectedPixType : null,
                                  items: _pixTypeOptions.map((e) => e['value']!).toList(),
                                  itemAsString: (String v) => languages[choosenLanguage][_pixTypeOptions.firstWhere((e) => e['value'] == v, orElse: () => {'value': v, 'key': 'text_pix_email'})['key']] ?? v,
                                  onChanged: (String? value) => setState(() => _selectedPixType = value),
                                  popupProps: PopupProps.menu(
                                    showSearchBox: true,
                                    searchFieldProps: TextFieldProps(
                                      decoration: InputDecoration(
                                        hintText: languages[choosenLanguage]['text_search'] ?? 'Buscar',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ),
                                  dropdownDecoratorProps: DropDownDecoratorProps(
                                    dropdownSearchDecoration: InputDecoration(
                                      labelText: languages[choosenLanguage]['text_pix_type'],
                                      labelStyle: TextStyle(color: (isDarkTheme == true) ? textColor : null),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: (isDarkTheme == true) ? textColor : hintColor),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: media.width * 0.05),
                                TextField(
                                  controller: holderName,
                                  decoration: InputDecoration(
                                      labelText: languages[choosenLanguage]['text_accoutHolderName'],
                                      labelStyle: TextStyle(color: (isDarkTheme == true) ? textColor : null),
                                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: (isDarkTheme == true) ? textColor : Colors.blue)),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), gapPadding: 1),
                                      enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(color: (isDarkTheme == true) ? textColor : hintColor),
                                          borderRadius: BorderRadius.circular(12),
                                          gapPadding: 1),
                                      isDense: true),
                                  style: GoogleFonts.poppins(color: textColor),
                                ),
                                SizedBox(height: media.width * 0.05),
                                TextField(
                                  controller: accountNumber,
                                  decoration: InputDecoration(
                                      labelText: languages[choosenLanguage]['text_accountNumber'],
                                      labelStyle: TextStyle(color: (isDarkTheme == true) ? textColor : null),
                                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: (isDarkTheme == true) ? textColor : Colors.blue)),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), gapPadding: 1),
                                      enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(color: (isDarkTheme == true) ? textColor : hintColor),
                                          borderRadius: BorderRadius.circular(12),
                                          gapPadding: 1),
                                      isDense: true),
                                  style: GoogleFonts.poppins(color: textColor),
                                ),
                                SizedBox(height: media.width * 0.05),
                                DropdownSearch<String>(
                                  selectedItem: _selectedBank == _bankOutrosKey ? null : _selectedBank,
                                  items: _bankNames + [_bankOutrosKey],
                                  itemAsString: (String s) => s == _bankOutrosKey ? (languages[choosenLanguage]['text_others'] ?? 'Outros') : s,
                                  onChanged: (String? v) => setState(() => _selectedBank = v),
                                  popupProps: PopupProps.menu(
                                    showSearchBox: true,
                                    searchFieldProps: TextFieldProps(
                                      decoration: InputDecoration(
                                        hintText: languages[choosenLanguage]['text_search'] ?? 'Buscar',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ),
                                  dropdownDecoratorProps: DropDownDecoratorProps(
                                    dropdownSearchDecoration: InputDecoration(
                                      labelText: languages[choosenLanguage]['text_bankName'],
                                      labelStyle: TextStyle(color: (isDarkTheme == true) ? textColor : null),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: (isDarkTheme == true) ? textColor : hintColor),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                if (_selectedBank == _bankOutrosKey) ...[
                                  SizedBox(height: media.width * 0.05),
                                  TextField(
                                    controller: bankOtherController,
                                    decoration: InputDecoration(
                                        labelText: '${languages[choosenLanguage]['text_bankName']} (${languages[choosenLanguage]['text_others'] ?? 'Outros'})',
                                        labelStyle: TextStyle(color: (isDarkTheme == true) ? textColor : null),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), gapPadding: 1),
                                        enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(color: (isDarkTheme == true) ? textColor : hintColor),
                                            borderRadius: BorderRadius.circular(12),
                                            gapPadding: 1),
                                        isDense: true),
                                    style: GoogleFonts.poppins(color: textColor),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ],
                                SizedBox(height: media.width * 0.05),
                                TextField(
                                  controller: bankCode,
                                  decoration: InputDecoration(
                                      labelText: languages[choosenLanguage]['text_bankCode'],
                                      labelStyle: TextStyle(color: (isDarkTheme == true) ? textColor : null),
                                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: (isDarkTheme == true) ? textColor : Colors.blue)),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), gapPadding: 1),
                                      enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(color: (isDarkTheme == true) ? textColor : hintColor),
                                          borderRadius: BorderRadius.circular(12),
                                          gapPadding: 1),
                                      isDense: true),
                                  style: GoogleFonts.poppins(color: textColor),
                                ),
                                SizedBox(height: media.width * 0.1),
                              ],
                            )
                          : Column(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(media.width * 0.025),
                                  width: media.width * 0.9,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: page,
                                      boxShadow: [
                                        BoxShadow(
                                            blurRadius: 2,
                                            color:
                                                Colors.black.withOpacity(0.2),
                                            spreadRadius: 2),
                                      ]),
                                  child: Column(
                                    children: [
                                      Text(
                                        languages[choosenLanguage]
                                            ['text_accoutHolderName'],
                                        style: GoogleFonts.poppins(
                                            fontSize: media.width * sixteen,
                                            color: hintColor),
                                      ),
                                      SizedBox(
                                        height: media.width * 0.025,
                                      ),
                                      Text(
                                        bankData['account_name'],
                                        style: GoogleFonts.poppins(
                                            fontSize: media.width * sixteen,
                                            color: textColor),
                                      ),
                                      SizedBox(
                                        height: media.width * 0.05,
                                      ),
                                      Text(
                                        languages[choosenLanguage]
                                            ['text_bankName'],
                                        style: GoogleFonts.poppins(
                                            fontSize: media.width * sixteen,
                                            color: hintColor),
                                      ),
                                      SizedBox(
                                        height: media.width * 0.025,
                                      ),
                                      Text(
                                        bankData['bank_name'],
                                        style: GoogleFonts.poppins(
                                            fontSize: media.width * sixteen,
                                            color: textColor),
                                      ),
                                      SizedBox(
                                        height: media.width * 0.05,
                                      ),
                                      Text(
                                        languages[choosenLanguage]
                                            ['text_accountNumber'],
                                        style: GoogleFonts.poppins(
                                            fontSize: media.width * sixteen,
                                            color: hintColor),
                                      ),
                                      SizedBox(
                                        height: media.width * 0.025,
                                      ),
                                      Text(
                                        bankData['account_no'],
                                        style: GoogleFonts.poppins(
                                            fontSize: media.width * sixteen,
                                            color: textColor),
                                      ),
                                      SizedBox(
                                        height: media.width * 0.05,
                                      ),
                                      Text(
                                        languages[choosenLanguage]
                                            ['text_bankCode'],
                                        style: GoogleFonts.poppins(
                                            fontSize: media.width * sixteen,
                                            color: hintColor),
                                      ),
                                      SizedBox(
                                        height: media.width * 0.025,
                                      ),
                                      Text(
                                        bankData['bank_code'],
                                        style: GoogleFonts.poppins(
                                            fontSize: media.width * sixteen,
                                            color: textColor),
                                      ),
                                      if (bankData['type'] != null && bankData['type'].toString().isNotEmpty) ...[
                                        SizedBox(height: media.width * 0.05),
                                        Text(
                                          languages[choosenLanguage]['text_pix_type'],
                                          style: GoogleFonts.poppins(
                                              fontSize: media.width * sixteen,
                                              color: hintColor),
                                        ),
                                        SizedBox(height: media.width * 0.025),
                                        Text(
                                          languages[choosenLanguage][_pixTypeOptions
                                                  .firstWhere(
                                                    (e) => e['value'] == bankData['type'].toString(),
                                                    orElse: () => {'value': '', 'key': 'text_pix_email'},
                                                  )['key']] ??
                                              bankData['type'].toString(),
                                          style: GoogleFonts.poppins(
                                              fontSize: media.width * sixteen,
                                              color: textColor),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  height: media.width * 0.05,
                                ),
                              ],
                            ),
                    )),
                    (_edit == true || bankData.isEmpty)
                        ? Row(
                            mainAxisAlignment: (bankData.isEmpty)
                                ? MainAxisAlignment.center
                                : MainAxisAlignment.spaceBetween,
                            children: [
                              (bankData.isNotEmpty)
                                  ? Button(
                                      onTap: () {
                                        setState(() {
                                          _edit = false;
                                        });
                                      },
                                      width: media.width * 0.4,
                                      text: languages[choosenLanguage]
                                          ['text_cancel'])
                                  : Container(),
                              Button(
                                  onTap: () async {
                                    FocusManager.instance.primaryFocus
                                        ?.unfocus();
                                    final bankNameValue = _selectedBank == _bankOutrosKey
                                        ? bankOtherController.text
                                        : (_selectedBank ?? '');
                                    if (holderName.text.isNotEmpty &&
                                        accountNumber.text.isNotEmpty &&
                                        bankCode.text.isNotEmpty &&
                                        _selectedBank != null &&
                                        _selectedBank!.isNotEmpty &&
                                        (_selectedBank != _bankOutrosKey || bankOtherController.text.isNotEmpty) &&
                                        _selectedPixType != null &&
                                        _selectedPixType!.isNotEmpty) {
                                      setState(() {
                                        _isLoading = true;
                                      });
                                      var val = await addBankData(
                                          holderName.text,
                                          accountNumber.text,
                                          bankCode.text,
                                          bankNameValue,
                                          type: _selectedPixType);
                                      if (val == 'success') {
                                        setState(() {
                                          _edit = false;
                                        });
                                        pop();
                                      } else if (val == 'logout') {
                                        navigateLogout();
                                      } else {
                                        setState(() {
                                          _showError = val.toString();
                                          _errorClear();
                                        });
                                      }
                                      setState(() {
                                        _isLoading = false;
                                      });
                                    }
                                  },
                                  width: (bankData.isEmpty)
                                      ? null
                                      : media.width * 0.4,
                                  text: languages[choosenLanguage]
                                      ['text_confirm']),
                            ],
                          )
                        : Button(
                            onTap: () {
                              setState(() {
                                accountNumber.text =
                                    bankData['account_no'].toString();
                                bankCode.text = bankData['bank_code'].toString();
                                holderName.text = bankData['account_name'].toString();
                                _selectedPixType = bankData['type']?.toString();
                                if (_selectedPixType != null && !_pixTypeOptions.any((e) => e['value'] == _selectedPixType)) {
                                  _selectedPixType = 'email';
                                }
                                final bn = bankData['bank_name']?.toString() ?? '';
                                if (bn.isEmpty) {
                                  _selectedBank = null;
                                  bankOtherController.clear();
                                } else if (_bankNames.contains(bn)) {
                                  _selectedBank = bn;
                                  bankOtherController.clear();
                                } else {
                                  _selectedBank = _bankOutrosKey;
                                  bankOtherController.text = bn;
                                }
                                _edit = true;
                              });
                            },
                            text: languages[choosenLanguage]['text_edit'])
                  ],
                ),
              ),
              (_showError != '')
                  ? Positioned(
                      top: 0,
                      child: Container(
                        height: media.height * 1,
                        width: media.width * 1,
                        color: Colors.transparent.withOpacity(0.6),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                alignment: Alignment.center,
                                width: media.width * 0.8,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: page,
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          spreadRadius: 2,
                                          blurRadius: 2)
                                    ]),
                                padding: EdgeInsets.all(media.width * 0.05),
                                child: SizedBox(
                                  width: media.width * 0.7,
                                  child: Text(
                                    _showError.toString(),
                                    style: GoogleFonts.poppins(
                                        fontSize: media.width * sixteen,
                                        color: textColor),
                                  ),
                                ),
                              )
                            ]),
                      ))
                  : Container(),

              (internet == false)
                  ? Positioned(
                      top: 0,
                      child: NoInternet(onTap: () {
                        setState(() {
                          internetTrue();
                        });
                      }))
                  : Container(),

              (_isLoading == true)
                  ? const Positioned(top: 0, child: Loading())
                  : Container()
            ],
          ),
        ),
      ),
    );
  }
}
