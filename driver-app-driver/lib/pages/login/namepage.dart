import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../functions/functions.dart';
import '../../styles/styles.dart';
import '../../translation/translation.dart';
import '../../widgets/widgets.dart';
import 'login.dart';

String name = ''; //name of user

class NamePage extends StatefulWidget {
  const NamePage({Key? key}) : super(key: key);

  @override
  State<NamePage> createState() => _NamePageState();
}

bool isverifyemail = false;
String email = ''; // email of user
String _error = '';
// dynamic proImageFile1;

class _NamePageState extends State<NamePage> {
  TextEditingController firstname = TextEditingController();
  TextEditingController lastname = TextEditingController();
  TextEditingController emailtext = TextEditingController();
  TextEditingController controller = TextEditingController();
  TextEditingController cpfController = TextEditingController();
  TextEditingController birthDateController = TextEditingController();
  TextEditingController cepController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController numberController = TextEditingController();
  TextEditingController complementController = TextEditingController();
  TextEditingController neighborhoodController = TextEditingController();
  TextEditingController cityController = TextEditingController();

  final FocusNode _firstnameFocusNode = FocusNode();
  final FocusNode _lastnameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _cepFocusNode = FocusNode();
  final FocusNode _cpfFocusNode = FocusNode();
  final FocusNode _birthDateFocusNode = FocusNode();
  final FocusNode _addressFocusNode = FocusNode();
  final FocusNode _numberFocusNode = FocusNode();
  final FocusNode _neighborhoodFocusNode = FocusNode();
  final FocusNode _cityFocusNode = FocusNode();
  final FocusNode _stateFocusNode = FocusNode();
  final FocusNode _genderFocusNode = FocusNode();
  final FocusNode _passengerPreferenceFocusNode = FocusNode();
  bool _isFirstnameFocused = false;
  bool _isLastnameFocused = false;
  bool _isEmailFocused = false;
  bool _isPhoneFocused = false;
  bool _isCepFocused = false;
  bool _isCpfFocused = false;
  bool _isBirthDateFocused = false;
  bool _isAddressFocused = false;
  bool _isNumberFocused = false;
  bool _isNeighborhoodFocused = false;
  bool _isCityFocused = false;
  bool _isStateFocused = false;
  bool _isGenderFocused = false;
  bool _isPassengerPreferenceFocused = false;
  bool _loadingCep = false;
  MaskTextInputFormatter? _phoneMaskFormatter;
  MaskTextInputFormatter? _cpfMaskFormatter;
  MaskTextInputFormatter? _cepMaskFormatter;
  MaskTextInputFormatter? _birthDateMaskFormatter;
  String _selectedState = '';
  String _selectedGender = '';
  String _selectedPassengerPreference = 'both';

