import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../functions/functions.dart';
import '../../styles/styles.dart';
import '../../translation/translation.dart';
import '../../widgets/widgets.dart';
import '../loadingPage/loading.dart';
import '../login/login.dart';
import '../noInternet/nointernet.dart';
import 'requiredinformation.dart';

// ignore: must_be_immutable
class CarInformation extends StatefulWidget {
  int? frompage;
  CarInformation({this.frompage, Key? key}) : super(key: key);

  @override
  State<CarInformation> createState() => _CarInformationState();
}

bool isowner = false;
dynamic myVehicalType;
dynamic myVehicleIconFor = '';
List vehicletypelist = [];
dynamic vehicleColor;
dynamic myServiceLocation;
dynamic myServiceId;
String vehicleModelId = '';
dynamic vehicleModelName;
dynamic modelYear;
String vehicleMakeId = '';
dynamic vehicleNumber;
dynamic vehicleMakeName;
String myVehicleId = '';
String mycustommake = '';
String mycustommodel = '';
List choosevehicletypelist = [];

class _CarInformationState extends State<CarInformation> {
  bool loaded = false;
  bool chooseWorkArea = false;
  bool _isLoading = false;
  String _error = '';
  bool chooseVehicleMake = false;
  bool chooseVehicleModel = false;
  bool chooseVehicleType = false;
  String dateError = '';
  bool vehicleAdded = false;
  String uploadError = '';
  bool iscustommake = false;

  // Variáveis para rastrear campos com erro
  bool _hasTransportTypeError = false;
  bool _hasServiceLocationError = false;
  bool _hasVehicleTypeError = false;
  bool _hasVehicleMakeError = false;
  bool _hasVehicleModelError = false;
  bool _hasModelYearError = false;
  bool _hasVehicleNumberError = false;
  bool _hasVehicleColorError = false;

  // FocusNodes para detectar quando um campo está em foco
  final FocusNode _transportTypeFocus = FocusNode();
  final FocusNode _serviceLocationFocus = FocusNode();
  final FocusNode _vehicleTypeFocus = FocusNode();
  final FocusNode _vehicleMakeFocus = FocusNode();
  final FocusNode _vehicleModelFocus = FocusNode();
  final FocusNode _modelYearFocus = FocusNode();
  final FocusNode _vehicleNumberFocus = FocusNode();
  final FocusNode _vehicleColorFocus = FocusNode();
  final FocusNode _referralFocus = FocusNode();

  // Controle de tempo para chamada da API de tipos de veículo
  DateTime? _lastVehicleTypeApiCall;

  // Lista de anos (ano atual até 16 anos atrás)
  List<String> get vehicleYears {
    final currentYear = DateTime.now().year;
    final years = <String>[];
    for (int i = 0; i <= 16; i++) {
      years.add((currentYear - i).toString());
    }
    return years;
  }

  // Lista de cores do veículo
  final List<String> vehicleColors = [
    'Branco',
    'Preto',
    'Prata / Prateado',
    'Cinza / Grafite',
    'Vermelho',
    'Azul',
    'Verde',
    'Amarelo',
    'Marrom',
    'Bege',
    'Dourado',
    'Laranja',
    'Roxo',
    'Rosa',
    'Vinho / Bordô',
    'Creme / Marfim',
    'Turquesa / Azul-claro',
    'Bronze',
  ];
  TextEditingController modelcontroller = TextEditingController();
  TextEditingController colorcontroller = TextEditingController();
  TextEditingController numbercontroller = TextEditingController();
  TextEditingController referralcontroller = TextEditingController();
  TextEditingController custommakecontroller = TextEditingController();
  TextEditingController custommodelcontroller = TextEditingController();

  //navigate
  navigate() {
    Navigator.pop(context, true);
    serviceLocations.clear();
    vehicleMake.clear();
    vehicleModel.clear();
    vehicleType.clear();
  }

