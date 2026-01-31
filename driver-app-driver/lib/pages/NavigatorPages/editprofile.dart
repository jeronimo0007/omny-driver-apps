import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_driver/pages/login/landingpage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import '../../functions/functions.dart';
import '../../styles/styles.dart';
import '../../translation/translation.dart';
import '../../widgets/widgets.dart';
import '../loadingPage/loading.dart';
import '../login/carinformation.dart';
import '../login/profileinformation.dart';
import '../login/uploaddocument.dart';
import '../noInternet/nointernet.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({Key? key}) : super(key: key);

  @override
  State<EditProfile> createState() => _EditProfileState();
}

dynamic proImageFile;

class _EditProfileState extends State<EditProfile> {
  ImagePicker picker = ImagePicker();
  bool _isLoading = false;
  String _error = '';
  bool _pickImage = false;
  String _permission = '';
  TextEditingController name = TextEditingController();
  TextEditingController email = TextEditingController();

//get gallery permission
  getGalleryPermission() async {
    dynamic status;
    if (platform == TargetPlatform.android) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt <= 32) {
        status = await Permission.storage.status;
        if (status != PermissionStatus.granted) {
          status = await Permission.storage.request();
        }

        /// use [Permissions.storage.status]
      } else {
        status = await Permission.photos.status;
        if (status != PermissionStatus.granted) {
          status = await Permission.photos.request();
        }
      }
    } else {
      status = await Permission.photos.status;
      if (status != PermissionStatus.granted) {
        status = await Permission.photos.request();
      }
    }
    return status;
  }

  navigateLogout() {
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => const LandingPage()));
  }

  String _genderLabel(String value) {
    if (value.isEmpty) return '';
    for (var e in genderOptions) {
      if (e['value'] == value) return e['label_pt'] ?? value;
    }
    return value;
  }

  String _passengerPreferenceLabel(String value) {
    if (value.isEmpty) return '';
    for (var e in passengerPreferenceOptions) {
      if (e['value'] == value) return e['label_pt'] ?? value;
    }
    return value;
  }

  /// Formata data da API (yyyy-MM-dd) para exibição (dd/mm/yyyy).
  String _formatBirthDateForDisplay(dynamic value) {
    if (value == null || value.toString().isEmpty) return '';
    final s = value.toString();
    if (s.length >= 10 && s.contains('-')) {
      final parts = s.split('-');
      if (parts.length == 3) return '${parts[2]}/${parts[1]}/${parts[0]}';
    }
    return s;
  }

  /// Formata CPF (11 dígitos ou já formatado) para exibição.
  String _formatCpfForDisplay(dynamic value) {
    if (value == null || value.toString().isEmpty) return '';
    final digits = value.toString().replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length == 11) {
      return '${digits.substring(0, 3)}.${digits.substring(3, 6)}.${digits.substring(6, 9)}-${digits.substring(9)}';
    }
    return value.toString();
  }

//get camera permission
  getCameraPermission() async {
    var status = await Permission.camera.status;
    if (status != PermissionStatus.granted) {
      status = await Permission.camera.request();
    }
    return status;
  }

//pick image from gallery
  // Usa Photo Picker do Android (não requer permissões READ_MEDIA_IMAGES)
  pickImageFromGallery() async {
    try {
      final pickedFile =
          await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
      if (pickedFile != null) {
        setState(() {
          proImageFile = pickedFile.path;
          _pickImage = false;
        });
      }
    } catch (e) {
      setState(() {
        _permission = 'noPhotos';
      });
    }
  }

