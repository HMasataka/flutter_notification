import 'dart:io';
import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';

// アプリ停止中に通知が来た場合の処理
// トップレベル関数で定義する必要がある
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // FirebaseNotificationListenerの状態に依存出来ないためここで初期化
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

  // 必要なフィールドの初期化
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
    // アプリ起動中の通知監視
    FirebaseMessaging.onMessage.listen(_handleOnMessageNotification);
    // アプリが裏画面で起動している状態の通知監視 裏画面からの復帰時に処理される
    FirebaseMessaging.onMessageOpenedApp.listen(_handleOnMessageOpenedNotification);
    // アプリ停止中の通知監視
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // androidのローカル通知に利用するチャンネルの初期化
  _initializeNotificationChannel() async {
    channel = const AndroidNotificationChannel(
      'default_notification_channel',
      channalName,
      importance: Importance.max, // 優先度を最大に設定
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    var initializationSettingsAndroid = const AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // androidのローカル通知送信
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

  _handleOnMessageNotification(RemoteMessage message) {
    // フォアグラウンド起動中に通知が来た場合、Androidは通知が表示されないため、ローカル通知として表示する
    if (Platform.isAndroid) {
      final notification = message.notification;
      final android = message.notification?.android;
      if (notification != null && android != null) {
        _showLocalNotification(notification, android);
      }
    }
  }

  _handleOnMessageOpenedNotification(RemoteMessage message) {
    debugPrint('Got a message whilst in the foreground!');
    debugPrint('Message data: ${message.data}');

    if (message.notification != null) {
      debugPrint('${message.notification?.title}');
      debugPrint('${message.notification?.body}');
    }
  }
}
