import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../functions/functions.dart';
import '../../styles/styles.dart';
import '../../translations/translation.dart';
import '../../widgets/widgets.dart';
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
  FocusNode firstnameFocus = FocusNode();
  FocusNode lastnameFocus = FocusNode();
  FocusNode emailFocus = FocusNode();
  FocusNode phoneFocus = FocusNode();
  FocusNode cpfFocus = FocusNode();
  FocusNode birthDateFocus = FocusNode();
  FocusNode genderFocus = FocusNode();
  FocusNode passengerPreferenceFocus = FocusNode();
  String? selectedGender;
  String? selectedPassengerPreference;

  // Estados de validação
  bool firstnameError = false;
  bool lastnameError = false;
  bool emailError = false;
  bool genderError = false;
  bool cpfError = false;
  bool birthDateError = false;
  bool passengerPreferenceError = false;

  @override
  void initState() {
    _error = '';

    if (isLoginemail == true) {
      emailtext.text = email;
    }

    // Definir preferência de motorista padrão
    selectedPassengerPreference = 'nao_tenho_preferencia';
    passengerPreference = 'nao_tenho_preferencia';

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
    passengerPreferenceFocus.addListener(() {
      setState(() {});
    });

    super.initState();
  }

  @override
  void dispose() {
    firstnameFocus.dispose();
    lastnameFocus.dispose();
    emailFocus.dispose();
    phoneFocus.dispose();
    cpfFocus.dispose();
    birthDateFocus.dispose();
    genderFocus.dispose();
    passengerPreferenceFocus.dispose();
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

  // Função de validação
  bool validateFields() {
    setState(() {
      firstnameError = firstname.text.trim().isEmpty;
      lastnameError = lastname.text.trim().isEmpty;
      emailError = emailtext.text.trim().isEmpty;
      genderError = selectedGender == null || selectedGender!.isEmpty;
      cpfError = cpfController.text.replaceAll(RegExp(r'[^\d]'), '').isEmpty;
      birthDateError = birthDateController.text.trim().isEmpty;
      passengerPreferenceError = selectedPassengerPreference == null ||
          selectedPassengerPreference!.isEmpty;
    });

    return !firstnameError &&
        !lastnameError &&
        !emailError &&
        !genderError &&
        !cpfError &&
        !birthDateError &&
        !passengerPreferenceError;
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
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: media.height * 0.02),
                        MyText(
                          text: languages[choosenLanguage]['text_your_name'],
                          size: media.width * twenty,
                          fontweight: FontWeight.bold,
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        SizedBox(
                          width: media.width * 0.9,
                          child: MyText(
                            text: languages[choosenLanguage]['text_prob_name'],
                            size: media.width * twelve,
                            color: textColor.withOpacity(0.5),
                            fontweight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                  constraints: BoxConstraints(
                                    minHeight: media.width * 0.13,
                                  ),
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
                                          ['text_first_name'],
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
                                  constraints: BoxConstraints(
                                    minHeight: media.width * 0.13,
                                  ),
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
                                        ['text_last_name'],
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
                        // Campo de Gênero (Dropdown)
                        Container(
                          height: media.width * 0.13,
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
                          child: DropdownButtonFormField<String>(
                            value: selectedGender,
                            focusNode: genderFocus,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: languages[choosenLanguage]
                                      ['text_select_gender'] ??
                                  'Selecione o gênero',
                              hintStyle: getGoogleFontStyle(
                                fontSize: media.width * fourteen,
                                color: hintColor,
                              ),
                            ),
                            style: getGoogleFontStyle(
                              fontSize: media.width * fourteen,
                              color: textColor,
                            ),
                            dropdownColor: page,
                            items: [
                              DropdownMenuItem<String>(
                                value: 'masculino',
                                child: Text(
                                  languages[choosenLanguage]
                                          ['text_masculine'] ??
                                      'Masculino',
                                  style: getGoogleFontStyle(
                                    fontSize: media.width * fourteen,
                                    color: textColor,
                                  ),
                                ),
                              ),
                              DropdownMenuItem<String>(
                                value: 'feminino',
                                child: Text(
                                  languages[choosenLanguage]['text_feminine'] ??
                                      'Feminino',
                                  style: getGoogleFontStyle(
                                    fontSize: media.width * fourteen,
                                    color: textColor,
                                  ),
                                ),
                              ),
                              DropdownMenuItem<String>(
                                value: 'prefiro_nao_dizer',
                                child: Text(
                                  languages[choosenLanguage]
                                          ['text_prefer_not_to_say'] ??
                                      'Prefiro não dizer',
                                  style: getGoogleFontStyle(
                                    fontSize: media.width * fourteen,
                                    color: textColor,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (String? value) {
                              setState(() {
                                selectedGender = value;
                                gender = value ?? '';
                                if (genderError &&
                                    value != null &&
                                    value.isNotEmpty) {
                                  genderError = false;
                                }
                              });
                            },
                          ),
                        ),
                        SizedBox(
                          height: media.height * 0.02,
                        ),
                        // Campo de CPF
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
                        // Campo de Data de Nascimento
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
                        // Campo de Preferência de Motorista (Dropdown)
                        Container(
                          height: media.width * 0.13,
                          decoration: BoxDecoration(
                            color: page,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: passengerPreferenceError
                                  ? Colors.red
                                  : (passengerPreferenceFocus.hasFocus
                                      ? buttonColor
                                      : textColor),
                              width: (passengerPreferenceError ||
                                      passengerPreferenceFocus.hasFocus)
                                  ? 2
                                  : 1,
                            ),
                            boxShadow: (passengerPreferenceError ||
                                    passengerPreferenceFocus.hasFocus)
                                ? [
                                    BoxShadow(
                                      color: passengerPreferenceError
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
                          child: DropdownButtonFormField<String>(
                            value: selectedPassengerPreference,
                            focusNode: passengerPreferenceFocus,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: languages[choosenLanguage]
                                      ['text_passenger_preference'] ??
                                  'Preferência de Motorista',
                              hintStyle: getGoogleFontStyle(
                                fontSize: media.width * fourteen,
                                color: hintColor,
                              ),
                            ),
                            style: getGoogleFontStyle(
                              fontSize: media.width * fourteen,
                              color: textColor,
                            ),
                            dropdownColor: page,
                            items: [
                              DropdownMenuItem<String>(
                                value: 'masculino',
                                child: Text(
                                  languages[choosenLanguage]
                                          ['text_masculine'] ??
                                      'Masculino',
                                  style: getGoogleFontStyle(
                                    fontSize: media.width * fourteen,
                                    color: textColor,
                                  ),
                                ),
                              ),
                              DropdownMenuItem<String>(
                                value: 'feminino',
                                child: Text(
                                  languages[choosenLanguage]['text_feminine'] ??
                                      'Feminino',
                                  style: getGoogleFontStyle(
                                    fontSize: media.width * fourteen,
                                    color: textColor,
                                  ),
                                ),
                              ),
                              DropdownMenuItem<String>(
                                value: 'nao_tenho_preferencia',
                                child: Text(
                                  languages[choosenLanguage]
                                          ['text_no_preference'] ??
                                      'Não tenho preferência',
                                  style: getGoogleFontStyle(
                                    fontSize: media.width * fourteen,
                                    color: textColor,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (String? value) {
                              setState(() {
                                selectedPassengerPreference = value;
                                passengerPreference = value ?? '';
                                if (passengerPreferenceError &&
                                    value != null &&
                                    value.isNotEmpty) {
                                  passengerPreferenceError = false;
                                }
                              });
                            },
                          ),
                        ),
                        SizedBox(
                          height: media.width * 0.05,
                        ),
                        (isfromomobile == false)
                            ? Container(
                                padding:
                                    const EdgeInsets.fromLTRB(10, 0, 10, 0),
                                height: 55,
                                width: media.width * 0.9,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: phoneFocus.hasFocus
                                        ? buttonColor
                                        : textColor,
                                    width: phoneFocus.hasFocus ? 2 : 1,
                                  ),
                                  boxShadow: phoneFocus.hasFocus
                                      ? [
                                          BoxShadow(
                                            color: buttonColor.withOpacity(0.3),
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
                                              phnumber = controller.text;
                                            });
                                            if (controller.text.length ==
                                                countries[phcode]
                                                    ['dial_max_length']) {
                                              FocusManager.instance.primaryFocus
                                                  ?.unfocus();
                                            }
                                          },
                                          maxLength: countries[phcode]
                                              ['dial_max_length'],
                                          style: getGoogleFontStyle(
                                                  color: textColor,
                                                  fontSize:
                                                      media.width * sixteen,
                                                  fontWeight: FontWeight.normal)
                                              .copyWith(letterSpacing: 1),
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            counterText: '',
                                            prefixText:
                                                '${countries[phcode]['dial_code']} ',
                                            prefixStyle: getGoogleFontStyle(
                                                    color: textColor,
                                                    fontSize:
                                                        media.width * sixteen,
                                                    fontWeight:
                                                        FontWeight.normal)
                                                .copyWith(letterSpacing: 1),
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
                              )
                            : Container(),
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
                                            var result = await validateEmail(
                                                emailtext.text);
                                            if (result == 'success') {
                                              isfromomobile = true;
                                              isverifyemail = true;

                                              currentPage = 3;
                                            } else {
                                              setState(() {
                                                _error = serverErrorMessage.isNotEmpty
                                                    ? serverErrorMessage
                                                    : result.toString();
                                              });
                                              // showToast();
                                            }
                                          } else {
                                            // showToast();
                                            setState(() {
                                              _error =
                                                  languages[choosenLanguage]
                                                      ['text_email_validation'];
                                            });
                                            // showToast();
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
                                              selectedPassengerPreference !=
                                                  null)
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
                                      FocusManager.instance.primaryFocus
                                          ?.unfocus();
                                      loginLoading = true;
                                      valueNotifierLogin.incrementNotifier();
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
                                          selectedPassengerPreference != null)
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
                          border: Border.all(
                              color: Colors.red.shade300, width: 1.5),
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
