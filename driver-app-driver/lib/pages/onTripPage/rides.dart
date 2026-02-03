import 'dart:async';
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:permission_handler/permission_handler.dart' as perm;
import 'package:http/http.dart' as http;
import '../../functions/functions.dart';
import '../../functions/notifications.dart';
import '../../styles/styles.dart';
import '../../translation/translation.dart';
import '../../widgets/widgets.dart';
import '../NavigatorPages/notification.dart';
import '../loadingPage/loading.dart';
import '../login/landingpage.dart';
import '../navDrawer/nav_drawer.dart';
import '../vehicleInformations/docs_onprocess.dart';
import 'droplocation.dart';
import 'map_page.dart';

class RidePage extends StatefulWidget {
  const RidePage({Key? key}) : super(key: key);

  @override
  State<RidePage> createState() => _RidePageState();
}

final distanceBetween = [
  {'name': '0-2 km', 'value': '0.43496'},
  {'name': '0-5 km', 'value': '1.0874'},
  {'name': '0-7 km', 'value': '1.7088'}
];
int _choosenDistance = 1;
List choosenRide = [];

class _RidePageState extends State<RidePage> with WidgetsBindingObserver {
  late geolocator.LocationPermission permission;
  int gettingPerm = 0;
  String state = '';
  bool _isLoading = false;
  bool _selectDistance = false;
  bool makeOnline = false;
  bool _cancel = false;

  bool currentpage = true;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    if (userDetails['vehicle_types'] != [] && userDetails['role'] != 'owner') {
      setState(() {
        vechiletypeslist = userDetails['driverVehicleType']['data'];
      });
    }
    getadminCurrentMessages();
    currentpage = true;
    getLocs();
    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      isBackground = false;
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      isBackground = true;
    }
  }

  @override
  void dispose() {
    time?.cancel();
    bidStream?.cancel();
    super.dispose();
  }

  navigateLogout() {
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LandingPage()),
        (route) => false);
  }

