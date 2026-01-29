import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';
import '../domain/app_notification.dart';
import 'notification_repository.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background message
  print("Handling a background message: ${message.messageId}");
}

class RealTimeNotificationService {
  final Ref _ref;
  io.Socket? _socket;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  RealTimeNotificationService(this._ref);

  Future<void> init() async {
    // 1. Initialize Firebase Messaging
    try {
       NotificationSettings settings = await _fcm.requestPermission(
         alert: true,
         badge: true,
         sound: true,
       );

       if (settings.authorizationStatus == AuthorizationStatus.authorized) {
         print('User granted permission');
       }

       // Handle background messages
       FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

       // Handle foreground messages
       FirebaseMessaging.onMessage.listen((RemoteMessage message) {
         print('Got a message whilst in the foreground!');
         if (message.notification != null) {
           _showLocalNotificationFromFCM(message);
         }
         _ref.invalidate(unreadNotificationCountProvider);
         _ref.invalidate(notificationsListProvider);
       });

       // Register token
       await _registerFcmToken();
    } catch (e) {
      print('Firebase Messaging Init Error: $e');
    }

    // 2. Initialize Local Notifications
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          // Handle navigation if needed
          print('Notification payload: ${response.payload}');
        }
      },
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'tryd_notifications',
      'Tryd Notifications',
      description: 'Notifications for Tryd app activities and challenges',
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 3. Connect to Socket for legacy/instant in-app updates
    await connectSocket();
  }

  Future<void> _registerFcmToken() async {
    String? token = await _fcm.getToken();
    if (token != null) {
      print('FCM Token: $token');
      try {
        final dio = _ref.read(apiClientProvider);
        await dio.post(ApiConstants.pushTokens, data: {
          'token': token,
          'platform': defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
          'deviceInfo': {'model': 'Mobile Device'} // Simplified
        });
      } catch (e) {
        print('Error registering push token: $e');
      }
    }
  }

  Future<void> connectSocket() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) return;

    final socketUrl = ApiConstants.baseUrl.replaceAll('/api', '');

    _socket = io.io(socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'auth': {'token': token}
    });

    _socket!.connect();

    _socket!.on('notification', (data) {
      _handleSocketNotification(data);
    });
  }

  void _handleSocketNotification(dynamic data) {
    final notification = AppNotification.fromJson(data);
    _showLocalNotification(notification);
    _ref.invalidate(unreadNotificationCountProvider);
    _ref.invalidate(notificationsListProvider);
  }

  void _showLocalNotificationFromFCM(RemoteMessage message) {
    if (message.notification == null) return;
    
    _localNotifications.show(
      message.hashCode,
      message.notification!.title,
      message.notification!.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'tryd_notifications',
          'Tryd Notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }

  Future<void> _showLocalNotification(AppNotification notification) async {
    await _localNotifications.show(
      notification.id.hashCode,
      notification.title,
      notification.message,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'tryd_notifications',
          'Tryd Notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      payload: notification.id,
    );
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }
}

final realTimeNotificationServiceProvider = Provider<RealTimeNotificationService>((ref) {
  return RealTimeNotificationService(ref);
});
