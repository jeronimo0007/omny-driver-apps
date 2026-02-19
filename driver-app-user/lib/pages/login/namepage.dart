import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../functions/functions.dart';
import '../../styles/styles.dart';
import '../../translations/translation.dart';
import '../../widgets/widgets.dart';
import 'agreement.dart';
import 'login.dart';

String name = ''; //name of user
String gender = ''; //gender of user
String document = ''; //CPF of user
String birthDate = ''; //birth date of user
String passengerPreference = ''; //passenger preference of user

class NamePage extends StatefulWidget {
  const NamePage({Key? key}) : super(key: key);

  @override
  State<NamePage> createState() => _NamePageState();
}

bool isverifyemail = false;
String email = ''; // email of user
String _error = '';
dynamic proImageFile;

class _NamePageState extends State<NamePage> {
  TextEditingController firstname = TextEditingController();
  TextEditingController lastname = TextEditingController();
  TextEditingController emailtext = TextEditingController();
  TextEditingController controller = TextEditingController();
  TextEditingController cpfController = TextEditingController();
  TextEditingController birthDateController = TextEditingController();
  final TextEditingController _referralController = TextEditingController();
  FocusNode referralFocus = FocusNode();
  FocusNode firstnameFocus = FocusNode();
  FocusNode lastnameFocus = FocusNode();
  FocusNode emailFocus = FocusNode();
  FocusNode phoneFocus = FocusNode();
  FocusNode cpfFocus = FocusNode();
  FocusNode birthDateFocus = FocusNode();
  FocusNode genderFocus = FocusNode();
  String? selectedGender;

  // Estados de validação
  bool firstnameError = false;
  bool lastnameError = false;
  bool emailError = false;
  bool genderError = false;
  bool cpfError = false;
  bool birthDateError = false;
  bool referralError = false; // No user o código de indicação é obrigatório
  bool phoneError = false; // Celular obrigatório para concluir cadastro
  @override
  void initState() {
    _error = '';
    passengerPreference = 'nao_tenho_preferencia';

    if (isLoginemail == true) {
      emailtext.text = email;
    }

    firstnameFocus.addListener(() {
      setState(() {});
    });
    lastnameFocus.addListener(() {
      setState(() {});
    });
    emailFocus.addListener(() {
      setState(() {});
    });
    phoneFocus.addListener(() {
      setState(() {});
    });
    cpfFocus.addListener(() {
      setState(() {});
    });
    birthDateFocus.addListener(() {
      setState(() {});
    });
    genderFocus.addListener(() {
      setState(() {});
    });
    referralFocus.addListener(() => setState(() {}));

    super.initState();
  }

  @override
  void dispose() {
    _referralController.dispose();
    referralFocus.dispose();
    firstnameFocus.dispose();
    lastnameFocus.dispose();
    emailFocus.dispose();
    phoneFocus.dispose();
    cpfFocus.dispose();
    birthDateFocus.dispose();
    genderFocus.dispose();
    cpfController.dispose();
    birthDateController.dispose();
    super.dispose();
  }

  showToast() {
    setState(() {
      showtoast = true;
    });
    Future.delayed(const Duration(seconds: 4), () {
      setState(() {
        showtoast = false;
      });
    });
  }

  bool showtoast = false;