//getting permission and current location
  getLocs() async {
    permission = await geolocator.GeolocatorPlatform.instance.checkPermission();
    serviceEnabled =
        await geolocator.GeolocatorPlatform.instance.isLocationServiceEnabled();

    if (permission == geolocator.LocationPermission.denied ||
        permission == geolocator.LocationPermission.deniedForever ||
        serviceEnabled == false) {
      gettingPerm++;

      if (gettingPerm > 1) {
        locationAllowed = false;
        if (userDetails['active'] == true) {
          var val = await driverStatus();
          if (val == 'logout') {
            navigateLogout();
          }
        }
        state = '3';
      } else {
        state = '2';
      }
      setState(() {
        _isLoading = false;
      });
    } else if (permission == geolocator.LocationPermission.whileInUse ||
        permission == geolocator.LocationPermission.always) {
      if (serviceEnabled == true) {
        if (center == null) {
          var locs = await geolocator.Geolocator.getLastKnownPosition();
          if (locs != null) {
            center = LatLng(locs.latitude, locs.longitude);
            heading = locs.heading;
          } else {
            var loc = await geolocator.Geolocator.getCurrentPosition(
                desiredAccuracy: geolocator.LocationAccuracy.low);
            center = LatLng(double.parse(loc.latitude.toString()),
                double.parse(loc.longitude.toString()));
            heading = loc.heading;
          }
        }
        if (mounted) {
          setState(() {});
        }
      }

      if (makeOnline == true && userDetails['active'] == false) {
        var val = await driverStatus();
        if (val == 'logout') {
          navigateLogout();
        }
      }
      makeOnline = false;
      if (mounted) {
        setState(() {
          locationAllowed = true;
          state = '3';
          _isLoading = false;
        });
      }
    }
  }

  dynamic time;
  dynamic bidStream;
  List rideBck = [];
  timer() {
    bidStream = FirebaseDatabase.instance
        .ref()
        .child(
            'bid-meta/${choosenRide[0]["request_id"]}/drivers/driver_${userDetails["id"]}')
        .onChildRemoved
        .handleError((onError) {
      bidStream?.cancel();
    }).listen((event) {
      if (driverReq.isEmpty) {
        getUserDetails();
      }
    });
    time = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (waitingList.isNotEmpty) {
        valueNotifierTimer.incrementNotifier();
      } else {
        timer.cancel();
        bidStream?.cancel();
        bidStream = null;
        time = null;
      }
    });
  }

  getLocationPermission() async {
    if (permission == geolocator.LocationPermission.denied ||
        permission == geolocator.LocationPermission.deniedForever) {
      if (permission != geolocator.LocationPermission.deniedForever) {
        if (platform == TargetPlatform.android) {
          await perm.Permission.location.request();
          await perm.Permission.locationAlways.request();
        } else {
          await [perm.Permission.location].request();
        }
      }
      if (serviceEnabled == false) {
        await geolocator.Geolocator.getCurrentPosition(
            desiredAccuracy: geolocator.LocationAccuracy.low);
        // await location.requestService();
      }
    } else if (serviceEnabled == false) {
      await geolocator.Geolocator.getCurrentPosition(
          desiredAccuracy: geolocator.LocationAccuracy.low);
      // await location.requestService();
    }
    setState(() {
      _isLoading = true;
    });
    getLocs();
  }

  popFunction() {
    return false;
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return PopScope(
      canPop: popFunction(),
      onPopInvoked: (did) {
        if (logout == false) {
          if (platform == TargetPlatform.android) {
            platforms.invokeMethod('pipmode');
          }
        }
      },
      child: Material(
          child: (state != '1' && state != '2')
              ? ValueListenableBuilder(
                  valueListenable: valueNotifierHome.value,
                  builder: (context, value, child) {
                    if (time == null && waitingList.isNotEmpty) {
                      timer();
                    }
                    if (driverReq.isNotEmpty && currentpage == true) {
                      currentpage = false;
                      choosenRide.clear();
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const Maps()),
                            (route) => false);
                      });
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
                                  builder: (context) =>
                                      const NotificationPage()));
                        });
                      }
                    }
                    if (userDetails['approve'] == false && driverReq.isEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const DocsProcess()),
                            (route) => false);
                      });
                    }

                    return Directionality(
                      textDirection: (languageDirection == 'rtl')
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      child: Scaffold(
                        drawer: const NavDrawer(),
                        body: Stack(
                          children: [
                            Container(
                              height: media.height * 1,
                              width: media.width * 1,
                              padding: EdgeInsets.fromLTRB(
                                  media.width * 0.05,
                                  media.width * 0.05 +
                                      MediaQuery.of(context).padding.top,
                                  media.width * 0.05,
                                  media.width * 0.05),
                              color: page,
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        height: media.width * 0.1,
                                        width: media.width * 0.1,
                                        decoration: BoxDecoration(
                                            boxShadow: [
                                              BoxShadow(
                                                  blurRadius: 2,
                                                  color: textColor
                                                      .withOpacity(0.2),
                                                  spreadRadius: 2)
                                            ],
                                            color: page,
                                            borderRadius: BorderRadius.circular(
                                                media.width * 0.01)),
                                        child: StatefulBuilder(
                                            builder: (context, setState) {
                                          return InkWell(
                                              onTap: () async {
                                                Scaffold.of(context)
                                                    .openDrawer();

                                                // printWrapped(userDetails.toString());
                                                // Navigator.push(context, MaterialPageRoute(builder: (context)=>RidePage()));
                                              },
                                              child: Icon(
                                                Icons.menu,
                                                size: media.width * 0.05,
                                                color: textColor,
                                              ));
                                        }),
                                      ),
                                      (userDetails['low_balance'] == false) &&
                                              (userDetails['role'] ==
                                                      'driver' &&
                                                  (userDetails[
                                                              'vehicle_type_id'] !=
                                                          null ||
                                                      userDetails[
                                                              'vehicle_types']
                                                          .isNotEmpty))
                                          ? Container(
                                              alignment: Alignment.center,
                                              child: InkWell(
                                                  onTap: () async {
                                                    // await getUserDetails();
                                                    if (((userDetails[
                                                                    'vehicle_type_id'] !=
                                                                null) ||
                                                            (userDetails[
                                                                    'vehicle_types'] !=
                                                                [])) &&
                                                        userDetails['role'] ==
                                                            'driver') {
                                                      if (locationAllowed ==
                                                              true &&
                                                          serviceEnabled ==
                                                              true) {
                                                        setState(() {
                                                          _isLoading = true;
                                                        });

                                                        var val =
                                                            await driverStatus();
                                                        if (val == 'logout') {
                                                          navigateLogout();
                                                        }
                                                        setState(() {
                                                          _isLoading = false;
                                                        });
                                                      } else if (locationAllowed ==
                                                              true &&
                                                          serviceEnabled ==
                                                              false) {
                                                        await geolocator
                                                                .Geolocator
                                                            .getCurrentPosition(
                                                                desiredAccuracy:
                                                                    geolocator
                                                                        .LocationAccuracy
                                                                        .low);
                                                        if (await geolocator
                                                            .GeolocatorPlatform
                                                            .instance
                                                            .isLocationServiceEnabled()) {
                                                          serviceEnabled = true;
                                                          setState(() {
                                                            _isLoading = true;
                                                          });

                                                          var val =
                                                              await driverStatus();
                                                          if (val == 'logout') {
                                                            navigateLogout();
                                                          }
                                                          setState(() {
                                                            _isLoading = false;
                                                          });
                                                        }
                                                      } else {
                                                        if (serviceEnabled ==
                                                            true) {
                                                          setState(() {
                                                            makeOnline = true;
                                                          });
                                                        } else {
                                                          await geolocator
                                                                  .Geolocator
                                                              .getCurrentPosition(
                                                                  desiredAccuracy:
                                                                      geolocator
                                                                          .LocationAccuracy
                                                                          .low);
                                                          setState(() {
                                                            _isLoading = true;
                                                          });
                                                          await getLocs();
                                                          if (serviceEnabled ==
                                                              true) {
                                                            setState(() {
                                                              makeOnline = true;
                                                            });
                                                          }
                                                        }
                                                      }
                                                    }
                                                  },
                                                  child: Container(
                                                    padding: EdgeInsets.only(
                                                        left:
                                                            media.width * 0.01,
                                                        right:
                                                            media.width * 0.01),
                                                    height: media.width * 0.08,
                                                    width: media.width * 0.267,
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              media.width *
                                                                  0.04),
                                                      color: (userDetails[
                                                                  'active'] ==
                                                              false)
                                                          ? const Color(
                                                                  0xff707070)
                                                              .withOpacity(0.6)
                                                          : const Color(
                                                              0xff00E688),
                                                    ),
                                                    child:
                                                        (userDetails[
                                                                    'active'] ==
                                                                false)
                                                            ? Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceBetween,
                                                                children: [
                                                                  Container(
                                                                    padding: EdgeInsets.all(
                                                                        media.width *
                                                                            0.01),
                                                                    height: media
                                                                            .width *
                                                                        0.07,
                                                                    width: media
                                                                            .width *
                                                                        0.07,
                                                                    decoration: BoxDecoration(
                                                                        shape: BoxShape
                                                                            .circle,
                                                                        color:
                                                                            onlineOfflineText),
                                                                    child: Image
                                                                        .asset(
                                                                      'assets/images/offline.png',
                                                                      color: const Color(
                                                                          0xff707070),
                                                                    ),
                                                                  ),
                                                                  Expanded(
                                                                    child: Padding(
                                                                      padding: EdgeInsets.symmetric(horizontal: media.width * 0.02),
                                                                      child: MyText(
                                                                        text: languages[
                                                                                choosenLanguage]
                                                                            [
                                                                            'text_on_duty'],
                                                                        size: media
                                                                                .width *
                                                                            twelve,
                                                                        color: (isDarkTheme ==
                                                                                true)
                                                                            ? textColor.withOpacity(
                                                                                0.7)
                                                                            : const Color(
                                                                                0xff555555),
                                                                        maxLines: 1,
                                                                        overflow: TextOverflow.ellipsis,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  SizedBox(width: media.width * 0.01),
                                                                ],
                                                              )
                                                            : Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceBetween,
                                                                children: [
                                                                  Expanded(
                                                                    child: MyText(
                                                                      text: languages[
                                                                              choosenLanguage]
                                                                          [
                                                                          'text_off_duty'],
                                                                      size: media
                                                                              .width *
                                                                          twelve,
                                                                      color:
                                                                          textColor,
                                                                      maxLines: 1,
                                                                      overflow: TextOverflow.ellipsis,
                                                                    ),
                                                                  ),
                                                                  SizedBox(width: media.width * 0.02),
                                                                  Container(
                                                                    padding: EdgeInsets.all(
                                                                        media.width *
                                                                            0.01),
                                                                    height: media
                                                                            .width *
                                                                        0.07,
                                                                    width: media
                                                                            .width *
                                                                        0.07,
                                                                    decoration: BoxDecoration(
                                                                        shape: BoxShape
                                                                            .circle,
                                                                        color:
                                                                            onlineOfflineText),
                                                                    child: Image
                                                                        .asset(
                                                                      'assets/images/offline.png',
                                                                      color: const Color(
                                                                          0xff00E688),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                  )),
                                            )
                                          : (userDetails['role'] == 'driver' &&
                                                  (userDetails[
                                                              'vehicle_type_id'] ==
                                                          null &&
                                                      userDetails[
                                                              'vehicle_types']
                                                          .isEmpty))
                                              ? Container(
                                                  decoration: BoxDecoration(
                                                      color: buttonColor,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10)),
                                                  width: media.width * 0.4,
                                                  padding: EdgeInsets.all(
                                                      media.width * 0.025),
                                                  child: Text(
                                                    languages[choosenLanguage][
                                                        'text_no_fleet_assigned'],
                                                    style: GoogleFonts.poppins(
                                                      fontSize: media.width *
                                                          fourteen,
                                                      color: Colors.white,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                )
                                              : (userDetails.isNotEmpty &&
                                                      userDetails[
                                                              'low_balance'] ==
                                                          true)
                                                  ?
                                                  //low balance
                                                  Container(
                                                      decoration: BoxDecoration(
                                                          color: buttonColor,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      10)),
                                                      width: media.width * 0.4,
                                                      padding: EdgeInsets.all(
                                                          media.width * 0.025),
                                                      child: Text(
                                                        userDetails['owner_id'] !=
                                                                null
                                                            ? languages[
                                                                    choosenLanguage]
                                                                [
                                                                'text_fleet_diver_low_bal']
                                                            : languages[
                                                                    choosenLanguage]
                                                                [
                                                                'text_low_balance'],
                                                        style:
                                                            GoogleFonts.poppins(
                                                          fontSize:
                                                              media.width *
                                                                  fourteen,
                                                          color: Colors.white,
                                                        ),
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
                                                    )
                                                  : Container(),
                                      (userDetails['enable_bidding'] == true)
                                          ? InkWell(
                                              onTap: () {
                                                setState(() {
                                                  _choosenDistance =
                                                      choosenDistance;
                                                  _selectDistance = true;
                                                });
                                              },
                                              child: Text(
                                                distanceBetween[choosenDistance]
                                                        ['name']
                                                    .toString(),
                                                style: GoogleFonts.poppins(
                                                    fontSize:
                                                        media.width * fourteen,
                                                    fontWeight: FontWeight.w600,
                                                    color: buttonColor),
                                                textDirection:
                                                    TextDirection.ltr,
                                              ))
                                          : Container()
                                    ],
                                  ),
                                  SizedBox(
                                    height: media.width * 0.05,
                                  ),
                                  userDetails['active'] == true &&
                                          rideList.isNotEmpty &&
                                          driverReq.isEmpty
                                      ? Expanded(
                                          child: SingleChildScrollView(
                                            child: Column(
                                              children: rideList
                                                  .asMap()
                                                  .map((key, value) {
                                                    List stops = [];
                                                    if (rideList[key]
                                                            ['trip_stops'] !=
                                                        'null') {
                                                      stops = jsonDecode(
                                                          rideList[key]
                                                              ['trip_stops']);
                                                    }
                                                    return MapEntry(
                                                        key,
                                                        InkWell(
                                                          onTap: () {
                                                            choosenRide.clear();
                                                            choosenRide.add(
                                                                rideList[key]);

                                                            if (choosenRide[0][
                                                                    'trip_stops'] !=
                                                                'null') {
                                                              tripStops = stops;
                                                            } else {
                                                              tripStops.clear();
                                                            }

                                                            Navigator.push(
                                                                context,
                                                                MaterialPageRoute(
                                                                    builder:
                                                                        (context) =>
                                                                            const Maps()));
                                                          },
                                                          child: Container(
                                                            padding: EdgeInsets
                                                                .all(media
                                                                        .width *
                                                                    0.05),
                                                            margin: EdgeInsets.only(
                                                                bottom: media
                                                                        .width *
                                                                    0.04),
                                                            width: media.width *
                                                                0.9,
                                                            clipBehavior: Clip.hardEdge,
                                                            decoration: BoxDecoration(
                                                                color: Colors
                                                                    .white,
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            10),
                                                                boxShadow: [
                                                                  BoxShadow(
                                                                      blurRadius:
                                                                          2.0,
                                                                      spreadRadius:
                                                                          2.0,
                                                                      color: Colors
                                                                          .black
                                                                          .withOpacity(
                                                                              0.2))
                                                                ]),
                                                            child: Column(
                                                              children: [
                                                                Row(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    Column(
                                                                      children: [
                                                                        Container(
                                                                          height:
                                                                              media.width * 0.1,
                                                                          width:
                                                                              media.width * 0.1,
                                                                          decoration: BoxDecoration(
                                                                              shape: BoxShape.circle,
                                                                              image: DecorationImage(image: NetworkImage(rideList[key]['user_img']), fit: BoxFit.cover)),
                                                                        ),
                                                                        SizedBox(
                                                                          height:
                                                                              media.width * 0.05,
                                                                        ),
                                                                        SizedBox(
                                                                          width:
                                                                              media.width * 0.1,
                                                                          child:
                                                                              Text(
                                                                            rideList[key]['user_name'],
                                                                            style:
                                                                                GoogleFonts.poppins(fontSize: media.width * fourteen, fontWeight: FontWeight.w600),
                                                                            textAlign:
                                                                                TextAlign.center,
                                                                            maxLines:
                                                                                1,
                                                                          ),
                                                                        )
                                                                      ],
                                                                    ),
                                                                    SizedBox(
                                                                      width: media
                                                                              .width *
                                                                          0.025,
                                                                    ),
                                                                    Column(
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .start,
                                                                      children: [
                                                                        ClipRect(
                                                                          child: Row(
                                                                            mainAxisAlignment:
                                                                                MainAxisAlignment.spaceBetween,
                                                                            children: [
                                                                              Expanded(
                                                                                child: Padding(
                                                                                  padding: EdgeInsets.only(right: media.width * 0.005),
                                                                                  child: Text(
                                                                                    languages[choosenLanguage]['text_pick'],
                                                                                    style: GoogleFonts.poppins(fontSize: media.width * fourteen, fontWeight: FontWeight.w600),
                                                                                    overflow: TextOverflow.ellipsis,
                                                                                    maxLines: 1,
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                              Expanded(
                                                                                child: InkWell(
                                                                                  onTap: () {
                                                                                    setState(() {
                                                                                      choosenRide.clear();
                                                                                      choosenRide.add(rideList[key]);
                                                                                      _cancel = true;
                                                                                    });
                                                                                  },
                                                                                  child: Text(
                                                                                    languages[choosenLanguage]['text_skip_ride'],
                                                                                    style: GoogleFonts.poppins(fontSize: media.width * (fourteen * 0.75), fontWeight: FontWeight.w600, color: Colors.red),
                                                                                    overflow: TextOverflow.ellipsis,
                                                                                    maxLines: 1,
                                                                                    textAlign: TextAlign.end,
                                                                                  ),
                                                                                ),
                                                                              )
                                                                            ],
                                                                          ),
                                                                        ),
                                                                        SizedBox(
                                                                          height:
                                                                              media.width * 0.025,
                                                                        ),
                                                                        SizedBox(
                                                                          width:
                                                                              media.width * 0.65,
                                                                          child:
                                                                              Text(
                                                                            rideList[key]['pick_address'],
                                                                            style:
                                                                                GoogleFonts.poppins(
                                                                              fontSize: media.width * twelve,
                                                                            ),
                                                                            // maxLines:
                                                                            //     1,
                                                                          ),
                                                                        ),
                                                                        (stops.isEmpty)
                                                                            ? Column(
                                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                                children: [
                                                                                  SizedBox(
                                                                                    height: media.width * 0.025,
                                                                                  ),
                                                                                  Text(
                                                                                    languages[choosenLanguage]['text_drop'],
                                                                                    // 'droppppppp',
                                                                                    style: GoogleFonts.poppins(fontSize: media.width * fourteen, fontWeight: FontWeight.w600),
                                                                                  ),
                                                                                  SizedBox(
                                                                                    height: media.width * 0.025,
                                                                                  ),
                                                                                  SizedBox(
                                                                                    width: media.width * 0.65,
                                                                                    child: Text(
                                                                                      rideList[key]['drop_address'],
                                                                                      style: GoogleFonts.poppins(
                                                                                        fontSize: media.width * twelve,
                                                                                      ),
                                                                                      // maxLines: 1,
                                                                                    ),
                                                                                  )
                                                                                ],
                                                                              )
                                                                            : Column(
                                                                                children: stops
                                                                                    .asMap()
                                                                                    .map((key, value) {
                                                                                      return MapEntry(
                                                                                          key,
                                                                                          Column(
                                                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                                                            children: [
                                                                                              if (key == 0)
                                                                                                SizedBox(
                                                                                                  height: media.width * 0.025,
                                                                                                ),
                                                                                              if (key == 0)
                                                                                                Text(
                                                                                                  languages[choosenLanguage]['text_drop'],
                                                                                                  style: GoogleFonts.poppins(fontSize: media.width * fourteen, fontWeight: FontWeight.w600),
                                                                                                ),
                                                                                              SizedBox(
                                                                                                height: media.width * 0.025,
                                                                                              ),
                                                                                              SizedBox(
                                                                                                width: media.width * 0.65,
                                                                                                child: Text(
                                                                                                  stops[key]['address'],
                                                                                                  style: GoogleFonts.poppins(
                                                                                                    fontSize: media.width * twelve,
                                                                                                  ),
                                                                                                  // maxLines: 1,
                                                                                                ),
                                                                                              )
                                                                                            ],
                                                                                          ));
                                                                                    })
                                                                                    .values
                                                                                    .toList(),
                                                                              ),
                                                                        if (rideList[key]['goods'] !=
                                                                            'null')
                                                                          Column(
                                                                            crossAxisAlignment:
                                                                                CrossAxisAlignment.start,
                                                                            children: [
                                                                              SizedBox(
                                                                                height: media.width * 0.025,
                                                                              ),
                                                                              Text(
                                                                                languages[choosenLanguage]['text_goods_type'],
                                                                                style: GoogleFonts.poppins(fontSize: media.width * fourteen, fontWeight: FontWeight.w600),
                                                                              ),
                                                                              SizedBox(
                                                                                height: media.width * 0.025,
                                                                              ),
                                                                              SizedBox(
                                                                                width: media.width * 0.65,
                                                                                child: Text(
                                                                                  rideList[key]['goods'],
                                                                                  style: GoogleFonts.poppins(
                                                                                    fontSize: media.width * twelve,
                                                                                  ),
                                                                                  maxLines: 2,
                                                                                ),
                                                                              )
                                                                            ],
                                                                          ),
                                                                      ],
                                                                    )
                                                                  ],
                                                                ),
                                                                SizedBox(
                                                                  height: media
                                                                          .width *
                                                                      0.025,
                                                                ),
                                                                SizedBox(
                                                                  width: media
                                                                          .width *
                                                                      0.9,
                                                                  child: Text(
                                                                    '${rideList[key]['currency']} ${formatDecimalBr(rideList[key]['price'])}',
                                                                    style: GoogleFonts.poppins(
                                                                        fontSize:
                                                                            media.width *
                                                                                sixteen,
                                                                        fontWeight:
                                                                            FontWeight.w600),
                                                                    textAlign:
                                                                        TextAlign
                                                                            .end,
                                                                  ),
                                                                )
                                                              ],
                                                            ),
                                                          ),
                                                        ));
                                                  })
                                                  .values
                                                  .toList(),
                                            ),
                                          ),
                                        )
                                      : (userDetails['active'] == false)
                                          ? Expanded(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  SizedBox(
                                                    width: media.width * 0.7,
                                                    height: media.width * 0.7,
                                                    child: Image.asset(
                                                      'assets/images/offline_image.png',
                                                      fit: BoxFit.contain,
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    height: media.width * 0.05,
                                                  ),
                                                  SizedBox(
                                                    width: media.width * 0.9,
                                                    child: Text(
                                                      languages[choosenLanguage]
                                                          [
                                                          'text_you_are_offduty'],
                                                      style:
                                                          GoogleFonts.poppins(
                                                        fontSize: media.width *
                                                            sixteen,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  )
                                                ],
                                              ),
                                            )
                                          : (rideList.isEmpty)
                                              ? Expanded(
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      SizedBox(
                                                        width:
                                                            media.width * 0.7,
                                                        height:
                                                            media.width * 0.7,
                                                        child: Image.asset(
                                                          'assets/images/no_ride.png',
                                                          fit: BoxFit.contain,
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        height:
                                                            media.width * 0.05,
                                                      ),
                                                      Padding(
                                                        padding: EdgeInsets.symmetric(
                                                            horizontal: media.width * 0.02),
                                                        child: Text(
                                                          languages[
                                                                  choosenLanguage]
                                                              [
                                                              'text_no_ride_in_area'],
                                                          style: GoogleFonts
                                                              .poppins(
                                                                  fontSize: media
                                                                          .width *
                                                                      sixteen,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color:
                                                                      textColor),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      )
                                                    ],
                                                  ),
                                                )
                                              : Container(),
                                ],
                              ),
                            ),
                            (driverReq.isEmpty &&
                                    userDetails['role'] != 'owner' &&
                                    userDetails['transport_type'] !=
                                        'delivery' &&
                                    userDetails['active'] == true)
                                ? Positioned(
                                    bottom: media.width * 0.05,
                                    left: media.width * 0.05,
                                    right: media.width * 0.05,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Button(
                                              color: theme,
                                              onTap: () async {
                                                addressList.clear();
                                                var val = await geoCoding(
                                                    center.latitude,
                                                    center.longitude);
                                                setState(() {
                                                  if (addressList
                                                      .where((element) =>
                                                          element.id == 'pickup')
                                                      .isNotEmpty) {
                                                    var add = addressList
                                                        .firstWhere((element) =>
                                                            element.id ==
                                                            'pickup');
                                                    add.address = val;
                                                    add.latlng = LatLng(
                                                        center.latitude,
                                                        center.longitude);
                                                  } else {
                                                    addressList.add(AddressList(
                                                        id: 'pickup',
                                                        address: val,
                                                        latlng: LatLng(
                                                            center.latitude,
                                                            center.longitude)));
                                                  }
                                                });
                                                if (addressList.isNotEmpty) {
                                                  // ignore: use_build_context_synchronously
                                                  Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              const DropLocation()));
                                                }
                                              },
                                              text: languages[choosenLanguage]
                                                  ['text_instant_ride'])
                                        )
                                      ],
                                    ))
                                : Container(),

                            //delete account
                            (deleteAccount == true)
                                ? Positioned(
                                    top: 0,
                                    child: Container(
                                      height: media.height * 1,
                                      width: media.width * 1,
                                      color:
                                          Colors.transparent.withOpacity(0.6),
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
                                                    decoration:
                                                        const BoxDecoration(
                                                            shape:
                                                                BoxShape.circle,
                                                            color:
                                                                Colors.white),
                                                    child: InkWell(
                                                        onTap: () {
                                                          setState(() {
                                                            deleteAccount =
                                                                false;
                                                          });
                                                        },
                                                        child: const Icon(Icons
                                                            .cancel_outlined))),
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
                                                  style: GoogleFonts.poppins(
                                                      fontSize:
                                                          media.width * sixteen,
                                                      color: textColor,
                                                      fontWeight:
                                                          FontWeight.w600),
                                                ),
                                                SizedBox(
                                                  height: media.width * 0.05,
                                                ),
                                                Button(
                                                    onTap: () async {
                                                      setState(() {
                                                        deleteAccount = false;
                                                        _isLoading = true;
                                                      });
                                                      var result =
                                                          await userDelete();
                                                      if (result == 'success') {
                                                        setState(() {
                                                          Navigator.pushAndRemoveUntil(
                                                              context,
                                                              MaterialPageRoute(
                                                                  builder:
                                                                      (context) =>
                                                                          const LandingPage()),
                                                              (route) => false);
                                                          userDetails.clear();
                                                        });
                                                      } else if (result ==
                                                          'logout') {
                                                        navigateLogout();
                                                      } else {
                                                        setState(() {
                                                          _isLoading = false;
                                                          deleteAccount = true;
                                                        });
                                                      }
                                                      setState(() {
                                                        _isLoading = false;
                                                      });
                                                    },
                                                    text: languages[
                                                            choosenLanguage]
                                                        ['text_confirm'])
                                              ],
                                            ),
                                          )
                                        ],
                                      ),
                                    ))
                                : Container(),

                            //logout popup
                            (logout == true)
                                ? Positioned(
                                    top: 0,
                                    child: Container(
                                      height: media.height * 1,
                                      width: media.width * 1,
                                      color:
                                          Colors.transparent.withOpacity(0.6),
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
                                                            logout = false;
                                                          });
                                                        },
                                                        child: Icon(
                                                          Icons.cancel_outlined,
                                                          color: textColor,
                                                        ))),
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
                                                      ['text_confirmlogout'],
                                                  textAlign: TextAlign.center,
                                                  style: GoogleFonts.poppins(
                                                      fontSize:
                                                          media.width * sixteen,
                                                      color: textColor,
                                                      fontWeight:
                                                          FontWeight.w600),
                                                ),
                                                SizedBox(
                                                  height: media.width * 0.05,
                                                ),
                                                Button(
                                                    onTap: () async {
                                                      setState(() {
                                                        _isLoading = true;
                                                        logout = false;
                                                      });
                                                      var result =
                                                          await userLogout();
                                                      if (result == 'success') {
                                                        setState(() {
                                                          Navigator.pushAndRemoveUntil(
                                                              context,
                                                              MaterialPageRoute(
                                                                  builder:
                                                                      (context) =>
                                                                          const LandingPage()),
                                                              (route) => false);
                                                          userDetails.clear();
                                                        });
                                                      } else {
                                                        if (result == 'logout') {
                                                          navigateLogout();
                                                        }
                                                        if (mounted) setState(() {
                                                          _isLoading = false;
                                                          logout = true;
                                                        });
                                                      }
                                                    },
                                                    text: languages[
                                                            choosenLanguage]
                                                        ['text_confirm'])
                                              ],
                                            ),
                                          )
                                        ],
                                      ),
                                    ))
                                : Container(),

                            if (_cancel == true)
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
                                                      _cancel = false;
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
                                                ['text_cancel_confirmation'],
                                            // 'yyygghjhgjhgjhghgh',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.poppins(
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
                                                  _isLoading = true;
                                                });
                                                try {
                                                  await FirebaseDatabase
                                                      .instance
                                                      .ref()
                                                      .child(
                                                          'bid-meta/${choosenRide[0]["request_id"]}/drivers/driver_${userDetails["id"]}')
                                                      .update({
                                                    'driver_id':
                                                        userDetails['id'],
                                                    'price': choosenRide[0]
                                                            ["price"]
                                                        .toString(),
                                                    'driver_name':
                                                        userDetails['name'],
                                                    'driver_img': userDetails[
                                                        'profile_picture'],
                                                    'bid_time':
                                                        ServerValue.timestamp,
                                                    'is_rejected': 'by_driver'
                                                  });

                                                  // Navigator.pop(context);
                                                } catch (e) {
                                                  debugPrint(e.toString());
                                                }
                                                setState(() {
                                                  _cancel = false;
                                                  _isLoading = false;
                                                });
                                              },
                                              text: languages[choosenLanguage]
                                                  ['text_confirm'])
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              )),

                            //waiting for ride to accept by customer
                            if (waitingList.isNotEmpty)
                              Positioned(
                                  child: ValueListenableBuilder(
                                      valueListenable: valueNotifierTimer.value,
                                      builder: (context, value, child) {
                                        var val = DateTime.now()
                                            .difference(DateTime
                                                .fromMillisecondsSinceEpoch(
                                                    waitingList[0]['drivers'][
                                                            'driver_${userDetails["id"]}']
                                                        ['bid_time']))
                                            .inSeconds;
                                        if (int.parse(val.toString()) >=
                                            (int.parse(userDetails[
                                                        'maximum_time_for_find_drivers_for_bitting_ride']
                                                    .toString()) +
                                                5)) {
                                          FirebaseDatabase.instance
                                              .ref()
                                              .child(
                                                  'bid-meta/${waitingList[0]["request_id"]}/drivers/driver_${userDetails["id"]}')
                                              .update(
                                                  {"is_rejected": 'by_user'});
                                        }
                                        return Container(
                                          height: media.height * 1,
                                          width: media.width * 1,
                                          color: Colors.transparent
                                              .withOpacity(0.6),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Expanded(
                                                child: Container(),
                                              ),
                                              if (waitingList.isNotEmpty)
                                                Container(
                                                  width: media.width * 1,
                                                  decoration: BoxDecoration(
                                                      color: page,
                                                      //  borderRadius: BorderRadius.only(topRight:Radius.circular(10), topLeft: Radius.circular(10)),
                                                      boxShadow: [
                                                        BoxShadow(
                                                            blurRadius: 2.0,
                                                            spreadRadius: 2.0,
                                                            color: Colors.black
                                                                .withOpacity(
                                                                    0.2))
                                                      ]),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Container(
                                                        width: (media.width *
                                                                1 /
                                                                (int.parse(userDetails[
                                                                            'maximum_time_for_find_drivers_for_bitting_ride']
                                                                        .toString()) +
                                                                    5)) *
                                                            ((int.parse(userDetails[
                                                                            'maximum_time_for_find_drivers_for_bitting_ride']
                                                                        .toString()) +
                                                                    5) -
                                                                double.parse(val
                                                                    .toString())),
                                                        height: 5,
                                                        color: buttonColor,
                                                      ),
                                                      SizedBox(
                                                        height:
                                                            media.width * 0.05,
                                                      ),
                                                      Column(
                                                        children: [
                                                          SizedBox(
                                                              width:
                                                                  media.width *
                                                                      0.7,
                                                              child: Text(
                                                                languages[
                                                                        choosenLanguage]
                                                                    [
                                                                    'text_waiting_for_user'],
                                                                style: GoogleFonts.poppins(
                                                                    fontSize: media
                                                                            .width *
                                                                        sixteen,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    color:
                                                                        textColor),
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                              )),
                                                          Container(
                                                            padding: EdgeInsets
                                                                .all(media
                                                                        .width *
                                                                    0.05),
                                                            child: Column(
                                                              children: [
                                                                Row(
                                                                  children: [
                                                                    Column(
                                                                      children: [
                                                                        Container(
                                                                          height:
                                                                              media.width * 0.1,
                                                                          width:
                                                                              media.width * 0.1,
                                                                          decoration: BoxDecoration(
                                                                              shape: BoxShape.circle,
                                                                              image: DecorationImage(image: NetworkImage(waitingList[0]['user_img']), fit: BoxFit.cover)),
                                                                        ),
                                                                        SizedBox(
                                                                          height:
                                                                              media.width * 0.05,
                                                                        ),
                                                                        SizedBox(
                                                                          width:
                                                                              media.width * 0.1,
                                                                          child:
                                                                              Text(
                                                                            waitingList[0]['user_name'],
                                                                            style: GoogleFonts.poppins(
                                                                                fontSize: media.width * fourteen,
                                                                                color: textColor,
                                                                                fontWeight: FontWeight.w600),
                                                                            textAlign:
                                                                                TextAlign.center,
                                                                            maxLines:
                                                                                1,
                                                                          ),
                                                                        )
                                                                      ],
                                                                    ),
                                                                    SizedBox(
                                                                      width: media
                                                                              .width *
                                                                          0.025,
                                                                    ),
                                                                    Expanded(
                                                                      child:
                                                                          SingleChildScrollView(
                                                                        child:
                                                                            Column(
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.start,
                                                                          children: [
                                                                            Row(
                                                                              mainAxisAlignment: MainAxisAlignment.start,
                                                                              children: [
                                                                                Container(
                                                                                  height: media.width * 0.05,
                                                                                  width: media.width * 0.05,
                                                                                  alignment: Alignment.center,
                                                                                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.green),
                                                                                  child: Container(
                                                                                    height: media.width * 0.025,
                                                                                    width: media.width * 0.025,
                                                                                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.8)),
                                                                                  ),
                                                                                ),
                                                                                SizedBox(
                                                                                  width: media.width * 0.06,
                                                                                ),
                                                                                Expanded(
                                                                                  child: MyText(
                                                                                    text: waitingList[0]['pick_address'],
                                                                                    // maxLines: 1,
                                                                                    size: media.width * twelve,
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                            SizedBox(
                                                                              height: media.width * 0.02,
                                                                            ),
                                                                            Row(
                                                                              mainAxisAlignment: MainAxisAlignment.start,
                                                                              children: [
                                                                                Container(
                                                                                  height: media.width * 0.06,
                                                                                  width: media.width * 0.06,
                                                                                  alignment: Alignment.center,
                                                                                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.red.withOpacity(0.1)),
                                                                                  child: Icon(
                                                                                    Icons.location_on_outlined,
                                                                                    color: const Color(0xFFFF0000),
                                                                                    size: media.width * eighteen,
                                                                                  ),
                                                                                ),
                                                                                SizedBox(
                                                                                  width: media.width * 0.05,
                                                                                ),
                                                                                Expanded(
                                                                                  child: MyText(
                                                                                    text: waitingList[0]['drop_address'],
                                                                                    // maxLines: 1,
                                                                                    size: media.width * twelve,
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    )
                                                                  ],
                                                                ),
                                                                SizedBox(
                                                                  height: media
                                                                          .width *
                                                                      0.025,
                                                                ),
                                                                SizedBox(
                                                                  width: media
                                                                          .width *
                                                                      0.9,
                                                                  child: Text(
                                                                    '${waitingList[0]['currency']} ${formatDecimalBr(waitingList[0]['drivers']['driver_${userDetails["id"]}']['price'])}',
                                                                    style: GoogleFonts.poppins(
                                                                        fontSize:
                                                                            media.width *
                                                                                sixteen,
                                                                        color:
                                                                            textColor,
                                                                        fontWeight:
                                                                            FontWeight.w600),
                                                                    textAlign:
                                                                        TextAlign
                                                                            .end,
                                                                  ),
                                                                )
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      )
                                                    ],
                                                  ),
                                                )
                                            ],
                                          ),
                                        );
                                      })),

                            //select distance
                            (_selectDistance == true)
                                ? Positioned(
                                    top: 0,
                                    child: Container(
                                      height: media.height * 1,
                                      width: media.width * 1,
                                      color:
                                          Colors.transparent.withOpacity(0.6),
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
                                                            _selectDistance =
                                                                false;
                                                          });
                                                        },
                                                        child: Icon(
                                                          Icons.cancel_outlined,
                                                          color: textColor,
                                                        ))),
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
                                                      ['text_distance_between'],
                                                  textAlign: TextAlign.center,
                                                  style: GoogleFonts.poppins(
                                                      fontSize:
                                                          media.width * sixteen,
                                                      color: textColor,
                                                      fontWeight:
                                                          FontWeight.w600),
                                                ),
                                                SizedBox(
                                                  height: media.width * 0.05,
                                                ),
                                                Column(
                                                  children: distanceBetween
                                                      .asMap()
                                                      .map((i, value) {
                                                        return MapEntry(
                                                          i,
                                                          InkWell(
                                                            onTap: () {
                                                              setState(() {
                                                                _choosenDistance =
                                                                    i;
                                                              });
                                                            },
                                                            child: Row(
                                                              children: [
                                                                Container(
                                                                  height: media
                                                                          .height *
                                                                      0.05,
                                                                  width: media
                                                                          .width *
                                                                      0.05,
                                                                  decoration: BoxDecoration(
                                                                      shape: BoxShape
                                                                          .circle,
                                                                      border: Border.all(
                                                                          color:
                                                                              textColor,
                                                                          width:
                                                                              1.2)),
                                                                  alignment:
                                                                      Alignment
                                                                          .center,
                                                                  child: (_choosenDistance ==
                                                                          i)
                                                                      ? Container(
                                                                          height:
                                                                              media.width * 0.03,
                                                                          width:
                                                                              media.width * 0.03,
                                                                          decoration:
                                                                              BoxDecoration(
                                                                            shape:
                                                                                BoxShape.circle,
                                                                            color:
                                                                                textColor,
                                                                          ),
                                                                        )
                                                                      : Container(),
                                                                ),
                                                                SizedBox(
                                                                  width: media
                                                                          .width *
                                                                      0.05,
                                                                ),
                                                                Text(
                                                                  distanceBetween[
                                                                              i]
                                                                          [
                                                                          'name']
                                                                      .toString(),
                                                                  style: GoogleFonts.poppins(
                                                                      fontSize:
                                                                          media.width *
                                                                              sixteen,
                                                                      color:
                                                                          textColor,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600),
                                                                )
                                                              ],
                                                            ),
                                                          ),
                                                        );
                                                      })
                                                      .values
                                                      .toList(),
                                                ),
                                                SizedBox(
                                                  height: media.width * 0.025,
                                                ),
                                                Button(
                                                    onTap: () async {
                                                      setState(() {
                                                        choosenDistance =
                                                            _choosenDistance;
                                                        _selectDistance = false;
                                                        pref.setString(
                                                            'choosenDistance',
                                                            choosenDistance
                                                                .toString());

                                                        rideStart?.cancel();
                                                        rideStart = null;
                                                        rideRequest();
                                                      });
                                                    },
                                                    text: languages[
                                                            choosenLanguage]
                                                        ['text_confirm'])
                                              ],
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  )
                                : Container(),

                            (updateAvailable == true)
                                ? Positioned(
                                    top: 0,
                                    child: Container(
                                      height: media.height * 1,
                                      width: media.width * 1,
                                      color:
                                          Colors.transparent.withOpacity(0.6),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                              width: media.width * 0.9,
                                              padding: EdgeInsets.all(
                                                  media.width * 0.05),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                color: page,
                                              ),
                                              child: Column(
                                                children: [
                                                  SizedBox(
                                                      width: media.width * 0.8,
                                                      child: Text(
                                                        languages[
                                                                choosenLanguage]
                                                            [
                                                            'text_update_available'],
                                                        style:
                                                            GoogleFonts.poppins(
                                                                fontSize: media
                                                                        .width *
                                                                    sixteen,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600),
                                                      )),
                                                  SizedBox(
                                                    height: media.width * 0.05,
                                                  ),
                                                  Button(
                                                      onTap: () async {
                                                        if (platform ==
                                                            TargetPlatform
                                                                .android) {
                                                          openBrowser(
                                                              'https://play.google.com/store/apps/details?id=${package.packageName}');
                                                        } else {
                                                          setState(() {
                                                            _isLoading = true;
                                                          });
                                                          var response = await http
                                                              .get(Uri.parse(
                                                                  'http://itunes.apple.com/lookup?bundleId=${package.packageName}'));
                                                          if (response
                                                                  .statusCode ==
                                                              200) {
                                                            openBrowser(jsonDecode(
                                                                        response
                                                                            .body)[
                                                                    'results'][0]
                                                                [
                                                                'trackViewUrl']);

                                                            // printWrapped(jsonDecode(response.body)['results'][0]['trackViewUrl']);
                                                          }

                                                          setState(() {
                                                            _isLoading = false;
                                                          });
                                                        }
                                                      },
                                                      text: 'Update')
                                                ],
                                              ))
                                        ],
                                      ),
                                    ))
                                : Container(),

                            //loader
                            (_isLoading == true)
                                ? const Positioned(top: 0, child: Loading())
                                : Container(),
                          ],
                        ),
                      ),
                    );
                  })
              : (state == '1')
                  ? Container(
                      padding: EdgeInsets.all(media.width * 0.05),
                      width: media.width * 0.6,
                      height: media.width * 0.3,
                      decoration: BoxDecoration(
                          color: page,
                          boxShadow: [
                            BoxShadow(
                                blurRadius: 5,
                                color: Colors.black.withOpacity(0.2),
                                spreadRadius: 2)
                          ],
                          borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            languages[choosenLanguage]['text_enable_location'],
                            style: GoogleFonts.poppins(
                                fontSize: media.width * sixteen,
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
                                languages[choosenLanguage]['text_ok'],
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: media.width * twenty,
                                    color: buttonColor),
                              ),
                            ),
                          )
                        ],
                      ),
                    )
                  : (state == '2')
                      ? Container(
                          height: media.height * 1,
                          width: media.width * 1,
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: media.height * 0.31,
                                child: Image.asset(
                                  'assets/images/location_perm.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                              SizedBox(
                                height: media.width * 0.05,
                              ),
                              Text(
                                languages[choosenLanguage]['text_trustedtaxi'],
                                style: GoogleFonts.poppins(
                                    fontSize: media.width * eighteen,
                                    fontWeight: FontWeight.w600),
                              ),
                              SizedBox(
                                height: media.width * 0.025,
                              ),
                              Text(
                                languages[choosenLanguage]
                                    ['text_allowpermission1'],
                                style: GoogleFonts.poppins(
                                  fontSize: media.width * fourteen,
                                ),
                              ),
                              Text(
                                languages[choosenLanguage]
                                    ['text_allowpermission2'],
                                style: GoogleFonts.poppins(
                                  fontSize: media.width * fourteen,
                                ),
                              ),
                              SizedBox(
                                height: media.width * 0.05,
                              ),
                              Container(
                                padding: EdgeInsets.fromLTRB(media.width * 0.05,
                                    0, media.width * 0.05, 0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                        width: media.width * 0.075,
                                        child: const Icon(
                                            Icons.location_on_outlined)),
                                    SizedBox(
                                      width: media.width * 0.025,
                                    ),
                                    SizedBox(
                                      width: media.width * 0.8,
                                      child: Text(
                                        languages[choosenLanguage]
                                            ['text_loc_permission'],
                                        style: GoogleFonts.poppins(
                                            fontSize: media.width * fourteen,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: media.width * 0.02,
                              ),
                              Container(
                                padding: EdgeInsets.fromLTRB(media.width * 0.05,
                                    0, media.width * 0.05, 0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                        width: media.width * 0.075,
                                        child: const Icon(
                                            Icons.location_on_outlined)),
                                    SizedBox(
                                      width: media.width * 0.025,
                                    ),
                                    SizedBox(
                                      width: media.width * 0.8,
                                      child: Text(
                                        languages[choosenLanguage]
                                            ['text_background_permission'],
                                        style: GoogleFonts.poppins(
                                            fontSize: media.width * fourteen,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                  padding: EdgeInsets.all(media.width * 0.05),
                                  child: Button(
                                      onTap: () async {
                                        getLocationPermission();
                                      },
                                      text: languages[choosenLanguage]
                                          ['text_continue']))
                            ],
                          ),
                        )
                      : Container()),
    );
  }
}
