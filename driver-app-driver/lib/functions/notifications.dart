// import 'package:awesome_notifications/awesome_notifications.dart';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'functions.dart';

// create an instance
FirebaseMessaging messaging = FirebaseMessaging.instance;
FlutterLocalNotificationsPlugin fltNotification =
    FlutterLocalNotificationsPlugin();
FlutterLocalNotificationsPlugin rideNotification =
    FlutterLocalNotificationsPlugin();
bool isGeneral = false;
String latestNotification = '';
int id = 0;

void notificationTapBackground(NotificationResponse notificationResponse) {
  isGeneral = true;
  valueNotifierHome.incrementNotifier();
}

var androidDetails = const AndroidNotificationDetails(
  '54321',
  'normal_notification',
  enableVibration: true,
  enableLights: true,
  importance: Importance.high,
  playSound: true,
  priority: Priority.high,
  visibility: NotificationVisibility.private,
);

const iosDetails = DarwinNotificationDetails(
    presentAlert: true, presentBadge: true, presentSound: true);

var generalNotificationDetails =
    NotificationDetails(android: androidDetails, iOS: iosDetails);

var androiInit =
    const AndroidInitializationSettings('@mipmap/ic_launcher'); //for logo
var iosInit = const DarwinInitializationSettings(
  defaultPresentAlert: true,
  defaultPresentBadge: true,
  defaultPresentSound: true,
);
var initSetting = InitializationSettings(android: androiInit, iOS: iosInit);

Future<void> initMessaging() async {
  await fltNotification.initialize(initSetting);

  await FirebaseMessaging.instance.requestPermission();

  FirebaseMessaging.instance.getInitialMessage().then((message) async {
    if (message?.data != null) {
      final pushType = message!.data['push_type']?.toString() ?? '';
      if (pushType == 'general') {
        latestNotification = message.data['message'] ?? '';
        isGeneral = true;
        valueNotifierHome.incrementNotifier();
      } else {
        // App aberto por notificação de corrida: atualizar para mostrar popup aceitar
        await getUserDetails();
        valueNotifierHome.incrementNotifier();
      }
    }
  });

  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    final data = message.data;
    final pushType = data['push_type']?.toString() ?? '';

    // Mensagem geral (com ou sem notification payload)
    if (pushType == 'general') {
      if (notification != null) {
        latestNotification = data['message'] ?? '';
        if ((data['image'] ?? '').toString().isNotEmpty) {
          _showBigPictureNotificationURLGeneral(data);
        } else {
          _showGeneralNotification(data);
        }
      }
      return;
    }

    // Pedido/corrida (qualquer outro push_type ou mensagem só com data)
    if (kDebugMode) {
      debugPrint('🔔 [FCM] Pedido de corrida recebido – push_type=$pushType, data-only=${notification == null}');
    }
    await getUserDetails();
    valueNotifierHome.incrementNotifier();
    if (notification != null) {
      _showRideNotification(notification);
    } else {
      final title = data['title']?.toString() ?? data['message']?.toString() ?? 'Novo pedido';
      final body = data['body']?.toString() ?? data['message']?.toString() ?? 'Toque para aceitar a corrida';
      _showRideNotificationText(title, body);
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
    final pushType = message.data['push_type']?.toString() ?? '';
    if (pushType == 'general') {
      latestNotification = message.data['message'] ?? '';
      isGeneral = true;
      valueNotifierHome.incrementNotifier();
    } else {
      // Usuário tocou na notificação de corrida: atualizar para mostrar aceitar/rejeitar
      await getUserDetails();
      valueNotifierHome.incrementNotifier();
    }
  });
}

Future<String> _downloadAndSaveFile(String url, String fileName) async {
  final Directory directory = await getApplicationDocumentsDirectory();
  final String filePath = '${directory.path}/$fileName';
  final http.Response response = await http.get(Uri.parse(url));
  final File file = File(filePath);
  await file.writeAsBytes(response.bodyBytes);
  return filePath;
}

Future<Uint8List> _getByteArrayFromUrl(String url) async {
  final http.Response response = await http.get(Uri.parse(url));
  return response.bodyBytes;
}

Future<void> _showBigPictureNotificationURLGeneral(message) async {
  latestNotification = message['message'];
  if (platform == TargetPlatform.android) {
    final ByteArrayAndroidBitmap bigPicture =
        ByteArrayAndroidBitmap(await _getByteArrayFromUrl(message['image']));
    final BigPictureStyleInformation bigPictureStyleInformation =
        BigPictureStyleInformation(bigPicture);
    final AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'notification_1',
      'general image notification',
      channelDescription: 'general notification with image',
      styleInformation: bigPictureStyleInformation,
      enableVibration: true,
      enableLights: true,
      importance: Importance.high,
      playSound: true,
      priority: Priority.high,
      visibility: NotificationVisibility.public,
    );
    final NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);
    fltNotification.initialize(initSetting,
        onDidReceiveNotificationResponse: notificationTapBackground,
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground);
    await fltNotification.show(
        id++, message['title'], message['message'], notificationDetails);
  } else {
    final String bigPicturePath = await _downloadAndSaveFile(
        Uri.parse(message['image']).toString(), 'bigPicture.jpg');
    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        attachments: <DarwinNotificationAttachment>[
          DarwinNotificationAttachment(
            bigPicturePath,
          )
        ]);

    final NotificationDetails notificationDetails =
        NotificationDetails(iOS: iosDetails);
    fltNotification.initialize(initSetting,
        onDidReceiveNotificationResponse: notificationTapBackground,
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground);
    await fltNotification.show(
        id++, message['title'], message['message'], notificationDetails);
  }
  id = id++;
}

Future<void> _showGeneralNotification(message) async {
  latestNotification = message['message'];
  const AndroidNotificationDetails androidNotificationDetails =
      AndroidNotificationDetails(
    'notification_1',
    'general notification',
    channelDescription: 'general notification',
    enableVibration: true,
    enableLights: true,
    importance: Importance.high,
    playSound: true,
    priority: Priority.high,
    visibility: NotificationVisibility.public,
  );
  const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true, presentBadge: true, presentSound: true);
  const NotificationDetails notificationDetails =
      NotificationDetails(android: androidNotificationDetails, iOS: iosDetails);
  fltNotification.initialize(initSetting,
      onDidReceiveNotificationResponse: notificationTapBackground,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground);
  await fltNotification.show(
      id++, message['title'], message['message'], notificationDetails);
  id = id++;
}

Future<void> _showRideNotification(RemoteNotification message) async {
  await _showRideNotificationText(
    message.title ?? 'Novo pedido',
    message.body ?? 'Toque para aceitar a corrida',
  );
}

Future<void> _showRideNotificationText(String title, String body) async {
  const AndroidNotificationDetails androidNotificationDetails =
      AndroidNotificationDetails(
    'ride_requests',
    'Pedidos de corrida',
    channelDescription: 'Notificação de novo pedido para aceitar ou rejeitar',
    enableVibration: true,
    enableLights: true,
    importance: Importance.max,
    playSound: true,
    priority: Priority.max,
    visibility: NotificationVisibility.public,
    fullScreenIntent: true,
  );
  const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
    interruptionLevel: InterruptionLevel.timeSensitive,
  );
  const NotificationDetails notificationDetails =
      NotificationDetails(android: androidNotificationDetails, iOS: iosDetails);
  rideNotification.initialize(initSetting);
  await rideNotification.show(id++, title, body, notificationDetails);
  id = id++;
}