  @override
  void initState() {
    _error = '';
    _cpfMaskFormatter = MaskTextInputFormatter(
      mask: '###.###.###-##',
      filter: {"#": RegExp(r'[0-9]')},
      type: MaskAutoCompletionType.lazy,
    );
    _cepMaskFormatter = MaskTextInputFormatter(
      mask: '#####-###',
      filter: {"#": RegExp(r'[0-9]')},
      type: MaskAutoCompletionType.lazy,
    );
    _birthDateMaskFormatter = MaskTextInputFormatter(
      mask: '##/##/####',
      filter: {"#": RegExp(r'[0-9]')},
      type: MaskAutoCompletionType.lazy,
    );
    if (userCep.isNotEmpty) cepController.text = userCep;
    if (userAddress.isNotEmpty) addressController.text = userAddress;
    if (userNumber.isNotEmpty) numberController.text = userNumber;
    if (userComplement.isNotEmpty) complementController.text = userComplement;
    if (userNeighborhood.isNotEmpty)
      neighborhoodController.text = userNeighborhood;
    if (userCity.isNotEmpty) cityController.text = userCity;
    if (userState.isNotEmpty) _selectedState = userState;
    if (userGender.isNotEmpty) _selectedGender = userGender;
    if (userPassengerPreference.isNotEmpty)
      _selectedPassengerPreference = userPassengerPreference;
    if (userCpf.isNotEmpty) cpfController.text = userCpf;
    if (userBirthDate.isNotEmpty && userBirthDate.length >= 10) {
      // userBirthDate vem como yyyy-MM-dd; exibir dd/mm/yyyy
      final p = userBirthDate.split('-');
      if (p.length == 3) birthDateController.text = '${p[2]}/${p[1]}/${p[0]}';
    }

    if (isLoginemail == true) {
      emailtext.text = email;
    }

    // Inicializar o formatter de máscara
    _updatePhoneMaskFormatter();

    _cepFocusNode.addListener(() {
      setState(() {
        _isCepFocused = _cepFocusNode.hasFocus;
        if (!_cepFocusNode.hasFocus) _onCepBlur();
      });
    });
    _cpfFocusNode.addListener(
        () => setState(() => _isCpfFocused = _cpfFocusNode.hasFocus));
    _birthDateFocusNode.addListener(() =>
        setState(() => _isBirthDateFocused = _birthDateFocusNode.hasFocus));
    _addressFocusNode.addListener(
        () => setState(() => _isAddressFocused = _addressFocusNode.hasFocus));
    _numberFocusNode.addListener(
        () => setState(() => _isNumberFocused = _numberFocusNode.hasFocus));
    _neighborhoodFocusNode.addListener(() => setState(
        () => _isNeighborhoodFocused = _neighborhoodFocusNode.hasFocus));
    _cityFocusNode.addListener(
        () => setState(() => _isCityFocused = _cityFocusNode.hasFocus));
    _stateFocusNode.addListener(
        () => setState(() => _isStateFocused = _stateFocusNode.hasFocus));
    _genderFocusNode.addListener(
        () => setState(() => _isGenderFocused = _genderFocusNode.hasFocus));
    _passengerPreferenceFocusNode.addListener(() => setState(() =>
        _isPassengerPreferenceFocused =
            _passengerPreferenceFocusNode.hasFocus));

    _firstnameFocusNode.addListener(() {
      setState(() {
        _isFirstnameFocused = _firstnameFocusNode.hasFocus;
      });
    });

    _lastnameFocusNode.addListener(() {
      setState(() {
        _isLastnameFocused = _lastnameFocusNode.hasFocus;
      });
    });

    _emailFocusNode.addListener(() {
      setState(() {
        _isEmailFocused = _emailFocusNode.hasFocus;
      });
    });

    _phoneFocusNode.addListener(() {
      setState(() {
        _isPhoneFocused = _phoneFocusNode.hasFocus;
      });
    });

    super.initState();
  }

  // Atualiza o formatter de máscara quando o país muda
  void _updatePhoneMaskFormatter() {
    _phoneMaskFormatter = MaskTextInputFormatter(
      mask: _getPhoneMask(),
      filter: {"#": RegExp(r'[0-9]')},
      type: MaskAutoCompletionType.lazy,
    );
  }

  // Função para obter a máscara de telefone baseada no país
  String _getPhoneMask() {
    if (countries.isNotEmpty && phcode != null && countries[phcode] != null) {
      int maxLength = countries[phcode]['dial_max_length'] ?? 10;

      // Máscaras comuns por tamanho
      if (maxLength <= 8) {
        return '####-####';
      } else if (maxLength == 9) {
        return '#####-####';
      } else if (maxLength == 10) {
        return '(##)#####-####'; // Formato brasileiro
      } else if (maxLength == 11) {
        return '(##)#####-####';
      } else {
        // Máscara genérica: grupos de 4 dígitos separados por espaço
        String mask = '';
        for (int i = 0; i < maxLength; i++) {
          if (i > 0 && i % 4 == 0) {
            mask += ' ';
          }
          mask += '#';
        }
        return mask;
      }
    }
    // Padrão brasileiro
    return '(##)#####-####';
  }

  // Função para obter o hint do telefone
  String _getPhoneHint() {
    if (countries.isNotEmpty && phcode != null && countries[phcode] != null) {
      int maxLength = countries[phcode]['dial_max_length'] ?? 10;

      if (maxLength <= 8) {
        return '1234-5678';
      } else if (maxLength == 9) {
        return '12345-6789';
      } else if (maxLength == 10) {
        return '(11)91234-5678';
      } else if (maxLength == 11) {
        return '(11)91234-5678';
      } else {
        return '';
      }
    }
    return '(11)91234-5678';
  }

