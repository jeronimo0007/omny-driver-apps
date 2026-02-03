import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:pinput/pinput.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../functions/functions.dart';
import '../../styles/styles.dart';
import '../../translation/translation.dart';
import '../../widgets/widgets.dart';
import '../loadingPage/loading.dart';
import 'carinformation.dart';
import 'login.dart';
import 'namepage.dart';
import 'requiredinformation.dart';

// ignore: must_be_immutable
class ProfileInformation extends StatefulWidget {
  dynamic from;
  ProfileInformation({Key? key, this.from}) : super(key: key);

  @override
  State<ProfileInformation> createState() => _ProfileInformationState();
}

class _ProfileInformationState extends State<ProfileInformation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  TextEditingController firstname = TextEditingController();
  TextEditingController emailText = TextEditingController();
  TextEditingController lastname = TextEditingController();
  TextEditingController mobile = TextEditingController();
  TextEditingController pinText = TextEditingController();
  TextEditingController cpfController = TextEditingController();
  TextEditingController birthDateController = TextEditingController();
  TextEditingController cepController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController numberController = TextEditingController();
  TextEditingController complementController = TextEditingController();
  TextEditingController neighborhoodController = TextEditingController();
  TextEditingController cityController = TextEditingController();
  MaskTextInputFormatter? _cpfMaskFormatter;
  MaskTextInputFormatter? _cepMaskFormatter;
  MaskTextInputFormatter? _birthDateMaskFormatter;
  String _selectedState = '';
  String _selectedGender = '';
  String _selectedPassengerPreference = 'both';
  bool _isLoading = true;
  bool chooseWorkArea = false;
  String _error = '';
  String _otperror = '';
  bool getOtp = false;

  @override
  void initState() {
    _cpfMaskFormatter = MaskTextInputFormatter(
        mask: '###.###.###-##',
        filter: {"#": RegExp(r'[0-9]')},
        type: MaskAutoCompletionType.lazy);
    _cepMaskFormatter = MaskTextInputFormatter(
        mask: '#####-###',
        filter: {"#": RegExp(r'[0-9]')},
        type: MaskAutoCompletionType.lazy);
    _birthDateMaskFormatter = MaskTextInputFormatter(
        mask: '##/##/####',
        filter: {"#": RegExp(r'[0-9]')},
        type: MaskAutoCompletionType.lazy);
    countryCode();
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  String _birthDateToApi(String ddMmYyyy) {
    final digits = ddMmYyyy.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length != 8) return '';
    return '${digits.substring(4, 8)}-${digits.substring(2, 4)}-${digits.substring(0, 2)}';
  }

  Future<void> _onCepBlur() async {
    final cep = cepController.text.replaceAll(RegExp(r'[^\d]'), '');
    if (cep.length != 8) return;
    final result = await fetchCep(cep);
    if (result != null && mounted) {
      setState(() {
        addressController.text = result['logradouro'] ?? '';
        neighborhoodController.text = result['bairro'] ?? '';
        cityController.text = result['localidade'] ?? '';
        _selectedState = result['uf'] ?? '';
      });
    }
  }

  void _syncGlobalsFromForm() {
    userCpf = cpfController.text.replaceAll(RegExp(r'[^\d]'), '');
    userBirthDate = _birthDateToApi(birthDateController.text);
    userCep = cepController.text.replaceAll(RegExp(r'[^\d]'), '');
    userAddress = addressController.text;
    userNumber = numberController.text;
    userComplement = complementController.text;
    userNeighborhood = neighborhoodController.text;
    userCity = cityController.text;
    userState = _selectedState;
    userGender = _selectedGender;
    userPassengerPreference = _selectedPassengerPreference;
  }

  Widget _buildEditFieldLabel(String label) {
    var media = MediaQuery.of(context).size;
    return SizedBox(
      width: media.width * 0.9,
      child: MyText(
          text: label,
          size: media.width * sixteen,
          fontweight: FontWeight.bold),
    );
  }

  Widget _buildEditTextField(TextEditingController ctrl, String hint) {
    var media = MediaQuery.of(context).size;
    return Container(
      height: media.width * 0.13,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color:
                (isDarkTheme == true) ? textColor.withOpacity(0.4) : underline),
        color: (isDarkTheme == true) ? Colors.black : const Color(0xffF8F8F8),
      ),
      padding: const EdgeInsets.only(left: 12, right: 12),
      child: TextFormField(
        controller: ctrl,
        onChanged: (_) => setState(() {}),
        style: GoogleFonts.poppins(
            fontSize: media.width * sixteen, color: textColor),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(
              fontSize: media.width * sixteen, color: hintColor),
          border: InputBorder.none,
        ),
      ),
    );
  }

  countryCode() async {
    if (widget.from == null) {
      firstname.text = name.toString().split(' ')[0];
      lastname.text = name.toString().split(' ')[1];
      mobile.text = phnumber;
      emailText.text = email;
    } else {
      firstname.text = userDetails['name'].toString().split(' ')[0];
      lastname.text = (userDetails['name'].toString().split(' ').length > 1)
          ? userDetails['name'].toString().split(' ')[1]
          : '';
      mobile.text = userDetails['mobile'];
      emailText.text = userDetails['email'];
      userCpf = userDetails['document']?.toString() ?? userCpf;
      userBirthDate = userDetails['birth_date']?.toString() ?? userBirthDate;
      userCep = userDetails['postal_code']?.toString() ??
          userDetails['zipcode']?.toString() ??
          userCep;
      userAddress = userDetails['address']?.toString() ?? userAddress;
      userNumber = userDetails['address_number']?.toString() ?? userNumber;
      userComplement = userDetails['complement']?.toString() ?? userComplement;
      userNeighborhood =
          userDetails['neighborhood']?.toString() ?? userNeighborhood;
      userCity = userDetails['city']?.toString() ?? userCity;
      userState = userDetails['state']?.toString() ?? userState;
      userGender = userDetails['gender']?.toString() ?? userGender;
      userPassengerPreference =
          userDetails['passenger_preference']?.toString() ??
              userPassengerPreference;
      _selectedState = userState;
      _selectedGender = userGender;
      _selectedPassengerPreference = userPassengerPreference;
      final doc = (userDetails['document'] ?? userCpf).toString();
      final docDigits = doc.replaceAll(RegExp(r'[^\d]'), '');
      if (docDigits.length == 11) {
        cpfController.text =
            '${docDigits.substring(0, 3)}.${docDigits.substring(3, 6)}.${docDigits.substring(6, 9)}-${docDigits.substring(9)}';
      } else {
        cpfController.text = doc;
      }
      if (userBirthDate.isNotEmpty && userBirthDate.length >= 10) {
        final p = userBirthDate.split('-');
        if (p.length == 3) birthDateController.text = '${p[2]}/${p[1]}/${p[0]}';
      }
      final pc =
          (userDetails['postal_code'] ?? userDetails['zipcode'] ?? userCep)
              .toString();
      final pcDigits = pc.replaceAll(RegExp(r'[^\d]'), '');
      if (pcDigits.length == 8) {
        cepController.text =
            '${pcDigits.substring(0, 5)}-${pcDigits.substring(5)}';
      } else {
        cepController.text = pc;
      }
      addressController.text = userAddress;
      numberController.text = userNumber;
      complementController.text = userComplement;
      neighborhoodController.text = userNeighborhood;
      cityController.text = userCity;
    }
    _isLoading = false;
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Material(
      child: Directionality(
        textDirection: (languageDirection == 'rtl')
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: Stack(
          children: [
            Container(
              padding: EdgeInsets.only(
                  left: media.width * 0.05, right: media.width * 0.05),
              height: media.height * 1,
              width: media.width * 1,
              color: page,
              child: Column(
                children: [
                  SizedBox(
                    height:
                        media.width * 0.05 + MediaQuery.of(context).padding.top,
                  ),
                  Stack(
                    children: [
                      Container(
                        padding: EdgeInsets.only(bottom: media.width * 0.05),
                        width: media.width * 1,
                        alignment: Alignment.center,
                        child: MyText(
                            text: languages[choosenLanguage]['text_reqinfo'],
                            size: media.width * sixteen),
                      ),
                      Positioned(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            InkWell(
                                onTap: () {
                                  Navigator.pop(context);
                                },
                                child: Icon(Icons.arrow_back_ios,
                                    color: textColor)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: media.width * 0.05,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          SizedBox(
                            width: media.width * 0.9,
                            child: MyText(
                              text: languages[choosenLanguage]
                                      ['text_profile_info']
                                  .toString()
                                  .toUpperCase(),
                              size: media.width * fourteen,
                              fontweight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(
                            height: media.width * 0.05,
                          ),
                          SizedBox(
                            width: media.width * 0.9,
                            child: MyText(
                              text: languages[choosenLanguage]['text_name'],
                              size: media.width * sixteen,
                              fontweight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(
                            height: media.width * 0.05,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                    height: media.width * 0.13,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: (isDarkTheme == true)
                                                ? textColor.withOpacity(0.4)
                                                : underline),
                                        color: (isDarkTheme == true)
                                            ? Colors.black
                                            : const Color(0xffF8F8F8)),
                                    padding: const EdgeInsets.only(
                                        left: 5, right: 5),
                                    child: MyTextField(
                                      textController: firstname,
                                      hinttext: languages[choosenLanguage]
                                          ['text_first_name'],
                                      onTap: (val) {
                                        setState(() {});
                                      },
                                      readonly:
                                          (widget.from == null) ? true : false,
                                    )),
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
                                            color: (isDarkTheme == true)
                                                ? textColor.withOpacity(0.4)
                                                : underline),
                                        color: (isDarkTheme == true)
                                            ? Colors.black
                                            : const Color(0xffF8F8F8)),
                                    padding: const EdgeInsets.only(
                                        left: 5, right: 5),
                                    child: MyTextField(
                                      textController: lastname,
                                      hinttext: languages[choosenLanguage]
                                          ['text_last_name'],
                                      onTap: (val) {
                                        setState(() {});
                                      },
                                      readonly:
                                          (widget.from == null) ? true : false,
                                    )),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: media.height * 0.02,
                          ),
                          SizedBox(
                            width: media.width * 0.9,
                            child: MyText(
                              text: languages[choosenLanguage]['text_mob_num'],
                              size: media.width * sixteen,
                              fontweight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(
                            height: media.height * 0.02,
                          ),
                          Container(
                            height: media.width * 0.13,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: (isDarkTheme == true)
                                        ? textColor.withOpacity(0.4)
                                        : underline),
                                color: (isDarkTheme == true)
                                    ? Colors.black
                                    : const Color(0xffF8F8F8)),
                            padding: const EdgeInsets.only(left: 5, right: 5),
                            child: MyTextField(
                              textController: mobile,
                              hinttext: languages[choosenLanguage]
                                  ['text_enter_phone_number'],
                              onTap: (val) {
                                setState(() {});
                              },
                              readonly: widget.from == 'edit',
                            ),
                          ),
                          SizedBox(
                            height: media.height * 0.02,
                          ),
                          SizedBox(
                            width: media.width * 0.9,
                            child: MyText(
                              text: languages[choosenLanguage]['text_email'],
                              size: media.width * sixteen,
                              fontweight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(
                            height: media.height * 0.02,
                          ),
                          Container(
                              height: media.width * 0.13,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: (isDarkTheme == true)
                                          ? textColor.withOpacity(0.4)
                                          : underline),
                                  color: (isDarkTheme == true)
                                      ? Colors.black
                                      : const Color(0xffF8F8F8)),
                              padding: const EdgeInsets.only(left: 5, right: 5),
                              child: MyTextField(
                                textController: emailText,
                                hinttext: languages[choosenLanguage]
                                    ['text_enter_email'],
                                onTap: (val) {
                                  setState(() {});
                                },
                                readonly: widget.from == 'edit',
                              )),
                          if (widget.from == 'edit') ...[
                            SizedBox(height: media.height * 0.02),
                            _buildEditFieldLabel(languages[choosenLanguage]
                                    ['text_cpf'] ??
                                'CPF'),
                            SizedBox(height: media.height * 0.01),
                            Container(
                              height: media.width * 0.13,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: (isDarkTheme == true)
                                        ? textColor.withOpacity(0.4)
                                        : underline),
                                color: (isDarkTheme == true)
                                    ? Colors.black
                                    : const Color(0xffF8F8F8),
                              ),
                              padding:
                                  const EdgeInsets.only(left: 12, right: 12),
                              child: TextFormField(
                                controller: cpfController,
                                readOnly: true,
                                inputFormatters: _cpfMaskFormatter != null
                                    ? [_cpfMaskFormatter!]
                                    : [],
                                onChanged: (_) => setState(() {}),
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
                                ),
                              ),
                            ),
                            SizedBox(height: media.height * 0.02),
                            _buildEditFieldLabel(languages[choosenLanguage]
                                    ['text_birth_date'] ??
                                'Data de nascimento'),
                            SizedBox(height: media.height * 0.01),
                            Container(
                              height: media.width * 0.13,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: (isDarkTheme == true)
                                        ? textColor.withOpacity(0.4)
                                        : underline),
                                color: (isDarkTheme == true)
                                    ? Colors.black
                                    : const Color(0xffF8F8F8),
                              ),
                              padding:
                                  const EdgeInsets.only(left: 12, right: 12),
                              child: TextFormField(
                                controller: birthDateController,
                                inputFormatters: _birthDateMaskFormatter != null
                                    ? [_birthDateMaskFormatter!]
                                    : [],
                                onChanged: (_) => setState(() {}),
                                keyboardType: TextInputType.number,
                                style: GoogleFonts.poppins(
                                    fontSize: media.width * sixteen,
                                    color: textColor),
                                decoration: InputDecoration(
                                  hintText: languages[choosenLanguage]
                                          ['text_birth_date_hint'] ??
                                      'dd/mm/aaaa',
                                  hintStyle: GoogleFonts.poppins(
                                      fontSize: media.width * sixteen,
                                      color: hintColor),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            SizedBox(height: media.height * 0.02),
                            _buildEditFieldLabel(languages[choosenLanguage]
                                    ['text_cep'] ??
                                'CEP'),
                            SizedBox(height: media.height * 0.01),
                            Container(
                              height: media.width * 0.13,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: (isDarkTheme == true)
                                        ? textColor.withOpacity(0.4)
                                        : underline),
                                color: (isDarkTheme == true)
                                    ? Colors.black
                                    : const Color(0xffF8F8F8),
                              ),
                              padding:
                                  const EdgeInsets.only(left: 12, right: 12),
                              child: TextFormField(
                                controller: cepController,
                                inputFormatters: _cepMaskFormatter != null
                                    ? [_cepMaskFormatter!]
                                    : [],
                                onChanged: (val) {
                                  userCep =
                                      val.replaceAll(RegExp(r'[^\d]'), '');
                                  if (userCep.length == 8) _onCepBlur();
                                  setState(() {});
                                },
                                onTapOutside: (_) => _onCepBlur(),
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
                                ),
                              ),
                            ),
                            SizedBox(height: media.height * 0.02),
                            _buildEditFieldLabel(languages[choosenLanguage]
                                    ['text_address'] ??
                                'Endereço'),
                            SizedBox(height: media.height * 0.01),
                            _buildEditTextField(
                                addressController,
                                languages[choosenLanguage]
                                        ['text_address_hint'] ??
                                    'Logradouro'),
                            SizedBox(height: media.height * 0.02),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildEditFieldLabel(
                                          languages[choosenLanguage]
                                                  ['text_number'] ??
                                              'Número'),
                                      SizedBox(height: media.height * 0.01),
                                      _buildEditTextField(
                                          numberController,
                                          languages[choosenLanguage]
                                                  ['text_number_hint'] ??
                                              'Nº'),
                                    ],
                                  ),
                                ),
                                SizedBox(width: media.width * 0.03),
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildEditFieldLabel(
                                          languages[choosenLanguage]
                                                  ['text_complement'] ??
                                              'Complemento'),
                                      SizedBox(height: media.height * 0.01),
                                      _buildEditTextField(
                                          complementController,
                                          languages[choosenLanguage]
                                                  ['text_complement_hint'] ??
                                              'Apto, bloco...'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: media.height * 0.02),
                            _buildEditFieldLabel(languages[choosenLanguage]
                                    ['text_neighborhood'] ??
                                'Bairro'),
                            SizedBox(height: media.height * 0.01),
                            _buildEditTextField(
                                neighborhoodController,
                                languages[choosenLanguage]
                                        ['text_neighborhood_hint'] ??
                                    'Bairro'),
                            SizedBox(height: media.height * 0.02),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildEditFieldLabel(
                                          languages[choosenLanguage]
                                                  ['text_city'] ??
                                              'Cidade'),
                                      SizedBox(height: media.height * 0.01),
                                      _buildEditTextField(
                                          cityController,
                                          languages[choosenLanguage]
                                                  ['text_city_hint'] ??
                                              'Cidade'),
                                    ],
                                  ),
                                ),
                                SizedBox(width: media.width * 0.03),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildEditFieldLabel(
                                          languages[choosenLanguage]
                                                  ['text_state'] ??
                                              'Estado'),
                                      SizedBox(height: media.height * 0.01),
                                      DropdownSearch<String>(
                                        selectedItem: _selectedState.isEmpty ? null : _selectedState,
                                        items: brazilianStates.map((s) => s['uf']!).toList(),
                                        itemAsString: (String s) {
                                          final e = brazilianStates.firstWhere(
                                            (e) => e['uf'] == s,
                                            orElse: () => {'uf': s, 'name': s},
                                          );
                                          return '${e['uf']} - ${e['name']}';
                                        },
                                        onChanged: (v) => setState(() => _selectedState = v ?? ''),
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
                                            hintText: languages[choosenLanguage]['text_state_hint'] ?? 'UF',
                                            hintStyle: GoogleFonts.poppins(fontSize: media.width * fourteen, color: hintColor),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                            filled: true,
                                            fillColor: (isDarkTheme == true) ? Colors.black : const Color(0xffF8F8F8),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: media.height * 0.02),
                            _buildEditFieldLabel(languages[choosenLanguage]
                                    ['text_gender'] ??
                                'Sexo'),
                            SizedBox(height: media.height * 0.01),
                            DropdownSearch<String>(
                              selectedItem: _selectedGender.isEmpty ? null : _selectedGender,
                              items: genderOptions.map((g) => g['value']!).toList(),
                              itemAsString: (String v) =>
                                  languages[choosenLanguage]['text_gender_$v'] ??
                                  genderOptions.firstWhere((e) => e['value'] == v, orElse: () => {'value': v, 'label_pt': v})['label_pt']!,
                              onChanged: (v) => setState(() => _selectedGender = v ?? ''),
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
                                  hintText: languages[choosenLanguage]['text_gender_hint'] ?? 'Selecione',
                                  hintStyle: GoogleFonts.poppins(fontSize: media.width * fourteen, color: hintColor),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  filled: true,
                                  fillColor: (isDarkTheme == true) ? Colors.black : const Color(0xffF8F8F8),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                            ),
                            SizedBox(height: media.height * 0.02),
                            _buildEditFieldLabel(languages[choosenLanguage]
                                    ['text_passenger_preference'] ??
                                'Preferência de atendimento'),
                            SizedBox(height: media.height * 0.01),
                            DropdownSearch<String>(
                              selectedItem: _selectedPassengerPreference.isEmpty ? null : _selectedPassengerPreference,
                              items: passengerPreferenceOptions.map((p) => p['value']!).toList(),
                              itemAsString: (String v) =>
                                  languages[choosenLanguage]['text_passenger_$v'] ??
                                  passengerPreferenceOptions.firstWhere((e) => e['value'] == v, orElse: () => {'value': v, 'label_pt': v})['label_pt']!,
                              onChanged: (v) => setState(() => _selectedPassengerPreference = v ?? 'both'),
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
                                  hintText: languages[choosenLanguage]['text_passenger_preference_hint'] ?? 'Preferência',
                                  hintStyle: GoogleFonts.poppins(fontSize: media.width * fourteen, color: hintColor),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  filled: true,
                                  fillColor: (isDarkTheme == true) ? Colors.black : const Color(0xffF8F8F8),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                            ),
                            SizedBox(height: media.height * 0.02),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (_error != '')
                    Container(
                      width: media.width * 0.9,
                      padding: EdgeInsets.only(
                          top: media.width * 0.02, bottom: media.width * 0.02),
                      child: MyText(
                        text: _error,
                        size: media.width * twelve,
                        color: Colors.red,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  Button(
                      onTap: () async {
                        setState(() {
                          _error = '';
                        });
                        String pattern =
                            r"^[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?\.)+[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])*$";

                        RegExp regex = RegExp(pattern);
                        if (regex.hasMatch(emailText.text)) {
                          if (widget.from == null) {
                            if (myServiceId != '' && myServiceId != null) {
                              profileCompleted = true;
                              Navigator.pop(context, true);
                            }
                          } else {
                            setState(() {
                              _isLoading = true;
                            });
                            // ignore: prefer_typing_uninitialized_variables
                            var nav;
                            if (userDetails['mobile'] == mobile.text) {
                              _syncGlobalsFromForm();
                              nav = await updateProfile(
                                '${firstname.text} ${lastname.text}',
                                emailText.text,
                              );
                              if (nav != 'success') {
                                _error = nav.toString();
                              } else {
                                // ignore: use_build_context_synchronously
                                Navigator.pop(context, true);
                              }
                            } else {
                              await phoneAuth(mobile.text);
                              setState(() {
                                getOtp = true;
                              });
                            }

                            setState(() {
                              _isLoading = false;
                            });
                          }
                        } else {
                          setState(() {
                            _error = languages[choosenLanguage]
                                ['text_email_validation'];
                          });
                        }
                      },
                      text: languages[choosenLanguage]['text_confirm']),
                  const SizedBox(
                    height: 20,
                  )
                ],
              ),
            ),
            if (getOtp == true)
              Positioned(
                  child: Container(
                height: media.height * 1,
                width: media.width * 1,
                color: Colors.transparent.withOpacity(0.2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: media.width * 0.9,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                getOtp = false;
                              });
                            },
                            child: Container(
                              height: media.width * 0.1,
                              width: media.width * 0.1,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle, color: page),
                              child:
                                  Icon(Icons.cancel_outlined, color: textColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: media.width * 0.025,
                    ),
                    Container(
                      width: media.width * 0.9,
                      padding: EdgeInsets.all(media.width * 0.05),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12), color: page),
                      child: Column(
                        children: [
                          SizedBox(
                            width: media.width * 0.8,
                            child: MyText(
                              text:
                                  '${languages[choosenLanguage]['text_enter_otp']}${mobile.text}',
                              size: media.width * fourteen,
                              fontweight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(
                            height: media.width * 0.025,
                          ),
                          SizedBox(
                            width: media.width * 0.8,
                            child: Pinput(
                              length: 6,
                              onChanged: (val) {
                                // print(val);
                              },
                              // onSubmitted: (String val) {},
                              controller: pinText,
                            ),
                          ),
                          if (_otperror != '')
                            SizedBox(
                              height: media.width * 0.05,
                            ),
                          Container(
                            width: media.width * 0.8,
                            padding:
                                EdgeInsets.only(bottom: media.width * 0.025),
                            child: MyText(
                              text: _otperror,
                              size: media.width * twelve,
                              color: Colors.red,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Button(
                              onTap: () async {
                                if (pinText.text.length == 6) {
                                  setState(() {
                                    _otperror = '';
                                    _isLoading = true;
                                  });
                                  try {
                                    PhoneAuthCredential credential =
                                        PhoneAuthProvider.credential(
                                            verificationId: verId,
                                            smsCode: pinText.text);

                                    // Sign the user in (or link) with the credential
                                    await FirebaseAuth.instance
                                        .signInWithCredential(credential);
                                    _syncGlobalsFromForm();
                                    await updateProfile(
                                      '${firstname.text} ${lastname.text}',
                                      emailText.text,
                                    );
                                    // navigate(verify);
                                  } on FirebaseAuthException catch (error) {
                                    if (error.code ==
                                        'invalid-verification-code') {
                                      setState(() {
                                        pinText.clear();
                                        _otperror = languages[choosenLanguage]
                                            ['text_otp_error'];
                                      });
                                    }
                                  }
                                  setState(() {
                                    pinText.clear();
                                    getOtp = false;
                                    _isLoading = false;
                                  });
                                } else {
                                  phoneAuth(mobile.text);
                                }
                              },
                              text: (pinText.text.length == 6)
                                  ? languages[choosenLanguage]['text_confirm']
                                  : languages[choosenLanguage]
                                      ['text_resend_code']),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).viewInsets.bottom,
                    )
                  ],
                ),
              )),
            if (_isLoading == true) const Positioned(child: Loading())
          ],
        ),
      ),
    );
  }
}