//pick image from camera
  pickImageFromCamera() async {
    var permission = await getCameraPermission();
    if (permission == PermissionStatus.granted) {
      final pickedFile =
          await picker.pickImage(source: ImageSource.camera, imageQuality: 50);
      setState(() {
        proImageFile = pickedFile?.path;
        _pickImage = false;
      });
    } else {
      setState(() {
        _permission = 'noCamera';
      });
    }
  }

  @override
  void initState() {
    _error = '';
    proImageFile = null;
    name.text = userDetails['name'];
    email.text = userDetails['email'];
    userGender = userDetails['gender']?.toString() ?? '';
    userPassengerPreference = userDetails['passenger_preference']?.toString() ?? 'both';
    userCpf = userDetails['document']?.toString() ?? userCpf;
    userBirthDate = userDetails['birth_date']?.toString() ?? userBirthDate;
    userCep = userDetails['postal_code']?.toString() ?? userDetails['zipcode']?.toString() ?? '';
    userAddress = userDetails['address']?.toString() ?? '';
    userNumber = userDetails['address_number']?.toString() ?? '';
    userComplement = userDetails['complement']?.toString() ?? '';
    userNeighborhood = userDetails['neighborhood']?.toString() ?? '';
    userCity = userDetails['city']?.toString() ?? '';
    userState = userDetails['state']?.toString() ?? '';
    super.initState();
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
        child: Stack(
          children: [
            Container(
              padding: EdgeInsets.all(media.width * 0.05),
              height: media.height * 1,
              width: media.width * 1,
              color: page,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          SizedBox(height: MediaQuery.of(context).padding.top),
                          Stack(
                            children: [
                              Container(
                                padding:
                                    EdgeInsets.only(bottom: media.width * 0.05),
                                width: media.width * 1,
                                alignment: Alignment.center,
                                child: MyText(
                                  text: languages[choosenLanguage]
                                      ['text_editprofile'],
                                  size: media.width * twenty,
                                  fontweight: FontWeight.w600,
                                ),
                              ),
                              Positioned(
                                  child: InkWell(
                                      onTap: () {
                                        Navigator.pop(context, true);
                                      },
                                      child: Icon(Icons.arrow_back_ios,
                                          color: textColor)))
                            ],
                          ),
                          SizedBox(height: media.width * 0.05),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _pickImage = true;
                              });
                            },
                            child: Stack(
                              children: [
                                Container(
                                  height: media.width * 0.3,
                                  width: media.width * 0.3,
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: page,
                                      image: (proImageFile == null)
                                          ? DecorationImage(
                                              image: NetworkImage(
                                                userDetails['profile_picture'],
                                              ),
                                              fit: BoxFit.cover)
                                          : DecorationImage(
                                              image:
                                                  FileImage(File(proImageFile)),
                                              fit: BoxFit.cover)),
                                ),
                                Positioned(
                                    right: media.width * 0.04,
                                    bottom: media.width * 0.02,
                                    child: Container(
                                      height: media.width * 0.05,
                                      width: media.width * 0.05,
                                      decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(0xff898989)),
                                      child: Icon(
                                        Icons.edit,
                                        color: topBar,
                                        size: media.width * 0.04,
                                      ),
                                    ))
                              ],
                            ),
                          ),
                          SizedBox(
                            height: media.width * 0.04,
                          ),
                          Container(
                            padding: EdgeInsets.all(media.width * 0.02),
                            decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.1)),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.person_pin_outlined,
                                            color: textColor),
                                        MyText(
                                          text: languages[choosenLanguage]
                                              ['text_profile'],
                                          size: media.width * fourteen,
                                          fontweight: FontWeight.w700,
                                        )
                                      ],
                                    ),
                                    InkWell(
                                      onTap: () async {
                                        var nav = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    ProfileInformation(
                                                        from: 'edit')));
                                        if (nav != null) {
                                          if (nav) {
                                            setState(() {});
                                          }
                                        }
                                      },
                                      child: Container(
                                        decoration:
                                            BoxDecoration(color: topBar),
                                        padding:
                                            EdgeInsets.all(media.width * 0.01),
                                        child: Icon(
                                          Icons.edit,
                                          // color: const Color(0XFFFF0000),
                                          size: media.width * 0.04,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: media.width * 0.02,
                                ),
                                ProfileDetails(
                                    heading: languages[choosenLanguage]
                                        ['text_name'],
                                    value: userDetails['name']),
                                ProfileDetails(
                                    heading: languages[choosenLanguage]
                                        ['text_mobile'],
                                    value: userDetails['mobile']),
                                ProfileDetails(
                                    heading: languages[choosenLanguage]
                                        ['text_email'],
                                    value: userDetails['email']),
                                ProfileDetails(
                                    heading: languages[choosenLanguage]
                                        ['text_wok_area'],
                                    value:
                                        userDetails['service_location_name']),
                                if ((userDetails['document'] ?? userCpf).toString().isNotEmpty)
                                  ProfileDetails(
                                    heading: languages[choosenLanguage]['text_cpf'] ?? 'CPF',
                                    value: _formatCpfForDisplay(userDetails['document'] ?? userCpf)),
                                if ((userDetails['birth_date'] ?? userBirthDate).toString().isNotEmpty)
                                  ProfileDetails(
                                    heading: languages[choosenLanguage]['text_birth_date'] ?? 'Data de nascimento',
                                    value: _formatBirthDateForDisplay(userDetails['birth_date'] ?? userBirthDate)),
                                if ((userDetails['gender'] ?? userGender).toString().isNotEmpty)
                                  ProfileDetails(
                                    heading: languages[choosenLanguage]['text_gender'] ?? 'Gênero',
                                    value: _genderLabel(userDetails['gender'] ?? userGender)),
                                if ((userDetails['passenger_preference'] ?? userPassengerPreference).toString().isNotEmpty)
                                  ProfileDetails(
                                    heading: languages[choosenLanguage]['text_passenger_preference'] ?? 'Preferência de passageiro',
                                    value: _passengerPreferenceLabel(userDetails['passenger_preference'] ?? userPassengerPreference)),
                                if ((userDetails['postal_code'] ?? userDetails['zipcode'] ?? userCep).toString().isNotEmpty)
                                  ProfileDetails(
                                    heading: languages[choosenLanguage]['text_cep'] ?? 'CEP',
                                    value: userDetails['postal_code'] ?? userDetails['zipcode'] ?? userCep),
                                if ((userDetails['address'] ?? userAddress).toString().isNotEmpty)
                                  ProfileDetails(
                                    heading: languages[choosenLanguage]['text_address'] ?? 'Endereço',
                                    value: '${userDetails['address'] ?? userAddress}${(userDetails['address_number'] ?? userNumber).toString().isNotEmpty ? ", ${userDetails['address_number'] ?? userNumber}" : ""}${(userDetails['complement'] ?? userComplement).toString().isNotEmpty ? " - ${userDetails['complement'] ?? userComplement}" : ""}${(userDetails['neighborhood'] ?? userNeighborhood).toString().isNotEmpty ? " - ${userDetails['neighborhood'] ?? userNeighborhood}" : ""}'),
                                if ((userDetails['city'] ?? userCity).toString().isNotEmpty)
                                  ProfileDetails(
                                    heading: languages[choosenLanguage]['text_city'] ?? 'Cidade',
                                    value: userDetails['city'] ?? userCity),
                                if ((userDetails['state'] ?? userState).toString().isNotEmpty)
                                  ProfileDetails(
                                    heading: languages[choosenLanguage]['text_state'] ?? 'Estado',
                                    value: userDetails['state'] ?? userState),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: media.width * 0.05,
                          ),
                          (userDetails['role'] != 'owner')
                              ? Container(
                                  padding: EdgeInsets.all(media.width * 0.02),
                                  decoration: BoxDecoration(
                                      color: Colors.grey.withOpacity(0.1)),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.local_taxi,
                                                  color: textColor),
                                              MyText(
                                                text: languages[choosenLanguage]
                                                    ['text_car_info'],
                                                size: media.width * fourteen,
                                                fontweight: FontWeight.w700,
                                              )
                                            ],
                                          ),
                                          (userDetails['owner_id'] == null)
                                              ? InkWell(
                                                  onTap: () async {
                                                    myServiceId = userDetails[
                                                        'service_location_id'];

                                                    var nav =
                                                        await Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                                builder:
                                                                    (context) =>
                                                                        CarInformation(
                                                                          frompage:
                                                                              2,
                                                                        )));
                                                    if (nav != null) {
                                                      if (nav) {
                                                        setState(() {});
                                                      }
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                        color: topBar),
                                                    padding: EdgeInsets.all(
                                                        media.width * 0.01),
                                                    child: Icon(
                                                      Icons.edit,
                                                      // color: const Color(0XFFFF0000),
                                                      size: media.width * 0.04,
                                                    ),
                                                  ),
                                                )
                                              : Container(),
                                        ],
                                      ),
                                      SizedBox(
                                        height: media.width * 0.02,
                                      ),
                                      (userDetails['owner_id'] != null &&
                                              userDetails[
                                                      'vehicle_type_name'] ==
                                                  null)
                                          ? Row(
                                              children: [
                                                MyText(
                                                  text: languages[
                                                          choosenLanguage][
                                                      'text_no_fleet_assigned'],
                                                  size: media.width * eighteen,
                                                  fontweight: FontWeight.bold,
                                                ),
                                              ],
                                            )
                                          : Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      flex: 60,
                                                      child: MyText(
                                                          text: languages[
                                                                  choosenLanguage]
                                                              ['text_type'],
                                                          size: media.width *
                                                              fourteen),
                                                    ),
                                                    SizedBox(
                                                      height:
                                                          media.width * 0.02,
                                                    ),
                                                    Expanded(
                                                      flex: 40,
                                                      child: Wrap(
                                                        children: [
                                                          if (userDetails[
                                                                  'owner_id'] ==
                                                              null)
                                                            for (int i = 0;
                                                                i <=
                                                                    userDetails['driverVehicleType']['data']
                                                                            .length -
                                                                        1;
                                                                i++)
                                                              MyText(
                                                                text:
                                                                    '${userDetails['driverVehicleType']['data'][i]['vehicletype_name']},',
                                                                size: media
                                                                        .width *
                                                                    fourteen,
                                                                color: textColor
                                                                    .withOpacity(
                                                                        0.4),
                                                              ),
                                                          if (userDetails[
                                                                  'owner_id'] !=
                                                              null)
                                                            MyText(
                                                              text: userDetails[
                                                                  'vehicle_type_name'],
                                                              size:
                                                                  media.width *
                                                                      sixteen,
                                                              color: textColor
                                                                  .withOpacity(
                                                                      0.4),
                                                              fontweight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(
                                                  height: media.width * 0.02,
                                                ),
                                                ProfileDetails(
                                                    heading: languages[
                                                            choosenLanguage]
                                                        ['text_make_name'],
                                                    value: userDetails[
                                                        'car_make_name']),
                                                ProfileDetails(
                                                    heading: languages[
                                                            choosenLanguage]
                                                        ['text_model_name'],
                                                    value: userDetails[
                                                        'car_model_name']),
                                                ProfileDetails(
                                                    heading: languages[
                                                            choosenLanguage]
                                                        ['text_license'],
                                                    value: userDetails[
                                                        'car_number']),
                                                ProfileDetails(
                                                    heading: languages[
                                                            choosenLanguage]
                                                        ['text_color'],
                                                    value: userDetails[
                                                        'car_color']),
                                              ],
                                            )
                                    ],
                                  ),
                                )
                              : Container(),
                          SizedBox(
                            height: media.width * 0.05,
                          ),
                          Container(
                            padding: EdgeInsets.all(media.width * 0.02),
                            decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.1)),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.text_snippet,
                                            color: textColor),
                                        MyText(
                                          text: languages[choosenLanguage]
                                              ['text_docs'],
                                          size: media.width * fourteen,
                                          fontweight: FontWeight.w700,
                                        )
                                      ],
                                    ),
                                    InkWell(
                                      onTap: () async {
                                        var nav = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    UploadDocument()));
                                        if (nav != null) {
                                          if (nav) {
                                            setState(() {});
                                          }
                                        }
                                      },
                                      child: Container(
                                        decoration:
                                            BoxDecoration(color: topBar),
                                        padding:
                                            EdgeInsets.all(media.width * 0.01),
                                        child: Icon(
                                          Icons.edit,
                                          // color: const Color(0XFFFF0000),
                                          size: media.width * 0.04,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  if (_error != '')
                    Container(
                      padding: EdgeInsets.only(top: media.width * 0.02),
                      child: MyText(
                        text: _error,
                        size: media.width * twelve,
                        color: Colors.red,
                      ),
                    ),
                  if (proImageFile != null)
                    Container(
                        padding: EdgeInsets.only(top: media.width * 0.02),
                        width: media.width * 0.8,
                        child: Button(
                            onTap: () async {
                              setState(() {
                                _isLoading = true;
                              });
                              dynamic val;

                              val = await updateProfile(
                                userDetails['name'],
                                userDetails['email'],
                                // userDetails['mobile']
                              );

                              if (val == 'success') {
                                proImageFile = null;
                              } else {
                                setState(() {
                                  _error = val.toString();
                                });
                              }
                              setState(() {
                                _isLoading = false;
                              });
                            },
                            text: languages[choosenLanguage]['text_confirm']))
                ],
              ),
            ),

            //pick image popup
            (_pickImage == true)
                ? Positioned(
                    bottom: 0,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _pickImage = false;
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
                              padding: EdgeInsets.all(media.width * 0.05),
                              width: media.width * 1,
                              decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(25),
                                      topRight: Radius.circular(25)),
                                  border: Border.all(
                                    color: borderLines,
                                    width: 1.2,
                                  ),
                                  color: page),
                              child: Column(
                                children: [
                                  Container(
                                    height: media.width * 0.02,
                                    width: media.width * 0.15,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(
                                          media.width * 0.01),
                                      color: Colors.grey,
                                    ),
                                  ),
                                  SizedBox(
                                    height: media.width * 0.05,
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Column(
                                        children: [
                                          InkWell(
                                            onTap: () {
                                              pickImageFromCamera();
                                            },
                                            child: Container(
                                                height: media.width * 0.171,
                                                width: media.width * 0.171,
                                                decoration: BoxDecoration(
                                                    border: Border.all(
                                                        color: borderLines,
                                                        width: 1.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12)),
                                                child: Icon(
                                                  Icons.camera_alt_outlined,
                                                  size: media.width * 0.064,
                                                  color: textColor,
                                                )),
                                          ),
                                          SizedBox(
                                            height: media.width * 0.02,
                                          ),
                                          MyText(
                                            text: languages[choosenLanguage]
                                                ['text_camera'],
                                            size: media.width * ten,
                                            color: textColor.withOpacity(0.4),
                                          )
                                        ],
                                      ),
                                      Column(
                                        children: [
                                          InkWell(
                                            onTap: () {
                                              pickImageFromGallery();
                                            },
                                            child: Container(
                                                height: media.width * 0.171,
                                                width: media.width * 0.171,
                                                decoration: BoxDecoration(
                                                    border: Border.all(
                                                        color: borderLines,
                                                        width: 1.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12)),
                                                child: Icon(
                                                  Icons.image_outlined,
                                                  size: media.width * 0.064,
                                                  color: textColor,
                                                )),
                                          ),
                                          SizedBox(
                                            height: media.width * 0.02,
                                          ),
                                          MyText(
                                            text: languages[choosenLanguage]
                                                ['text_gallery'],
                                            size: media.width * ten,
                                            color: textColor.withOpacity(0.4),
                                          )
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ))
                : Container(),

            //permission denied popup
            (_permission != '')
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
                                    _permission = '';
                                    _pickImage = false;
                                  });
                                },
                                child: Container(
                                  height: media.width * 0.1,
                                  width: media.width * 0.1,
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle, color: page),
                                  child: Icon(Icons.cancel_outlined,
                                      color: textColor),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: media.width * 0.05,
                        ),
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
                                    color: Colors.black.withOpacity(0.2))
                              ]),
                          child: Column(
                            children: [
                              SizedBox(
                                  width: media.width * 0.8,
                                  child: MyText(
                                    text: (_permission == 'noPhotos')
                                        ? languages[choosenLanguage]
                                            ['text_open_photos_setting']
                                        : languages[choosenLanguage]
                                            ['text_open_camera_setting'],
                                    size: media.width * sixteen,
                                    fontweight: FontWeight.w600,
                                  )),
                              SizedBox(height: media.width * 0.05),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  InkWell(
                                      onTap: () async {
                                        await openAppSettings();
                                      },
                                      child: MyText(
                                        text: languages[choosenLanguage]
                                            ['text_open_settings'],
                                        size: media.width * sixteen,
                                        fontweight: FontWeight.w600,
                                        color: buttonColor,
                                      )),
                                  InkWell(
                                      onTap: () async {
                                        (_permission == 'noCamera')
                                            ? pickImageFromCamera()
                                            : pickImageFromGallery();
                                        setState(() {
                                          _permission = '';
                                        });
                                      },
                                      child: MyText(
                                        text: languages[choosenLanguage]
                                            ['text_done'],
                                        size: media.width * sixteen,
                                        fontweight: FontWeight.w600,
                                        color: buttonColor,
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
            (_isLoading == true)
                ? const Positioned(top: 0, child: Loading())
                : Container(),

            //error
            (_error != '')
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
                              color: page),
                          child: Column(
                            children: [
                              SizedBox(
                                width: media.width * 0.8,
                                child: MyText(
                                  text: _error.toString(),
                                  textAlign: TextAlign.center,
                                  size: media.width * sixteen,
                                  fontweight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(
                                height: media.width * 0.05,
                              ),
                              Button(
                                  onTap: () async {
                                    setState(() {
                                      _error = '';
                                    });
                                  },
                                  text: languages[choosenLanguage]['text_ok'])
                            ],
                          ),
                        )
                      ],
                    ),
                  ))
                : Container(),

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
          ],
        ),
      ),
    );
  }
}

class ProfileDetails extends StatelessWidget {
  final String heading;
  final String value;
  const ProfileDetails({super.key, required this.heading, required this.value});

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 60,
              child: MyText(text: heading, size: media.width * fourteen),
            ),
            Expanded(
              flex: 40,
              child: MyText(
                text: value,
                size: media.width * fourteen,
                color: textColor.withOpacity(0.4),
              ),
            )
          ],
        ),
        SizedBox(
          height: media.width * 0.02,
        ),
      ],
    );
  }
}
