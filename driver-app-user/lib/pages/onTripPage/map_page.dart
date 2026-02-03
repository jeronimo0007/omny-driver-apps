import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:location/location.dart';
import 'dart:ui' as ui;
import '../../functions/functions.dart';
import '../../functions/geohash.dart';
import '../../functions/notifications.dart';
import '../../styles/styles.dart';
import '../../translations/translation.dart';
import '../../widgets/widgets.dart';
import '../NavigatorPages/notification.dart';
import '../loadingPage/loading.dart';
import '../login/login.dart';
import '../navDrawer/nav_drawer.dart';
import 'package:geolocator/geolocator.dart' as geolocs;
import 'package:permission_handler/permission_handler.dart' as perm;
import 'package:vector_math/vector_math.dart' as vector;
import '../noInternet/noInternet.dart';
import 'booking_confirmation.dart';
import 'drop_loc_select.dart';

class Maps extends StatefulWidget {
  const Maps({Key? key}) : super(key: key);

  @override
  State<Maps> createState() => _MapsState();
}

dynamic serviceEnabled;
dynamic currentLocation;
LatLng center = const LatLng(41.4219057, -102.0840772);
String mapStyle = '';
List myMarkers = [];
Set<Marker> markers = {};
String dropAddressConfirmation = '';
List<AddressList> addressList = <AddressList>[];
dynamic favLat;
dynamic favLng;
String favSelectedAddress = '';
String favName = 'Home';
String favNameText = '';
bool requestCancelledByDriver = false;
bool cancelRequestByUser = false;
bool logout = false;
bool _deleteAccountModalOpened = false;
int choosenTransportType =
    (userDetails['enable_modules_for_applications'] == 'both' ||
            userDetails['enable_modules_for_applications'] == 'taxi')
        ? 0
        : 1;

class _MapsState extends State<Maps>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  // dynamic _currentCenter;
  dynamic _lastCenter;
  LatLng _centerLocation = const LatLng(41.4219057, -102.0840772);
  final _debouncer = Debouncer(milliseconds: 1000);
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  dynamic animationController;
  dynamic _sessionToken;
  bool _loading = false;
  bool _pickaddress = false;
  bool _dropaddress = false;
  final bool _dropLocationMap = false;
  bool _locationDenied = false;
  int gettingPerm = 0;
  Animation<double>? _animation;

  late geolocs.LocationPermission permission;
  Location location = Location();
  String state = '';
  dynamic _controller;
  Map myBearings = {};

  dynamic pinLocationIcon;
  dynamic deliveryIcon;
  dynamic bikeIcon;
  dynamic userLocationIcon;
  bool favAddressAdd = false;
  bool contactus = false;
  bool _isDarkTheme = false;
  final TextEditingController _deleteConfirmController =
      TextEditingController();

  final _mapMarkerSC = StreamController<List<Marker>>();
  StreamSink<List<Marker>> get _mapMarkerSink => _mapMarkerSC.sink;
  Stream<List<Marker>> get carMarkerStream => _mapMarkerSC.stream;

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      _controller = controller;
      _controller?.setMapStyle(mapStyle);
    });
  }

  @override
  void initState() {
    super.initState();
    try {
      debugPrint('🔄 Maps initState() iniciado');
      _isDarkTheme = isDarkTheme;
      WidgetsBinding.instance.addObserver(this);

      // Verificar se userDetails está disponível antes de acessar
      if (userDetails.isNotEmpty &&
          userDetails.containsKey('enable_modules_for_applications')) {
        choosenTransportType =
            (userDetails['enable_modules_for_applications'] == 'both' ||
                    userDetails['enable_modules_for_applications'] == 'taxi')
                ? 0
                : 1;
      } else {
        // Valor padrão se userDetails não estiver disponível
        choosenTransportType = 0;
        debugPrint(
            '⚠️ userDetails não disponível, usando valor padrão para choosenTransportType');
      }

      getLocs();

      getadminCurrentMessages();
      debugPrint('✅ Maps initState() concluído');
    } catch (e, stackTrace) {
      debugPrint('❌ Erro em Maps initState(): $e');
      debugPrint('📋 Stack trace: $stackTrace');
      // Garantir que a UI seja atualizada mesmo com erro
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_controller != null) {
        _controller?.setMapStyle(mapStyle);
      }
      if (locationAllowed == true) {
        if (positionStream == null || positionStream!.isPaused) {
          positionStreamData();
        }
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _controller = null;
    animationController?.dispose();
    _deleteConfirmController.dispose();
    super.dispose();
  }

  navigateLogout() {
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
        (route) => false);
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

//navigate
  navigate() {
    if (choosenTransportType == 0) {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => BookingConfirmation()),
          (route) => false);
    } else if (choosenTransportType == 1) {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => DropLocation()));
    }
  }