  navigateref() {
    // Se foi um novo cadastro (frompage == 1), navega para RequiredInformation
    // Caso contrário, apenas volta para a tela anterior
    if (widget.frompage == 1) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const RequiredInformation()),
        (route) => false,
      );
    } else {
      Navigator.pop(context, true);
    }
  }

  navigateLogout() {
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
        (route) => false);
  }

  @override
  void initState() {
    getServiceLoc();
    super.initState();

    // Adicionar listeners para atualizar o estado quando o foco mudar
    _transportTypeFocus.addListener(() => setState(() {}));
    _serviceLocationFocus.addListener(() => setState(() {}));
    _vehicleTypeFocus.addListener(() => setState(() {}));
    _vehicleMakeFocus.addListener(() => setState(() {}));
    _vehicleModelFocus.addListener(() => setState(() {}));
    _modelYearFocus.addListener(() => setState(() {}));
    _vehicleNumberFocus.addListener(() => setState(() {}));
    _vehicleColorFocus.addListener(() => setState(() {}));
    _referralFocus.addListener(() => setState(() {}));

    // Adicionar listeners aos controllers de texto para detectar mudanças e limpar erros
    numbercontroller.addListener(() {
      setState(() {
        if (numbercontroller.text.isNotEmpty) {
          _hasVehicleNumberError = false;
        }
      });
    });
    referralcontroller.addListener(() => setState(() {}));
    custommakecontroller.addListener(() {
      setState(() {
        if (custommakecontroller.text.isNotEmpty) {
          _hasVehicleMakeError = false;
        }
      });
    });
    custommodelcontroller.addListener(() {
      setState(() {
        if (custommodelcontroller.text.isNotEmpty) {
          _hasVehicleModelError = false;
        }
      });
    });
  }

  @override
  void dispose() {
    _transportTypeFocus.dispose();
    _serviceLocationFocus.dispose();
    _vehicleTypeFocus.dispose();
    _vehicleMakeFocus.dispose();
    _vehicleModelFocus.dispose();
    _modelYearFocus.dispose();
    _vehicleNumberFocus.dispose();
    _vehicleColorFocus.dispose();
    _referralFocus.dispose();
    super.dispose();
  }

  // Função helper para determinar a cor da borda baseado no estado
  Color _getBorderColor({
    required bool isActive, // Quando a lista está aberta ou campo está em foco
    required bool isFilled,
    bool hasError = false, // Quando o campo tem erro de validação
  }) {
    if (hasError) {
      return Colors.red; // Vermelho quando há erro
    } else if (isActive) {
      return Colors.purple; // Roxo quando em foco/ativo
    } else if (isFilled) {
      return Colors.green.shade300; // Verde claro quando preenchido
    } else {
      return textColor.withOpacity(0.3); // Cor padrão
    }
  }

  // Função para validar campos e marcar erros
  void _validateFields() {
    setState(() {
      // Limpar erros anteriores
      _hasTransportTypeError = false;
      _hasServiceLocationError = false;
      _hasVehicleTypeError = false;
      _hasVehicleMakeError = false;
      _hasVehicleModelError = false;
      _hasModelYearError = false;
      _hasVehicleNumberError = false;
      _hasVehicleColorError = false;

      // Validar cada campo apenas se ele estiver visível/necessário
      if (widget.frompage == 1 && transportType.isEmpty) {
        _hasTransportTypeError = true;
      }
      if (widget.frompage == 1 &&
          isowner != true &&
          transportType.isNotEmpty &&
          (myServiceId == null || myServiceId == '')) {
        _hasServiceLocationError = true;
      }
      if ((widget.frompage == 1 &&
              isowner == false &&
              (myServiceId != null && myServiceId != '')) ||
          (widget.frompage == 1 &&
              transportType.isNotEmpty &&
              enabledModule == 'both') ||
          (widget.frompage != 1) ||
          (isowner == true)) {
        if (myVehicleId == '') {
          _hasVehicleTypeError = true;
        }
      }
      if (myVehicleId != '') {
        if (iscustommake) {
          if (mycustommake == '') {
            _hasVehicleMakeError = true;
          }
        } else {
          if (vehicleMakeId == '') {
            _hasVehicleMakeError = true;
          }
        }
      }
      if ((iscustommake && mycustommake != '') ||
          (!iscustommake && vehicleMakeId != '')) {
        if (iscustommake) {
          if (mycustommodel == '') {
            _hasVehicleModelError = true;
          }
        } else {
          if (vehicleModelId == '') {
            _hasVehicleModelError = true;
          }
        }
      }
      if ((iscustommake && mycustommodel != '') ||
          (!iscustommake && vehicleModelId != '')) {
        if (modelYear == null || modelYear.toString().isEmpty) {
          _hasModelYearError = true;
        }
        if (numbercontroller.text.isEmpty) {
          _hasVehicleNumberError = true;
        }
        if (vehicleColor == null || vehicleColor.toString().isEmpty) {
          _hasVehicleColorError = true;
        }
      }
    });
  }

  // Função para mostrar popup de confirmação com resumo das informações
  Future<void> _showConfirmationDialog() async {
    var media = MediaQuery.of(context).size;

    // Coletar informações para exibir
    String transportTypeText = '';
    if (transportType.isNotEmpty) {
      transportTypeText = transportType == 'taxi'
          ? (languages[choosenLanguage]?['text_taxi_']?.toString() ?? 'Taxi')
          : transportType == 'delivery'
              ? (languages[choosenLanguage]?['text_delivery']?.toString() ??
                  'Delivery')
              : (languages[choosenLanguage]?['text_both']?.toString() ??
                  'Both');
    }

    String serviceLocationText = myServiceLocation?.toString() ??
        (languages[choosenLanguage]?['text_service_loc']?.toString() ??
            'Service Location');

    String vehicleTypeText = '';
    if (myVehicleId != '' && vehicleType.isNotEmpty) {
      try {
        vehicleTypeText = vehicleType
            .firstWhere((element) => element['id'] == myVehicleId)['name']
            .toString();
      } catch (e) {
        vehicleTypeText =
            languages[choosenLanguage]?['text_vehicle_type']?.toString() ??
                'Vehicle Type';
      }
    }

    String vehicleMakeText = '';
    if (iscustommake) {
      vehicleMakeText = mycustommake;
    } else if (vehicleMakeId != '' && vehicleMake.isNotEmpty) {
      try {
        vehicleMakeText = vehicleMake
            .firstWhere(
                (element) => element['id'].toString() == vehicleMakeId)['name']
            .toString();
      } catch (e) {
        vehicleMakeText = vehicleMakeName?.toString() ?? '';
      }
    }

    String vehicleModelText = '';
    if (iscustommake) {
      vehicleModelText = mycustommodel;
    } else if (vehicleModelId != '' && vehicleModel.isNotEmpty) {
      try {
        vehicleModelText = vehicleModel
            .firstWhere(
                (element) => element['id'].toString() == vehicleModelId)['name']
            .toString();
      } catch (e) {
        vehicleModelText = vehicleModelName?.toString() ?? '';
      }
    }

    String modelYearText = modelYear?.toString() ?? '';
    String vehicleNumberText = numbercontroller.text;
    String vehicleColorText = vehicleColor?.toString() ?? colorcontroller.text;
    String referralText = loginReferralCode.trim();

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(media.width * 0.05),
            decoration: BoxDecoration(
              color: page,
              borderRadius: BorderRadius.circular(20),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: MyText(
                          text: languages[choosenLanguage]?['text_confirm']
                                  ?.toString() ??
                              'Confirm',
                          size: media.width * eighteen,
                          fontweight: FontWeight.bold,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (userDetails.isNotEmpty && userDetails['name'] != null)
                        Expanded(
                          child: MyText(
                            text: userDetails['name'].toString(),
                            size: media.width * eighteen,
                            fontweight: FontWeight.bold,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                          ),
                        ),
                      SizedBox(width: media.width * 0.02),
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        child: Icon(
                          Icons.close,
                          color: textColor,
                          size: media.width * 0.06,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: media.width * 0.05),
                  MyText(
                    text: languages[choosenLanguage]?['text_car_info']
                            ?.toString() ??
                        'Car Information',
                    size: media.width * sixteen,
                    fontweight: FontWeight.w600,
                    color: buttonColor,
                  ),
                  SizedBox(height: media.width * 0.03),
                  if (widget.frompage == 1 && transportType.isNotEmpty)
                    _buildInfoRow(
                      media,
                      (languages[choosenLanguage] ??
                                  languages['en'])?['text_label_transport_type']
                              ?.toString() ??
                          'Transport Type',
                      transportTypeText,
                    ),
                  if (widget.frompage == 1 &&
                      isowner == false &&
                      myServiceId != null &&
                      myServiceId != '')
                    _buildInfoRow(
                      media,
                      (languages[choosenLanguage] ?? languages['en'])?[
                                  'text_label_service_location']
                              ?.toString() ??
                          'Service Location',
                      serviceLocationText,
                    ),
                  if (vehicleTypeText.isNotEmpty)
                    _buildInfoRow(
                      media,
                      (languages[choosenLanguage] ??
                                  languages['en'])?['text_label_type']
                              ?.toString() ??
                          'Type',
                      vehicleTypeText,
                    ),
                  if (vehicleMakeText.isNotEmpty)
                    _buildInfoRow(
                      media,
                      (languages[choosenLanguage] ??
                                  languages['en'])?['text_label_make']
                              ?.toString() ??
                          'Make',
                      vehicleMakeText,
                    ),
                  if (vehicleModelText.isNotEmpty)
                    _buildInfoRow(
                      media,
                      (languages[choosenLanguage] ??
                                  languages['en'])?['text_label_model']
                              ?.toString() ??
                          'Model',
                      vehicleModelText,
                    ),
                  if (modelYearText.isNotEmpty)
                    _buildInfoRow(
                      media,
                      (languages[choosenLanguage] ??
                                  languages['en'])?['text_label_year']
                              ?.toString() ??
                          'Year',
                      modelYearText,
                    ),
                  if (vehicleNumberText.isNotEmpty)
                    _buildInfoRow(
                      media,
                      (languages[choosenLanguage] ??
                                  languages['en'])?['text_label_plate']
                              ?.toString() ??
                          'Plate',
                      vehicleNumberText,
                    ),
                  if (vehicleColorText.isNotEmpty)
                    _buildInfoRow(
                      media,
                      (languages[choosenLanguage] ??
                                  languages['en'])?['text_label_color']
                              ?.toString() ??
                          'Color',
                      vehicleColorText,
                    ),
                  if (referralText.isNotEmpty)
                    _buildInfoRow(
                      media,
                      (languages[choosenLanguage] ??
                                  languages['en'])?['text_label_referral']
                              ?.toString() ??
                          'Referral',
                      referralText,
                    ),
                  SizedBox(height: media.width * 0.05),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                vertical: media.width * 0.03),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: MyText(
                                text: languages[choosenLanguage]?['text_cancel']
                                        ?.toString() ??
                                    'Cancel',
                                size: media.width * fourteen,
                                fontweight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: media.width * 0.03),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            _confirmAndSubmit();
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                vertical: media.width * 0.03),
                            decoration: BoxDecoration(
                              color: buttonColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: MyText(
                                text: languages[choosenLanguage]
                                            ?['text_confirm']
                                        ?.toString() ??
                                    'Confirm',
                                size: media.width * fourteen,
                                fontweight: FontWeight.w600,
                                color: page,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Widget helper para construir uma linha de informação
  Widget _buildInfoRow(Size media, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: media.width * 0.03),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            flex: 2,
            child: MyText(
              text: '$label:',
              size: media.width * fourteen,
              fontweight: FontWeight.w600,
              color: textColor.withOpacity(0.7),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: media.width * 0.02),
          Expanded(
            flex: 3,
            child: MyText(
              text: value,
              size: media.width * fourteen,
              fontweight: FontWeight.w500,
              color: textColor,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Função para confirmar e submeter os dados
  Future<void> _confirmAndSubmit() async {
    debugPrint('🚀 [UI] ========== CONFIRMANDO E SUBMETENDO ==========');
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _error = '';
      _isLoading = true;
    });

    // Verificar todas as condições antes de decidir qual API chamar
    debugPrint('🚀 [UI] Verificando condições...');
    debugPrint(
        '🚀 [UI] Condição 1 - userDetails.isEmpty: ${userDetails.isEmpty}');
    debugPrint(
        '🚀 [UI] Condição 2 - userDetails[role] == owner: ${userDetails.isNotEmpty ? userDetails['role'] == 'owner' : false}');
    debugPrint(
        '🚀 [UI] Condição 3 - frompage == 1 && userDetails.isNotEmpty && isowner != true: ${widget.frompage == 1 && userDetails.isNotEmpty && isowner != true}');

    // PRIORIDADE 1: Se userDetails está vazio, é cadastro novo - chamar registerDriver()
    if (userDetails.isEmpty) {
      debugPrint('🚀🚀🚀 [UI] ✅ ENTROU NO CAMINHO: userDetails.isEmpty');
      debugPrint('🚀🚀🚀 [UI] Chamando registerDriver()...');
      debugPrint('🚀 [UI] myVehicleId: $myVehicleId');
      debugPrint('🚀 [UI] myServiceId: $myServiceId');

      // Garantir que vehicleNumber e vehicleColor estão definidos
      if (vehicleNumber == null || vehicleNumber == '') {
        vehicleNumber = numbercontroller.text;
        debugPrint(
            '🚀 [UI] vehicleNumber definido do controller: $vehicleNumber');
      }
      if (vehicleColor == null || vehicleColor == '') {
        vehicleColor = colorcontroller.text;
        debugPrint(
            '🚀 [UI] vehicleColor definido do controller: $vehicleColor');
      }

      vehicletypelist.clear();
      if (myVehicleId.isNotEmpty) {
        vehicletypelist.add(myVehicleId);
        debugPrint('🚀 [UI] Adicionando vehicle type ID: $myVehicleId');
      }
      debugPrint(
          '🚀 [UI] vehicletypelist após processamento: $vehicletypelist');
      debugPrint('🚀 [UI] Dados finais antes de chamar API:');
      debugPrint('🚀 [UI]   - vehicleNumber: $vehicleNumber');
      debugPrint('🚀 [UI]   - vehicleColor: $vehicleColor');
      debugPrint('🚀 [UI]   - vehicleMakeId: $vehicleMakeId');
      debugPrint('🚀 [UI]   - vehicleModelId: $vehicleModelId');
      debugPrint('🚀 [UI]   - modelYear: $modelYear');
      debugPrint('🚀 [UI]   - myServiceId: $myServiceId');
      debugPrint('🚀 [UI]   - transportType: $transportType');

      debugPrint(
          '🚀🚀🚀 [UI] ========== CHAMANDO registerDriver() AGORA ==========');
      var reg = await registerDriver();
      debugPrint(
          '🚀🚀🚀 [UI] ========== registerDriver() RETORNOU: $reg ==========');

      if (reg == 'true') {
        carInformationCompleted = true;
        navigateref();
      } else {
        setState(() {
          _error = reg.toString();
          _isLoading = false;
        });
      }
      setState(() {
        _isLoading = false;
      });
    } else if (userDetails.isNotEmpty && userDetails['role'] == 'owner') {
      debugPrint('🚀🚀🚀 [UI] ✅ ENTROU NO CAMINHO: userDetails[role] == owner');
      debugPrint('🚀 [UI] Entrando no caminho: userDetails[role] == owner');
      debugPrint('🚀 [UI] Chamando addDriver()...');
      if (myVehicleId.isNotEmpty) {
        vehicletypelist.add(myVehicleId);
      }
      var reg = await addDriver();
      debugPrint('🚀 [UI] addDriver() retornou: $reg');
      setState(() {
        _isLoading = false;
      });
      if (reg == 'true') {
        setState(() {
          vehicleAdded = true;
        });
      } else if (reg == 'logout') {
        navigateLogout();
      } else {
        setState(() {
          _error = reg.toString();
        });
      }
    }
    // PRIORIDADE 3: Se frompage == 1 e userDetails não está vazio e não é owner (usa referral do cadastro inicial)
    else if (widget.frompage == 1 &&
        userDetails.isNotEmpty &&
        isowner != true) {
      debugPrint(
          '🚀 [UI] Entrando no caminho: frompage == 1 && userDetails.isNotEmpty && isowner != true');
      if (loginReferralCode.trim().isNotEmpty) {
        var val = await updateReferral(loginReferralCode.trim());
        if (val == 'true') {
          carInformationCompleted = true;
          navigateref();
        } else {
          setState(() {
            _error = languages[choosenLanguage]['text_referral_code'];
            _isLoading = false;
          });
        }
      } else {
        carInformationCompleted = true;
        navigateref();
      }
    }
    // PRIORIDADE 4: Caso padrão - atualizar veículo
    else {
      debugPrint('🚀 [UI] Entrando no caminho: else (updateVehicle)');
      debugPrint('🚀 [UI] Chamando updateVehicle()...');
      vehicletypelist.clear();
      if (myVehicleId.isNotEmpty) {
        vehicletypelist.add(myVehicleId);
        debugPrint('🚀 [UI] Adicionando vehicle type ID: $myVehicleId');
      }
      debugPrint(
          '🚀 [UI] vehicletypelist após processamento: $vehicletypelist');

      var update = await updateVehicle();
      debugPrint('🚀 [UI] updateVehicle() retornou: $update');
      if (update == 'success') {
        navigate();
      } else if (update == 'logout') {
        navigateLogout();
      } else {
        setState(() {
          _error = update.toString();
        });
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Função helper para obter o texto do local de serviço de forma segura
  String _getServiceLocationDisplayText() {
    debugPrint('📍 [UI] _getServiceLocationDisplayText - Iniciando');
    debugPrint(
        '📍 [UI] _getServiceLocationDisplayText - widget.frompage: ${widget.frompage}');
    debugPrint(
        '📍 [UI] _getServiceLocationDisplayText - myServiceId: $myServiceId');
    debugPrint(
        '📍 [UI] _getServiceLocationDisplayText - serviceLocations.length: ${serviceLocations.length}');

    // Se for primeira página e não tem service ID selecionado, mostrar placeholder
    if (widget.frompage == 1 && (myServiceId == null || myServiceId == '')) {
      debugPrint(
          '📍 [UI] _getServiceLocationDisplayText - Retornando placeholder');
      return (languages[choosenLanguage] ??
                  languages['en'])?['text_service_loc']
              ?.toString() ??
          'Qual é o seu local de serviço';
    }

    // Se tem service ID selecionado
    if (myServiceId != null && myServiceId != '') {
      debugPrint(
          '📍 [UI] _getServiceLocationDisplayText - Tentando encontrar local com ID: $myServiceId');
      debugPrint(
          '📍 [UI] _getServiceLocationDisplayText - Tipo do myServiceId: ${myServiceId.runtimeType}');

      // Se já temos o nome salvo em myServiceLocation, usar ele diretamente
      if (myServiceLocation != null && myServiceLocation != '') {
        debugPrint(
            '📍 [UI] _getServiceLocationDisplayText - Usando myServiceLocation salvo: $myServiceLocation');
        return myServiceLocation.toString();
      }

      if (serviceLocations.isNotEmpty) {
        try {
          // Tentar encontrar o local pelo ID - comparar como string para evitar problemas de tipo
          for (var i = 0; i < serviceLocations.length; i++) {
            final locationId = serviceLocations[i]['id']?.toString() ?? '';
            final searchId = myServiceId.toString();

            debugPrint(
                '📍 [UI] _getServiceLocationDisplayText - Comparando [$i]: "$locationId" com "$searchId"');

            if (locationId == searchId) {
              final locationName =
                  serviceLocations[i]['name']?.toString() ?? '';
              debugPrint(
                  '📍 [UI] _getServiceLocationDisplayText - ✅ Encontrado! Nome: $locationName');
              // Salvar no myServiceLocation para próxima vez
              myServiceLocation = locationName;
              return locationName;
            }
          }

          debugPrint(
              '📍 [UI] _getServiceLocationDisplayText - ⚠️ Local não encontrado na lista após busca completa');
        } catch (e) {
          debugPrint(
              '📍 [UI] _getServiceLocationDisplayText - ❌ ERRO ao buscar local: $e');
          debugPrint(
              '📍 [UI] _getServiceLocationDisplayText - Stack trace: ${StackTrace.current}');
        }
      } else {
        debugPrint(
            '📍 [UI] _getServiceLocationDisplayText - ⚠️ serviceLocations está vazio');
      }
    }

    // Fallback: usar userDetails se disponível
    if (userDetails.isNotEmpty &&
        userDetails['service_location_name'] != null) {
      debugPrint(
          '📍 [UI] _getServiceLocationDisplayText - Usando userDetails: ${userDetails['service_location_name']}');
      return userDetails['service_location_name'].toString();
    }

    debugPrint(
        '📍 [UI] _getServiceLocationDisplayText - Retornando placeholder final');
    return (languages[choosenLanguage] ?? languages['en'])?['text_service_loc']
            ?.toString() ??
        'Qual é o seu local de serviço';
  }

//get service loc data
  getServiceLoc() async {
    // Limpar seleção de tipo de veículo
    vehicletypelist.clear();
    // NÃO limpar myServiceId e myServiceLocation se já estiverem definidos
    // Isso preserva a seleção do usuário
    // myServiceId = '';
    // myServiceLocation = '';
    vehicleMakeId = '';
    vehicleModelId = '';
    if (enabledModule == 'both') {
      // Só limpar transportType se não estiver definido ainda
      // transportType = '';
    }
    myVehicleId = '';
    // ignore: unused_local_variable, prefer_typing_uninitialized_variables
    var result;
    debugPrint('🚗 [UI] getServiceLoc - Iniciando carregamento');
    debugPrint('🚗 [UI] getServiceLoc - frompage: ${widget.frompage}');
    debugPrint('🚗 [UI] getServiceLoc - isowner: $isowner');
    debugPrint('🚗 [UI] getServiceLoc - transportType: $transportType');
    debugPrint('🚗 [UI] getServiceLoc - myServiceId antes: $myServiceId');

    if (widget.frompage == 2 || isowner == true) {
      myVehicleId = '';
      debugPrint('🚗 [UI] getServiceLoc - Chamando getvehicleType()...');
      result = await getvehicleType();
      debugPrint('🚗 [UI] getServiceLoc - Resultado getvehicleType: $result');
      debugPrint(
          '🚗 [UI] getServiceLoc - vehicleType.length após chamada: ${vehicleType.length}');
      if (vehicleType.isEmpty) {
        debugPrint(
            '🚗 [UI] getServiceLoc - AVISO: vehicleType está vazio após getvehicleType()!');
      }
    } else {
      vehicletypelist = [];
      debugPrint('📍 [UI] getServiceLoc - Chamando getServiceLocation()...');
      result = await getServiceLocation();
      debugPrint(
          '📍 [UI] getServiceLoc - Resultado getServiceLocation: $result');
      debugPrint(
          '📍 [UI] getServiceLoc - serviceLocations.length após chamada: ${serviceLocations.length}');
      if (serviceLocations.isEmpty) {
        debugPrint(
            '📍 [UI] getServiceLoc - AVISO: serviceLocations está vazio após getServiceLocation()!');
      } else {
        debugPrint('📍 [UI] getServiceLoc - Locais de serviço carregados:');
        for (var i = 0; i < serviceLocations.length; i++) {
          debugPrint('📍 [UI] getServiceLoc -   [$i] ${serviceLocations[i]}');
        }
      }
    }

    debugPrint('🚗 [UI] getServiceLoc - Resultado final: $result');
    debugPrint('🚗 [UI] getServiceLoc - myServiceId depois: $myServiceId');

    if (mounted) {
      setState(() {
        loaded = true;
      });
      debugPrint('🚗 [UI] getServiceLoc - Estado atualizado: loaded = true');
    }
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
          resizeToAvoidBottomInset: true,
          body: Stack(
            children: [
              Container(
                height: media.height * 1,
                width: media.width * 1,
                color: page,
                child: Column(
                  children: [
                    // Header: safe area, voltar e logo (igual à tela de termos)
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
                    SizedBox(
                      height: media.width * 0.05,
                    ),
                    Expanded(
                        child: Container(
                      padding: EdgeInsets.fromLTRB(
                          media.width * 0.05,
                          media.width * 0.05,
                          media.width * 0.05,
                          media.width * 0.05),
                      child: SingleChildScrollView(
                        padding: EdgeInsets.only(bottom: media.width * 0.5),
                        physics: const AlwaysScrollableScrollPhysics(),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Título da tela
                            Center(
                              child: Text(
                                widget.frompage == 2
                                    ? (languages[choosenLanguage]['text_updateVehicle'] ?? 'Atualizar veículo')
                                    : (languages[choosenLanguage]['text_car_info'] ?? 'Informações do veículo'),
                                style: GoogleFonts.poppins(
                                  fontSize: media.width * twenty,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            if (widget.frompage == 2) ...[
                              SizedBox(height: media.width * 0.02),
                              Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: media.width * 0.05),
                                  child: Text(
                                    'Atenção: ao atualizar seu veículo, você fica bloqueado até uma nova análise.',
                                    style: GoogleFonts.poppins(
                                      fontSize: media.width * fourteen,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              SizedBox(height: media.width * 0.04),
                            ],
                            // Sempre mostrar opção de seleção de tipo de transporte quando frompage == 1
                            if (widget.frompage == 1)
                              Column(
                                children: [
                                  SizedBox(
                                    height: media.width * 0.05,
                                  ),
                                  SizedBox(
                                      width: media.width * 0.9,
                                      child: MyText(
                                        text: languages[choosenLanguage]
                                            ['text_register_for'],
                                        size: media.width * fourteen,
                                        fontweight: FontWeight.w600,
                                        maxLines: 1,
                                      )),
                                  SizedBox(
                                    height: media.height * 0.012,
                                  ),
                                  Container(
                                    width: media.width * 0.9,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: _getBorderColor(
                                          isActive: false,
                                          isFilled: transportType.isNotEmpty,
                                          hasError: _hasTransportTypeError,
                                        ),
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: DropdownSearch<String>(
                                      selectedItem: transportType.isEmpty ? null : transportType,
                                      items: const ['taxi', 'delivery', 'both'],
                                      itemAsString: (String v) {
                                        if (v == 'taxi') return languages[choosenLanguage]?['text_taxi_']?.toString() ?? languages['en']?['text_taxi_']?.toString() ?? 'Taxi';
                                        if (v == 'delivery') return languages[choosenLanguage]?['text_delivery']?.toString() ?? languages['en']?['text_delivery']?.toString() ?? 'Delivery';
                                        return languages[choosenLanguage]?['text_both']?.toString() ?? languages['en']?['text_both']?.toString() ?? 'Both';
                                      },
                                      onChanged: (String? newValue) {
                                        if (newValue != null) {
                                          setState(() {
                                            transportType = newValue;
                                            myVehicleId = '';
                                            vehicleMakeId = '';
                                            vehicleModelId = '';
                                            myServiceId = '';
                                            myServiceLocation = '';
                                            _hasTransportTypeError = false;
                                          });
                                          debugPrint(
                                              '🚗 [UI] Transport type selecionado: $transportType');
                                        }
                                      },
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
                                          hintText: languages[choosenLanguage]?['text_register_for']?.toString() ?? 'Register for',
                                          hintStyle: GoogleFonts.poppins(fontSize: media.width * fourteen, color: textColor.withOpacity(0.5)),
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(horizontal: media.width * 0.05, vertical: media.width * 0.036),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: media.width * 0.05,
                                  )
                                ],
                              ),
                            // Local de serviço - só aparece quando transportType está selecionado
                            if (widget.frompage == 1 &&
                                isowner == false &&
                                transportType.isNotEmpty)
                              SizedBox(
                                width: media.width * 0.9,
                                child: MyText(
                                  text: languages[choosenLanguage]
                                      ['text_service_location'],
                                  size: media.width * fourteen,
                                  fontweight: FontWeight.w600,
                                  maxLines: 1,
                                ),
                              ),
                            if (widget.frompage == 1 &&
                                isowner == false &&
                                transportType.isNotEmpty)
                              SizedBox(
                                height: media.height * 0.012,
                              ),
                            widget.frompage == 1 &&
                                    isowner == false &&
                                    transportType.isNotEmpty
                                ? InkWell(
                                    onTap: () async {
                                      debugPrint(
                                          '📍 [UI] Campo de local de serviço clicado');
                                      debugPrint(
                                          '📍 [UI] - enabledModule: $enabledModule');
                                      debugPrint(
                                          '📍 [UI] - transportType: $transportType');
                                      debugPrint(
                                          '📍 [UI] - chooseWorkArea: $chooseWorkArea');

                                      // Precisa ter transportType selecionado primeiro
                                      if (transportType == '') {
                                        debugPrint(
                                            '📍 [UI] - ⚠️ Precisa selecionar tipo de transporte primeiro (text_register_for)');
                                        return; // Não fazer nada se não tiver transportType
                                      }

                                      // Permitir abrir/fechar a lista de locais
                                      setState(() {
                                        if (chooseWorkArea == true) {
                                          chooseWorkArea = false;
                                          debugPrint(
                                              '📍 [UI] - Fechando lista de locais');
                                        } else {
                                          chooseWorkArea = true;
                                          chooseVehicleMake = false;
                                          chooseVehicleModel = false;
                                          chooseVehicleType = false;
                                          // Limpar foco de campos de texto
                                          _vehicleNumberFocus.unfocus();
                                          _referralFocus.unfocus();
                                          _vehicleMakeFocus.unfocus();
                                          _vehicleModelFocus.unfocus();
                                          debugPrint(
                                              '📍 [UI] - Abrindo lista de locais');
                                        }
                                      });
                                    },
                                    child: Container(
                                      width: media.width * 0.9,
                                      height: media.width * 0.13,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: media.width * 0.05,
                                        vertical: media.width * 0.036,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: _getBorderColor(
                                            isActive: chooseWorkArea,
                                            isFilled: myServiceId != null &&
                                                myServiceId != '',
                                            hasError: _hasServiceLocationError,
                                          ),
                                          width: 1.5,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              _getServiceLocationDisplayText(),
                                              key: ValueKey(
                                                  'service_location_${myServiceId}_$myServiceLocation'),
                                              style: GoogleFonts.poppins(
                                                fontSize:
                                                    media.width * fourteen,
                                                color: (myServiceId != null &&
                                                        myServiceId != '')
                                                    ? textColor
                                                    : textColor
                                                        .withOpacity(0.5),
                                                fontWeight:
                                                    (myServiceId != null &&
                                                            myServiceId != '')
                                                        ? FontWeight.w600
                                                        : FontWeight.w500,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                          SizedBox(width: media.width * 0.02),
                                          Icon(
                                            chooseWorkArea
                                                ? Icons.arrow_drop_down
                                                : Icons.arrow_left,
                                            color: textColor,
                                            size: media.width * 0.08,
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : Container(),
                            SizedBox(
                              height: media.width * 0.02,
                            ),
                            if (chooseWorkArea == true &&
                                serviceLocations.isNotEmpty)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                margin:
                                    EdgeInsets.only(bottom: media.width * 0.03),
                                width: media.width * 0.9,
                                // height: media.width * 0.5,
                                padding: EdgeInsets.all(media.width * 0.03),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: underline),
                                ),
                                child: SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(),
                                  child: Column(
                                    children: serviceLocations
                                        .asMap()
                                        .map((i, value) {
                                          return MapEntry(
                                              i,
                                              Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  onTap: () async {
                                                    final selectedId =
                                                        serviceLocations[i]
                                                                    ['id']
                                                                ?.toString() ??
                                                            '';
                                                    final selectedName =
                                                        serviceLocations[i]
                                                                    ['name']
                                                                ?.toString() ??
                                                            '';

                                                    debugPrint(
                                                        '📍 [UI] Local selecionado - ID: $selectedId, Nome: $selectedName');
                                                    debugPrint(
                                                        '📍 [UI] serviceLocations.length: ${serviceLocations.length}');

                                                    // Atualizar estado imediatamente para mostrar o nome selecionado
                                                    debugPrint(
                                                        '📍 [UI] ========== ANTES DO SETSTATE ==========');
                                                    debugPrint(
                                                        '📍 [UI] myServiceId antes: $myServiceId');
                                                    debugPrint(
                                                        '📍 [UI] myServiceLocation antes: $myServiceLocation');
                                                    debugPrint(
                                                        '📍 [UI] selectedId: $selectedId');
                                                    debugPrint(
                                                        '📍 [UI] selectedName: $selectedName');

                                                    setState(() {
                                                      myVehicleId = '';
                                                      vehicleMakeId = '';
                                                      vehicleModelId = '';
                                                      myServiceId = selectedId;
                                                      myServiceLocation =
                                                          selectedName;
                                                      chooseWorkArea = false;
                                                      _isLoading = true;
                                                      _hasServiceLocationError =
                                                          false;
                                                    });

                                                    debugPrint(
                                                        '📍 [UI] ========== DEPOIS DO SETSTATE ==========');
                                                    debugPrint(
                                                        '📍 [UI] Estado atualizado - myServiceId: $myServiceId');
                                                    debugPrint(
                                                        '📍 [UI] Estado atualizado - myServiceLocation: $myServiceLocation');
                                                    debugPrint(
                                                        '📍 [UI] Texto que será exibido: ${_getServiceLocationDisplayText()}');
                                                    debugPrint(
                                                        '📍 [UI] serviceLocations.length: ${serviceLocations.length}');
                                                    debugPrint(
                                                        '📍 [UI] ===========================================');

                                                    // Forçar rebuild imediato para mostrar o nome ANTES de chamar getvehicleType
                                                    if (mounted) {
                                                      await Future.delayed(
                                                          const Duration(
                                                              milliseconds:
                                                                  50));
                                                      setState(() {
                                                        // Apenas para forçar rebuild e mostrar o nome imediatamente
                                                        debugPrint(
                                                            '📍 [UI] Forçando rebuild - myServiceLocation: $myServiceLocation');
                                                      });
                                                    }

                                                    debugPrint(
                                                        '🚗 [UI] Botão selecionado - Chamando getvehicleType()...');
                                                    debugPrint(
                                                        '🚗 [UI] transportType atual: $transportType');

                                                    var result =
                                                        await getvehicleType();

                                                    debugPrint(
                                                        '🚗 [UI] Resultado getvehicleType: $result');
                                                    debugPrint(
                                                        '🚗 [UI] vehicleType.length: ${vehicleType.length}');

                                                    if (result == 'success') {
                                                      debugPrint(
                                                          '🚗 [UI] Sucesso! vehicleType carregado com ${vehicleType.length} tipos');
                                                      if (vehicleType
                                                          .isNotEmpty) {
                                                        debugPrint(
                                                            '🚗 [UI] Primeiro tipo disponível: ${vehicleType[0]}');
                                                      }
                                                    } else {
                                                      debugPrint(
                                                          '🚗 [UI] ERRO: Falha ao carregar tipos de veículo');
                                                      debugPrint(
                                                          '🚗 [UI] Resultado: $result');
                                                    }

                                                    // Limpar seleção anterior

                                                    // Atualizar estado final para garantir que a UI seja atualizada
                                                    if (mounted) {
                                                      setState(() {
                                                        _isLoading = false;
                                                        debugPrint(
                                                            '📍 [UI] Estado final - myServiceId: $myServiceId');
                                                        debugPrint(
                                                            '📍 [UI] Estado final - myServiceLocation: $myServiceLocation');
                                                        debugPrint(
                                                            '📍 [UI] Texto exibido será: ${_getServiceLocationDisplayText()}');
                                                      });
                                                    }
                                                  },
                                                  child: Container(
                                                    width: media.width * 0.8,
                                                    padding: EdgeInsets.only(
                                                        top:
                                                            media.width * 0.025,
                                                        bottom: media.width *
                                                            0.025),
                                                    child: Text(
                                                      serviceLocations[i]
                                                          ['name'],
                                                      style:
                                                          GoogleFonts.poppins(
                                                              fontSize:
                                                                  media.width *
                                                                      fourteen,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color: textColor),
                                                    ),
                                                  ),
                                                ),
                                              ));
                                        })
                                        .values
                                        .toList(),
                                  ),
                                ),
                              ),
                            // Tipo de veículo - só aparece quando local de serviço está selecionado OU quando é owner OU quando transportType está selecionado
                            if ((widget.frompage == 1 &&
                                    isowner == false &&
                                    (myServiceId != null &&
                                        myServiceId != '')) ||
                                (widget.frompage == 1 &&
                                    transportType.isNotEmpty &&
                                    enabledModule == 'both') ||
                                (widget.frompage != 1) ||
                                (isowner == true))
                              SizedBox(
                                width: media.width * 0.9,
                                child: MyText(
                                  text: languages[choosenLanguage]
                                      ['text_vehicle_type'],
                                  size: media.width * fourteen,
                                  fontweight: FontWeight.w600,
                                  maxLines: 1,
                                ),
                              ),
                            if ((widget.frompage == 1 &&
                                    isowner == false &&
                                    (myServiceId != null &&
                                        myServiceId != '')) ||
                                (widget.frompage == 1 &&
                                    transportType.isNotEmpty &&
                                    enabledModule == 'both') ||
                                (widget.frompage != 1) ||
                                (isowner == true))
                              SizedBox(
                                height: media.height * 0.012,
                              ),
                            // Tipo de veículo - só aparece quando local de serviço está selecionado OU quando é owner OU quando transportType está selecionado
                            if ((widget.frompage == 1 &&
                                    isowner == false &&
                                    (myServiceId != null &&
                                        myServiceId != '')) ||
                                (widget.frompage == 1 &&
                                    transportType.isNotEmpty &&
                                    enabledModule == 'both') ||
                                (widget.frompage != 1) ||
                                (isowner == true))
                              (userDetails['vehicle_type_name'] == null &&
                                      userDetails['role'] != 'owner')
                                  ? InkWell(
                                      onTap: () async {
                                        debugPrint(
                                            '🚗 [UI] Tipo de veículo clicado');
                                        debugPrint(
                                            '🚗 [UI] - enabledModule: $enabledModule');
                                        debugPrint(
                                            '🚗 [UI] - transportType: $transportType');
                                        debugPrint(
                                            '🚗 [UI] - myServiceId: $myServiceId');
                                        debugPrint(
                                            '🚗 [UI] - isowner: $isowner');
                                        debugPrint(
                                            '🚗 [UI] - chooseVehicleType atual: $chooseVehicleType');

                                        if (chooseVehicleType == true) {
                                          setState(() {
                                            chooseVehicleType = false;
                                          });
                                        } else {
                                          // Permitir escolher tipo de veículo se:
                                          // 1. Já tem local selecionado, OU
                                          // 2. É owner, OU
                                          // 3. transportType está selecionado (permite escolher tipo antes do local)
                                          final canChooseType =
                                              (myServiceId != '' &&
                                                      myServiceId != null) ||
                                                  (isowner == true) ||
                                                  (transportType != '');

                                          debugPrint(
                                              '🚗 [UI] - Pode escolher tipo? $canChooseType');

                                          if (canChooseType) {
                                            // Verificar se passaram 5 segundos desde a última chamada
                                            final now = DateTime.now();
                                            final shouldCallApi =
                                                _lastVehicleTypeApiCall ==
                                                        null ||
                                                    now
                                                            .difference(
                                                                _lastVehicleTypeApiCall!)
                                                            .inSeconds >=
                                                        15;

                                            if (shouldCallApi) {
                                              setState(() {
                                                _isLoading = true;
                                              });
                                              // Chamar API para buscar tipos de veículo
                                              await getvehicleType();
                                              _lastVehicleTypeApiCall =
                                                  DateTime.now();
                                              setState(() {
                                                _isLoading = false;
                                              });
                                              debugPrint(
                                                  '🚗 [UI] - ✅ API chamada para buscar tipos de veículo');
                                            } else {
                                              debugPrint(
                                                  '🚗 [UI] - ⏱️ Usando dados em cache (menos de 5s desde última chamada)');
                                            }

                                            setState(() {
                                              chooseVehicleType = true;
                                            });
                                            debugPrint(
                                                '🚗 [UI] - ✅ Abrindo seleção de tipo de veículo');
                                          } else {
                                            chooseVehicleType = false;
                                            debugPrint(
                                                '🚗 [UI] - ❌ Não pode escolher tipo ainda');
                                            debugPrint('🚗 [UI] - Condições:');
                                            debugPrint(
                                                '🚗 [UI]   - Tem local: ${myServiceId != '' && myServiceId != null}');
                                            debugPrint(
                                                '🚗 [UI]   - É owner: $isowner');
                                            debugPrint(
                                                '🚗 [UI]   - enabledModule == both: ${enabledModule == 'both'}');
                                            debugPrint(
                                                '🚗 [UI]   - transportType != vazio: ${transportType != ''}');
                                          }
                                          chooseWorkArea = false;
                                          chooseVehicleMake = false;
                                          chooseVehicleModel = false;
                                          // Limpar foco de campos de texto
                                          _vehicleNumberFocus.unfocus();
                                          _referralFocus.unfocus();
                                          _vehicleMakeFocus.unfocus();
                                          _vehicleModelFocus.unfocus();
                                        }
                                        setState(() {});
                                      },
                                      child: Container(
                                        width: media.width * 0.9,
                                        height: media.width * 0.13,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: _getBorderColor(
                                              isActive: chooseVehicleType,
                                              isFilled: myVehicleId != '',
                                              hasError: _hasVehicleTypeError,
                                            ),
                                            width: 1.5,
                                          ),
                                          color: page,
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: media.width * 0.05,
                                        ),
                                        child: (myVehicleId == '')
                                            ? Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      languages[choosenLanguage]
                                                              [
                                                              'text_vehicle_type']
                                                          .toString(),
                                                      style:
                                                          GoogleFonts.poppins(
                                                        fontSize: media.width *
                                                            fourteen,
                                                        color: textColor
                                                            .withOpacity(0.5),
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      maxLines: 1,
                                                    ),
                                                  ),
                                                  SizedBox(
                                                      width:
                                                          media.width * 0.02),
                                                  Icon(
                                                    chooseVehicleType
                                                        ? Icons.arrow_drop_down
                                                        : Icons.arrow_left,
                                                    color: textColor,
                                                    size: media.width * 0.08,
                                                  ),
                                                ],
                                              )
                                            : Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Expanded(
                                                    child: myVehicleId != '' &&
                                                            vehicleType
                                                                .isNotEmpty
                                                        ? Text(
                                                            vehicleType
                                                                    .firstWhere(
                                                                      (element) =>
                                                                          element['id']
                                                                              .toString() ==
                                                                          myVehicleId
                                                                              .toString(),
                                                                      orElse:
                                                                          () =>
                                                                              {
                                                                        'name':
                                                                            ''
                                                                      },
                                                                    )['name']
                                                                    ?.toString() ??
                                                                '',
                                                            style: GoogleFonts
                                                                .poppins(
                                                              fontSize:
                                                                  media.width *
                                                                      fourteen,
                                                              color: textColor,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            maxLines: 1,
                                                          )
                                                        : Container(),
                                                  ),
                                                  SizedBox(
                                                      width:
                                                          media.width * 0.02),
                                                  Icon(
                                                    chooseVehicleType
                                                        ? Icons.arrow_drop_down
                                                        : Icons.arrow_left,
                                                    color: textColor,
                                                    size: media.width * 0.08,
                                                  ),
                                                ],
                                              ),
                                      ),
                                    )
                                  : InkWell(
                                      onTap: () async {
                                        if (chooseVehicleType == true) {
                                          setState(() {
                                            chooseVehicleType = false;
                                          });
                                        } else {
                                          // Permitir escolher tipo de veículo se:
                                          // 1. Já tem local selecionado, OU
                                          // 2. É owner, OU
                                          // 3. transportType está selecionado (permite escolher tipo antes do local)
                                          if ((myServiceId != '' &&
                                                  myServiceId != null) ||
                                              (isowner == true) ||
                                              (transportType != '')) {
                                            // Verificar se passaram 5 segundos desde a última chamada
                                            final now = DateTime.now();
                                            final shouldCallApi =
                                                _lastVehicleTypeApiCall ==
                                                        null ||
                                                    now
                                                            .difference(
                                                                _lastVehicleTypeApiCall!)
                                                            .inSeconds >=
                                                        5;

                                            if (shouldCallApi) {
                                              setState(() {
                                                _isLoading = true;
                                              });
                                              // Chamar API para buscar tipos de veículo
                                              await getvehicleType();
                                              _lastVehicleTypeApiCall =
                                                  DateTime.now();
                                              setState(() {
                                                _isLoading = false;
                                              });
                                              debugPrint(
                                                  '🚗 [UI] - ✅ API chamada para buscar tipos de veículo');
                                            } else {
                                              debugPrint(
                                                  '🚗 [UI] - ⏱️ Usando dados em cache (menos de 5s desde última chamada)');
                                            }

                                            setState(() {
                                              chooseVehicleType = true;
                                            });
                                          } else {
                                            chooseVehicleType = false;
                                          }
                                          chooseWorkArea = false;
                                          chooseVehicleMake = false;
                                          chooseVehicleModel = false;
                                          // Limpar foco de campos de texto
                                          _vehicleNumberFocus.unfocus();
                                          _referralFocus.unfocus();
                                          _vehicleMakeFocus.unfocus();
                                          _vehicleModelFocus.unfocus();
                                        }
                                        setState(() {});
                                      },
                                      child: Container(
                                        width: media.width * 0.9,
                                        height: media.width * 0.13,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: _getBorderColor(
                                              isActive: chooseVehicleType,
                                              isFilled: myVehicleId != '',
                                              hasError: _hasVehicleTypeError,
                                            ),
                                            width: 1.5,
                                          ),
                                          color: page,
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: media.width * 0.05,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                (myVehicleId == '')
                                                    ? languages[choosenLanguage]
                                                            [
                                                            'text_vehicle_type']
                                                        .toString()
                                                    : (myVehicleId != '' &&
                                                            myVehicleId != '')
                                                        ? vehicleType.isNotEmpty
                                                            ? vehicleType
                                                                .firstWhere(
                                                                    (element) =>
                                                                        element[
                                                                            'id'] ==
                                                                        myVehicleId)[
                                                                    'name']
                                                                .toString()
                                                            : ''
                                                        : myVehicalType
                                                            .toString(),
                                                style: GoogleFonts.poppins(
                                                  fontSize:
                                                      media.width * fourteen,
                                                  color: (myVehicleId == '')
                                                      ? textColor
                                                          .withOpacity(0.5)
                                                      : textColor,
                                                  fontWeight:
                                                      (myVehicleId == '')
                                                          ? FontWeight.w500
                                                          : FontWeight.w600,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ),
                                            SizedBox(width: media.width * 0.02),
                                            Icon(
                                              chooseVehicleType
                                                  ? Icons.arrow_drop_down
                                                  : Icons.arrow_left,
                                              color: textColor,
                                              size: media.width * 0.08,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                            if ((widget.frompage == 1 &&
                                    isowner == false &&
                                    (myServiceId != null &&
                                        myServiceId != '')) ||
                                (widget.frompage == 1 &&
                                    transportType.isNotEmpty &&
                                    enabledModule == 'both') ||
                                (widget.frompage != 1) ||
                                (isowner == true))
                              SizedBox(
                                height: media.width * 0.02,
                              ),
                            if (chooseVehicleType == true &&
                                vehicleType.isNotEmpty)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                width: media.width * 0.9,
                                margin:
                                    EdgeInsets.only(bottom: media.width * 0.03),
                                // height: media.width * 0.5,
                                padding: EdgeInsets.all(media.width * 0.03),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: underline),
                                ),
                                child: SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(),
                                  child: Column(
                                    children: vehicleType
                                        .asMap()
                                        .map((i, value) {
                                          return MapEntry(
                                              i,
                                              Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  onTap: () async {
                                                    setState(() {
                                                      vehicleMake.clear();
                                                      vehicleModel.clear();
                                                      vehicleMakeId = '';
                                                      vehicleModelId = '';
                                                      vehicleMakeName = '';
                                                      vehicleModelName = '';
                                                      myVehicleId =
                                                          vehicleType[i]['id']
                                                              .toString();
                                                      // Tipo único - já foi definido acima

                                                      chooseVehicleType = false;
                                                      iscustommake = false;
                                                      _hasVehicleTypeError =
                                                          false;
                                                    });
                                                    setState(() {
                                                      _isLoading = true;
                                                    });
                                                    // Usar vehicle_make_for do tipo selecionado
                                                    final vehicleMakeFor = vehicleType[
                                                                    i][
                                                                'vehicle_make_for']
                                                            ?.toString() ??
                                                        vehicleType[i][
                                                                'icon_types_for']
                                                            ?.toString() ??
                                                        vehicleType[i]['icon']
                                                            ?.toString() ??
                                                        '';
                                                    await getVehicleMake(
                                                      transportType: (isowner ==
                                                              true)
                                                          ? userDetails[
                                                              'transport_type']
                                                          : transportType,
                                                      myVehicleIconFor:
                                                          vehicleMakeFor,
                                                    );
                                                    setState(() {
                                                      _isLoading = false;
                                                    });
                                                  },
                                                  child: Container(
                                                      width: media.width * 0.8,
                                                      padding: EdgeInsets.only(
                                                          top: media.width *
                                                              0.025,
                                                          bottom: media.width *
                                                              0.025),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Image.network(
                                                            vehicleType[i]
                                                                    ['icon']
                                                                .toString(),
                                                            fit: BoxFit.contain,
                                                            width: media.width *
                                                                0.1,
                                                            height:
                                                                media.width *
                                                                    0.08,
                                                            errorBuilder:
                                                                (context, error,
                                                                    stackTrace) {
                                                              return Icon(
                                                                Icons
                                                                    .directions_car,
                                                                size: media
                                                                        .width *
                                                                    0.1,
                                                                color:
                                                                    textColor,
                                                              );
                                                            },
                                                          ),
                                                          const SizedBox(
                                                            width: 10,
                                                          ),
                                                          Expanded(
                                                            child: Text(
                                                              vehicleType[i]
                                                                      ['name']
                                                                  .toString()
                                                                  .toUpperCase(),
                                                              style: GoogleFonts.poppins(
                                                                  fontSize: media
                                                                          .width *
                                                                      fourteen,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color:
                                                                      textColor),
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              maxLines: 2,
                                                            ),
                                                          ),
                                                        ],
                                                      )),
                                                ),
                                              ));
                                        })
                                        .values
                                        .toList(),
                                  ),
                                ),
                              ),
                            // Marca do veículo - só aparece quando tipo de veículo está selecionado
                            if (myVehicleId != '')
                              SizedBox(
                                width: media.width * 0.9,
                                child: MyText(
                                  text: languages[choosenLanguage]
                                      ['text_vehicle_make'],
                                  size: media.width * fourteen,
                                  fontweight: FontWeight.w600,
                                  maxLines: 1,
                                ),
                              ),
                            if (myVehicleId != '')
                              SizedBox(
                                height: media.height * 0.012,
                              ),
                            // Marca do veículo - só aparece quando tipo de veículo está selecionado
                            if (myVehicleId != '')
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    if (chooseVehicleMake == true) {
                                      chooseVehicleMake = false;
                                    } else {
                                      if (myVehicleId != '') {
                                        chooseVehicleMake = true;
                                      } else {
                                        chooseVehicleMake = false;
                                      }
                                      chooseWorkArea = false;
                                      chooseVehicleModel = false;
                                      chooseVehicleType = false;
                                      // Limpar foco de campos de texto
                                      _vehicleNumberFocus.unfocus();
                                      _referralFocus.unfocus();
                                      _vehicleMakeFocus.unfocus();
                                      _vehicleModelFocus.unfocus();
                                    }
                                  });
                                },
                                child: (iscustommake == false)
                                    ? Container(
                                        width: media.width * 0.9,
                                        height: media.width * 0.13,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: media.width * 0.05,
                                          vertical: media.width * 0.036,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: _getBorderColor(
                                              isActive: chooseVehicleMake,
                                              isFilled: vehicleMakeId != '',
                                              hasError: _hasVehicleMakeError,
                                            ),
                                            width: 1.5,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                (vehicleMakeId == '')
                                                    ? languages[choosenLanguage]
                                                        ['text_sel_make']
                                                    : (vehicleMakeId != '')
                                                        ? vehicleMake.isNotEmpty
                                                            ? vehicleMake
                                                                .firstWhere(
                                                                    (element) =>
                                                                        element['id']
                                                                            .toString() ==
                                                                        vehicleMakeId)[
                                                                    'name']
                                                                .toString()
                                                            : ''
                                                        : vehicleMakeName == ''
                                                            ? languages[
                                                                    choosenLanguage]
                                                                [
                                                                'text_vehicle_make']
                                                            : vehicleMakeName,
                                                style: GoogleFonts.poppins(
                                                  fontSize:
                                                      media.width * fourteen,
                                                  color: (vehicleMakeId == '')
                                                      ? textColor
                                                          .withOpacity(0.5)
                                                      : textColor,
                                                  fontWeight:
                                                      (vehicleMakeId == '')
                                                          ? FontWeight.w500
                                                          : FontWeight.w600,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ),
                                            SizedBox(width: media.width * 0.02),
                                            Icon(
                                              chooseVehicleMake
                                                  ? Icons.arrow_drop_down
                                                  : Icons.arrow_left,
                                              color: textColor,
                                              size: media.width * 0.08,
                                            ),
                                          ],
                                        ),
                                      )
                                    : Container(
                                        width: media.width * 0.9,
                                        height: media.width * 0.13,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: media.width * 0.05,
                                        ),
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: _getBorderColor(
                                              isActive:
                                                  _vehicleMakeFocus.hasFocus,
                                              isFilled: mycustommake != '',
                                              hasError: _hasVehicleMakeError,
                                            ),
                                            width: 1.5,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _vehicleMakeFocus.requestFocus();
                                            });
                                          },
                                          child: InputField(
                                            focusNode: _vehicleMakeFocus,
                                            underline: false,
                                            autofocus: true,
                                            text: languages[choosenLanguage]?[
                                                        'text_enter_vehicle_make']
                                                    ?.toString() ??
                                                (languages['en']?[
                                                            'text_enter_vehicle_make']
                                                        ?.toString() ??
                                                    'Enter Vehicle Make'),
                                            textController:
                                                custommakecontroller,
                                            onTap: (val) {
                                              setState(() {
                                                mycustommake = val;
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                              ),
                            if (myVehicleId != '')
                              SizedBox(
                                height: media.width * 0.02,
                              ),
                            if (myVehicleId != '')
                              (chooseVehicleMake == true &&
                                      iscustommake == false)
                                  ? AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                      margin: EdgeInsets.only(
                                          bottom: media.width * 0.03),
                                      width: media.width * 0.9,
                                      height: media.width * 0.5,
                                      padding:
                                          EdgeInsets.all(media.width * 0.03),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: underline),
                                      ),
                                      child: SingleChildScrollView(
                                        physics: const BouncingScrollPhysics(),
                                        child: Column(
                                          children: [
                                            Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                onTap: () {
                                                  setState(() {
                                                    iscustommake = true;
                                                    custommakecontroller.text =
                                                        '';
                                                    custommodelcontroller.text =
                                                        '';
                                                  });
                                                },
                                                child: Container(
                                                  width: media.width * 0.8,
                                                  padding: EdgeInsets.only(
                                                      top: media.width * 0.025,
                                                      bottom:
                                                          media.width * 0.025),
                                                  child: Text(
                                                    languages[choosenLanguage]?[
                                                                'text_custom_make']
                                                            ?.toString() ??
                                                        (languages['en']?[
                                                                    'text_custom_make']
                                                                ?.toString() ??
                                                            'Custom Make'),
                                                    style: GoogleFonts.poppins(
                                                        fontSize: media.width *
                                                            fourteen,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: textColor),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Column(
                                              children: vehicleMake
                                                  .asMap()
                                                  .map((i, value) {
                                                    return MapEntry(
                                                        i,
                                                        Material(
                                                          color: Colors
                                                              .transparent,
                                                          child: InkWell(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8),
                                                            onTap: () async {
                                                              setState(() {
                                                                vehicleModelId =
                                                                    '';
                                                                vehicleModelName =
                                                                    '';
                                                                vehicleMakeId =
                                                                    vehicleMake[i]
                                                                            [
                                                                            'id']
                                                                        .toString();
                                                                chooseVehicleMake =
                                                                    false;
                                                                _isLoading =
                                                                    true;
                                                                _hasVehicleMakeError =
                                                                    false;
                                                              });

                                                              var result =
                                                                  await getVehicleModel();
                                                              if (result ==
                                                                  'success') {
                                                                setState(() {
                                                                  _isLoading =
                                                                      false;
                                                                });
                                                              } else {
                                                                setState(() {
                                                                  _isLoading =
                                                                      false;
                                                                });
                                                              }
                                                            },
                                                            child: Container(
                                                              width:
                                                                  media.width *
                                                                      0.8,
                                                              padding: EdgeInsets.only(
                                                                  top: media
                                                                          .width *
                                                                      0.025,
                                                                  bottom: media
                                                                          .width *
                                                                      0.025),
                                                              child: Text(
                                                                vehicleMake[i]
                                                                        ['name']
                                                                    .toString(),
                                                                style: GoogleFonts.poppins(
                                                                    fontSize: media
                                                                            .width *
                                                                        fourteen,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    color:
                                                                        textColor),
                                                              ),
                                                            ),
                                                          ),
                                                        ));
                                                  })
                                                  .values
                                                  .toList(),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : Container(),
                            // Modelo do veículo - só aparece quando marca está selecionada
                            if ((iscustommake && mycustommake != '') ||
                                (!iscustommake && vehicleMakeId != ''))
                              SizedBox(
                                width: media.width * 0.9,
                                child: MyText(
                                  text: languages[choosenLanguage]
                                      ['text_vehicle_model'],
                                  size: media.width * fourteen,
                                  fontweight: FontWeight.w600,
                                  maxLines: 1,
                                ),
                              ),
                            if ((iscustommake && mycustommake != '') ||
                                (!iscustommake && vehicleMakeId != ''))
                              SizedBox(
                                height: media.height * 0.012,
                              ),
                            // Modelo do veículo - só aparece quando marca está selecionada
                            if ((iscustommake && mycustommake != '') ||
                                (!iscustommake && vehicleMakeId != ''))
                              (iscustommake)
                                  ? Container(
                                      width: media.width * 0.9,
                                      height: media.width * 0.13,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: media.width * 0.05,
                                      ),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: _getBorderColor(
                                            isActive:
                                                _vehicleModelFocus.hasFocus,
                                            isFilled: mycustommodel != '',
                                            hasError: _hasVehicleModelError,
                                          ),
                                          width: 1.5,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _vehicleModelFocus.requestFocus();
                                          });
                                        },
                                        child: InputField(
                                          focusNode: _vehicleModelFocus,
                                          underline: false,
                                          autofocus: true,
                                          text: languages[choosenLanguage]?[
                                                      'text_enter_vehicle_model']
                                                  ?.toString() ??
                                              (languages['en']?[
                                                          'text_enter_vehicle_model']
                                                      ?.toString() ??
                                                  'Enter Vehicle Model'),
                                          textController: custommodelcontroller,
                                          onTap: (val) {
                                            setState(() {
                                              mycustommodel = val;
                                            });
                                          },
                                        ),
                                      ),
                                    )
                                  : InkWell(
                                      onTap: () {
                                        setState(() {
                                          if (chooseVehicleModel == true) {
                                            chooseVehicleModel = false;
                                          } else {
                                            if (vehicleMakeId != '') {
                                              chooseVehicleModel = true;
                                            } else {
                                              chooseVehicleModel = false;
                                            }
                                            chooseVehicleMake = false;
                                            chooseWorkArea = false;
                                            chooseVehicleType = false;
                                            // Limpar foco de campos de texto
                                            _vehicleNumberFocus.unfocus();
                                            _referralFocus.unfocus();
                                            _vehicleMakeFocus.unfocus();
                                            _vehicleModelFocus.unfocus();
                                          }
                                        });
                                      },
                                      child: Container(
                                        width: media.width * 0.9,
                                        height: media.width * 0.13,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: media.width * 0.05,
                                          vertical: media.width * 0.036,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: _getBorderColor(
                                              isActive: chooseVehicleModel,
                                              isFilled: vehicleModelId != '',
                                              hasError: _hasVehicleModelError,
                                            ),
                                            width: 1.5,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                (vehicleModelId == '')
                                                    ? languages[choosenLanguage]
                                                        ['text_sel_model']
                                                    : (vehicleModelId != '' &&
                                                            vehicleModelId !=
                                                                '' &&
                                                            vehicleModel
                                                                .isNotEmpty)
                                                        ? vehicleModel
                                                            .firstWhere(
                                                                (element) =>
                                                                    element['id']
                                                                        .toString() ==
                                                                    vehicleModelId)[
                                                                'name']
                                                            .toString()
                                                        : vehicleModelName == ''
                                                            ? languages[
                                                                    choosenLanguage]
                                                                [
                                                                'text_vehicle_model']
                                                            : vehicleModelName,
                                                style: GoogleFonts.poppins(
                                                  fontSize:
                                                      media.width * fourteen,
                                                  color: (vehicleModelId == '')
                                                      ? textColor
                                                          .withOpacity(0.5)
                                                      : textColor,
                                                  fontWeight:
                                                      (vehicleModelId == '')
                                                          ? FontWeight.w500
                                                          : FontWeight.w600,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ),
                                            SizedBox(width: media.width * 0.02),
                                            Icon(
                                              chooseVehicleModel
                                                  ? Icons.arrow_drop_down
                                                  : Icons.arrow_left,
                                              color: textColor,
                                              size: media.width * 0.08,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                            if ((iscustommake && mycustommake != '') ||
                                (!iscustommake && vehicleMakeId != ''))
                              SizedBox(
                                height: media.width * 0.02,
                              ),
                            if ((iscustommake && mycustommake != '') ||
                                (!iscustommake && vehicleMakeId != ''))
                              if (chooseVehicleModel == true &&
                                  vehicleModel.isNotEmpty)
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  margin: EdgeInsets.only(
                                      bottom: media.width * 0.03),
                                  width: media.width * 0.9,
                                  height: media.width * 0.5,
                                  padding: EdgeInsets.all(media.width * 0.03),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: underline),
                                  ),
                                  child: SingleChildScrollView(
                                    physics: const BouncingScrollPhysics(),
                                    child: Column(
                                      children: vehicleModel
                                          .asMap()
                                          .map((i, value) {
                                            return MapEntry(
                                                i,
                                                Material(
                                                  color: Colors.transparent,
                                                  child: InkWell(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    onTap: () async {
                                                      setState(() {
                                                        vehicleModelId =
                                                            vehicleModel[i]
                                                                    ['id']
                                                                .toString();
                                                        chooseVehicleModel =
                                                            false;
                                                        _isLoading = true;
                                                      });

                                                      var result =
                                                          await getVehicleModel();
                                                      if (result == 'success') {
                                                        setState(() {
                                                          _isLoading = false;
                                                        });
                                                      } else {
                                                        setState(() {
                                                          _isLoading = false;
                                                        });
                                                      }
                                                      // setState(() {});
                                                    },
                                                    child: Container(
                                                      width: media.width * 0.8,
                                                      padding: EdgeInsets.only(
                                                          top: media.width *
                                                              0.025,
                                                          bottom: media.width *
                                                              0.025),
                                                      child: Text(
                                                        vehicleModel[i]['name']
                                                            .toString(),
                                                        style:
                                                            GoogleFonts.poppins(
                                                                fontSize: media
                                                                        .width *
                                                                    fourteen,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color:
                                                                    textColor),
                                                      ),
                                                    ),
                                                  ),
                                                ));
                                          })
                                          .values
                                          .toList(),
                                    ),
                                  ),
                                ),
                            // Ano do modelo - só aparece quando modelo está selecionado
                            if ((iscustommake && mycustommodel != '') ||
                                (!iscustommake && vehicleModelId != ''))
                              SizedBox(
                                height: media.height * 0.02,
                              ),
                            if ((iscustommake && mycustommodel != '') ||
                                (!iscustommake && vehicleModelId != ''))
                              SizedBox(
                                width: media.width * 0.9,
                                child: MyText(
                                  text: languages[choosenLanguage]
                                      ['text_vehicle_model_year'],
                                  size: media.width * fourteen,
                                  fontweight: FontWeight.w600,
                                  maxLines: 1,
                                ),
                              ),
                            if ((iscustommake && mycustommodel != '') ||
                                (!iscustommake && vehicleModelId != ''))
                              SizedBox(
                                height: media.height * 0.012,
                              ),
                            if ((iscustommake && mycustommodel != '') ||
                                (!iscustommake && vehicleModelId != ''))
                              Container(
                                width: media.width * 0.9,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: _getBorderColor(
                                      isActive: false,
                                      isFilled: modelYear != null &&
                                          modelYear.toString().isNotEmpty,
                                      hasError: _hasModelYearError,
                                    ),
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: DropdownSearch<String>(
                                  selectedItem: modelYear != null && modelYear.toString().isNotEmpty ? modelYear.toString() : null,
                                  items: vehicleYears,
                                  itemAsString: (String year) => year,
                                  onChanged: ((iscustommake) ? mycustommodel == '' : vehicleModelId == '')
                                      ? null
                                      : (String? newValue) {
                                          if (newValue != null) {
                                            setState(() {
                                              modelYear = int.parse(newValue);
                                              modelcontroller.text = newValue;
                                              dateError = '';
                                              _hasModelYearError = false;
                                            });
                                          }
                                        },
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
                                      hintText: languages[choosenLanguage]['text_enter_vehicle_model_year'],
                                      hintStyle: GoogleFonts.poppins(fontSize: media.width * fourteen, color: hintColor),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(horizontal: media.width * 0.05, vertical: media.width * 0.036),
                                    ),
                                  ),
                                ),
                              ),

                            //vehicle number - só aparece quando modelo está selecionado

                            if ((iscustommake && mycustommodel != '') ||
                                (!iscustommake && vehicleModelId != ''))
                              SizedBox(
                                width: media.width * 0.9,
                                child: MyText(
                                  text: languages[choosenLanguage]
                                      ['text_enter_vehicle'],
                                  size: media.width * fourteen,
                                  fontweight: FontWeight.w600,
                                  maxLines: 1,
                                ),
                              ),
                            if ((iscustommake && mycustommodel != '') ||
                                (!iscustommake && vehicleModelId != ''))
                              SizedBox(
                                height: media.height * 0.012,
                              ),
                            if ((iscustommake && mycustommodel != '') ||
                                (!iscustommake && vehicleModelId != ''))
                              Container(
                                width: media.width * 0.9,
                                height: media.width * 0.13,
                                padding: EdgeInsets.symmetric(
                                  horizontal: media.width * 0.05,
                                ),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: _getBorderColor(
                                      isActive: _vehicleNumberFocus.hasFocus,
                                      isFilled:
                                          numbercontroller.text.isNotEmpty,
                                      hasError: _hasVehicleNumberError,
                                    ),
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _vehicleNumberFocus.requestFocus();
                                    });
                                  },
                                  child: InputField(
                                    focusNode: _vehicleNumberFocus,
                                    readonly: ((iscustommake)
                                            ? mycustommodel == ''
                                            : vehicleModelId == '')
                                        ? true
                                        : false,
                                    underline: false,
                                    text: languages[choosenLanguage]
                                        ['text_enter_vehicle'],
                                    textController: numbercontroller,
                                    onTap: (val) {
                                      setState(() {
                                        vehicleNumber = numbercontroller.text;
                                      });
                                    },
                                    maxLength: 20,
                                  ),
                                ),
                              ),

                            //vehicle color - só aparece quando modelo está selecionado
                            if ((iscustommake && mycustommodel != '') ||
                                (!iscustommake && vehicleModelId != ''))
                              SizedBox(
                                width: media.width * 0.9,
                                child: MyText(
                                  text: languages[choosenLanguage]
                                      ['text_vehicle_color'],
                                  size: media.width * fourteen,
                                  fontweight: FontWeight.w600,
                                  maxLines: 1,
                                ),
                              ),
                            if ((iscustommake && mycustommodel != '') ||
                                (!iscustommake && vehicleModelId != ''))
                              SizedBox(
                                height: media.height * 0.012,
                              ),
                            if ((iscustommake && mycustommodel != '') ||
                                (!iscustommake && vehicleModelId != ''))
                              Container(
                                width: media.width * 0.9,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: _getBorderColor(
                                      isActive: false,
                                      isFilled: vehicleColor != null &&
                                          vehicleColor.toString().isNotEmpty,
                                      hasError: _hasVehicleColorError,
                                    ),
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: DropdownSearch<String>(
                                  selectedItem: vehicleColor != null && vehicleColor.toString().isNotEmpty ? vehicleColor.toString() : null,
                                  items: vehicleColors,
                                  itemAsString: (String color) => color,
                                  onChanged: ((iscustommake) ? mycustommodel == '' : vehicleModelId == '')
                                      ? null
                                      : (String? newValue) {
                                          if (newValue != null) {
                                            setState(() {
                                              vehicleColor = newValue;
                                              colorcontroller.text = newValue;
                                              _hasVehicleColorError = false;
                                            });
                                          }
                                        },
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
                                      hintText: languages[choosenLanguage]['Text_enter_vehicle_color'],
                                      hintStyle: GoogleFonts.poppins(fontSize: media.width * fourteen, color: hintColor),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(horizontal: media.width * 0.05, vertical: media.width * 0.036),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    )),
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
                  ],
                ),
              ),

              // Botão fixo na parte inferior
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  top: false,
                  child: Container(
                    decoration: BoxDecoration(
                      color: page,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.only(
                      left: media.width * 0.05,
                      right: media.width * 0.05,
                      top: media.width * 0.03,
                      bottom: media.width * 0.05,
                    ),
                    child: Builder(
                      builder: (context) {
                        // Verificar condições para debug
                        // Para hasServiceId: precisa ter local selecionado OU transportType selecionado
                        // Mas se transportType está selecionado, ainda precisa ter local para finalizar
                        final hasServiceId =
                            (widget.frompage == 1 && isowner != true)
                                ? (myServiceId != null && myServiceId != '')
                                : true;
                        final hasNumber = numbercontroller.text != '' &&
                            numbercontroller.text.length < 21;
                        final hasVehicle = myVehicleId != '' || false;
                        final hasMake = (iscustommake)
                            ? mycustommake != ''
                            : vehicleMakeId != '';
                        final hasModel = (iscustommake)
                            ? mycustommodel != ''
                            : vehicleModelId != '';
                        // Validar ano do modelo com tratamento de erro
                        bool hasYear = false;
                        try {
                          if (modelYear != null) {
                            final year = int.parse(modelYear.toString());
                            final currentYear = DateTime.now().year;
                            // Ano deve estar entre o ano atual e 16 anos atrás
                            final minYear = currentYear - 16;
                            hasYear = year >= minYear && year <= currentYear;
                            debugPrint(
                                '🚀 [UI] Validação de ano - modelYear: $modelYear, currentYear: $currentYear, minYear: $minYear, hasYear: $hasYear');
                          }
                        } catch (e) {
                          debugPrint('🚀 [UI] ERRO ao validar ano: $e');
                          hasYear = false;
                        }
                        final hasColor = colorcontroller.text.isNotEmpty;

                        final allConditionsMet = hasServiceId &&
                            hasNumber &&
                            hasVehicle &&
                            hasMake &&
                            hasModel &&
                            hasYear &&
                            hasColor;

                        // Log apenas quando as condições mudarem (para evitar spam)
                        if (allConditionsMet) {
                          debugPrint(
                              '✅ [UI] Botão Continuar - Todas as condições atendidas');
                        } else {
                          debugPrint(
                              '❌ [UI] Botão Continuar - Condições não atendidas:');
                          debugPrint(
                              '   - hasServiceId: $hasServiceId (myServiceId: $myServiceId, frompage: ${widget.frompage}, isowner: $isowner)');
                          debugPrint(
                              '   - hasNumber: $hasNumber (${numbercontroller.text.length} chars)');
                          debugPrint(
                              '   - hasVehicle: $hasVehicle (myVehicleId: $myVehicleId)');
                          debugPrint(
                              '   - hasMake: $hasMake (iscustommake: $iscustommake, vehicleMakeId: $vehicleMakeId, mycustommake: $mycustommake)');
                          debugPrint(
                              '   - hasModel: $hasModel (vehicleModelId: $vehicleModelId, mycustommodel: $mycustommodel)');
                          debugPrint(
                              '   - hasYear: $hasYear (modelcontroller: ${modelcontroller.text}, modelYear: $modelYear)');
                          debugPrint(
                              '   - hasColor: $hasColor (${colorcontroller.text})');
                        }

                        return InkWell(
                          onTap: allConditionsMet
                              ? () async {
                                  await _showConfirmationDialog();
                                }
                              : () {
                                  // Validar campos e mostrar erros quando clicado enquanto desabilitado
                                  _validateFields();
                                },
                          child: Container(
                            decoration: BoxDecoration(
                              color: allConditionsMet
                                  ? buttonColor
                                  : Colors.grey.shade400,
                              borderRadius: BorderRadius.circular(80),
                            ),
                            height: media.width * 0.12,
                            padding: EdgeInsets.only(
                              left: media.width * twenty,
                              right: media.width * twenty,
                            ),
                            alignment: Alignment.center,
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: Text(
                                widget.frompage != 2
                                    ? (languages[choosenLanguage]
                                            ['text_confirm'] ??
                                        'Continuar')
                                    : (languages[choosenLanguage]
                                            ['text_updateVehicle'] ??
                                        'Atualizar veículo'),
                                style: choosenLanguage == 'ar'
                                    ? GoogleFonts.cairo(
                                        fontSize: media.width * fourteen,
                                        color: page,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1)
                                    : GoogleFonts.poppins(
                                        fontSize: media.width * sixteen,
                                        color: page,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              if (vehicleAdded == true)
                Positioned(
                    child: Container(
                  height: media.height * 1,
                  width: media.width * 1,
                  color: Colors.transparent.withOpacity(0.6),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          color: page,
                          width: media.width * 0.9,
                          padding: EdgeInsets.all(media.width * 0.05),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: media.width * 0.7,
                                child: Text(
                                    languages[choosenLanguage]
                                        ['text_vehicle_added'],
                                    style: GoogleFonts.poppins(
                                      fontSize: media.width * sixteen,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    )),
                              ),
                              SizedBox(
                                height: media.width * 0.1,
                              ),
                              Button(
                                  width: media.width * 0.2,
                                  height: media.width * 0.1,
                                  onTap: () {
                                    Navigator.pop(context, true);
                                  },
                                  text: languages[choosenLanguage]['text_ok'])
                            ],
                          ),
                        )
                      ]),
                )),
//no internet
              (internet == false)
                  ? Positioned(
                      top: 0,
                      child: NoInternet(
                        onTap: () {
                          setState(() {
                            internetTrue();
                          });
                        },
                      ))
                  : Container(),
              //loader
              (_isLoading == true)
                  ? const Positioned(top: 0, child: Loading())
                  : Container(),
            ],
          ),
        ),
      ),
    );
  }
}