  Widget _buildLabeledField(
    TextEditingController ctrl,
    String label,
    String hint,
    void Function(String) onSave, {
    FocusNode? focusNode,
    bool isFocused = false,
  }) {
    var media = MediaQuery.of(context).size;
    final usePurpleBorder = focusNode != null && isFocused;
    return Container(
      height: media.width * 0.13,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: usePurpleBorder ? const Color(0xFF9A03E9) : textColor,
          width: usePurpleBorder ? 2.0 : 1.0,
        ),
      ),
      padding: const EdgeInsets.only(left: 12, right: 12),
      child: TextFormField(
        controller: ctrl,
        focusNode: focusNode,
        onChanged: (v) {
          onSave(v);
          setState(() {});
        },
        style: GoogleFonts.poppins(
            fontSize: media.width * sixteen, color: textColor),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(
              fontSize: media.width * sixteen, color: hintColor),
          border: InputBorder.none,
          labelText: label,
          labelStyle: GoogleFonts.poppins(
              fontSize: media.width * twelve, color: hintColor),
        ),
      ),
    );
  }

  Future<void> _onCepBlur() async {
    final cep = cepController.text.replaceAll(RegExp(r'[^\d]'), '');
    if (cep.length != 8) return;
    setState(() => _loadingCep = true);
    final result = await fetchCep(cep);
    if (result != null && mounted) {
      setState(() {
        addressController.text = result['logradouro'] ?? '';
        neighborhoodController.text = result['bairro'] ?? '';
        cityController.text = result['localidade'] ?? '';
        _selectedState = result['uf'] ?? '';
        userAddress = addressController.text;
        userNeighborhood = neighborhoodController.text;
        userCity = cityController.text;
        userState = _selectedState;
      });
    }
    if (mounted) setState(() => _loadingCep = false);
  }

  /// Converte data no formato dd/mm/yyyy para yyyy-MM-dd (API).
  String _birthDateToApi(String masked) {
    final digits = masked.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length != 8) return '';
    final day = digits.substring(0, 2);
    final month = digits.substring(2, 4);
    final year = digits.substring(4, 8);
    return '$year-$month-$day';
  }

  @override
  void dispose() {
    _firstnameFocusNode.dispose();
    _lastnameFocusNode.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    _cepFocusNode.dispose();
    _cpfFocusNode.dispose();
    _birthDateFocusNode.dispose();
    _addressFocusNode.dispose();
    _numberFocusNode.dispose();
    _neighborhoodFocusNode.dispose();
    _cityFocusNode.dispose();
    _stateFocusNode.dispose();
    _genderFocusNode.dispose();
    _passengerPreferenceFocusNode.dispose();
    cpfController.dispose();
    birthDateController.dispose();
    cepController.dispose();
    addressController.dispose();
    numberController.dispose();
    complementController.dispose();
    neighborhoodController.dispose();
    cityController.dispose();
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
                                  height: media.width * 0.13,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: _isFirstnameFocused
                                          ? const Color(0xFF9A03E9) // Roxo
                                          : textColor,
                                      width: _isFirstnameFocused ? 2.0 : 1.0,
                                    ),
                                  ),
                                  padding:
                                      const EdgeInsets.only(left: 5, right: 5),
                                  child: MyTextField(
                                      textController: firstname,
                                      focusNode: _firstnameFocusNode,
                                      hinttext: languages[choosenLanguage]
                                          ['text_first_name'],
                                      onTap: (val) {
                                        setState(() {});
                                      })),
                            ),
                            SizedBox(
                              width: media.height * 0.02,
                            ),
                            Expanded(
                              child: Container(
                                  height: media.width * 0.13,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: _isLastnameFocused
                                          ? const Color(0xFF9A03E9) // Roxo
                                          : textColor,
                                      width: _isLastnameFocused ? 2.0 : 1.0,
                                    ),
                                  ),
                                  padding:
                                      const EdgeInsets.only(left: 5, right: 5),
                                  child: MyTextField(
                                    hinttext: languages[choosenLanguage]
                                        ['text_last_name'],
                                    textController: lastname,
                                    focusNode: _lastnameFocusNode,
                                    onTap: (val) {
                                      setState(() {});
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
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _isEmailFocused
                                    ? const Color(0xFF9A03E9) // Roxo
                                    : textColor,
                                width: _isEmailFocused ? 2.0 : 1.0,
                              ),
                            ),
                            padding: const EdgeInsets.only(left: 5, right: 5),
                            child: MyTextField(
                              textController: emailtext,
                              focusNode: _emailFocusNode,
                              readonly: (isfromomobile == false) ? true : false,
                              hinttext: languages[choosenLanguage]
                                  ['text_enter_email'],
                              onTap: (val) {
                                setState(() {});
                              },
                            )),
                        SizedBox(height: media.width * 0.04),
                        // CPF
                        Container(
                          height: media.width * 0.13,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _isCpfFocused
                                  ? const Color(0xFF9A03E9)
                                  : textColor,
                              width: _isCpfFocused ? 2.0 : 1.0,
                            ),
                          ),
                          padding: const EdgeInsets.only(left: 12, right: 12),
                          child: TextFormField(
                            controller: cpfController,
                            focusNode: _cpfFocusNode,
                            inputFormatters: _cpfMaskFormatter != null
                                ? [_cpfMaskFormatter!]
                                : [],
                            onChanged: (val) {
                              userCpf = val.replaceAll(RegExp(r'[^\d]'), '');
                              setState(() {});
                            },
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.poppins(
                                fontSize: media.width * sixteen,
                                color: textColor),
                            decoration: InputDecoration(
                              hintText: languages[choosenLanguage]
                                      ['text_cpf_hint'] ??
                                  '000.000.000-00',
                              hintStyle: GoogleFonts.poppins(
                                  fontSize: media.width * sixteen,
                                  color: hintColor),
                              border: InputBorder.none,
                              labelText: languages[choosenLanguage]
                                      ['text_cpf'] ??
                                  'CPF',
                              labelStyle: GoogleFonts.poppins(
                                  fontSize: media.width * twelve,
                                  color: hintColor),
                            ),
                          ),
                        ),
                        SizedBox(height: media.width * 0.03),
                        // Data de nascimento (máscara dd/mm/aaaa)
                        Container(
                          height: media.width * 0.13,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _isBirthDateFocused
                                  ? const Color(0xFF9A03E9)
                                  : textColor,
                              width: _isBirthDateFocused ? 2.0 : 1.0,
                            ),
                          ),
                          padding: const EdgeInsets.only(left: 12, right: 12),
                          child: TextFormField(
                            controller: birthDateController,
                            focusNode: _birthDateFocusNode,
                            inputFormatters: _birthDateMaskFormatter != null
                                ? [_birthDateMaskFormatter!]
                                : [],
                            onChanged: (val) {
                              userBirthDate = _birthDateToApi(val);
                              setState(() {});
                            },
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.poppins(
                                fontSize: media.width * sixteen,
                                color: textColor),
                            decoration: InputDecoration(
                              hintText: languages[choosenLanguage]
                                      ['text_birth_date_hint'] ??
                                  '00/00/0000',
                              hintStyle: GoogleFonts.poppins(
                                  fontSize: media.width * sixteen,
                                  color: hintColor),
                              border: InputBorder.none,
                              labelText: languages[choosenLanguage]
                                      ['text_birth_date'] ??
                                  'Data de nascimento',
                              labelStyle: GoogleFonts.poppins(
                                  fontSize: media.width * twelve,
                                  color: hintColor),
                            ),
                          ),
                        ),
                        SizedBox(height: media.width * 0.03),
                        // CEP
                        Container(
                          height: media.width * 0.13,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _isCepFocused
                                  ? const Color(0xFF9A03E9)
                                  : textColor,
                              width: _isCepFocused ? 2.0 : 1.0,
                            ),
                          ),
                          padding: const EdgeInsets.only(left: 12, right: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: cepController,
                                  focusNode: _cepFocusNode,
                                  inputFormatters: _cepMaskFormatter != null
                                      ? [_cepMaskFormatter!]
                                      : [],
                                  onChanged: (val) {
                                    userCep =
                                        val.replaceAll(RegExp(r'[^\d]'), '');
                                    if (userCep.length == 8) _onCepBlur();
                                    setState(() {});
                                  },
                                  keyboardType: TextInputType.number,
                                  style: GoogleFonts.poppins(
                                      fontSize: media.width * sixteen,
                                      color: textColor),
                                  decoration: InputDecoration(
                                    hintText: languages[choosenLanguage]
                                            ['text_cep_hint'] ??
                                        '00000-000',
                                    hintStyle: GoogleFonts.poppins(
                                        fontSize: media.width * sixteen,
                                        color: hintColor),
                                    border: InputBorder.none,
                                    labelText: languages[choosenLanguage]
                                            ['text_cep'] ??
                                        'CEP',
                                    labelStyle: GoogleFonts.poppins(
                                        fontSize: media.width * twelve,
                                        color: hintColor),
                                  ),
                                ),
                              ),
                              if (_loadingCep)
                                Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2, color: theme))),
                            ],
                          ),
                        ),
                        SizedBox(height: media.width * 0.03),
                        // Endereço (obrigatório – borda roxa no foco)
                        _buildLabeledField(
                            addressController,
                            languages[choosenLanguage]['text_address'] ??
                                'Endereço',
                            languages[choosenLanguage]['text_address_hint'] ??
                                'Logradouro',
                            (v) => userAddress = v,
                            focusNode: _addressFocusNode,
                            isFocused: _isAddressFocused),
                        SizedBox(height: media.width * 0.03),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildLabeledField(
                                  numberController,
                                  languages[choosenLanguage]['text_number'] ??
                                      'Número',
                                  languages[choosenLanguage]
                                          ['text_number_hint'] ??
                                      'Nº',
                                  (v) => userNumber = v,
                                  focusNode: _numberFocusNode,
                                  isFocused: _isNumberFocused),
                            ),
                            SizedBox(width: media.width * 0.03),
                            Expanded(
                              flex: 3,
                              child: _buildLabeledField(
                                  complementController,
                                  languages[choosenLanguage]
                                          ['text_complement'] ??
                                      'Complemento',
                                  languages[choosenLanguage]
                                          ['text_complement_hint'] ??
                                      'Apto, bloco...',
                                  (v) => userComplement = v),
                            ),
                          ],
                        ),
                        SizedBox(height: media.width * 0.03),
                        _buildLabeledField(
                            neighborhoodController,
                            languages[choosenLanguage]['text_neighborhood'] ??
                                'Bairro',
                            languages[choosenLanguage]
                                    ['text_neighborhood_hint'] ??
                                'Bairro',
                            (v) => userNeighborhood = v,
                            focusNode: _neighborhoodFocusNode,
                            isFocused: _isNeighborhoodFocused),
                        SizedBox(height: media.width * 0.03),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildLabeledField(
                                  cityController,
                                  languages[choosenLanguage]['text_city'] ??
                                      'Cidade',
                                  languages[choosenLanguage]
                                          ['text_city_hint'] ??
                                      'Cidade',
                                  (v) => userCity = v,
                                  focusNode: _cityFocusNode,
                                  isFocused: _isCityFocused),
                            ),
                            SizedBox(width: media.width * 0.03),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  MyText(
                                    text: languages[choosenLanguage]
                                            ['text_state'] ??
                                        'Estado',
                                    size: media.width * twelve,
                                    color: textColor,
                                    fontweight: FontWeight.w600,
                                  ),
                                  SizedBox(height: media.width * 0.015),
                                  Focus(
                                    focusNode: _stateFocusNode,
                                    child: Container(
                                      height: media.width * 0.13,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: _isStateFocused
                                              ? const Color(0xFF9A03E9)
                                              : textColor,
                                          width: _isStateFocused ? 2.0 : 1.0,
                                        ),
                                      ),
                                      padding: const EdgeInsets.only(
                                          left: 8, right: 8),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: _selectedState.isEmpty
                                              ? null
                                              : _selectedState,
                                          onTap: () =>
                                              _stateFocusNode.requestFocus(),
                                          hint: Text(
                                            languages[choosenLanguage]
                                                    ['text_state_hint'] ??
                                                'UF',
                                            style: GoogleFonts.poppins(
                                                fontSize:
                                                    media.width * fourteen,
                                                color: hintColor),
                                          ),
                                          isExpanded: true,
                                          items: brazilianStates.map((s) {
                                            return DropdownMenuItem<String>(
                                              value: s['uf'],
                                              child: Text(s['uf']!,
                                                  style: GoogleFonts.poppins(
                                                      fontSize: media.width *
                                                          fourteen,
                                                      color: textColor)),
                                            );
                                          }).toList(),
                                          onChanged: (v) {
                                            setState(() {
                                              _selectedState = v ?? '';
                                              userState = _selectedState;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: media.width * 0.03),
                        // Sexo
                        MyText(
                          text:
                              languages[choosenLanguage]['text_sexo'] ?? 'Sexo',
                          size: media.width * twelve,
                          color: textColor,
                          fontweight: FontWeight.w600,
                        ),
                        SizedBox(height: media.width * 0.015),
                        Focus(
                          focusNode: _genderFocusNode,
                          child: Container(
                            width: media.width * 0.9,
                            height: media.width * 0.13,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _isGenderFocused
                                    ? const Color(0xFF9A03E9)
                                    : textColor,
                                width: _isGenderFocused ? 2.0 : 1.0,
                              ),
                            ),
                            padding: const EdgeInsets.only(left: 12, right: 12),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedGender.isEmpty
                                    ? null
                                    : _selectedGender,
                                onTap: () => _genderFocusNode.requestFocus(),
                                hint: Text(
                                  languages[choosenLanguage]
                                          ['text_gender_hint'] ??
                                      'Selecione o gênero',
                                  style: GoogleFonts.poppins(
                                      fontSize: media.width * fourteen,
                                      color: hintColor),
                                ),
                                isExpanded: true,
                                items: genderOptions.map((g) {
                                  return DropdownMenuItem<String>(
                                    value: g['value'],
                                    child: Text(
                                      languages[choosenLanguage]
                                              ['text_gender_${g['value']}'] ??
                                          g['label_pt']!,
                                      style: GoogleFonts.poppins(
                                          fontSize: media.width * fourteen,
                                          color: textColor),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (v) {
                                  setState(() {
                                    _selectedGender = v ?? '';
                                    userGender = _selectedGender;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: media.width * 0.03),
                        // Preferência de atendimento
                        MyText(
                          text: languages[choosenLanguage]
                                  ['text_preference_service'] ??
                              'Preferência de atendimento',
                          size: media.width * twelve,
                          color: textColor,
                          fontweight: FontWeight.w600,
                        ),
                        SizedBox(height: media.width * 0.015),
                        Focus(
                          focusNode: _passengerPreferenceFocusNode,
                          child: Container(
                            width: media.width * 0.9,
                            height: media.width * 0.13,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _isPassengerPreferenceFocused
                                    ? const Color(0xFF9A03E9)
                                    : textColor,
                                width:
                                    _isPassengerPreferenceFocused ? 2.0 : 1.0,
                              ),
                            ),
                            padding: const EdgeInsets.only(left: 12, right: 12),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedPassengerPreference.isEmpty
                                    ? null
                                    : _selectedPassengerPreference,
                                onTap: () => _passengerPreferenceFocusNode
                                    .requestFocus(),
                                hint: Text(
                                  languages[choosenLanguage]
                                          ['text_passenger_preference_hint'] ??
                                      'Preferência de passageiro',
                                  style: GoogleFonts.poppins(
                                      fontSize: media.width * fourteen,
                                      color: hintColor),
                                ),
                                isExpanded: true,
                                items: passengerPreferenceOptions.map((p) {
                                  return DropdownMenuItem<String>(
                                    value: p['value'],
                                    child: Text(
                                      languages[choosenLanguage][
                                              'text_passenger_${p['value']}'] ??
                                          p['label_pt']!,
                                      style: GoogleFonts.poppins(
                                          fontSize: media.width * fourteen,
                                          color: textColor),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (v) {
                                  setState(() {
                                    _selectedPassengerPreference = v ?? 'both';
                                    userPassengerPreference =
                                        _selectedPassengerPreference;
                                  });
                                },
                              ),
                            ),
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
                                    color: _isPhoneFocused
                                        ? const Color(0xFF9A03E9) // Roxo
                                        : textColor,
                                    width: _isPhoneFocused ? 2.0 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Botão de seleção de país
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
                                                                        (languages[choosenLanguage] ?? languages['en'])?['text_search'] ??
                                                                            'Search',
                                                                    hintStyle: GoogleFonts.poppins(
                                                                        fontSize:
                                                                            media.width *
                                                                                sixteen,
                                                                        color:
                                                                            hintColor)),
                                                                style: GoogleFonts.poppins(
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
                                                                                        phcode = i;
                                                                                        Navigator.pop(context);
                                                                                        // Atualizar estado principal e limpar campo
                                                                                        controller.clear();
                                                                                        phnumber = '';
                                                                                        _updatePhoneMaskFormatter();
                                                                                        setState(() {});
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
                                                                                            phcode = i;
                                                                                            Navigator.pop(context);
                                                                                            // Atualizar estado principal e limpar campo
                                                                                            controller.clear();
                                                                                            phnumber = '';
                                                                                            _updatePhoneMaskFormatter();
                                                                                            setState(() {});
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
                                        // Limpar o campo quando o país mudar para aplicar nova máscara
                                        controller.clear();
                                        phnumber = '';
                                        _updatePhoneMaskFormatter();
                                        setState(() {});
                                      },
                                      //input field
                                      child: Container(
                                        height: 50,
                                        alignment: Alignment.center,
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Image.network(
                                              (countries.isNotEmpty &&
                                                      phcode != null &&
                                                      countries[phcode] !=
                                                          null &&
                                                      countries[phcode]
                                                              ['flag'] !=
                                                          null
                                                  ? countries[phcode]['flag']
                                                  : 'https://flagcdn.com/w40/br.png'),
                                              width: 24,
                                              height: 24,
                                              fit: BoxFit.contain,
                                            ),
                                            SizedBox(
                                              width: media.width * 0.02,
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
                                      height: 35,
                                      color: underline,
                                    ),
                                    const SizedBox(width: 10),
                                    // Código do país - centralizado verticalmente
                                    Container(
                                      height: 50,
                                      alignment: Alignment.center,
                                      child: MyText(
                                        text: (countries.isNotEmpty &&
                                                phcode != null &&
                                                countries[phcode] != null &&
                                                countries[phcode]
                                                        ['dial_code'] !=
                                                    null)
                                            ? countries[phcode]['dial_code']
                                                .toString()
                                            : '+55',
                                        size: media.width * sixteen,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Campo de texto com máscara - centralizado verticalmente
                                    Expanded(
                                      child: Container(
                                        height: 50,
                                        alignment: Alignment.centerLeft,
                                        child: TextFormField(
                                          textAlign: TextAlign.start,
                                          controller: controller,
                                          focusNode: _phoneFocusNode,
                                          inputFormatters:
                                              _phoneMaskFormatter != null
                                                  ? [_phoneMaskFormatter!]
                                                  : [],
                                          onChanged: (val) {
                                            // Remove caracteres não numéricos para armazenar apenas números
                                            String digitsOnly = val.replaceAll(
                                                RegExp(r'[^\d]'), '');
                                            setState(() {
                                              phnumber = digitsOnly;
                                            });
                                            if (digitsOnly.length >=
                                                (countries[phcode] != null
                                                    ? countries[phcode][
                                                            'dial_max_length'] ??
                                                        10
                                                    : 10)) {
                                              FocusManager.instance.primaryFocus
                                                  ?.unfocus();
                                            }
                                          },
                                          style: choosenLanguage == 'ar'
                                              ? GoogleFonts.cairo(
                                                  color: textColor,
                                                  fontSize:
                                                      media.width * sixteen,
                                                  letterSpacing: 1,
                                                  height: 1.0,
                                                )
                                              : GoogleFonts.poppins(
                                                  color: textColor,
                                                  fontSize:
                                                      media.width * sixteen,
                                                  letterSpacing: 1,
                                                  height: 1.0,
                                                ),
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            counterText: '',
                                            hintText: _getPhoneHint(),
                                            hintStyle: choosenLanguage == 'ar'
                                                ? GoogleFonts.cairo(
                                                    color: textColor
                                                        .withOpacity(0.7),
                                                    fontSize:
                                                        media.width * sixteen,
                                                  )
                                                : GoogleFonts.poppins(
                                                    color: textColor
                                                        .withOpacity(0.7),
                                                    fontSize:
                                                        media.width * sixteen,
                                                  ),
                                            border: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    vertical: 0),
                                            isDense: true,
                                          ),
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              )
                            : Container(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                if (_error != '')
                  Column(
                    children: [
                      SizedBox(
                          width: media.width * 0.9,
                          child: MyText(
                            text: _error,
                            color: Colors.red,
                            size: media.width * fourteen,
                            textAlign: TextAlign.center,
                          )),
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
                                if (firstname.text.isNotEmpty &&
                                    emailtext.text.isNotEmpty) {
                                  setState(() {
                                    _error = '';
                                  });
                                  loginLoading = true;
                                  valueNotifierLogin.incrementNotifier();
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
                                    userCpf = cpfController.text
                                        .replaceAll(RegExp(r'[^\d]'), '');
                                    userBirthDate = _birthDateToApi(
                                        birthDateController.text);
                                    userCep = cepController.text
                                        .replaceAll(RegExp(r'[^\d]'), '');
                                    userAddress = addressController.text;
                                    userNumber = numberController.text;
                                    userComplement = complementController.text;
                                    userNeighborhood =
                                        neighborhoodController.text;
                                    userCity = cityController.text;
                                    userState = _selectedState;
                                    userGender = _selectedGender;
                                    userPassengerPreference =
                                        _selectedPassengerPreference;
                                    var result =
                                        await validateEmail(emailtext.text);
                                    if (result == 'success') {
                                      isfromomobile = true;
                                      isverifyemail = true;

                                      currentPage = 3;
                                    } else {
                                      setState(() {
                                        _error = result.toString();
                                      });
                                      // showToast();
                                    }
                                  } else {
                                    // showToast();
                                    setState(() {
                                      _error = languages[choosenLanguage]
                                          ['text_email_validation'];
                                    });
                                    // showToast();
                                  }
                                  loginLoading = false;
                                  valueNotifierLogin.incrementNotifier();
                                }
                              },
                              color: (firstname.text.isNotEmpty &&
                                      emailtext.text.isNotEmpty)
                                  ? buttonColor
                                  : Colors.grey,
                              text: languages[choosenLanguage]['text_next'])
                        ],
                      )
                    : Container(
                        width: media.width * 1 - media.width * 0.08,
                        alignment: Alignment.center,
                        child: Button(
                          onTap: () async {
                            if (firstname.text.isNotEmpty &&
                                controller.text.length >=
                                    countries[phcode]['dial_min_length']) {
                              if (lastname.text != '') {
                                name = '${firstname.text} ${lastname.text}';
                              } else {
                                name = firstname.text;
                              }
                              userCpf = cpfController.text
                                  .replaceAll(RegExp(r'[^\d]'), '');
                              userBirthDate =
                                  _birthDateToApi(birthDateController.text);
                              userCep = cepController.text
                                  .replaceAll(RegExp(r'[^\d]'), '');
                              userAddress = addressController.text;
                              userNumber = numberController.text;
                              userComplement = complementController.text;
                              userNeighborhood = neighborhoodController.text;
                              userCity = cityController.text;
                              userState = _selectedState;
                              userGender = _selectedGender;
                              userPassengerPreference =
                                  _selectedPassengerPreference;
                              FocusManager.instance.primaryFocus?.unfocus();
                              loginLoading = true;
                              valueNotifierLogin.incrementNotifier();
                              var val = await otpCall();
                              if (val.value == true) {
                                phoneAuthCheck = true;
                                await phoneAuth(
                                    (countries[phcode]?['dial_code'] ?? '') +
                                        phnumber);
                                value = 0;
                                currentPage = 3;
                              } else {
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
                                  controller.text.length >=
                                      countries[phcode]['dial_min_length'])
                              ? buttonColor
                              : Colors.grey,
                          text: (languages[choosenLanguage] ??
                                  languages['en'])?['text_next'] ??
                              'Next',
                        ),
                      ),
                const SizedBox(
                  height: 25,
                )
              ],
            ),
            //display toast
            (showtoast == true)
                ? Positioned(
                    bottom: media.width * 0.1,
                    left: media.width * 0.06,
                    right: media.width * 0.06,
                    child: Container(
                      padding: EdgeInsets.all(media.width * 0.04),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                                blurRadius: 2.0,
                                spreadRadius: 2.0,
                                color: Colors.black.withOpacity(0.2))
                          ],
                          color: verifyDeclined),
                      child: Text(
                        _error,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                            fontSize: media.width * fourteen,
                            fontWeight: FontWeight.w600,
                            color: textColor),
                      ),
                    ))
                : Container()
          ],
        ),
      ),
    );
  }
}