//get location permission and location details
  getLocs() async {
    try {
      debugPrint('🔄 getLocs() iniciado');
      myBearings.clear;
      addressList.clear();
      serviceEnabled = await location.serviceEnabled();
      polyline.clear();

      // Carregar ícones com tratamento de erro
      try {
        debugPrint('🔄 Carregando ícones do mapa...');
        final Uint8List markerIcon =
            await getBytesFromAsset('assets/images/top-taxi.png', 40);
        pinLocationIcon = BitmapDescriptor.fromBytes(markerIcon);

        final Uint8List deliveryIcons =
            await getBytesFromAsset('assets/images/deliveryicon.png', 40);
        deliveryIcon = BitmapDescriptor.fromBytes(deliveryIcons);

        final Uint8List bikeIcons =
            await getBytesFromAsset('assets/images/bike.png', 40);
        bikeIcon = BitmapDescriptor.fromBytes(bikeIcons);
        debugPrint('✅ Ícones carregados com sucesso');
      } catch (e) {
        debugPrint('❌ Erro ao carregar ícones: $e');
        // Usar ícones padrão se houver erro
        pinLocationIcon = BitmapDescriptor.defaultMarker;
        deliveryIcon = BitmapDescriptor.defaultMarker;
        bikeIcon = BitmapDescriptor.defaultMarker;
      }

      permission = await geolocs.GeolocatorPlatform.instance.checkPermission();

      if (permission == geolocs.LocationPermission.denied ||
          permission == geolocs.LocationPermission.deniedForever ||
          serviceEnabled == false) {
        gettingPerm++;
        debugPrint('⚠️ Permissão negada ou serviço desabilitado');
        debugPrint(
            '   permission: $permission, serviceEnabled: $serviceEnabled, gettingPerm: $gettingPerm');

        // Sempre mostrar tela de permissão se não tiver permissão
        state = '2';
        locationAllowed = false;
        _loading = false;
        setState(() {});
        debugPrint(
            '✅ Estado atualizado para tela de permissão: state = $state');
      } else {
        debugPrint('✅ Permissão concedida, obtendo localização...');
        // Na web, getLastKnownPosition não é suportado, então usamos getCurrentPosition diretamente
        if (kIsWeb) {
          debugPrint('🌐 Modo Web: usando getCurrentPosition');
          var loc = await geolocs.Geolocator.getCurrentPosition(
              desiredAccuracy: geolocs.LocationAccuracy.low);
          debugPrint(
              '📍 Localização obtida (Web): ${loc.latitude}, ${loc.longitude}');
          setState(() {
            center = LatLng(double.parse(loc.latitude.toString()),
                double.parse(loc.longitude.toString()));
            _centerLocation = LatLng(double.parse(loc.latitude.toString()),
                double.parse(loc.longitude.toString()));
            currentLocation = LatLng(double.parse(loc.latitude.toString()),
                double.parse(loc.longitude.toString()));
            _lastCenter = _centerLocation;
          });
        } else {
          // Para mobile, mantém o comportamento original
          debugPrint('📱 Modo Mobile: tentando getLastKnownPosition primeiro');
          var locs = await geolocs.Geolocator.getLastKnownPosition();
          if (locs != null) {
            debugPrint(
                '📍 Localização obtida (LastKnown): ${locs.latitude}, ${locs.longitude}');
            setState(() {
              center = LatLng(double.parse(locs.latitude.toString()),
                  double.parse(locs.longitude.toString()));
              _centerLocation = LatLng(double.parse(locs.latitude.toString()),
                  double.parse(locs.longitude.toString()));
              currentLocation = LatLng(double.parse(locs.latitude.toString()),
                  double.parse(locs.longitude.toString()));
              _lastCenter = _centerLocation;
            });
          } else {
            debugPrint(
                '⚠️ LastKnownPosition não disponível, usando getCurrentPosition');
            try {
              var loc = await geolocs.Geolocator.getCurrentPosition(
                      desiredAccuracy: geolocs.LocationAccuracy.low)
                  .timeout(
                const Duration(seconds: 15),
                onTimeout: () {
                  debugPrint('⏱️ Timeout ao obter localização atual');
                  throw Exception('Timeout ao obter localização');
                },
              );
              debugPrint(
                  '📍 Localização obtida (Current): ${loc.latitude}, ${loc.longitude}');
              setState(() {
                center = LatLng(double.parse(loc.latitude.toString()),
                    double.parse(loc.longitude.toString()));
                _centerLocation = LatLng(double.parse(loc.latitude.toString()),
                    double.parse(loc.longitude.toString()));
                currentLocation = LatLng(double.parse(loc.latitude.toString()),
                    double.parse(loc.longitude.toString()));
                _lastCenter = _centerLocation;
              });
            } catch (e) {
              debugPrint('❌ Erro ao obter localização atual: $e');
              // Usar localização padrão se não conseguir obter
              debugPrint('⚠️ Usando localização padrão');
              setState(() {
                // Manter a localização padrão ou usar uma localização conhecida
                center = const LatLng(41.4219057, -102.0840772);
                _centerLocation = const LatLng(41.4219057, -102.0840772);
                currentLocation = const LatLng(41.4219057, -102.0840772);
                _lastCenter = _centerLocation;
              });
            }
          }
        }
        debugPrint('✅ Coordenadas definidas: center = $center');
        // Aguardar o controller estar pronto antes de animar
        if (_controller != null) {
          try {
            await _controller!
                .animateCamera(CameraUpdate.newLatLngZoom(center, 14.0));
          } catch (e) {
            debugPrint('Erro ao animar câmera: $e');
            // Tentar mover a câmera sem animação se a animação falhar
            try {
              await _controller!
                  .moveCamera(CameraUpdate.newLatLngZoom(center, 14.0));
            } catch (e2) {
              debugPrint('Erro ao mover câmera: $e2');
            }
          }
        } else {
          debugPrint('⚠️ Controller do mapa ainda não está inicializado');
          // Aguardar um pouco e tentar novamente
          Future.delayed(const Duration(milliseconds: 500), () {
            if (_controller != null && mounted) {
              _controller!
                  .animateCamera(CameraUpdate.newLatLngZoom(center, 14.0));
            }
          });
        }

        //remove in original

        try {
          var val = await geoCoding(
              _centerLocation.latitude, _centerLocation.longitude);
          setState(() {
            if (addressList
                .where((element) => element.type == 'pickup')
                .isNotEmpty) {
              var add =
                  addressList.firstWhere((element) => element.type == 'pickup');
              add.address = val;
              add.latlng =
                  LatLng(_centerLocation.latitude, _centerLocation.longitude);
            } else {
              addressList.add(AddressList(
                  id: '1',
                  type: 'pickup',
                  address: val,
                  pickup: true,
                  latlng: LatLng(
                      _centerLocation.latitude, _centerLocation.longitude),
                  name: userDetails['name'] ?? '',
                  number: userDetails['mobile'] ?? ''));
            }
          });
        } catch (e) {
          debugPrint('Erro ao fazer geocoding: $e');
          // Continuar mesmo se o geocoding falhar
          setState(() {
            if (addressList
                .where((element) => element.type == 'pickup')
                .isEmpty) {
              addressList.add(AddressList(
                  id: '1',
                  type: 'pickup',
                  address: 'Localização atual',
                  pickup: true,
                  latlng: LatLng(
                      _centerLocation.latitude, _centerLocation.longitude),
                  name: userDetails['name'] ?? '',
                  number: userDetails['mobile'] ?? ''));
            }
          });
        }

        debugPrint('✅ Localização obtida com sucesso');
        debugPrint(
            '   Latitude: ${_centerLocation.latitude}, Longitude: ${_centerLocation.longitude}');

        setState(() {
          locationAllowed = true;
          state = '3';
          _loading = false;
        });

        debugPrint(
            '✅ Estado atualizado: state = $state, _loading = $_loading, locationAllowed = $locationAllowed');

        if (locationAllowed == true) {
          try {
            if (positionStream == null || positionStream!.isPaused) {
              debugPrint('🔄 Iniciando positionStream...');
              positionStreamData();
              debugPrint('✅ positionStream iniciado');
            }
          } catch (e) {
            debugPrint('❌ Erro ao iniciar positionStream: $e');
          }
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Erro em getLocs(): $e');
      debugPrint('📋 Stack trace: $stackTrace');
      setState(() {
        _loading = false;
        locationAllowed = false;
        state = '3';
      });
    }
  }

  getLocationPermission() async {
    try {
      // Verificar permissão atual antes de solicitar
      permission = await geolocs.GeolocatorPlatform.instance.checkPermission();
      serviceEnabled = await location.serviceEnabled();

      if (permission == geolocs.LocationPermission.denied ||
          permission == geolocs.LocationPermission.deniedForever) {
        if (permission != geolocs.LocationPermission.deniedForever) {
          var status = await perm.Permission.location.request();
          // Aguardar um pouco para o sistema processar a permissão
          await Future.delayed(const Duration(milliseconds: 500));
          // Verificar novamente após solicitar
          permission =
              await geolocs.GeolocatorPlatform.instance.checkPermission();
        }
      }

      if (serviceEnabled == false) {
        try {
          await geolocs.Geolocator.getCurrentPosition(
              desiredAccuracy: geolocs.LocationAccuracy.low);
          serviceEnabled = await location.serviceEnabled();
        } catch (e) {
          debugPrint('Erro ao obter localização: $e');
        }
      }

      setState(() {
        _loading = true;
      });

      // Chamar getLocs após garantir que as permissões estão corretas
      await getLocs();
    } catch (e) {
      debugPrint('❌ Erro em getLocationPermission(): $e');
      setState(() {
        _loading = false;
        state = '2';
      });
    }
  }

  int _bottom = 0;

  GeoHasher geo = GeoHasher();

  @override
  Widget build(BuildContext context) {
    double lat = 0.0144927536231884;
    double lon = 0.0181818181818182;
    double lowerLat = center.latitude - (lat * 1.24);
    double lowerLon = center.longitude - (lon * 1.24);

    double greaterLat = center.latitude + (lat * 1.24);
    double greaterLon = center.longitude + (lon * 1.24);
    var lower = geo.encode(lowerLon, lowerLat);
    var higher = geo.encode(greaterLon, greaterLat);

    var fdb = FirebaseDatabase.instance
        .ref('drivers')
        .orderByChild('g')
        .startAt(lower)
        .endAt(higher);

    var media = MediaQuery.of(context).size;
    popFunction() {
      if (_bottom == 1) {
        return false;
      } else {
        return true;
      }
    }

    return PopScope(
      canPop: popFunction(),
      onPopInvoked: (did) {
        if (_bottom == 1) {
          setState(() {
            _bottom = 0;
          });
        }
      },
      // onWillPop: () async {
      //   if (_bottom == 1) {
      //     setState(() {
      //       _bottom = 0;
      //     });
      //     return false;
      //   }
      //   return false;
      // },
      child: Material(
        child: ValueListenableBuilder(
            valueListenable: valueNotifierHome.value,
            builder: (context, value, child) {
              if (_isDarkTheme != isDarkTheme && _controller != null) {
                _controller!.setMapStyle(mapStyle);
                _isDarkTheme = isDarkTheme;
              }
              if (isGeneral == true) {
                isGeneral = false;
                if (lastNotification != latestNotification) {
                  lastNotification = latestNotification;
                  pref.setString('lastNotification', latestNotification);
                  latestNotification = '';
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const NotificationPage()));
                  });
                }
              }
              if (userRequestData.isNotEmpty &&
                  userRequestData['is_later'] == 1 &&
                  userRequestData['is_completed'] != 1 &&
                  userRequestData['accepted_at'] != null) {
                Future.delayed(const Duration(seconds: 2), () {
                  if (userRequestData['is_rental'] == true) {
                    Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) => BookingConfirmation(
                                  type: 1,
                                )),
                        (route) => false);
                  } else {
                    Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) => BookingConfirmation()),
                        (route) => false);
                  }
                });
              }
              return Directionality(
                textDirection: (languageDirection == 'rtl')
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: Scaffold(
                  key: _scaffoldKey,
                  resizeToAvoidBottomInset: false,
                  drawer: const NavDrawer(),
                  body: Stack(
                    children: [
                      Container(
                        color: page,
                        height: media.height * 1,
                        width: media.width * 1,
                        child: Column(
                            mainAxisAlignment: (state == '1' || state == '2')
                                ? MainAxisAlignment.center
                                : MainAxisAlignment.start,
                            children: [
                              (state == '1')
                                  ? Container(
                                      height: media.height * 1,
                                      width: media.width * 1,
                                      alignment: Alignment.center,
                                      child: Container(
                                        padding:
                                            EdgeInsets.all(media.width * 0.05),
                                        width: media.width * 0.6,
                                        height: media.width * 0.3,
                                        decoration: BoxDecoration(
                                            color: page,
                                            boxShadow: [
                                              BoxShadow(
                                                  blurRadius: 5,
                                                  color: Colors.black
                                                      .withOpacity(0.1),
                                                  spreadRadius: 2)
                                            ],
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              languages[choosenLanguage]
                                                  ['text_enable_location'],
                                              style: getGoogleFontStyle(
                                                  fontSize:
                                                      media.width * sixteen,
                                                  color: textColor,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            Container(
                                              alignment: Alignment.centerRight,
                                              child: InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    state = '';
                                                  });
                                                  getLocs();
                                                },
                                                child: Text(
                                                  languages[choosenLanguage]
                                                      ['text_ok'],
                                                  style: getGoogleFontStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize:
                                                          media.width * twenty,
                                                      color: buttonColor),
                                                ),
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    )
                                  : (state == '2')
                                      ? Container(
                                          height: media.height * 1,
                                          width: media.width * 1,
                                          alignment: Alignment.center,
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Expanded(
                                                  child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  SizedBox(
                                                    height: media.height * 0.31,
                                                    child: Image.asset(
                                                      'assets/images/location_perm.png',
                                                      fit: BoxFit.contain,
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    height: media.width * 0.02,
                                                  ),
                                                  MyText(
                                                    text: languages[
                                                            choosenLanguage][
                                                        'text_allowpermission1'],
                                                    size:
                                                        media.width * eighteen,
                                                    textAlign: TextAlign.center,
                                                    fontweight: FontWeight.bold,
                                                  ),
                                                  SizedBox(
                                                    height: media.width * 0.04,
                                                  ),
                                                  MyText(
                                                    text: languages[
                                                            choosenLanguage][
                                                        'text_allowpermission2'],
                                                    size: media.width * sixteen,
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  SizedBox(
                                                    height: media.width * 0.04,
                                                  ),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Container(
                                                        height:
                                                            media.width * 0.07,
                                                        width:
                                                            media.width * 0.07,
                                                        alignment:
                                                            Alignment.center,
                                                        decoration:
                                                            BoxDecoration(
                                                                shape: BoxShape
                                                                    .circle,
                                                                color: Colors
                                                                    .red
                                                                    .withOpacity(
                                                                        0.1)),
                                                        child: const Icon(
                                                          Icons
                                                              .location_on_outlined,
                                                          color:
                                                              Color(0xFFFF0000),
                                                        ),
                                                      ),
                                                      SizedBox(
                                                          width: media.width *
                                                              0.02),
                                                      MyText(
                                                        text: languages[
                                                                choosenLanguage]
                                                            [
                                                            'text_loc_permission_user'],
                                                        size: media.width *
                                                            sixteen,
                                                        fontweight:
                                                            FontWeight.bold,
                                                      )
                                                    ],
                                                  ),
                                                ],
                                              )),
                                              Container(
                                                  padding: EdgeInsets.all(
                                                      media.width * 0.05),
                                                  child: Button(
                                                      onTap: () async {
                                                        getLocationPermission();
                                                      },
                                                      text: languages[
                                                              choosenLanguage]
                                                          ['text_allow']))
                                            ],
                                          ),
                                        )
                                      : (state == '3')
                                          ? Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                SizedBox(
                                                    height: media.height * 1,
                                                    width: media.width * 1,
                                                    child: StreamBuilder<
                                                            DatabaseEvent>(
                                                        stream: fdb.onValue,
                                                        builder: (context,
                                                            AsyncSnapshot<
                                                                    DatabaseEvent>
                                                                event) {
                                                          if (event.hasData) {
                                                            List driverData =
                                                                [];
                                                            event.data!.snapshot
                                                                .children
                                                                // ignore: avoid_function_literals_in_foreach_calls
                                                                .forEach(
                                                                    (element) {
                                                              driverData.add(
                                                                  element
                                                                      .value);
                                                            });
                                                            // ignore: avoid_function_literals_in_foreach_calls
                                                            driverData.forEach(
                                                                (element) {
                                                              if (element['is_active'] ==
                                                                      1 &&
                                                                  element['is_available'] ==
                                                                      true) {
                                                                if ((choosenTransportType ==
                                                                            0 &&
                                                                        element['transport_type'] ==
                                                                            'taxi') ||
                                                                    choosenTransportType ==
                                                                            0 &&
                                                                        element['transport_type'] ==
                                                                            'both') {
                                                                  DateTime dt =
                                                                      DateTime.fromMillisecondsSinceEpoch(
                                                                          element[
                                                                              'updated_at']);

                                                                  if (DateTime.now()
                                                                          .difference(
                                                                              dt)
                                                                          .inMinutes <=
                                                                      2) {
                                                                    if (myMarkers
                                                                        .where((e) => e
                                                                            .markerId
                                                                            .toString()
                                                                            .contains(
                                                                                'car${element['id']}'))
                                                                        .isEmpty) {
                                                                      myMarkers.add(
                                                                          Marker(
                                                                        markerId:
                                                                            MarkerId('car${element['id']}'),
                                                                        rotation: (myBearings[element['id'].toString()] !=
                                                                                null)
                                                                            ? myBearings[element['id'].toString()]
                                                                            : 0.0,
                                                                        position: LatLng(
                                                                            element['l'][0],
                                                                            element['l'][1]),
                                                                        icon: (element['vehicle_type_icon'] ==
                                                                                'taxi')
                                                                            ? pinLocationIcon
                                                                            : bikeIcon,
                                                                      ));
                                                                    } else if (_controller !=
                                                                        null) {
                                                                      if (myMarkers.lastWhere((e) => e.markerId.toString().contains('car${element['id']}')).position.latitude !=
                                                                              element['l'][
                                                                                  0] ||
                                                                          myMarkers.lastWhere((e) => e.markerId.toString().contains('car${element['id']}')).position.longitude !=
                                                                              element['l'][1]) {
                                                                        var dist = calculateDistance(
                                                                            myMarkers.lastWhere((e) => e.markerId.toString().contains('car${element['id']}')).position.latitude,
                                                                            myMarkers.lastWhere((e) => e.markerId.toString().contains('car${element['id']}')).position.longitude,
                                                                            element['l'][0],
                                                                            element['l'][1]);
                                                                        if (dist >
                                                                                100 &&
                                                                            _controller !=
                                                                                null) {
                                                                          animationController =
                                                                              AnimationController(
                                                                            duration:
                                                                                const Duration(milliseconds: 1500), //Animation duration of marker

                                                                            vsync:
                                                                                this, //From the widget
                                                                          );

                                                                          animateCar(
                                                                              myMarkers.lastWhere((e) => e.markerId.toString().contains('car${element['id']}')).position.latitude,
                                                                              myMarkers.lastWhere((e) => e.markerId.toString().contains('car${element['id']}')).position.longitude,
                                                                              element['l'][0],
                                                                              element['l'][1],
                                                                              _mapMarkerSink,
                                                                              this,
                                                                              _controller,
                                                                              'car${element['id']}',
                                                                              element['id'],
                                                                              (element['vehicle_type_icon'] == 'taxi') ? pinLocationIcon : bikeIcon);
                                                                        }
                                                                      }
                                                                    }
                                                                  }
                                                                } else if ((choosenTransportType ==
                                                                            1 &&
                                                                        element['transport_type'] ==
                                                                            'delivery') ||
                                                                    (choosenTransportType ==
                                                                            1 &&
                                                                        element['transport_type'] ==
                                                                            'both')) {
                                                                  DateTime dt =
                                                                      DateTime.fromMillisecondsSinceEpoch(
                                                                          element[
                                                                              'updated_at']);

                                                                  if (DateTime.now()
                                                                          .difference(
                                                                              dt)
                                                                          .inMinutes <=
                                                                      2) {
                                                                    if (myMarkers
                                                                        .where((e) => e
                                                                            .markerId
                                                                            .toString()
                                                                            .contains(
                                                                                'car${element['id']}'))
                                                                        .isEmpty) {
                                                                      myMarkers.add(
                                                                          Marker(
                                                                        markerId:
                                                                            MarkerId('car${element['id']}'),
                                                                        rotation: (myBearings[element['id'].toString()] !=
                                                                                null)
                                                                            ? myBearings[element['id'].toString()]
                                                                            : 0.0,
                                                                        position: LatLng(
                                                                            element['l'][0],
                                                                            element['l'][1]),
                                                                        icon: (element['vehicle_type_icon'] ==
                                                                                'truck')
                                                                            ? deliveryIcon
                                                                            : bikeIcon,
                                                                      ));
                                                                    } else if (_controller !=
                                                                        null) {
                                                                      if (myMarkers.lastWhere((e) => e.markerId.toString().contains('car${element['id']}')).position.latitude !=
                                                                              element['l'][
                                                                                  0] ||
                                                                          myMarkers.lastWhere((e) => e.markerId.toString().contains('car${element['id']}')).position.longitude !=
                                                                              element['l'][1]) {
                                                                        var dist = calculateDistance(
                                                                            myMarkers.lastWhere((e) => e.markerId.toString().contains('car${element['id']}')).position.latitude,
                                                                            myMarkers.lastWhere((e) => e.markerId.toString().contains('car${element['id']}')).position.longitude,
                                                                            element['l'][0],
                                                                            element['l'][1]);
                                                                        if (dist >
                                                                                100 &&
                                                                            _controller !=
                                                                                null) {
                                                                          animationController =
                                                                              AnimationController(
                                                                            duration:
                                                                                const Duration(milliseconds: 1500), //Animation duration of marker

                                                                            vsync:
                                                                                this, //From the widget
                                                                          );

                                                                          animateCar(
                                                                            myMarkers.lastWhere((e) => e.markerId.toString().contains('car${element['id']}')).position.latitude,
                                                                            myMarkers.lastWhere((e) => e.markerId.toString().contains('car${element['id']}')).position.longitude,
                                                                            element['l'][0],
                                                                            element['l'][1],
                                                                            _mapMarkerSink,
                                                                            this,
                                                                            _controller,
                                                                            'car${element['id']}',
                                                                            element['id'],
                                                                            (element['vehicle_type_icon'] == 'truck')
                                                                                ? deliveryIcon
                                                                                : bikeIcon,
                                                                          );
                                                                        }
                                                                      }
                                                                    }
                                                                  }
                                                                }
                                                              } else {
                                                                if (myMarkers
                                                                    .where((e) => e
                                                                        .markerId
                                                                        .toString()
                                                                        .contains(
                                                                            'car${element['id']}'))
                                                                    .isNotEmpty) {
                                                                  myMarkers.removeWhere((e) => e
                                                                      .markerId
                                                                      .toString()
                                                                      .contains(
                                                                          'car${element['id']}'));
                                                                }
                                                              }
                                                            });
                                                          }
                                                          return StreamBuilder<
                                                                  List<Marker>>(
                                                              stream:
                                                                  carMarkerStream,
                                                              builder: (context,
                                                                  snapshot) {
                                                                return GoogleMap(
                                                                  onMapCreated:
                                                                      _onMapCreated,
                                                                  compassEnabled:
                                                                      false,
                                                                  initialCameraPosition:
                                                                      CameraPosition(
                                                                    target:
                                                                        center,
                                                                    zoom: 14.0,
                                                                  ),
                                                                  onCameraMove:
                                                                      (CameraPosition
                                                                          position) {
                                                                    _centerLocation =
                                                                        position
                                                                            .target;
                                                                  },
                                                                  onCameraIdle:
                                                                      () async {
                                                                    setState(
                                                                        () {});
                                                                  },
                                                                  minMaxZoomPreference:
                                                                      const MinMaxZoomPreference(
                                                                          8.0,
                                                                          20.0),
                                                                  myLocationButtonEnabled:
                                                                      false,
                                                                  markers: Set<
                                                                          Marker>.from(
                                                                      myMarkers),
                                                                  buildingsEnabled:
                                                                      false,
                                                                  zoomControlsEnabled:
                                                                      false,
                                                                  myLocationEnabled:
                                                                      true,
                                                                );
                                                              });
                                                        })),
                                                Positioned(
                                                    top: 0,
                                                    child: Container(
                                                        height:
                                                            media.height * 1,
                                                        width: media.width * 1,
                                                        alignment:
                                                            Alignment.center,
                                                        child: (_dropLocationMap ==
                                                                false)
                                                            ? Column(
                                                                children: [
                                                                  SizedBox(
                                                                    height: (media.height /
                                                                            2) -
                                                                        media.width *
                                                                            0.08,
                                                                  ),
                                                                  Image.asset(
                                                                    'assets/images/pick_icon.png',
                                                                    width: media
                                                                            .width *
                                                                        0.07,
                                                                    height: media
                                                                            .width *
                                                                        0.08,
                                                                  ),
                                                                  const SizedBox(
                                                                    height: 10,
                                                                  ),
                                                                  InkWell(
                                                                    onTap: () {
                                                                      setState(
                                                                          () {
                                                                        _pickaddress =
                                                                            true;
                                                                        _dropaddress =
                                                                            false;
                                                                        addAutoFill
                                                                            .clear();
                                                                        _bottom =
                                                                            1;
                                                                      });
                                                                    },
                                                                    child:
                                                                        Container(
                                                                      decoration: BoxDecoration(
                                                                          gradient: LinearGradient(colors: [
                                                                            (isDarkTheme == true)
                                                                                ? const Color(0xff000000)
                                                                                : const Color(0xffFFFFFF),
                                                                            (isDarkTheme == true)
                                                                                ? theme
                                                                                : const Color(0xffEFEFEF),
                                                                          ], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                                                                          borderRadius: BorderRadius.circular(5)),
                                                                      width: media
                                                                              .width *
                                                                          0.8,
                                                                      padding:
                                                                          const EdgeInsets
                                                                              .all(
                                                                              5),
                                                                      child:
                                                                          Row(
                                                                        children: [
                                                                          Expanded(
                                                                            child:
                                                                                MyText(
                                                                              size: media.width * twelve,
                                                                              fontweight: FontWeight.w600,
                                                                              text: (addressList.where((element) => element.type == 'pickup').isNotEmpty) ? addressList.firstWhere((element) => element.type == 'pickup', orElse: () => AddressList(id: '', address: '', pickup: true, latlng: const LatLng(0.0, 0.0))).address : languages[choosenLanguage]['text_4lettersforautofill'],
                                                                              // maxLines: 1,
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  SizedBox(
                                                                    height: media
                                                                            .width *
                                                                        0.025,
                                                                  ),
                                                                  if (_lastCenter !=
                                                                      _centerLocation)
                                                                    Row(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .center,
                                                                      children: [
                                                                        Button(
                                                                          onTap:
                                                                              () async {
                                                                            setState(() {
                                                                              _loading = true;
                                                                            });
                                                                            var val =
                                                                                await geoCoding(_centerLocation.latitude, _centerLocation.longitude);
                                                                            setState(() {
                                                                              if (addressList.where((element) => element.type == 'pickup').isNotEmpty) {
                                                                                var add = addressList.firstWhere((element) => element.type == 'pickup');
                                                                                add.address = val;
                                                                                add.latlng = LatLng(_centerLocation.latitude, _centerLocation.longitude);
                                                                              } else {
                                                                                addressList.add(AddressList(id: '1', type: 'pickup', address: val, pickup: true, latlng: LatLng(_centerLocation.latitude, _centerLocation.longitude), name: userDetails['name'] ?? '', number: userDetails['mobile'] ?? ''));
                                                                              }
                                                                              _lastCenter = _centerLocation;
                                                                              _loading = false;
                                                                            });
                                                                          },
                                                                          text: languages[choosenLanguage]
                                                                              [
                                                                              'text_confirm'],
                                                                        ),
                                                                      ],
                                                                    ),
                                                                ],
                                                              )
                                                            : Image.asset(
                                                                'assets/images/dropmarker.png'))),
                                                Positioned(
                                                  right: 10,
                                                  top: 150,
                                                  child: InkWell(
                                                    onTap: () async {
                                                      if (contactus == false) {
                                                        setState(() {
                                                          contactus = true;
                                                        });
                                                      } else {
                                                        setState(() {
                                                          contactus = false;
                                                        });
                                                      }
                                                    },
                                                    child: Container(
                                                      height: media.width * 0.1,
                                                      width: media.width * 0.1,
                                                      decoration: BoxDecoration(
                                                          boxShadow: [
                                                            BoxShadow(
                                                                blurRadius: 2,
                                                                color: Colors
                                                                    .black
                                                                    .withOpacity(
                                                                        0.2),
                                                                spreadRadius: 2)
                                                          ],
                                                          color: page,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(media
                                                                          .width *
                                                                      0.02)),
                                                      alignment:
                                                          Alignment.center,
                                                      child: Image.asset(
                                                          'assets/images/customercare.png',
                                                          fit: BoxFit.contain,
                                                          width: media.width *
                                                              0.06,
                                                          color: textColor),
                                                    ),
                                                  ),
                                                ),
                                                (contactus == true)
                                                    ? Positioned(
                                                        right: 10,
                                                        top: 155 +
                                                            media.width * 0.1,
                                                        child: InkWell(
                                                          onTap: () async {},
                                                          child: Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(10),
                                                              height: media.width *
                                                                  0.3,
                                                              width: media
                                                                      .width *
                                                                  0.45,
                                                              decoration: BoxDecoration(
                                                                  boxShadow: [
                                                                    BoxShadow(
                                                                        blurRadius:
                                                                            2,
                                                                        color: Colors
                                                                            .black
                                                                            .withOpacity(
                                                                                0.2),
                                                                        spreadRadius:
                                                                            2)
                                                                  ],
                                                                  color: page,
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(media.width *
                                                                              0.02)),
                                                              alignment:
                                                                  Alignment
                                                                      .center,
                                                              child: Column(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceEvenly,
                                                                children: [
                                                                  InkWell(
                                                                    onTap: () {
                                                                      makingPhoneCall(
                                                                          userDetails[
                                                                              'contact_us_mobile1']);
                                                                    },
                                                                    child: Row(
                                                                      children: [
                                                                        Expanded(
                                                                            flex:
                                                                                20,
                                                                            child:
                                                                                Icon(
                                                                              Icons.call,
                                                                              color: textColor,
                                                                            )),
                                                                        Expanded(
                                                                            flex:
                                                                                80,
                                                                            child:
                                                                                Text(
                                                                              userDetails['contact_us_mobile1'],
                                                                              style: getGoogleFontStyle(fontSize: media.width * fourteen, color: textColor),
                                                                            ))
                                                                      ],
                                                                    ),
                                                                  ),
                                                                  InkWell(
                                                                    onTap: () {
                                                                      makingPhoneCall(
                                                                          userDetails[
                                                                              'contact_us_mobile1']);
                                                                    },
                                                                    child: Row(
                                                                      children: [
                                                                        Expanded(
                                                                            flex:
                                                                                20,
                                                                            child:
                                                                                Icon(Icons.call, color: textColor)),
                                                                        Expanded(
                                                                            flex:
                                                                                80,
                                                                            child:
                                                                                Text(
                                                                              userDetails['contact_us_mobile2'],
                                                                              style: getGoogleFontStyle(fontSize: media.width * fourteen, color: textColor),
                                                                            ))
                                                                      ],
                                                                    ),
                                                                  ),
                                                                  InkWell(
                                                                    onTap: () {
                                                                      openBrowser(
                                                                          userDetails['contact_us_link']
                                                                              .toString());
                                                                    },
                                                                    child: Row(
                                                                      children: [
                                                                        Expanded(
                                                                            flex:
                                                                                20,
                                                                            child:
                                                                                Icon(Icons.vpn_lock_rounded, color: textColor)),
                                                                        Expanded(
                                                                            flex:
                                                                                80,
                                                                            child:
                                                                                Text(
                                                                              languages[choosenLanguage]['text_goto_url'],
                                                                              maxLines: 1,
                                                                              style: getGoogleFontStyle(fontSize: media.width * fourteen, color: textColor),
                                                                            ))
                                                                      ],
                                                                    ),
                                                                  )
                                                                ],
                                                              )),
                                                        ),
                                                      )
                                                    : Container(),
                                                (_bottom == 0)
                                                    ? Positioned(
                                                        top: MediaQuery.of(
                                                                    context)
                                                                .padding
                                                                .top +
                                                            25,
                                                        left: 0,
                                                        right: 0,
                                                        child: Padding(
                                                          padding: EdgeInsets.symmetric(horizontal: media.width * 0.05),
                                                          child: Row(
                                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                            children: [
                                                              Container(
                                                                height: 35,
                                                                width: 35,
                                                                decoration: BoxDecoration(
                                                                    boxShadow: [
                                                                      (_bottom == 0)
                                                                          ? BoxShadow(
                                                                              blurRadius: (_bottom == 0) ? 2 : 0,
                                                                              color: (_bottom == 0) ? Colors.black.withOpacity(0.2) : Colors.transparent,
                                                                              spreadRadius: (_bottom == 0) ? 2 : 0)
                                                                          : const BoxShadow(),
                                                                    ],
                                                                    color: page,
                                                                    borderRadius: BorderRadius.circular(4)),
                                                                alignment: Alignment.center,
                                                                child: InkWell(
                                                                    onTap: () {
                                                                      _scaffoldKey.currentState?.openDrawer();
                                                                    },
                                                                    child: Icon(Icons.menu, color: textColor)),
                                                              ),
                                                              (banners.isNotEmpty)
                                                                  ? SizedBox(
                                                                      width: media.width * 0.5,
                                                                      height: media.width * 0.15,
                                                                      child: const BannerImage())
                                                                  : const SizedBox.shrink(),
                                                              ValueListenableBuilder(
                                                                valueListenable: valueNotifierNotification.value,
                                                                builder: (context, value, child) {
                                                                  return Container(
                                                                    height: 35,
                                                                    width: 35,
                                                                    decoration: BoxDecoration(
                                                                      boxShadow: [
                                                                        BoxShadow(
                                                                          blurRadius: 2,
                                                                          color: Colors.black.withOpacity(0.2),
                                                                          spreadRadius: 2,
                                                                        ),
                                                                      ],
                                                                      color: page,
                                                                      borderRadius: BorderRadius.circular(4),
                                                                    ),
                                                                    alignment: Alignment.center,
                                                                    child: Stack(
                                                                      clipBehavior: Clip.none,
                                                                      children: [
                                                                        InkWell(
                                                                          onTap: () {
                                                                            userDetails['notifications_count'] = 0;
                                                                            Navigator.push(
                                                                              context,
                                                                              MaterialPageRoute(
                                                                                builder: (context) => const NotificationPage(),
                                                                              ),
                                                                            );
                                                                          },
                                                                          child: Icon(Icons.notifications_outlined, color: textColor, size: 22),
                                                                        ),
                                                                        if ((userDetails['notifications_count'] ?? 0) > 0)
                                                                          Positioned(
                                                                            right: -2,
                                                                            top: -2,
                                                                            child: Container(
                                                                              padding: const EdgeInsets.all(4),
                                                                              decoration: const BoxDecoration(
                                                                                shape: BoxShape.circle,
                                                                                color: Colors.red,
                                                                              ),
                                                                              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                                                              child: Text(
                                                                                (userDetails['notifications_count'] ?? 0).toString(),
                                                                                style: const TextStyle(fontSize: 10, color: Colors.white),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                      ],
                                                                    ),
                                                                  );
                                                                },
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                    )
                                                    : Container(),
                                                (_bottom == 0)
                                                    ? Positioned(
                                                        top: MediaQuery.of(
                                                                    context)
                                                                .padding
                                                                .top +
                                                            5,
                                                        left: 0,
                                                        right: 0,
                                                        child: Container(
                                                          alignment:
                                                              Alignment.center,
                                                          child: Text(
                                                            'Google',
                                                            style:
                                                                getGoogleFontStyle(
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              color: textColor
                                                                  .withOpacity(
                                                                      0.6),
                                                            ),
                                                          ),
                                                        ),
                                                      )
                                                    : Container(),
                                                Positioned(
                                                    bottom: 20 +
                                                        media.width * 0.43 +
                                                        50,
                                                    child: SizedBox(
                                                      width: media.width * 0.9,
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          (userDetails[
                                                                      'show_rental_ride'] ==
                                                                  true)
                                                              ? Button(
                                                                  onTap: () {
                                                                    if (addressList
                                                                        .isNotEmpty) {
                                                                      Navigator.pushAndRemoveUntil(
                                                                          context,
                                                                          MaterialPageRoute(
                                                                              builder: (context) => BookingConfirmation(
                                                                                    type: 1,
                                                                                  )),
                                                                          (route) => false);
                                                                    }
                                                                  },
                                                                  text: languages[
                                                                          choosenLanguage]
                                                                      [
                                                                      'text_rental'],
                                                                )
                                                              : Container(),
                                                          InkWell(
                                                            onTap: () async {
                                                              if (locationAllowed ==
                                                                  true) {
                                                                if (currentLocation !=
                                                                    null) {
                                                                  _controller?.animateCamera(
                                                                      CameraUpdate.newLatLngZoom(
                                                                          currentLocation,
                                                                          18.0));
                                                                  center =
                                                                      currentLocation;
                                                                } else {
                                                                  _controller?.animateCamera(
                                                                      CameraUpdate.newLatLngZoom(
                                                                          center,
                                                                          18.0));
                                                                }
                                                              } else {
                                                                if (serviceEnabled ==
                                                                    true) {
                                                                  setState(() {
                                                                    _locationDenied =
                                                                        true;
                                                                  });
                                                                } else {
                                                                  await geolocs
                                                                          .Geolocator
                                                                      .getCurrentPosition(
                                                                          desiredAccuracy: geolocs
                                                                              .LocationAccuracy
                                                                              .low);
                                                                  if (await geolocs
                                                                      .GeolocatorPlatform
                                                                      .instance
                                                                      .isLocationServiceEnabled()) {
                                                                    setState(
                                                                        () {
                                                                      _locationDenied =
                                                                          true;
                                                                    });
                                                                  }
                                                                }
                                                              }
                                                            },
                                                            child: Container(
                                                              height: 30,
                                                              width: 30,
                                                              decoration: BoxDecoration(
                                                                  boxShadow: [
                                                                    BoxShadow(
                                                                        blurRadius:
                                                                            2,
                                                                        color: Colors
                                                                            .black
                                                                            .withOpacity(
                                                                                0.2),
                                                                        spreadRadius:
                                                                            2)
                                                                  ],
                                                                  color: page,
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                          media.width *
                                                                              0.02)),
                                                              child: Icon(
                                                                  Icons
                                                                      .my_location_sharp,
                                                                  size: 20,
                                                                  color:
                                                                      textColor),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    )),
                                                Positioned(
                                                    bottom:
                                                        MediaQuery.of(context)
                                                                .padding
                                                                .bottom +
                                                            20,
                                                    child: GestureDetector(
                                                      onPanUpdate: (val) {
                                                        if (val.delta.dy > 0) {
                                                          setState(() {
                                                            _bottom = 0;
                                                            addAutoFill.clear();
                                                            _pickaddress =
                                                                false;
                                                            _dropaddress =
                                                                false;
                                                          });
                                                        }
                                                        if (val.delta.dy < 0) {
                                                          setState(() {
                                                            _bottom = 1;
                                                          });
                                                        }
                                                      },
                                                      child: Container(
                                                        padding: (_bottom == 1)
                                                            ? EdgeInsets.fromLTRB(
                                                                media.width *
                                                                    0.05,
                                                                media.width *
                                                                        0.03 +
                                                                    MediaQuery.of(
                                                                            context)
                                                                        .padding
                                                                        .top,
                                                                media
                                                                        .width *
                                                                    0.05,
                                                                0)
                                                            : EdgeInsets.only(
                                                                left: media
                                                                        .width *
                                                                    0.05,
                                                                right: media
                                                                        .width *
                                                                    0.05),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: page,
                                                          borderRadius: (_bottom ==
                                                                  0)
                                                              ? const BorderRadius
                                                                  .only(
                                                                  topLeft: Radius
                                                                      .circular(
                                                                          10),
                                                                  topRight: Radius
                                                                      .circular(
                                                                          10))
                                                              : BorderRadius
                                                                  .circular(0),
                                                        ),
                                                        height: (_bottom == 0)
                                                            ? media.width * 0.43
                                                            : media.height * 1,
                                                        width: media.width * 1,
                                                        child: Column(
                                                          children: [
                                                            (_bottom == 1)
                                                                ? Column(
                                                                    children: [
                                                                      const SizedBox(
                                                                        height:
                                                                            50,
                                                                      ),
                                                                      Row(
                                                                        children: [
                                                                          Material(
                                                                            color:
                                                                                Colors.transparent,
                                                                            child:
                                                                                InkWell(
                                                                              onTap: () {
                                                                                if (mounted) {
                                                                                  setState(() {
                                                                                    _bottom = 0;
                                                                                  });
                                                                                }
                                                                              },
                                                                              borderRadius: BorderRadius.circular(media.width * 0.05),
                                                                              child: Container(
                                                                                padding: EdgeInsets.all(media.width * 0.03),
                                                                                decoration: BoxDecoration(
                                                                                  color: (isDarkTheme == true) ? Colors.black.withOpacity(0.3) : Colors.white.withOpacity(0.9),
                                                                                  borderRadius: BorderRadius.circular(media.width * 0.05),
                                                                                  boxShadow: [
                                                                                    BoxShadow(
                                                                                      color: Colors.black.withOpacity(0.1),
                                                                                      blurRadius: 4,
                                                                                      offset: const Offset(0, 2),
                                                                                    ),
                                                                                  ],
                                                                                ),
                                                                                child: Icon(
                                                                                  Icons.arrow_back_ios,
                                                                                  color: (isDarkTheme == true) ? theme : Colors.black87,
                                                                                  size: media.width * 0.07,
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          SizedBox(
                                                                              width: media.width * 0.02),
                                                                          Expanded(
                                                                            child:
                                                                                MyText(
                                                                              text: languages[choosenLanguage]['text_where_to_go'],
                                                                              size: media.width * sixteen,
                                                                              fontweight: FontWeight.w700,
                                                                              color: textColor,
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                      SizedBox(
                                                                        height: media.width *
                                                                            0.02,
                                                                      ),
                                                                    ],
                                                                  )
                                                                : Container(),
                                                            (_bottom == 1)
                                                                ? Container(
                                                                    margin: const EdgeInsets
                                                                        .only(
                                                                        top:
                                                                            50),
                                                                    constraints:
                                                                        BoxConstraints(
                                                                      maxHeight: MediaQuery.of(context).viewInsets.bottom >
                                                                              0
                                                                          ? media.height *
                                                                              0.4
                                                                          : media.height *
                                                                              0.45,
                                                                    ),
                                                                    width: media
                                                                            .width *
                                                                        0.9,
                                                                    padding: EdgeInsets.only(
                                                                        left: media.width *
                                                                            0.02,
                                                                        right: media.width *
                                                                            0.02,
                                                                        bottom: media.width *
                                                                            0.02,
                                                                        top: 0),
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      borderRadius:
                                                                          BorderRadius.circular(media.width *
                                                                              0.02),
                                                                      color:
                                                                          page,
                                                                    ),
                                                                    child:
                                                                        SingleChildScrollView(
                                                                      child:
                                                                          Column(
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.start,
                                                                        mainAxisSize:
                                                                            MainAxisSize.min,
                                                                        children: [
                                                                          // Campo de Origem (Pickup) - Design Moderno
                                                                          Padding(
                                                                            padding:
                                                                                EdgeInsets.only(left: media.width * 0.04, bottom: media.width * 0.01),
                                                                            child:
                                                                                MyText(
                                                                              text: languages[choosenLanguage]['text_pickup'],
                                                                              size: media.width * fourteen,
                                                                              fontweight: FontWeight.w600,
                                                                              color: textColor,
                                                                            ),
                                                                          ),
                                                                          Container(
                                                                            margin:
                                                                                const EdgeInsets.only(bottom: 0, top: 0),
                                                                            width:
                                                                                double.infinity,
                                                                            decoration:
                                                                                BoxDecoration(
                                                                              color: (isDarkTheme == true) ? Colors.black : Colors.white,
                                                                              borderRadius: BorderRadius.circular(media.width * 0.03),
                                                                              border: Border.all(
                                                                                color: Colors.green.withOpacity(0.4),
                                                                                width: 2,
                                                                              ),
                                                                              boxShadow: [
                                                                                BoxShadow(
                                                                                  color: Colors.green.withOpacity(0.1),
                                                                                  blurRadius: 12,
                                                                                  offset: const Offset(0, 4),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                            child:
                                                                                Row(
                                                                              children: [
                                                                                Container(
                                                                                  margin: EdgeInsets.all(media.width * 0.02),
                                                                                  height: media.width * 0.07,
                                                                                  width: media.width * 0.07,
                                                                                  alignment: Alignment.center,
                                                                                  decoration: BoxDecoration(
                                                                                    shape: BoxShape.circle,
                                                                                    color: Colors.green.withOpacity(0.15),
                                                                                  ),
                                                                                  child: Icon(
                                                                                    Icons.circle,
                                                                                    size: media.width * 0.035,
                                                                                    color: Colors.green,
                                                                                  ),
                                                                                ),
                                                                                (_pickaddress == true && _bottom == 1)
                                                                                    ? Expanded(
                                                                                        child: TextField(
                                                                                            autofocus: true,
                                                                                            decoration: InputDecoration(
                                                                                              hintText: languages[choosenLanguage]['text_4letterpickup'],
                                                                                              hintStyle: getGoogleFontStyle(
                                                                                                fontSize: media.width * twelve,
                                                                                                color: textColor.withOpacity(0.4),
                                                                                              ),
                                                                                              border: InputBorder.none,
                                                                                            ),
                                                                                            style: getGoogleFontStyle(fontSize: media.width * fourteen, color: (isDarkTheme == true) ? theme : textColor),
                                                                                            maxLines: 1,
                                                                                            onChanged: (val) {
                                                                                              _debouncer.run(() {
                                                                                                if (val.length >= 3) {
                                                                                                  if (storedAutoAddress.where((element) => element['description'].toString().toLowerCase().contains(val.toLowerCase())).isNotEmpty) {
                                                                                                    addAutoFill.removeWhere((element) => element['description'].toString().toLowerCase().contains(val.toLowerCase()) == false);
                                                                                                    storedAutoAddress.where((element) => element['description'].toString().toLowerCase().contains(val.toLowerCase())).forEach((element) {
                                                                                                      addAutoFill.add(element);
                                                                                                    });
                                                                                                    valueNotifierHome.incrementNotifier();
                                                                                                  } else {
                                                                                                    getAutoAddress(val, _sessionToken, center.latitude, center.longitude);
                                                                                                  }
                                                                                                } else {
                                                                                                  setState(() {
                                                                                                    addAutoFill.clear();
                                                                                                  });
                                                                                                }
                                                                                              });
                                                                                            }),
                                                                                      )
                                                                                    : Expanded(
                                                                                        child: InkWell(
                                                                                          onTap: () {
                                                                                            setState(() {
                                                                                              _dropaddress = false;
                                                                                              _pickaddress = true;
                                                                                            });
                                                                                          },
                                                                                          child: Row(
                                                                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                            children: [
                                                                                              SizedBox(
                                                                                                width: media.width * 0.55,
                                                                                                child: MyText(
                                                                                                  text: (addressList.where((element) => element.type == 'pickup').isNotEmpty) ? addressList.firstWhere((element) => element.type == 'pickup', orElse: () => AddressList(id: '', address: '', pickup: true, latlng: const LatLng(0.0, 0.0))).address : languages[choosenLanguage]['text_4letterpickup'],
                                                                                                  size: media.width * fourteen,
                                                                                                  color: textColor,
                                                                                                  maxLines: 1,
                                                                                                  overflow: TextOverflow.ellipsis,
                                                                                                ),
                                                                                              ),
                                                                                            ],
                                                                                          ),
                                                                                        ),
                                                                                      ),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                          // Campo de Destino (Drop) - Design Moderno
                                                                          Padding(
                                                                            padding: EdgeInsets.only(
                                                                                left: media.width * 0.04,
                                                                                bottom: media.width * 0.01,
                                                                                top: media.width * 0.05),
                                                                            child:
                                                                                MyText(
                                                                              text: languages[choosenLanguage]['text_where_to_go'],
                                                                              size: media.width * fourteen,
                                                                              fontweight: FontWeight.w600,
                                                                              color: textColor,
                                                                            ),
                                                                          ),
                                                                          Container(
                                                                            margin:
                                                                                EdgeInsets.only(bottom: 0, top: media.width * 0.02),
                                                                            width:
                                                                                double.infinity,
                                                                            decoration:
                                                                                BoxDecoration(
                                                                              color: (isDarkTheme == true) ? Colors.black : Colors.white,
                                                                              borderRadius: BorderRadius.circular(media.width * 0.03),
                                                                              border: Border.all(
                                                                                color: Colors.red.withOpacity(0.4),
                                                                                width: 2,
                                                                              ),
                                                                              boxShadow: [
                                                                                BoxShadow(
                                                                                  color: Colors.red.withOpacity(0.1),
                                                                                  blurRadius: 12,
                                                                                  offset: const Offset(0, 4),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                            child:
                                                                                Row(
                                                                              children: [
                                                                                Container(
                                                                                  margin: EdgeInsets.all(media.width * 0.02),
                                                                                  height: media.width * 0.07,
                                                                                  width: media.width * 0.07,
                                                                                  alignment: Alignment.center,
                                                                                  decoration: BoxDecoration(
                                                                                    shape: BoxShape.circle,
                                                                                    color: Colors.red.withOpacity(0.15),
                                                                                  ),
                                                                                  child: Icon(
                                                                                    Icons.place,
                                                                                    size: media.width * 0.035,
                                                                                    color: Colors.red,
                                                                                  ),
                                                                                ),
                                                                                (_dropaddress == true && _bottom == 1)
                                                                                    ? Expanded(
                                                                                        child: TextField(
                                                                                            autofocus: true,
                                                                                            decoration: InputDecoration(
                                                                                              contentPadding: (languageDirection == 'rtl') ? EdgeInsets.only(bottom: media.width * 0.035) : EdgeInsets.only(bottom: media.width * 0.03),
                                                                                              border: InputBorder.none,
                                                                                              hintText: languages[choosenLanguage]['text_4lettersforautofill'],
                                                                                              hintStyle: getGoogleFontStyle(
                                                                                                fontSize: media.width * twelve,
                                                                                                color: textColor.withOpacity(0.4),
                                                                                              ),
                                                                                            ),
                                                                                            style: getGoogleFontStyle(fontSize: media.width * fourteen, color: (isDarkTheme == true) ? theme : textColor),
                                                                                            maxLines: 1,
                                                                                            onChanged: (val) {
                                                                                              _debouncer.run(() {
                                                                                                if (val.length >= 3) {
                                                                                                  getAutoAddress(val, _sessionToken, center.latitude, center.longitude);
                                                                                                } else {
                                                                                                  setState(() {
                                                                                                    addAutoFill.clear();
                                                                                                  });
                                                                                                }
                                                                                              });
                                                                                            }),
                                                                                      )
                                                                                    : Expanded(
                                                                                        child: InkWell(
                                                                                          onTap: () {
                                                                                            setState(() {
                                                                                              _dropaddress = true;
                                                                                              _pickaddress = false;
                                                                                            });
                                                                                          },
                                                                                          child: Row(
                                                                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                            children: [
                                                                                              SizedBox(
                                                                                                width: media.width * 0.55,
                                                                                                child: MyText(
                                                                                                  text: languages[choosenLanguage]['text_4lettersforautofill'],
                                                                                                  size: media.width * fourteen,
                                                                                                  color: (isDarkTheme == true) ? theme : textColor,
                                                                                                  maxLines: 1,
                                                                                                  overflow: TextOverflow.ellipsis,
                                                                                                ),
                                                                                              ),
                                                                                            ],
                                                                                          ),
                                                                                        ),
                                                                                      )
                                                                              ],
                                                                            ),
                                                                          ),
                                                                          // Locais Salvos
                                                                          (favAddress.isNotEmpty && _bottom == 1 && addAutoFill.isEmpty)
                                                                              ? Column(
                                                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                                                  children: [
                                                                                    SizedBox(
                                                                                      height: media.width * 0.02,
                                                                                    ),
                                                                                    MyText(
                                                                                      text: languages[choosenLanguage]['text_saved_place'],
                                                                                      size: media.width * fourteen,
                                                                                      fontweight: FontWeight.w700,
                                                                                    ),
                                                                                    SizedBox(
                                                                                      height: media.width * 0.02,
                                                                                    ),
                                                                                    (favAddress.length > 5)
                                                                                        ? SizedBox(
                                                                                            width: media.width * 0.9,
                                                                                            height: media.height * 0.26,
                                                                                            child: SingleChildScrollView(
                                                                                              child: Column(
                                                                                                children: [
                                                                                                  (favAddress.isNotEmpty)
                                                                                                      ? Column(
                                                                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                                                                          children: favAddress
                                                                                                              .asMap()
                                                                                                              .map((i, value) {
                                                                                                                return MapEntry(
                                                                                                                    i,
                                                                                                                    (i < 5)
                                                                                                                        ? Container(
                                                                                                                            padding: EdgeInsets.fromLTRB(0, media.width * 0.04, 0, media.width * 0.04),
                                                                                                                            decoration: BoxDecoration(
                                                                                                                              border: Border(bottom: BorderSide(width: 1.0, color: (isDarkTheme == true) ? textColor.withOpacity(0.2) : textColor.withOpacity(0.1))),
                                                                                                                            ),
                                                                                                                            child: Column(
                                                                                                                              children: [
                                                                                                                                SizedBox(
                                                                                                                                  width: media.width * 0.9,
                                                                                                                                  child: MyText(text: favAddress[i]['address_name'], size: media.width * twelve, maxLines: 2),
                                                                                                                                ),
                                                                                                                                SizedBox(
                                                                                                                                  height: media.width * 0.025,
                                                                                                                                ),
                                                                                                                                Row(
                                                                                                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                                                                  children: [
                                                                                                                                    SizedBox(
                                                                                                                                      height: media.width * 0.05,
                                                                                                                                      width: media.width * 0.05,
                                                                                                                                      child: (favAddress[i]['address_name'] == 'Home')
                                                                                                                                          ? Image.asset(
                                                                                                                                              'assets/images/home.png',
                                                                                                                                              color: textColor,
                                                                                                                                              width: media.width * 0.04,
                                                                                                                                            )
                                                                                                                                          : (favAddress[i]['address_name'] == 'Work')
                                                                                                                                              ? Image.asset(
                                                                                                                                                  'assets/images/briefcase.png',
                                                                                                                                                  color: textColor,
                                                                                                                                                  width: media.width * 0.04,
                                                                                                                                                )
                                                                                                                                              : Image.asset(
                                                                                                                                                  'assets/images/navigation.png',
                                                                                                                                                  color: textColor,
                                                                                                                                                  width: media.width * 0.04,
                                                                                                                                                ),
                                                                                                                                    ),
                                                                                                                                    InkWell(
                                                                                                                                      onTap: () async {
                                                                                                                                        if (_pickaddress == true) {
                                                                                                                                          setState(() {
                                                                                                                                            addAutoFill.clear();
                                                                                                                                            if (addressList.where((element) => element.type == 'pickup').isEmpty) {
                                                                                                                                              addressList.add(AddressList(id: '1', type: 'pickup', pickup: true, address: favAddress[i]['pick_address'], latlng: LatLng(favAddress[i]['pick_lat'], favAddress[i]['pick_lng'])));
                                                                                                                                            } else {
                                                                                                                                              addressList.firstWhere((element) => element.type == 'pickup').address = favAddress[i]['pick_address'];
                                                                                                                                              addressList.firstWhere((element) => element.type == 'pickup').latlng = LatLng(favAddress[i]['pick_lat'], favAddress[i]['pick_lng']);
                                                                                                                                            }
                                                                                                                                            _controller?.moveCamera(CameraUpdate.newLatLngZoom(LatLng(favAddress[i]['pick_lat'], favAddress[i]['pick_lng']), 14.0));

                                                                                                                                            _bottom = 0;
                                                                                                                                          });
                                                                                                                                        } else {
                                                                                                                                          setState(() {
                                                                                                                                            if (addressList.where((element) => element.type == 'drop').isEmpty) {
                                                                                                                                              addressList.add(AddressList(id: '2', type: 'drop', address: favAddress[i]['pick_address'], pickup: false, latlng: LatLng(favAddress[i]['pick_lat'], favAddress[i]['pick_lng'])));
                                                                                                                                            } else {
                                                                                                                                              addressList.firstWhere((element) => element.type == 'drop').address = favAddress[i]['pick_address'];
                                                                                                                                              addressList.firstWhere((element) => element.type == 'drop').latlng = LatLng(favAddress[i]['pick_lat'], favAddress[i]['pick_lng']);
                                                                                                                                            }
                                                                                                                                            addAutoFill.clear();
                                                                                                                                            _bottom = 0;
                                                                                                                                          });
                                                                                                                                          if (addressList.length == 2) {
                                                                                                                                            if (choosenTransportType == 0) {
                                                                                                                                              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => BookingConfirmation()), (route) => false);
                                                                                                                                            } else {
                                                                                                                                              Navigator.push(context, MaterialPageRoute(builder: (context) => DropLocation()));
                                                                                                                                            }

                                                                                                                                            dropAddress = favAddress[i]['pick_address'];
                                                                                                                                          }
                                                                                                                                        }
                                                                                                                                      },
                                                                                                                                      child: SizedBox(
                                                                                                                                        width: media.width * 0.8,
                                                                                                                                        child: MyText(text: favAddress[i]['pick_address'], size: media.width * twelve, maxLines: 2),
                                                                                                                                      ),
                                                                                                                                    ),
                                                                                                                                  ],
                                                                                                                                ),
                                                                                                                              ],
                                                                                                                            ),
                                                                                                                          )
                                                                                                                        : Container());
                                                                                                              })
                                                                                                              .values
                                                                                                              .toList(),
                                                                                                        )
                                                                                                      : Container(),
                                                                                                ],
                                                                                              ),
                                                                                            ),
                                                                                          )
                                                                                        : (favAddress.isNotEmpty)
                                                                                            ? Column(
                                                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                                                children: favAddress
                                                                                                    .asMap()
                                                                                                    .map((i, value) {
                                                                                                      return MapEntry(
                                                                                                          i,
                                                                                                          (i < 5)
                                                                                                              ? Container(
                                                                                                                  padding: EdgeInsets.fromLTRB(0, media.width * 0.04, 0, media.width * 0.04),
                                                                                                                  decoration: BoxDecoration(
                                                                                                                    border: Border(bottom: BorderSide(width: 1.0, color: (isDarkTheme == true) ? textColor.withOpacity(0.2) : textColor.withOpacity(0.1))),
                                                                                                                  ),
                                                                                                                  child: Column(
                                                                                                                    children: [
                                                                                                                      SizedBox(
                                                                                                                        width: media.width * 0.9,
                                                                                                                        child: MyText(text: favAddress[i]['address_name'], size: media.width * twelve, maxLines: 2),
                                                                                                                      ),
                                                                                                                      SizedBox(
                                                                                                                        height: media.width * 0.025,
                                                                                                                      ),
                                                                                                                      Row(
                                                                                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                                                        children: [
                                                                                                                          SizedBox(
                                                                                                                            height: media.width * 0.05,
                                                                                                                            width: media.width * 0.05,
                                                                                                                            child: (favAddress[i]['address_name'] == 'Home')
                                                                                                                                ? Image.asset(
                                                                                                                                    'assets/images/home.png',
                                                                                                                                    color: textColor,
                                                                                                                                    width: media.width * 0.04,
                                                                                                                                  )
                                                                                                                                : (favAddress[i]['address_name'] == 'Work')
                                                                                                                                    ? Image.asset(
                                                                                                                                        'assets/images/briefcase.png',
                                                                                                                                        color: textColor,
                                                                                                                                        width: media.width * 0.04,
                                                                                                                                      )
                                                                                                                                    : Image.asset(
                                                                                                                                        'assets/images/navigation.png',
                                                                                                                                        color: textColor,
                                                                                                                                        width: media.width * 0.04,
                                                                                                                                      ),
                                                                                                                          ),
                                                                                                                          InkWell(
                                                                                                                            onTap: () async {
                                                                                                                              if (_pickaddress == true) {
                                                                                                                                setState(() {
                                                                                                                                  addAutoFill.clear();
                                                                                                                                  if (addressList.where((element) => element.type == 'pickup').isEmpty) {
                                                                                                                                    addressList.add(AddressList(id: '1', type: 'pickup', pickup: true, address: favAddress[i]['pick_address'], latlng: LatLng(favAddress[i]['pick_lat'], favAddress[i]['pick_lng'])));
                                                                                                                                  } else {
                                                                                                                                    addressList.firstWhere((element) => element.type == 'pickup').address = favAddress[i]['pick_address'];
                                                                                                                                    addressList.firstWhere((element) => element.type == 'pickup').latlng = LatLng(favAddress[i]['pick_lat'], favAddress[i]['pick_lng']);
                                                                                                                                  }
                                                                                                                                  _controller?.moveCamera(CameraUpdate.newLatLngZoom(LatLng(favAddress[i]['pick_lat'], favAddress[i]['pick_lng']), 14.0));

                                                                                                                                  _bottom = 0;
                                                                                                                                });
                                                                                                                              } else {
                                                                                                                                setState(() {
                                                                                                                                  if (addressList.where((element) => element.type == 'drop').isEmpty) {
                                                                                                                                    addressList.add(AddressList(id: '2', type: 'drop', address: favAddress[i]['pick_address'], pickup: false, latlng: LatLng(favAddress[i]['pick_lat'], favAddress[i]['pick_lng'])));
                                                                                                                                  } else {
                                                                                                                                    addressList.firstWhere((element) => element.type == 'drop').address = favAddress[i]['pick_address'];
                                                                                                                                    addressList.firstWhere((element) => element.type == 'drop').latlng = LatLng(favAddress[i]['pick_lat'], favAddress[i]['pick_lng']);
                                                                                                                                  }
                                                                                                                                  addAutoFill.clear();
                                                                                                                                  _bottom = 0;
                                                                                                                                });
                                                                                                                                if (addressList.length == 2) {
                                                                                                                                  if (choosenTransportType == 0) {
                                                                                                                                    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => BookingConfirmation()), (route) => false);
                                                                                                                                  } else {
                                                                                                                                    Navigator.push(context, MaterialPageRoute(builder: (context) => DropLocation()));
                                                                                                                                  }

                                                                                                                                  dropAddress = favAddress[i]['pick_address'];
                                                                                                                                }
                                                                                                                              }
                                                                                                                            },
                                                                                                                            child: SizedBox(
                                                                                                                              width: media.width * 0.8,
                                                                                                                              child: MyText(text: favAddress[i]['pick_address'], size: media.width * twelve, maxLines: 2),
                                                                                                                            ),
                                                                                                                          ),
                                                                                                                        ],
                                                                                                                      ),
                                                                                                                    ],
                                                                                                                  ),
                                                                                                                )
                                                                                                              : Container());
                                                                                                    })
                                                                                                    .values
                                                                                                    .toList(),
                                                                                              )
                                                                                            : Container(),
                                                                                  ],
                                                                                )
                                                                              : Container(),
                                                                          // Resultados da Busca
                                                                          (_bottom == 1 && addAutoFill.isNotEmpty)
                                                                              ? Container(
                                                                                  padding: EdgeInsets.only(left: media.width * 0.03, right: media.width * 0.03, bottom: 100, top: 0),
                                                                                  decoration: BoxDecoration(
                                                                                    borderRadius: BorderRadius.circular(media.width * 0.02),
                                                                                    color: page,
                                                                                  ),
                                                                                  child: SingleChildScrollView(
                                                                                      physics: const BouncingScrollPhysics(),
                                                                                      child: Column(
                                                                                        children: [
                                                                                          (addAutoFill.isNotEmpty)
                                                                                              ? Column(
                                                                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                                                                  children: addAutoFill
                                                                                                      .asMap()
                                                                                                      .map((i, value) {
                                                                                                        return MapEntry(
                                                                                                            i,
                                                                                                            (i < 5)
                                                                                                                ? Container(
                                                                                                                    padding: EdgeInsets.fromLTRB(0, media.width * 0.04, 0, media.width * 0.04),
                                                                                                                    decoration: BoxDecoration(
                                                                                                                      border: Border(bottom: BorderSide(width: 1.0, color: (isDarkTheme == true) ? textColor.withOpacity(0.2) : textColor.withOpacity(0.1))),
                                                                                                                    ),
                                                                                                                    child: Row(
                                                                                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                                                      children: [
                                                                                                                        SizedBox(
                                                                                                                          height: media.width * 0.1,
                                                                                                                          width: media.width * 0.1,
                                                                                                                          child: Icon(Icons.access_time, color: textColor),
                                                                                                                        ),
                                                                                                                        Expanded(
                                                                                                                          child: InkWell(
                                                                                                                            onTap: () async {
                                                                                                                              var val = await geoCodingForLatLng(addAutoFill[i]['place_id']);

                                                                                                                              if (_pickaddress == true) {
                                                                                                                                setState(() {
                                                                                                                                  if (addressList.where((element) => element.type == 'pickup').isEmpty) {
                                                                                                                                    addressList.add(AddressList(id: '1', type: 'pickup', pickup: true, address: addAutoFill[i]['description'], latlng: val, name: userDetails['name'] ?? '', number: userDetails['mobile'] ?? ''));
                                                                                                                                  } else {
                                                                                                                                    addressList.firstWhere((element) => element.type == 'pickup').address = addAutoFill[i]['description'];
                                                                                                                                    addressList.firstWhere((element) => element.type == 'pickup').latlng = val;
                                                                                                                                  }
                                                                                                                                });
                                                                                                                              } else {
                                                                                                                                setState(() {
                                                                                                                                  if (addressList.where((element) => element.type == 'drop').isEmpty) {
                                                                                                                                    addressList.add(AddressList(id: '2', type: 'drop', pickup: false, address: addAutoFill[i]['description'], latlng: val));
                                                                                                                                  } else {
                                                                                                                                    addressList.firstWhere((element) => element.type == 'drop').address = addAutoFill[i]['description'];
                                                                                                                                    addressList.firstWhere((element) => element.type == 'drop').latlng = val;
                                                                                                                                  }
                                                                                                                                });
                                                                                                                                if (addressList.length == 2) {
                                                                                                                                  navigate();
                                                                                                                                }
                                                                                                                              }
                                                                                                                              setState(() {
                                                                                                                                addAutoFill.clear();
                                                                                                                                _dropaddress = false;

                                                                                                                                if (_pickaddress == true) {
                                                                                                                                  center = val;
                                                                                                                                  _controller?.moveCamera(CameraUpdate.newLatLngZoom(val, 14.0));
                                                                                                                                }
                                                                                                                                _bottom = 0;
                                                                                                                              });
                                                                                                                            },
                                                                                                                            child: Padding(
                                                                                                                              padding: EdgeInsets.symmetric(horizontal: media.width * 0.02),
                                                                                                                              child: MyText(text: addAutoFill[i]['description'], size: media.width * twelve, maxLines: 2),
                                                                                                                            ),
                                                                                                                          ),
                                                                                                                        ),
                                                                                                                        Material(
                                                                                                                          color: Colors.transparent,
                                                                                                                          child: InkWell(
                                                                                                                            onTap: () async {
                                                                                                                              if (favAddress.where((e) => e['pick_address'] == addAutoFill[i]['description']).isEmpty) {
                                                                                                                                var val = await geoCodingForLatLng(addAutoFill[i]['place_id']);
                                                                                                                                setState(() {
                                                                                                                                  favSelectedAddress = addAutoFill[i]['description'];
                                                                                                                                  favLat = val.latitude;
                                                                                                                                  favLng = val.longitude;
                                                                                                                                  favAddressAdd = true;
                                                                                                                                  favName = 'Home';
                                                                                                                                  favNameText = '';
                                                                                                                                });
                                                                                                                                valueNotifierHome.incrementNotifier();
                                                                                                                              }
                                                                                                                            },
                                                                                                                            borderRadius: BorderRadius.circular(media.width * 0.02),
                                                                                                                            child: Container(
                                                                                                                              padding: EdgeInsets.all(media.width * 0.02),
                                                                                                                              child: Icon(
                                                                                                                                Icons.bookmark,
                                                                                                                                size: media.width * 0.05,
                                                                                                                                color: favAddress.where((element) => element['pick_address'] == addAutoFill[i]['description']).isNotEmpty ? buttonColor : textColor.withOpacity(0.3),
                                                                                                                              ),
                                                                                                                            ),
                                                                                                                          ),
                                                                                                                        )
                                                                                                                      ],
                                                                                                                    ),
                                                                                                                  )
                                                                                                                : Container());
                                                                                                      })
                                                                                                      .values
                                                                                                      .toList(),
                                                                                                )
                                                                                              : Container(),
                                                                                        ],
                                                                                      )),
                                                                                )
                                                                              : Container(),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  )
                                                                : Container(),
                                                            (_bottom == 0)
                                                                ? SizedBox(
                                                                    height: media
                                                                            .width *
                                                                        0.02)
                                                                : Container(),
                                                            (_bottom == 0 &&
                                                                    userDetails[
                                                                            'enable_modules_for_applications'] ==
                                                                        'both')
                                                                ? Container(
                                                                    height: media
                                                                            .width *
                                                                        0.12,
                                                                    decoration: BoxDecoration(
                                                                        border: Border.all(
                                                                            color:
                                                                                buttonColor,
                                                                            width:
                                                                                1)),
                                                                    child: Row(
                                                                      children: [
                                                                        InkWell(
                                                                          onTap:
                                                                              () {
                                                                            if (choosenTransportType !=
                                                                                0) {
                                                                              setState(() {
                                                                                choosenTransportType = 0;
                                                                                myMarkers.clear();
                                                                              });
                                                                            }
                                                                          },
                                                                          child:
                                                                              Container(
                                                                            color: (choosenTransportType == 0)
                                                                                ? buttonColor
                                                                                : Colors.transparent,
                                                                            width:
                                                                                media.width * 0.45 - 1,
                                                                            alignment:
                                                                                Alignment.center,
                                                                            child:
                                                                                Text(
                                                                              languages[choosenLanguage]['text_taxi'],
                                                                              style: getGoogleFontStyle(
                                                                                fontSize: media.width * fourteen,
                                                                                fontWeight: FontWeight.bold,
                                                                                color: (choosenTransportType == 0) ? page : textColor,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        InkWell(
                                                                          onTap:
                                                                              () {
                                                                            if (choosenTransportType !=
                                                                                1) {
                                                                              setState(() {
                                                                                choosenTransportType = 1;
                                                                                myMarkers.clear();
                                                                              });
                                                                            }
                                                                          },
                                                                          child:
                                                                              Container(
                                                                            color: (choosenTransportType == 1)
                                                                                ? buttonColor
                                                                                : Colors.transparent,
                                                                            width:
                                                                                media.width * 0.45 - 1,
                                                                            alignment:
                                                                                Alignment.center,
                                                                            child:
                                                                                Text(
                                                                              languages[choosenLanguage]['text_delivery'],
                                                                              style: getGoogleFontStyle(
                                                                                fontSize: media.width * fourteen,
                                                                                fontWeight: FontWeight.bold,
                                                                                color: (choosenTransportType == 1) ? page : textColor,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        )
                                                                      ],
                                                                    ),
                                                                  )
                                                                : Container(),
                                                            SizedBox(
                                                              height:
                                                                  media.width *
                                                                      0.03,
                                                            ),
                                                            (_bottom == 0)
                                                                ? Column(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .start,
                                                                    children: [
                                                                      SizedBox(
                                                                          width: media.width *
                                                                              0.9,
                                                                          child: MyText(
                                                                              text: languages[choosenLanguage]['text_where_to_go'],
                                                                              fontweight: FontWeight.w700,
                                                                              size: media.width * sixteen)),
                                                                      SizedBox(
                                                                        height: media.width *
                                                                            0.04,
                                                                      ),
                                                                      InkWell(
                                                                        onTap:
                                                                            () {
                                                                          if (addressList
                                                                              .where((element) => element.type == 'pickup')
                                                                              .isNotEmpty) {
                                                                            setState(() {
                                                                              _pickaddress = false;
                                                                              _dropaddress = true;
                                                                              addAutoFill.clear();
                                                                              _bottom = 1;
                                                                            });
                                                                          }
                                                                        },
                                                                        child: Container(
                                                                            padding: EdgeInsets.fromLTRB(media.width * 0.03, 0, media.width * 0.03, 0),
                                                                            height: media.width * 0.1,
                                                                            width: media.width * 0.9,
                                                                            decoration: BoxDecoration(
                                                                                border: Border.all(
                                                                                  color: Colors.grey,
                                                                                  width: 1.5,
                                                                                ),
                                                                                borderRadius: BorderRadius.circular(media.width * 0.02),
                                                                                color: page),
                                                                            alignment: Alignment.centerLeft,
                                                                            child: Row(
                                                                              children: [
                                                                                Container(
                                                                                  height: media.width * 0.04,
                                                                                  width: media.width * 0.04,
                                                                                  alignment: Alignment.center,
                                                                                  decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xffFF0000).withOpacity(0.3)),
                                                                                  child: Container(
                                                                                    height: media.width * 0.02,
                                                                                    width: media.width * 0.02,
                                                                                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xffFF0000)),
                                                                                  ),
                                                                                ),
                                                                                SizedBox(width: media.width * 0.02),
                                                                                (_dropaddress == true && _bottom == 1)
                                                                                    ? Expanded(
                                                                                        child: TextField(
                                                                                            autofocus: true,
                                                                                            decoration: InputDecoration(
                                                                                              contentPadding: (languageDirection == 'rtl') ? EdgeInsets.only(bottom: media.width * 0.035) : EdgeInsets.only(bottom: media.width * 0.047),
                                                                                              border: InputBorder.none,
                                                                                              hintText: languages[choosenLanguage]['text_4lettersforautofill'],
                                                                                              hintStyle: choosenLanguage == 'ar'
                                                                                                  ? getGoogleFontStyle(
                                                                                                      fontSize: media.width * twelve,
                                                                                                      color: textColor.withOpacity(0.4),
                                                                                                    )
                                                                                                  : getGoogleFontStyle(
                                                                                                      fontSize: media.width * twelve,
                                                                                                      color: textColor.withOpacity(0.4),
                                                                                                    ),
                                                                                            ),
                                                                                            maxLines: 1,
                                                                                            onChanged: (val) {
                                                                                              _debouncer.run(() {
                                                                                                if (val.length >= 3) {
                                                                                                  if (storedAutoAddress.where((element) => element['description'].toString().toLowerCase().contains(val.toLowerCase())).isNotEmpty) {
                                                                                                    addAutoFill.removeWhere((element) => element['description'].toString().toLowerCase().contains(val.toLowerCase()) == false);
                                                                                                    storedAutoAddress.where((element) => element['description'].toString().toLowerCase().contains(val.toLowerCase())).forEach((element) {
                                                                                                      addAutoFill.add(element);
                                                                                                    });
                                                                                                    valueNotifierHome.incrementNotifier();
                                                                                                  } else {
                                                                                                    getAutoAddress(val, _sessionToken, center.latitude, center.longitude);
                                                                                                  }
                                                                                                } else {
                                                                                                  setState(() {
                                                                                                    addAutoFill.clear();
                                                                                                  });
                                                                                                }
                                                                                              });
                                                                                            }),
                                                                                      )
                                                                                    : Expanded(
                                                                                        child: MyText(
                                                                                        text: languages[choosenLanguage]['text_4lettersforautofill'],
                                                                                        size: media.width * twelve,
                                                                                        color: textColor.withOpacity(0.4),
                                                                                      )),
                                                                              ],
                                                                            )),
                                                                      )
                                                                    ],
                                                                  )
                                                                : Container(),
                                                          ],
                                                        ),
                                                      ),
                                                    )),
                                              ],
                                            )
                                          : Container(),
                            ]),
                      ),

                      //add fav address
                      (favAddressAdd == true)
                          ? Positioned(
                              top: 0,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    favAddressAdd = false;
                                  });
                                },
                                child: Container(
                                  height: media.height * 1,
                                  width: media.width * 1,
                                  color: Colors.transparent.withOpacity(0.6),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.fromLTRB(
                                            media.width * 0.05,
                                            media.width * 0.05,
                                            media.width * 0.05,
                                            MediaQuery.of(context)
                                                    .viewInsets
                                                    .bottom +
                                                media.width * 0.05),
                                        width: media.width * 1,
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                const BorderRadius.only(
                                                    topLeft:
                                                        Radius.circular(12),
                                                    topRight:
                                                        Radius.circular(12)),
                                            color: page),
                                        child: Column(
                                          children: [
                                            Row(
                                              children: [
                                                MyText(
                                                  text:
                                                      languages[choosenLanguage]
                                                          ['text_add_address'],
                                                  size: media.width * sixteen,
                                                  fontweight: FontWeight.w600,
                                                ),
                                              ],
                                            ),
                                            SizedBox(
                                              height: media.width * 0.025,
                                            ),
                                            Container(
                                              width: media.width * 0.9,
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  boxShadow: [
                                                    BoxShadow(
                                                        color: Colors.black
                                                            .withOpacity(0.2),
                                                        blurRadius: 2,
                                                        spreadRadius: 2)
                                                  ],
                                                  color: topBar),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    height: media.width * 0.064,
                                                    width: media.width * 0.064,
                                                    decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: const Color(
                                                                0xffFF0000)
                                                            .withOpacity(0.1)),
                                                    child: Icon(
                                                      Icons.place,
                                                      size: media.width * 0.04,
                                                      color: const Color(
                                                          0xffFF0000),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: media.width * 0.02,
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      favSelectedAddress,
                                                      style: getGoogleFontStyle(
                                                          fontSize:
                                                              media.width *
                                                                  twelve,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: (isDarkTheme ==
                                                                  true)
                                                              ? Colors.black
                                                              : textColor),
                                                      maxLines: 1,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(
                                              height: media.width * 0.025,
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                InkWell(
                                                  onTap: () {
                                                    FocusManager
                                                        .instance.primaryFocus
                                                        ?.unfocus();
                                                    setState(() {
                                                      favName = 'Home';
                                                    });
                                                  },
                                                  child: Container(
                                                    padding:
                                                        EdgeInsets.fromLTRB(
                                                            media.width * 0.05,
                                                            media.width * 0.02,
                                                            media.width * 0.05,
                                                            media.width * 0.02),
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                      border: Border.all(
                                                          color: (favName ==
                                                                  'Home')
                                                              ? buttonColor
                                                              : borderLines,
                                                          width: 1.1),
                                                      color: (favName == 'Home')
                                                          ? buttonColor
                                                          : Colors.transparent,
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                            Icons.home_outlined,
                                                            size: media.width *
                                                                0.05,
                                                            color: (favName ==
                                                                    'Home')
                                                                ? (isDarkTheme ==
                                                                        true)
                                                                    ? Colors
                                                                        .black
                                                                    : Colors
                                                                        .white
                                                                : (isDarkTheme ==
                                                                        true)
                                                                    ? Colors
                                                                        .white
                                                                    : Colors
                                                                        .black),
                                                        SizedBox(
                                                          width: media.width *
                                                              0.01,
                                                        ),
                                                        MyText(
                                                            text: languages[
                                                                    choosenLanguage]
                                                                ['text_home'],
                                                            size: media.width *
                                                                twelve,
                                                            color: (favName ==
                                                                    'Home')
                                                                ? (isDarkTheme ==
                                                                        true)
                                                                    ? Colors
                                                                        .black
                                                                    : Colors
                                                                        .white
                                                                : (isDarkTheme ==
                                                                        true)
                                                                    ? Colors
                                                                        .white
                                                                    : Colors
                                                                        .black)
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                InkWell(
                                                  onTap: () {
                                                    FocusManager
                                                        .instance.primaryFocus
                                                        ?.unfocus();
                                                    setState(() {
                                                      favName = 'Work';
                                                    });
                                                  },
                                                  child: Container(
                                                    padding:
                                                        EdgeInsets.fromLTRB(
                                                            media.width * 0.05,
                                                            media.width * 0.02,
                                                            media.width * 0.05,
                                                            media.width * 0.02),
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                      border: Border.all(
                                                          color: (favName ==
                                                                  'Work')
                                                              ? buttonColor
                                                              : borderLines,
                                                          width: 1.1),
                                                      color: (favName == 'Work')
                                                          ? buttonColor
                                                          : Colors.transparent,
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                            Icons
                                                                .work_outline_outlined,
                                                            size: media.width *
                                                                0.05,
                                                            color: (favName ==
                                                                    'Work')
                                                                ? (isDarkTheme ==
                                                                        true)
                                                                    ? Colors
                                                                        .black
                                                                    : Colors
                                                                        .white
                                                                : (isDarkTheme ==
                                                                        true)
                                                                    ? Colors
                                                                        .white
                                                                    : Colors
                                                                        .black),
                                                        SizedBox(
                                                          width: media.width *
                                                              0.01,
                                                        ),
                                                        MyText(
                                                            text: languages[
                                                                    choosenLanguage]
                                                                ['text_work'],
                                                            size: media.width *
                                                                twelve,
                                                            color: (favName ==
                                                                    'Work')
                                                                ? (isDarkTheme ==
                                                                        true)
                                                                    ? Colors
                                                                        .black
                                                                    : Colors
                                                                        .white
                                                                : (isDarkTheme ==
                                                                        true)
                                                                    ? Colors
                                                                        .white
                                                                    : Colors
                                                                        .black)
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                InkWell(
                                                  onTap: () {
                                                    FocusManager
                                                        .instance.primaryFocus
                                                        ?.unfocus();
                                                    setState(() {
                                                      favName = 'Others';
                                                    });
                                                  },
                                                  child: Container(
                                                    padding:
                                                        EdgeInsets.fromLTRB(
                                                            media.width * 0.05,
                                                            media.width * 0.02,
                                                            media.width * 0.05,
                                                            media.width * 0.02),
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                      border: Border.all(
                                                          color: (favName ==
                                                                  'Others')
                                                              ? buttonColor
                                                              : borderLines,
                                                          width: 1.1),
                                                      color: (favName ==
                                                              'Others')
                                                          ? buttonColor
                                                          : Colors.transparent,
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                            Icons
                                                                .bookmark_outline,
                                                            size: media.width *
                                                                0.05,
                                                            color: (favName ==
                                                                    'Others')
                                                                ? (isDarkTheme ==
                                                                        true)
                                                                    ? Colors
                                                                        .black
                                                                    : Colors
                                                                        .white
                                                                : (isDarkTheme ==
                                                                        true)
                                                                    ? Colors
                                                                        .white
                                                                    : Colors
                                                                        .black),
                                                        SizedBox(
                                                          width: media.width *
                                                              0.01,
                                                        ),
                                                        MyText(
                                                            text: languages[
                                                                    choosenLanguage]
                                                                [
                                                                'text_create_new_fav'],
                                                            size: media.width *
                                                                twelve,
                                                            color: (favName ==
                                                                    'Others')
                                                                ? (isDarkTheme ==
                                                                        true)
                                                                    ? Colors
                                                                        .black
                                                                    : Colors
                                                                        .white
                                                                : (isDarkTheme ==
                                                                        true)
                                                                    ? Colors
                                                                        .white
                                                                    : Colors
                                                                        .black)
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            (favName == 'Others')
                                                ? Container(
                                                    margin: EdgeInsets.only(
                                                        top:
                                                            media.width * 0.03),
                                                    padding: EdgeInsets.all(
                                                        media.width * 0.025),
                                                    decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                        border: Border.all(
                                                            color: borderLines,
                                                            width: 1.2)),
                                                    child: TextField(
                                                      decoration: InputDecoration(
                                                          border: InputBorder
                                                              .none,
                                                          hintText:
                                                              languages[
                                                                      choosenLanguage]
                                                                  [
                                                                  'text_enterfavname'],
                                                          hintStyle:
                                                              getGoogleFontStyle(
                                                                  fontSize: media
                                                                          .width *
                                                                      twelve,
                                                                  color:
                                                                      hintColor)),
                                                      maxLines: 1,
                                                      onChanged: (val) {
                                                        setState(() {
                                                          favNameText = val;
                                                        });
                                                      },
                                                    ),
                                                  )
                                                : Container(),
                                            SizedBox(
                                              height: media.width * 0.05,
                                            ),
                                            Button(
                                                onTap: () async {
                                                  if (favAddress.length >= 3) {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                        content: Text(languages[
                                                                    choosenLanguage]
                                                                [
                                                                'text_max_fav_reached'] ??
                                                            'Limite de favoritos atingido (máximo 4)'),
                                                        duration:
                                                            const Duration(
                                                                seconds: 2),
                                                      ),
                                                    );
                                                    return;
                                                  }

                                                  if (favName == 'Others' &&
                                                      favNameText != '') {
                                                    setState(() {
                                                      _loading = true;
                                                    });
                                                    var val =
                                                        await addFavLocation(
                                                            favLat,
                                                            favLng,
                                                            favSelectedAddress,
                                                            favNameText);
                                                    setState(() {
                                                      _loading = false;
                                                      if (val == true) {
                                                        favLat = null;
                                                        favLng = null;
                                                        favSelectedAddress = '';
                                                        favName = 'Home';
                                                        favNameText = '';
                                                        favAddressAdd = false;
                                                      } else if (val ==
                                                          'logout') {
                                                        navigateLogout();
                                                      }
                                                    });
                                                  } else if (favName ==
                                                          'Home' ||
                                                      favName == 'Work') {
                                                    setState(() {
                                                      _loading = true;
                                                    });
                                                    var val =
                                                        await addFavLocation(
                                                            favLat,
                                                            favLng,
                                                            favSelectedAddress,
                                                            favName);
                                                    setState(() {
                                                      _loading = false;
                                                      if (val == true) {
                                                        favLat = null;
                                                        favLng = null;
                                                        favName = 'Home';
                                                        favSelectedAddress = '';
                                                        favNameText = '';
                                                        favAddressAdd = false;
                                                      } else if (val ==
                                                          'logout') {
                                                        navigateLogout();
                                                      }
                                                    });
                                                  }
                                                },
                                                text: languages[choosenLanguage]
                                                    ['text_confirm'])
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ))
                          : Container(),

                      //driver cancelled request
                      (requestCancelledByDriver == true)
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
                                      width: media.width * 0.9,
                                      padding:
                                          EdgeInsets.all(media.width * 0.05),
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          color: page),
                                      child: Column(
                                        children: [
                                          Text(
                                            languages[choosenLanguage]
                                                ['text_drivercancelled'],
                                            style: getGoogleFontStyle(
                                                fontSize:
                                                    media.width * fourteen,
                                                fontWeight: FontWeight.w600,
                                                color: textColor),
                                          ),
                                          SizedBox(
                                            height: media.width * 0.05,
                                          ),
                                          Button(
                                              onTap: () {
                                                setState(() {
                                                  requestCancelledByDriver =
                                                      false;
                                                  userRequestData = {};
                                                });
                                              },
                                              text: languages[choosenLanguage]
                                                  ['text_ok'])
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ))
                          : Container(),

                      //user cancelled request
                      (cancelRequestByUser == true)
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
                                      width: media.width * 0.9,
                                      padding:
                                          EdgeInsets.all(media.width * 0.05),
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          color: page),
                                      child: Column(
                                        children: [
                                          Text(
                                            languages[choosenLanguage]
                                                ['text_cancelsuccess'],
                                            style: getGoogleFontStyle(
                                                fontSize:
                                                    media.width * fourteen,
                                                fontWeight: FontWeight.w600,
                                                color: textColor),
                                          ),
                                          SizedBox(
                                            height: media.width * 0.05,
                                          ),
                                          Button(
                                              onTap: () {
                                                setState(() {
                                                  cancelRequestByUser = false;
                                                  userRequestData = {};
                                                });
                                              },
                                              text: languages[choosenLanguage]
                                                  ['text_ok'])
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ))
                          : Container(),

                      //delete account
                      (deleteAccount == true)
                          ? Positioned(
                              top: 0,
                              child: Builder(
                                builder: (context) {
                                  // Limpar o campo quando o modal abrir
                                  if (!_deleteAccountModalOpened) {
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                      _deleteConfirmController.clear();
                                      _deleteAccountModalOpened = true;
                                    });
                                  }
                                  return Container(
                                    height: media.height * 1,
                                    width: media.width * 1,
                                    color: Colors.transparent.withOpacity(0.6),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: media.width * 0.9,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              Container(
                                                  height: media.height * 0.1,
                                                  width: media.width * 0.1,
                                                  decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: page),
                                                  child: InkWell(
                                                      onTap: () {
                                                        setState(() {
                                                          deleteAccount = false;
                                                          _deleteAccountModalOpened =
                                                              false;
                                                          _deleteConfirmController
                                                              .clear();
                                                        });
                                                      },
                                                      child: Icon(
                                                          Icons.cancel_outlined,
                                                          color: textColor))),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: EdgeInsets.all(
                                              media.width * 0.05),
                                          width: media.width * 0.9,
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              color: page),
                                          child: Column(
                                            children: [
                                              Text(
                                                languages[choosenLanguage]
                                                    ['text_delete_confirm'],
                                                textAlign: TextAlign.center,
                                                style: getGoogleFontStyle(
                                                    fontSize:
                                                        media.width * sixteen,
                                                    color: textColor,
                                                    fontWeight:
                                                        FontWeight.w600),
                                              ),
                                              SizedBox(
                                                height: media.width * 0.05,
                                              ),
                                              MyText(
                                                text: languages[choosenLanguage]
                                                        [
                                                        'text_delete_type_confirm'] ??
                                                    'Digite "concordo" para confirmar a exclusão:',
                                                size: media.width * fourteen,
                                                color:
                                                    textColor.withOpacity(0.7),
                                                textAlign: TextAlign.center,
                                              ),
                                              SizedBox(
                                                height: media.width * 0.03,
                                              ),
                                              Container(
                                                padding: EdgeInsets.all(
                                                    media.width * 0.03),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  border: Border.all(
                                                    color: textColor
                                                        .withOpacity(0.3),
                                                    width: 1.5,
                                                  ),
                                                  color: page,
                                                ),
                                                child: TextField(
                                                  controller:
                                                      _deleteConfirmController,
                                                  textAlign: TextAlign.center,
                                                  style: getGoogleFontStyle(
                                                    fontSize:
                                                        media.width * fourteen,
                                                    color: textColor,
                                                  ),
                                                  decoration: InputDecoration(
                                                    border: InputBorder.none,
                                                    hintText: languages[
                                                                choosenLanguage]
                                                            [
                                                            'text_delete_agree_word'] ??
                                                        'concordo',
                                                    hintStyle:
                                                        getGoogleFontStyle(
                                                      fontSize: media.width *
                                                          fourteen,
                                                      color: textColor
                                                          .withOpacity(0.4),
                                                    ),
                                                  ),
                                                  onChanged: (val) {
                                                    setState(() {});
                                                  },
                                                ),
                                              ),
                                              SizedBox(
                                                height: media.width * 0.05,
                                              ),
                                              (_deleteConfirmController.text
                                                          .toLowerCase()
                                                          .trim() ==
                                                      (languages[choosenLanguage]
                                                                  [
                                                                  'text_delete_agree_word'] ??
                                                              'concordo')
                                                          .toLowerCase())
                                                  ? Button(
                                                      onTap: () async {
                                                        setState(() {
                                                          deleteAccount = false;
                                                          _deleteAccountModalOpened =
                                                              false;
                                                          _loading = true;
                                                        });
                                                        _deleteConfirmController
                                                            .clear();
                                                        var result =
                                                            await userDelete();
                                                        if (result ==
                                                            'success') {
                                                          setState(() {
                                                            Navigator.pushAndRemoveUntil(
                                                                context,
                                                                MaterialPageRoute(
                                                                    builder:
                                                                        (context) =>
                                                                            const Login()),
                                                                (route) =>
                                                                    false);
                                                            userDetails.clear();
                                                          });
                                                        } else if (result ==
                                                            'logout') {
                                                          navigateLogout();
                                                        } else {
                                                          setState(() {
                                                            _loading = false;
                                                            deleteAccount =
                                                                true;
                                                            _deleteAccountModalOpened =
                                                                false;
                                                          });
                                                        }
                                                        setState(() {
                                                          _loading = false;
                                                        });
                                                      },
                                                      text: languages[
                                                              choosenLanguage]
                                                          ['text_confirm'])
                                                  : Container(
                                                      decoration: BoxDecoration(
                                                          color: buttonColor
                                                              .withOpacity(0.5),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      80)),
                                                      child: Container(
                                                        height:
                                                            media.width * 0.12,
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                                horizontal:
                                                                    media.width *
                                                                        0.02,
                                                                vertical: media
                                                                        .width *
                                                                    0.01),
                                                        alignment:
                                                            Alignment.center,
                                                        child: FittedBox(
                                                          fit: BoxFit.contain,
                                                          child: Text(
                                                            languages[
                                                                    choosenLanguage]
                                                                [
                                                                'text_confirm'],
                                                            style:
                                                                getGoogleFontStyle(
                                                              fontSize:
                                                                  media.width *
                                                                      sixteen,
                                                              color: page
                                                                  .withOpacity(
                                                                      0.5),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ).copyWith(
                                                                    letterSpacing:
                                                                        1),
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                  );
                                },
                              ))
                          : Container(),

                      //logout
                      (logout == true)
                          ? Positioned(
                              top: 0,
                              child: Container(
                                height: media.height * 1,
                                width: media.width * 1,
                                color: Colors.transparent.withOpacity(0.6),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: media.width * 0.9,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Container(
                                              height: media.height * 0.1,
                                              width: media.width * 0.1,
                                              decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: page),
                                              child: InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      logout = false;
                                                    });
                                                  },
                                                  child: Icon(
                                                      Icons.cancel_outlined,
                                                      color: textColor))),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding:
                                          EdgeInsets.all(media.width * 0.05),
                                      width: media.width * 0.9,
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          color: page),
                                      child: Column(
                                        children: [
                                          Text(
                                            languages[choosenLanguage]
                                                ['text_confirmlogout'],
                                            textAlign: TextAlign.center,
                                            style: getGoogleFontStyle(
                                                fontSize: media.width * sixteen,
                                                color: textColor,
                                                fontWeight: FontWeight.w600),
                                          ),
                                          SizedBox(
                                            height: media.width * 0.05,
                                          ),
                                          Button(
                                              onTap: () async {
                                                setState(() {
                                                  logout = false;
                                                  _loading = true;
                                                });
                                                var result = await userLogout();
                                                if (result == 'success' ||
                                                    result == 'logout') {
                                                  setState(() {
                                                    Navigator.pushAndRemoveUntil(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (context) =>
                                                                const Login()),
                                                        (route) => false);
                                                    userDetails.clear();
                                                  });
                                                } else {
                                                  setState(() {
                                                    _loading = false;
                                                    logout = true;
                                                  });
                                                }
                                                setState(() {
                                                  _loading = false;
                                                });
                                              },
                                              text: languages[choosenLanguage]
                                                  ['text_confirm'])
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ))
                          : Container(),
                      (_locationDenied == true)
                          ? Positioned(
                              child: Container(
                              height: media.height * 1,
                              width: media.width * 1,
                              color: Colors.transparent.withOpacity(0.6),
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
                                              _locationDenied = false;
                                            });
                                          },
                                          child: Container(
                                            height: media.height * 0.05,
                                            width: media.height * 0.05,
                                            decoration: BoxDecoration(
                                              color: page,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(Icons.cancel,
                                                color: buttonColor),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: media.width * 0.025),
                                  Container(
                                    padding: EdgeInsets.all(media.width * 0.05),
                                    width: media.width * 0.9,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: page,
                                        boxShadow: [
                                          BoxShadow(
                                              blurRadius: 2.0,
                                              spreadRadius: 2.0,
                                              color:
                                                  Colors.black.withOpacity(0.2))
                                        ]),
                                    child: Column(
                                      children: [
                                        SizedBox(
                                            width: media.width * 0.8,
                                            child: Text(
                                              languages[choosenLanguage]
                                                  ['text_open_loc_settings'],
                                              style: getGoogleFontStyle(
                                                  fontSize:
                                                      media.width * sixteen,
                                                  color: textColor,
                                                  fontWeight: FontWeight.w600),
                                            )),
                                        SizedBox(height: media.width * 0.05),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            InkWell(
                                                onTap: () async {
                                                  await perm.openAppSettings();
                                                },
                                                child: Text(
                                                  languages[choosenLanguage]
                                                      ['text_open_settings'],
                                                  style: getGoogleFontStyle(
                                                      fontSize:
                                                          media.width * sixteen,
                                                      color: buttonColor,
                                                      fontWeight:
                                                          FontWeight.w600),
                                                )),
                                            InkWell(
                                                onTap: () async {
                                                  setState(() {
                                                    _locationDenied = false;
                                                    _loading = true;
                                                  });

                                                  getLocs();
                                                },
                                                child: Text(
                                                  languages[choosenLanguage]
                                                      ['text_done'],
                                                  style: getGoogleFontStyle(
                                                      fontSize:
                                                          media.width * sixteen,
                                                      color: buttonColor,
                                                      fontWeight:
                                                          FontWeight.w600),
                                                ))
                                          ],
                                        )
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ))
                          : Container(),

                      //loader
                      (_loading == true || state == '')
                          ? const Positioned(top: 0, child: Loading())
                          : Container(),
                      (internet == false)
                          ? Positioned(
                              top: 0,
                              child: NoInternet(
                                onTap: () {
                                  setState(() {
                                    internetTrue();
                                    getUserDetails();
                                  });
                                },
                              ))
                          : Container()
                    ],
                  ),
                ),
              );
            }),
      ),
    );
  }

  double getBearing(LatLng begin, LatLng end) {
    double lat = (begin.latitude - end.latitude).abs();

    double lng = (begin.longitude - end.longitude).abs();

    if (begin.latitude < end.latitude && begin.longitude < end.longitude) {
      return vector.degrees(atan(lng / lat));
    } else if (begin.latitude >= end.latitude &&
        begin.longitude < end.longitude) {
      return (90 - vector.degrees(atan(lng / lat))) + 90;
    } else if (begin.latitude >= end.latitude &&
        begin.longitude >= end.longitude) {
      return vector.degrees(atan(lng / lat)) + 180;
    } else if (begin.latitude < end.latitude &&
        begin.longitude >= end.longitude) {
      return (90 - vector.degrees(atan(lng / lat))) + 270;
    }

    return -1;
  }

  animateCar(
      double fromLat, //Starting latitude

      double fromLong, //Starting longitude

      double toLat, //Ending latitude

      double toLong, //Ending longitude

      StreamSink<List<Marker>>
          mapMarkerSink, //Stream build of map to update the UI

      TickerProvider
          provider, //Ticker provider of the widget. This is used for animation

      GoogleMapController controller, //Google map controller of our widget

      markerid,
      markerBearing,
      icon) async {
    final double bearing =
        getBearing(LatLng(fromLat, fromLong), LatLng(toLat, toLong));

    myBearings[markerBearing.toString()] = bearing;

    var carMarker = Marker(
        markerId: MarkerId(markerid),
        position: LatLng(fromLat, fromLong),
        icon: icon,
        anchor: const Offset(0.5, 0.5),
        flat: true,
        draggable: false);

    myMarkers.add(carMarker);

    mapMarkerSink.add(Set<Marker>.from(myMarkers).toList());

    Tween<double> tween = Tween(begin: 0, end: 1);

    _animation = tween.animate(animationController)
      ..addListener(() async {
        myMarkers
            .removeWhere((element) => element.markerId == MarkerId(markerid));

        final v = _animation!.value;

        double lng = v * toLong + (1 - v) * fromLong;

        double lat = v * toLat + (1 - v) * fromLat;

        LatLng newPos = LatLng(lat, lng);

        //New marker location

        carMarker = Marker(
            markerId: MarkerId(markerid),
            position: newPos,
            icon: icon,
            anchor: const Offset(0.5, 0.5),
            flat: true,
            rotation: bearing,
            draggable: false);

        //Adding new marker to our list and updating the google map UI.

        myMarkers.add(carMarker);

        mapMarkerSink.add(Set<Marker>.from(myMarkers).toList());
      });

    //Starting the animation

    animationController.forward();
  }
}

class Debouncer {
  final int milliseconds;
  dynamic action;
  dynamic _timer;

  Debouncer({required this.milliseconds});

  run(VoidCallback action) {
    if (null != _timer) {
      _timer.cancel();
    }
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}

class BannerImage extends StatefulWidget {
  const BannerImage({super.key});

  @override
  State<BannerImage> createState() => _BannerImageState();
}

class _BannerImageState extends State<BannerImage> {
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;
  Timer? timer;
  bool end = false;
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (_currentPage == banners.length - 1) {
        end = true;
      } else if (_currentPage == 0) {
        end = false;
      }

      if (end == false) {
        _currentPage++;
      } else {
        _currentPage--;
      }

      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    timer!.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: PageView.builder(
        controller: _pageController,
        itemCount: banners.length,
        itemBuilder: (context, index) {
          return Image.network(
            banners[index]['image'],
            fit: BoxFit.fitWidth,
          );
        },
      ),
    );
  }
}