  // Função de validação (no user código de indicação e celular são obrigatórios)
  bool validateFields() {
    final phoneDigits = controller.text.replaceAll(RegExp(r'[^\d]'), '');
    final minLen = (phcode != null && countries[phcode] != null && countries[phcode]['dial_min_length'] != null)
        ? countries[phcode]['dial_min_length'] as int
        : 10;
    setState(() {
      firstnameError = firstname.text.trim().isEmpty;
      lastnameError = lastname.text.trim().isEmpty;
      emailError = emailtext.text.trim().isEmpty;
      genderError = selectedGender == null || selectedGender!.isEmpty;
      cpfError = cpfController.text.replaceAll(RegExp(r'[^\d]'), '').isEmpty;
      birthDateError = birthDateController.text.trim().isEmpty;
      referralError = _referralController.text.trim().isEmpty;
      phoneError = phoneDigits.length < minLen;
    });

    return !firstnameError &&
        !lastnameError &&
        !emailError &&
        !genderError &&
        !cpfError &&
        !birthDateError &&
        !referralError &&
        !phoneError;
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Material(
      color: page,
      child: Directionality(
        textDirection: (languageDirection == 'rtl')
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header com safe area, logo e botão voltar
                Container(
                  color: page,
                  padding: EdgeInsets.only(
                    top:
                        MediaQuery.of(context).padding.top + media.width * 0.03,
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
                      left: media.width * 0.05,
                      right: media.width * 0.05,
                      bottom: media.height * 0.06,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MyText(
                          text: languages[choosenLanguage]['text_sign_up'] ??
                              'Cadastre-se',
                          size: media.width * 0.055,
                          fontweight: FontWeight.bold,
                        ),
                        SizedBox(height: media.height * 0.02),
                        // Código de indicação (obrigatório no user)
                        MyText(
                          text: languages[choosenLanguage]
                                  ['text_referral_required'] ??
                              languages[choosenLanguage]
                                  ['text_label_referral'] ??
                              'Código de indicação',
                          size: media.width * fourteen,
                          color: referralError ? Colors.red : hintColor,
                        ),
                        SizedBox(height: media.height * 0.01),
                        Container(
                          height: 48,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: referralError
                                  ? Colors.red
                                  : (referralFocus.hasFocus
                                      ? buttonColor
                                      : textColor.withOpacity(0.5)),
                              width: referralError || referralFocus.hasFocus ? 2.0 : 1.0,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          alignment: Alignment.centerLeft,
                          child: TextFormField(
                            controller: _referralController,
                            focusNode: referralFocus,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: languages[choosenLanguage]
                                      ['text_enter_referral'] ??
                                  'Digite o código de indicação',
                              hintStyle: TextStyle(
                                fontSize: media.width * fourteen,
                                color: hintColor,
                              ),
                            ),
                            style: TextStyle(
                              fontSize: media.width * fourteen,
                              color: textColor,
                            ),
                            onChanged: (_) {
                              setState(() {
                                if (referralError &&
                                    _referralController.text.trim().isNotEmpty) {
                                  referralError = false;
                                }
                              });
                            },
                          ),
                        ),
                        SizedBox(height: media.height * 0.02),
                        Row(
                          children: [
                            Expanded(
                              child: MyText(
                                text: languages[choosenLanguage]['text_first_name'] ?? 'Nome',
                                size: media.width * fourteen,
                                color: textColor.withOpacity(0.8),
                              ),
                            ),
                            Expanded(
                              child: MyText(
                                text: languages[choosenLanguage]['text_last_name'] ?? 'Sobrenome',
                                size: media.width * fourteen,
                                color: textColor.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: media.height * 0.008),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                  height: media.width * 0.13,
                                  decoration: BoxDecoration(
                                    color: page,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: firstnameError
                                          ? Colors.red
                                          : (firstnameFocus.hasFocus
                                              ? buttonColor
                                              : textColor),
                                      width: (firstnameError ||
                                              firstnameFocus.hasFocus)
                                          ? 2
                                          : 1,
                                    ),
                                    boxShadow: (firstnameError ||
                                            firstnameFocus.hasFocus)
                                        ? [
                                            BoxShadow(
                                              color: firstnameError
                                                  ? Colors.red.withOpacity(0.3)
                                                  : buttonColor
                                                      .withOpacity(0.3),
                                              spreadRadius: 2,
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  padding: const EdgeInsets.only(
                                      left: 5, right: 5, top: 5, bottom: 5),
                                  alignment: Alignment.centerLeft,
                                  child: MyTextField(
                                      textController: firstname,
                                      hinttext: languages[choosenLanguage]
                                          ['text_first_name'] ?? 'Nome',
                                      maxline: null,
                                      focusNode: firstnameFocus,
                                      onTap: (val) {
                                        setState(() {
                                          if (firstnameError &&
                                              firstname.text
                                                  .trim()
                                                  .isNotEmpty) {
                                            firstnameError = false;
                                          }
                                        });
                                      })),
                            ),
                            SizedBox(
                              width: media.height * 0.02,
                            ),
                            Expanded(
                              child: Container(
                                  height: media.width * 0.13,
                                  decoration: BoxDecoration(
                                    color: page,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: lastnameError
                                          ? Colors.red
                                          : (lastnameFocus.hasFocus
                                              ? buttonColor
                                              : textColor),
                                      width: (lastnameError ||
                                              lastnameFocus.hasFocus)
                                          ? 2
                                          : 1,
                                    ),
                                    boxShadow: (lastnameError ||
                                            lastnameFocus.hasFocus)
                                        ? [
                                            BoxShadow(
                                              color: lastnameError
                                                  ? Colors.red.withOpacity(0.3)
                                                  : buttonColor
                                                      .withOpacity(0.3),
                                              spreadRadius: 2,
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  padding: const EdgeInsets.only(
                                      left: 5, right: 5, top: 5, bottom: 5),
                                  alignment: Alignment.centerLeft,
                                  child: MyTextField(
                                    hinttext: languages[choosenLanguage]
                                        ['text_last_name'] ?? 'Sobrenome',
                                    textController: lastname,
                                    maxline: null,
                                    focusNode: lastnameFocus,
                                    onTap: (val) {
                                      setState(() {
                                        if (lastnameError &&
                                            lastname.text.trim().isNotEmpty) {
                                          lastnameError = false;
                                        }
                                      });
                                    },
                                  )),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: media.height * 0.02,
                        ),
                        MyText(
                          text: languages[choosenLanguage]['text_select_gender'] ?? 'Gênero',
                          size: media.width * fourteen,
                          color: textColor.withOpacity(0.8),
                        ),
                        SizedBox(height: media.height * 0.008),
                        Container(
                          decoration: BoxDecoration(
                            color: page,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: genderError
                                  ? Colors.red
                                  : (genderFocus.hasFocus
                                      ? buttonColor
                                      : textColor),
                              width:
                                  (genderError || genderFocus.hasFocus) ? 2 : 1,
                            ),
                            boxShadow: (genderError || genderFocus.hasFocus)
                                ? [
                                    BoxShadow(
                                      color: genderError
                                          ? Colors.red.withOpacity(0.3)
                                          : buttonColor.withOpacity(0.3),
                                      spreadRadius: 2,
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          padding: const EdgeInsets.only(left: 5, right: 5),
                          child: DropdownSearch<String>(
                            selectedItem: selectedGender,
                            items: const [
                              'masculino',
                              'feminino',
                              'prefiro_nao_dizer'
                            ],
                            itemAsString: (String v) {
                              if (v == 'masculino')
                                return languages[choosenLanguage]
                                        ['text_masculine'] ??
                                    'Masculino';
                              if (v == 'feminino')
                                return languages[choosenLanguage]
                                        ['text_feminine'] ??
                                    'Feminino';
                              return languages[choosenLanguage]
                                      ['text_prefer_not_to_say'] ??
                                  'Prefiro não dizer';
                            },
                            onChanged: (String? value) {
                              setState(() {
                                selectedGender = value;
                                gender = value ?? '';
                                if (genderError &&
                                    value != null &&
                                    value.isNotEmpty) genderError = false;
                              });
                            },
                            popupProps: PopupProps.menu(
                              showSearchBox: true,
                              searchFieldProps: TextFieldProps(
                                decoration: InputDecoration(
                                  hintText: languages[choosenLanguage]
                                          ['text_search'] ??
                                      'Buscar',
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                            dropdownDecoratorProps: DropDownDecoratorProps(
                              dropdownSearchDecoration: InputDecoration(
                                hintText: languages[choosenLanguage]
                                        ['text_select_gender'] ??
                                    'Selecione o gênero',
                                hintStyle: getGoogleFontStyle(
                                    fontSize: media.width * fourteen,
                                    color: hintColor),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: media.height * 0.02,
                        ),
                        MyText(
                          text: languages[choosenLanguage]['text_enter_email'] ?? 'E-mail',
                          size: media.width * fourteen,
                          color: textColor.withOpacity(0.8),
                        ),
                        SizedBox(height: media.height * 0.008),
                        Container(
                            height: media.width * 0.13,
                            decoration: BoxDecoration(
                              color: page,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: emailError
                                    ? Colors.red
                                    : (emailFocus.hasFocus
                                        ? buttonColor
                                        : textColor),
                                width:
                                    (emailError || emailFocus.hasFocus) ? 2 : 1,
                              ),
                              boxShadow: (emailError || emailFocus.hasFocus)
                                  ? [
                                      BoxShadow(
                                        color: emailError
                                            ? Colors.red.withOpacity(0.3)
                                            : buttonColor.withOpacity(0.3),
                                        spreadRadius: 2,
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            padding: const EdgeInsets.only(left: 5, right: 5),
                            child: MyTextField(
                              textController: emailtext,
                              readonly: (isfromomobile == false) ? true : false,
                              hinttext: languages[choosenLanguage]
                                  ['text_enter_email'],
                              focusNode: emailFocus,
                              onTap: (val) {
                                setState(() {
                                  if (emailError &&
                                      emailtext.text.trim().isNotEmpty) {
                                    emailError = false;
                                  }
                                });
                              },
                            )),
                        SizedBox(
                          height: media.height * 0.02,
                        ),
                        MyText(
                          text: languages[choosenLanguage]['text_enter_cpf'] ?? 'CPF',
                          size: media.width * fourteen,
                          color: textColor.withOpacity(0.8),
                        ),
                        SizedBox(height: media.height * 0.008),
                        Container(
                          height: media.width * 0.13,
                          decoration: BoxDecoration(
                            color: page,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: cpfError
                                  ? Colors.red
                                  : (cpfFocus.hasFocus
                                      ? buttonColor
                                      : textColor),
                              width: (cpfError || cpfFocus.hasFocus) ? 2 : 1,
                            ),
                            boxShadow: (cpfError || cpfFocus.hasFocus)
                                ? [
                                    BoxShadow(
                                      color: cpfError
                                          ? Colors.red.withOpacity(0.3)
                                          : buttonColor.withOpacity(0.3),
                                      spreadRadius: 2,
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          padding: const EdgeInsets.only(left: 5, right: 5),
                          child: TextField(
                            controller: cpfController,
                            focusNode: cpfFocus,
                            inputFormatters: [CpfFormatter()],
                            keyboardType: TextInputType.number,
                            style: getGoogleFontStyle(
                              fontSize: media.width * fourteen,
                              color: textColor,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: languages[choosenLanguage]
                                      ['text_enter_cpf'] ??
                                  'CPF',
                              hintStyle: getGoogleFontStyle(
                                fontSize: media.width * fourteen,
                                color: hintColor,
                              ),
                            ),
                            onChanged: (val) {
                              setState(() {
                                document = cpfController.text
                                    .replaceAll(RegExp(r'[^\d]'), '');
                                if (cpfError && document.isNotEmpty) {
                                  cpfError = false;
                                }
                              });
                            },
                          ),
                        ),
                        SizedBox(
                          height: media.height * 0.02,
                        ),
                        MyText(
                          text: languages[choosenLanguage]['text_enter_birth_date'] ?? 'Data de nascimento',
                          size: media.width * fourteen,
                          color: textColor.withOpacity(0.8),
                        ),
                        SizedBox(height: media.height * 0.008),
                        Container(
                          height: media.width * 0.13,
                          decoration: BoxDecoration(
                            color: page,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: birthDateError
                                  ? Colors.red
                                  : (birthDateFocus.hasFocus
                                      ? buttonColor
                                      : textColor),
                              width: (birthDateError || birthDateFocus.hasFocus)
                                  ? 2
                                  : 1,
                            ),
                            boxShadow:
                                (birthDateError || birthDateFocus.hasFocus)
                                    ? [
                                        BoxShadow(
                                          color: birthDateError
                                              ? Colors.red.withOpacity(0.3)
                                              : buttonColor.withOpacity(0.3),
                                          spreadRadius: 2,
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                          ),
                          padding: const EdgeInsets.only(left: 5, right: 5),
                          child: TextField(
                            controller: birthDateController,
                            focusNode: birthDateFocus,
                            inputFormatters: [BirthDateFormatter()],
                            keyboardType: TextInputType.number,
                            style: getGoogleFontStyle(
                              fontSize: media.width * fourteen,
                              color: textColor,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: languages[choosenLanguage]
                                      ['text_enter_birth_date'] ??
                                  'Data de Nascimento (DD/MM/AAAA)',
                              hintStyle: getGoogleFontStyle(
                                fontSize: media.width * fourteen,
                                color: hintColor,
                              ),
                            ),
                            onChanged: (val) {
                              setState(() {
                                birthDate = birthDateController.text;
                                if (birthDateError && birthDate.isNotEmpty) {
                                  birthDateError = false;
                                }
                              });
                            },
                          ),
                        ),
                        SizedBox(
                          height: media.height * 0.02,
                        ),
                        // Celular sempre visível no cadastro (obrigatório)
                        Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  MyText(
                                    text: languages[choosenLanguage]['text_phone_number'] ?? 'Celular',
                                    size: media.width * fourteen,
                                    color: textColor.withOpacity(0.8),
                                  ),
                                  SizedBox(height: media.height * 0.008),
                                  Container(
                                padding:
                                    const EdgeInsets.fromLTRB(10, 0, 10, 0),
                                height: 55,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: phoneError
                                        ? Colors.red
                                        : (phoneFocus.hasFocus
                                            ? buttonColor
                                            : textColor),
                                    width: (phoneError || phoneFocus.hasFocus) ? 2 : 1,
                                  ),
                                  boxShadow: (phoneError || phoneFocus.hasFocus)
                                      ? [
                                          BoxShadow(
                                            color: phoneError
                                                ? Colors.red.withOpacity(0.3)
                                                : buttonColor.withOpacity(0.3),
                                            spreadRadius: 2,
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    InkWell(
                                      onTap: () async {
                                        if (countries.isNotEmpty) {
                                          //dialod box for select country for dial code
                                          await showDialog(
                                              context: context,
                                              builder: (context) {
                                                var searchVal = '';
                                                return AlertDialog(
                                                  backgroundColor: page,
                                                  insetPadding:
                                                      const EdgeInsets.all(10),
                                                  content: StatefulBuilder(
                                                      builder:
                                                          (context, setState) {
                                                    return Container(
                                                      width: media.width * 0.9,
                                                      color: page,
                                                      child: Directionality(
                                                        textDirection:
                                                            (languageDirection ==
                                                                    'rtl')
                                                                ? TextDirection
                                                                    .rtl
                                                                : TextDirection
                                                                    .ltr,
                                                        child: Column(
                                                          children: [
                                                            Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .only(
                                                                      left: 20,
                                                                      right:
                                                                          20),
                                                              height: 40,
                                                              width:
                                                                  media.width *
                                                                      0.9,
                                                              decoration: BoxDecoration(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              20),
                                                                  border: Border.all(
                                                                      color: Colors
                                                                          .grey,
                                                                      width:
                                                                          1.5)),
                                                              child: TextField(
                                                                decoration: InputDecoration(
                                                                    contentPadding: (languageDirection ==
                                                                            'rtl')
                                                                        ? EdgeInsets.only(
                                                                            bottom: media.width *
                                                                                0.035)
                                                                        : EdgeInsets.only(
                                                                            bottom: media.width *
                                                                                0.04),
                                                                    border:
                                                                        InputBorder
                                                                            .none,
                                                                    hintText:
                                                                        languages[choosenLanguage][
                                                                            'text_search'],
                                                                    hintStyle: getGoogleFontStyle(
                                                                        fontSize: media.width *
                                                                            sixteen,
                                                                        color:
                                                                            hintColor)),
                                                                style: getGoogleFontStyle(
                                                                    fontSize: media
                                                                            .width *
                                                                        sixteen,
                                                                    color:
                                                                        textColor),
                                                                onChanged:
                                                                    (val) {
                                                                  setState(() {
                                                                    searchVal =
                                                                        val;
                                                                  });
                                                                },
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                height: 20),
                                                            Expanded(
                                                              child:
                                                                  SingleChildScrollView(
                                                                child: Column(
                                                                  children: countries
                                                                      .asMap()
                                                                      .map((i, value) {
                                                                        return MapEntry(
                                                                            i,
                                                                            SizedBox(
                                                                              width: media.width * 0.9,
                                                                              child: (searchVal == '' && countries[i]['flag'] != null)
                                                                                  ? InkWell(
                                                                                      onTap: () {
                                                                                        setState(() {
                                                                                          phcode = i;
                                                                                        });
                                                                                        Navigator.pop(context);
                                                                                      },
                                                                                      child: Container(
                                                                                        padding: const EdgeInsets.only(top: 10, bottom: 10),
                                                                                        color: page,
                                                                                        child: Row(
                                                                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                          children: [
                                                                                            Row(
                                                                                              children: [
                                                                                                Image.network(countries[i]['flag']),
                                                                                                SizedBox(
                                                                                                  width: media.width * 0.02,
                                                                                                ),
                                                                                                SizedBox(
                                                                                                  width: media.width * 0.4,
                                                                                                  child: MyText(
                                                                                                    text: countries[i]['name'],
                                                                                                    size: media.width * sixteen,
                                                                                                  ),
                                                                                                ),
                                                                                              ],
                                                                                            ),
                                                                                            MyText(text: countries[i]['dial_code'], size: media.width * sixteen)
                                                                                          ],
                                                                                        ),
                                                                                      ))
                                                                                  : (countries[i]['flag'] != null && countries[i]['name'].toLowerCase().contains(searchVal.toLowerCase()))
                                                                                      ? InkWell(
                                                                                          onTap: () {
                                                                                            setState(() {
                                                                                              phcode = i;
                                                                                            });
                                                                                            Navigator.pop(context);
                                                                                          },
                                                                                          child: Container(
                                                                                            padding: const EdgeInsets.only(top: 10, bottom: 10),
                                                                                            color: page,
                                                                                            child: Row(
                                                                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                              children: [
                                                                                                Row(
                                                                                                  children: [
                                                                                                    Image.network(countries[i]['flag']),
                                                                                                    SizedBox(
                                                                                                      width: media.width * 0.02,
                                                                                                    ),
                                                                                                    SizedBox(
                                                                                                      width: media.width * 0.4,
                                                                                                      child: MyText(text: countries[i]['name'], size: media.width * sixteen),
                                                                                                    ),
                                                                                                  ],
                                                                                                ),
                                                                                                MyText(text: countries[i]['dial_code'], size: media.width * sixteen)
                                                                                              ],
                                                                                            ),
                                                                                          ))
                                                                                      : Container(),
                                                                            ));
                                                                      })
                                                                      .values
                                                                      .toList(),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  }),
                                                );
                                              });
                                        } else {
                                          getCountryCode();
                                        }
                                        setState(() {});
                                      },
                                      //input field
                                      child: Container(
                                        height: 50,
                                        alignment: Alignment.center,
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Image.network(
                                                countries[phcode]['flag']),
                                            SizedBox(
                                              width: media.width * 0.02,
                                            ),
                                            const SizedBox(
                                              width: 2,
                                            ),
                                            Icon(
                                              Icons.arrow_drop_down,
                                              size: 28,
                                              color: textColor,
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Container(
                                      width: 1,
                                      height: 55,
                                      color: underline,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Container(
                                        alignment: Alignment.bottomCenter,
                                        height: 50,
                                        child: TextFormField(
                                          textAlign: TextAlign.start,
                                          controller: controller,
                                          focusNode: phoneFocus,
                                          onChanged: (val) {
                                            setState(() {
                                              phnumber = controller.text.replaceAll(RegExp(r'[^\d]'), '');
                                              if (phoneError && phnumber.length >= (countries[phcode]?['dial_min_length'] ?? 10)) {
                                                phoneError = false;
                                              }
                                            });
                                            if (controller.text.replaceAll(RegExp(r'[^\d]'), '').length >=
                                                (countries[phcode]?['dial_max_length'] ?? 11)) {
                                              FocusManager.instance.primaryFocus
                                                  ?.unfocus();
                                            }
                                          },
                                          maxLength: countries[phcode]?['dial_max_length'] ?? 11,
                                          style: getGoogleFontStyle(
                                                  color: textColor,
                                                  fontSize:
                                                      media.width * sixteen,
                                                  fontWeight: FontWeight.normal)
                                              .copyWith(letterSpacing: 1),
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            counterText: '',
                                            hintStyle: getGoogleFontStyle(
                                              color: textColor.withOpacity(0.7),
                                              fontSize: media.width * sixteen,
                                            ),
                                            border: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                          ),
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                                ],
                              ),
                        const SizedBox(
                          height: 20,
                        ),
                        if (_error != '')
                          Column(
                            children: [
                              Container(
                                width: media.width * 0.9,
                                padding: EdgeInsets.symmetric(
                                    horizontal: media.width * 0.04,
                                    vertical: media.width * 0.03),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: Colors.red.shade300, width: 1.5),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline,
                                        color: Colors.red.shade700,
                                        size: media.width * 0.06),
                                    SizedBox(width: media.width * 0.02),
                                    Expanded(
                                      child: MyText(
                                        text: _error,
                                        color: Colors.red.shade800,
                                        size: media.width * fourteen,
                                        textAlign: TextAlign.start,
                                        fontweight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: media.width * 0.025,
                              )
                            ],
                          ),
                        (isfromomobile == true)
                            ? Column(
                                children: [
                                  Button(
                                      onTap: () async {
                                        // Validar todos os campos
                                        if (!validateFields()) {
                                          setState(() {
                                            _error = languages[choosenLanguage]
                                                    ['text_fill_all_fields'] ??
                                                'Por favor, preencha todos os campos obrigatórios';
                                          });
                                          return;
                                        }

                                        if (firstname.text.isNotEmpty &&
                                            emailtext.text.isNotEmpty) {
                                          setState(() {
                                            _error = '';
                                          });
                                          loginReferralCode =
                                              _referralController.text.trim();
                                          loginLoading = true;
                                          valueNotifierLogin
                                              .incrementNotifier();
                                          String pattern =
                                              r"^[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?\.)+[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])*$";
                                          RegExp regex = RegExp(pattern);
                                          if (regex.hasMatch(emailtext.text)) {
                                            setState(() {
                                              _error = '';
                                            });
                                            FocusScope.of(context).unfocus();
                                            if (lastname.text != '') {
                                              name =
                                                  '${firstname.text} ${lastname.text}';
                                            } else {
                                              name = firstname.text;
                                            }
                                            email = emailtext.text;
                                            phnumber = controller.text.replaceAll(RegExp(r'[^\d]'), '');
                                            final countryCode = countries[phcode]?['dial_code']?.toString() ?? '';
                                            final mobileDigits = controller.text.replaceAll(RegExp(r'[^\d]'), '');
                                            final docDigits = cpfController.text.replaceAll(RegExp(r'[^\d]'), '');
                                            var result = await validateEmailMobileDocument(
                                                emailtext.text.trim(),
                                                mobileDigits,
                                                countryCode,
                                                docDigits);
                                            if (result == 'success') {
                                              isfromomobile = true;
                                              isverifyemail = true;
                                              currentPage = 3;
                                              loginLoading = false;
                                              valueNotifierLogin.incrementNotifier();
                                              if (mounted) {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => const AggreementPage(),
                                                  ),
                                                );
                                              }
                                            } else {
                                              setState(() {
                                                _error = result.toString();
                                              });
                                            }
                                          } else {
                                            setState(() {
                                              _error =
                                                  languages[choosenLanguage]
                                                      ['text_email_validation'];
                                            });
                                          }
                                          loginLoading = false;
                                          valueNotifierLogin
                                              .incrementNotifier();
                                        }
                                      },
                                      color: (firstname.text.isNotEmpty &&
                                              lastname.text.isNotEmpty &&
                                              emailtext.text.isNotEmpty &&
                                              selectedGender != null &&
                                              cpfController.text
                                                  .replaceAll(
                                                      RegExp(r'[^\d]'), '')
                                                  .isNotEmpty &&
                                              birthDateController
                                                  .text.isNotEmpty &&
                                              _referralController.text
                                                  .trim()
                                                  .isNotEmpty &&
                                              controller.text.replaceAll(RegExp(r'[^\d]'), '').length >=
                                                  (countries[phcode] != null && countries[phcode]['dial_min_length'] != null
                                                      ? countries[phcode]['dial_min_length'] as int
                                                      : 10))
                                          ? buttonColor
                                          : Colors.grey,
                                      text: languages[choosenLanguage]
                                          ['text_next'])
                                ],
                              )
                            : Container(
                                width: media.width * 1 - media.width * 0.08,
                                alignment: Alignment.center,
                                child: Button(
                                  onTap: () async {
                                    // Validar todos os campos
                                    if (!validateFields()) {
                                      setState(() {
                                        _error = languages[choosenLanguage]
                                                ['text_fill_all_fields'] ??
                                            'Por favor, preencha todos os campos obrigatórios';
                                      });
                                      return;
                                    }

                                    if (firstname.text.isNotEmpty &&
                                        controller.text.length >=
                                            countries[phcode]
                                                ['dial_min_length']) {
                                      if (lastname.text != '') {
                                        name =
                                            '${firstname.text} ${lastname.text}';
                                      } else {
                                        name = firstname.text;
                                      }
                                      phnumber = controller.text.replaceAll(RegExp(r'[^\d]'), '');
                                      FocusManager.instance.primaryFocus
                                          ?.unfocus();
                                      loginReferralCode =
                                          _referralController.text.trim();
                                      loginLoading = true;
                                      valueNotifierLogin.incrementNotifier();
                                      final countryCode = countries[phcode]?['dial_code']?.toString() ?? '';
                                      final docDigits = cpfController.text.replaceAll(RegExp(r'[^\d]'), '');
                                      var validateResult = await validateEmailMobileDocument(
                                          emailtext.text.trim(),
                                          phnumber,
                                          countryCode,
                                          docDigits);
                                      if (validateResult != 'success') {
                                        setState(() => _error = validateResult.toString());
                                        loginLoading = false;
                                        valueNotifierLogin.incrementNotifier();
                                        return;
                                      }
                                      var val = await otpCall();
                                      // Tratar quando otpCall retorna null (nó não existe) - usar OTP próprio (false)
                                      if (val != null && val.value == true) {
                                        phoneAuthCheck = true;
                                        await phoneAuth(countries[phcode]
                                                ['dial_code'] +
                                            phnumber);
                                        value = 0;
                                        currentPage = 1;
                                        isfromomobile = true;
                                      } else {
                                        // Se val é null ou false, usar OTP próprio
                                        value = 0;
                                        isverifyemail = true;
                                        phoneAuthCheck = false;
                                        isfromomobile = true;
                                        currentPage = 1;
                                      }
                                      loginLoading = false;
                                      valueNotifierLogin.incrementNotifier();
                                    }
                                  },
                                  color: (firstname.text.isNotEmpty &&
                                          lastname.text.isNotEmpty &&
                                          controller.text.length >=
                                              countries[phcode]
                                                  ['dial_min_length'] &&
                                          selectedGender != null &&
                                          cpfController.text
                                              .replaceAll(RegExp(r'[^\d]'), '')
                                              .isNotEmpty &&
                                          birthDateController.text.isNotEmpty &&
                                          _referralController.text
                                              .trim()
                                              .isNotEmpty)
                                      ? buttonColor
                                      : Colors.grey,
                                  text: languages[choosenLanguage]['text_next'],
                                ),
                              ),
                        const SizedBox(
                          height: 25,
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
            //display toast
            (showtoast == true)
                ? Positioned(
                    bottom: media.width * 0.1,
                    left: media.width * 0.06,
                    right: media.width * 0.06,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: media.width * 0.04,
                          vertical: media.width * 0.035),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                              blurRadius: 2.0,
                              spreadRadius: 2.0,
                              color: Colors.black.withOpacity(0.2))
                        ],
                        color: verifyDeclined,
                        border:
                            Border.all(color: Colors.red.shade300, width: 1.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              color: Colors.white, size: media.width * 0.06),
                          SizedBox(width: media.width * 0.02),
                          Expanded(
                            child: Text(
                              _error,
                              textAlign: TextAlign.center,
                              style: getGoogleFontStyle(
                                  fontSize: media.width * fourteen,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ))
                : Container()
          ],
        ),
      ),
    );
  }
}

// Formatter para CPF (000.000.000-00)
class CpfFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (text.length > 11) {
      text = text.substring(0, 11);
    }

    String formatted = '';
    for (int i = 0; i < text.length; i++) {
      if (i == 3 || i == 6) {
        formatted += '.';
      } else if (i == 9) {
        formatted += '-';
      }
      formatted += text[i];
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// Formatter para Data de Nascimento (DD/MM/AAAA)
class BirthDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (text.length > 8) {
      text = text.substring(0, 8);
    }

    String formatted = '';
    for (int i = 0; i < text.length; i++) {
      if (i == 2 || i == 4) {
        formatted += '/';
      }
      formatted += text[i];
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
