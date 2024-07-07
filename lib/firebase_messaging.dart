import 'dart:io';
import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  debugPrint("Handling a background message: ${message.messageId}");
}

class FirebaseNotificationListener {
  static const channalName = "firebase_notification_channel";

  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  late AndroidNotificationChannel channel;

  FirebaseNotificationListener();

  init() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    final messaging = FirebaseMessaging.instance;
    messaging.requestPermission();

    await _initializeNotificationChannel();
  }

  listen() {
    FirebaseMessaging.onMessage.listen(_listenOnMessageNotification);
    FirebaseMessaging.onMessageOpenedApp.listen(_listenNotification);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  _initializeNotificationChannel() async {
    channel = const AndroidNotificationChannel(
      'default_notification_channel',
      channalName,
      importance: Importance.max,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    var initializationSettingsAndroid = const AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  _showLocalNotification(RemoteNotification notification, AndroidNotification android) {
    flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
        ),
      ),
    );
  }

  _listenOnMessageNotification(RemoteMessage message) {
    // フォアグラウンド起動中に通知が来た場合、
    // Androidは通知が表示されないため、ローカル通知として表示する
    if (Platform.isAndroid) {
      final notification = message.notification;
      final android = message.notification?.android;
      if (notification != null && android != null) {
        _showLocalNotification(notification, android);
      }
    }
  }

  _listenNotification(RemoteMessage message) {
    debugPrint('Got a message whilst in the foreground!');
    debugPrint('Message data: ${message.data}');

    if (message.notification != null) {
      debugPrint('${message.notification?.title}');
      debugPrint('${message.notification?.body}');
    }
  }
}
