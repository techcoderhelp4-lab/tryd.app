import 'dart:async';
import 'dart:ui';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../main.dart';
import '../domain/app_notification.dart';
import 'notification_repository.dart';
import '../../challenges/data/challenge_repository.dart';
import '../../activity/data/activity_repository.dart';
import '../../rewards/data/reward_repository.dart';
import '../../profile/data/user_repository.dart';
import 'package:permission_handler/permission_handler.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background message
  print("Handling a background message: ${message.messageId}");
}

class RealTimeNotificationService {
  final Ref _ref;
  io.Socket? _socket;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  FirebaseMessaging get _fcm => FirebaseMessaging.instance;
  bool _isMuted = false;

  void setMuted(bool muted) {
    _isMuted = muted;
    debugPrint('NotificationService: UI Muted set to $muted');
  }

  RealTimeNotificationService(this._ref);

  Future<void> init() async {
    print('NotificationService: Initializing...');
    
    // 1. Initialize Firebase Messaging
    try {
       // Set foreground presentation options (Mandatory for popups in foreground)
       await _fcm.setForegroundNotificationPresentationOptions(
         alert: true,
         badge: true,
         sound: true,
       );

       NotificationSettings settings = await _fcm.requestPermission(
         alert: true,
         badge: true,
         sound: true,
         provisional: false,
       );

       print('NotificationService: FCM Authorisation Status: ${settings.authorizationStatus}');

       // Handle background messages
       FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

       // Handle foreground messages
       FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
         print('NotificationService: Received FCM message: ${message.messageId}');
         if (message.notification != null) {
           showInAppBanner(
             message.notification!.title ?? 'New Notification',
             message.notification!.body ?? '',
             showAlert: true,
           );
         }
         
         await Future.delayed(const Duration(milliseconds: 1500));
         _ref.invalidate(unreadNotificationCountProvider);
         _ref.invalidate(notificationsListProvider);

         final type = message.data['type'];
         if (type == 'redemption_approved' || type == 'redemption_rejected') {
           _ref.invalidate(myRedemptionsProvider);
           _ref.invalidate(rewardsListProvider);
           _ref.invalidate(userProfileProvider);
         }
       });

       await _registerFcmToken();
    } catch (e) {
      print('NotificationService: Firebase Messaging Error: $e');
    }

    // 2. Initialize Local Notifications
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      // iOS requires explicit permission flags here — without them, local
      // notifications fired from the app silently fail (no banner, no sound).
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );
      
      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          print('NotificationService: Local notification tapped: ${response.payload}');
        },
      );

      if (Platform.isAndroid) {
        final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          // Priority Alerts Channel (High importance for popups)
          const AndroidNotificationChannel channel = AndroidNotificationChannel(
            'tryd_priority_alert_v2', // Incrementing to force recreation with MAX settings
            'Tryd Alerts',
            description: 'Critical updates and activity alerts',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            showBadge: true,
          );

          await androidPlugin.createNotificationChannel(channel);
          
          await Permission.notification.request();
        }
      }
      print('NotificationService: Local notifications initialized');
    } catch (e) {
      print('NotificationService: Local Init Error: $e');
    }

    // 3. Connect to Socket
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

    if (token == null) {
      debugPrint('Socket: No auth token found — skipping connection');
      return;
    }

    const socketUrl = ApiConstants.socketUrl;
    debugPrint('Socket: Connecting to $socketUrl');

    _socket = io.io(socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'secure': false,
      'reconnection': true,
      'reconnectionAttempts': 10,
      'reconnectionDelay': 1000,
      'reconnectionDelayMax': 5000,
      'timeout': 10000,
      'auth': {'token': token}
    });

    _socket!.on('connect', (_) => debugPrint('Socket: ✅ Connected (id: ${_socket?.id})'));
    _socket!.on('disconnect', (reason) => debugPrint('Socket: ❌ Disconnected — $reason'));
    _socket!.on('connect_error', (err) => debugPrint('Socket: ⚠️ Connection error — $err'));
    _socket!.on('error', (err) => debugPrint('Socket: ❌ General error — $err'));

    _socket!.connect();

    _socket!.on('notification', (data) async {
      debugPrint('Socket: Notification received');
      _handleSocketNotification(data);
    });

    _socket!.on('challenge_created', (data) {
      print('Real-time: New challenge created');
      _ref.invalidate(challengesListProvider);
    });

    _socket!.on('challenge_updated', (data) {
      print('Real-time: Challenge updated');
      _ref.invalidate(challengesListProvider);
      _ref.invalidate(activityStatsProvider('month')); // To update progress banners if any
    });

    _socket!.on('leaderboard_updated', (data) {
      final String? challengeId = data['challengeId'];
      print('Real-time: Leaderboard updated for challenge $challengeId');
      if (challengeId != null) {
        _ref.invalidate(challengeLeaderboardProvider(challengeId));
      }
    });
  }

  void _handleSocketNotification(dynamic data) {
    final notification = AppNotification.fromJson(data);
    showInAppBanner(notification.title, notification.message, showAlert: true);
    _ref.invalidate(unreadNotificationCountProvider);
    _ref.invalidate(notificationsListProvider);

    // Refresh data based on notification type or title
    final type = data is Map ? data['type'] : null;
    final title = notification.title.toLowerCase();

    if (type == 'redemption_approved' || 
        type == 'redemption_rejected' || 
        type == 'profile_updated' ||
        title.contains('profile updated')) {
      
      Timer(const Duration(milliseconds: 200), () {
        debugPrint('NotificationService: Invalidating profile and rewards providers...');
        _ref.invalidate(myRedemptionsProvider);
        _ref.invalidate(rewardsListProvider);
        _ref.invalidate(userProfileProvider);
      });
    }
  }

  void clearAllBanners() {
    scaffoldMessengerKey.currentState?.clearSnackBars();
  }

  void showInAppBanner(String title, String message, {bool showAlert = true, bool showSnackBar = true, bool force = false}) {
    // 1. Show System Alert (Tryd Alert) if requested
    if (showAlert) {
      _showLocalNotification(AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        message: message,
        type: 'system',
        createdAt: DateTime.now(),
      ));
    }

    if (showSnackBar) {
      if (_isMuted && !force) {
         debugPrint('NotificationService: SnackBar skipped because UI is Muted');
      } else {
         _showSnackBar(title, message);
      }
    }
  }

  void _showSnackBar(String title, String message) {
    scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
    
    const duration = Duration(milliseconds: 2000);
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        backgroundColor: const Color(0xFF930FBE),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: duration,
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () {
            scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
          },
        ),
      ),
    );

    // Foolproof Auto-dismiss: Force hide after duration + small buffer
    Timer(duration + const Duration(milliseconds: 100), () {
      scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
    });
  }

  Future<void> _showLocalNotification(AppNotification notification) async {
    try {
      await _localNotifications.show(
        notification.id.hashCode,
        notification.title,
        notification.message,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'tryd_priority_alert_v2',
            'Tryd Alerts',
            channelDescription: 'Critical updates and activity alerts',
            importance: Importance.max,
            priority: Priority.max,
            ticker: 'ticker',
            color: Color(0xFF930FBE),
            enableVibration: true,
            playSound: true,
            showWhen: true,
            // Show full notification content on the lock screen even when
            // the device is locked, matching Google Maps alert behaviour.
            visibility: NotificationVisibility.public,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: notification.id,
      );
      debugPrint('AlertNotification: Socket shown → ${notification.title}');
    } catch (e) {
      debugPrint('AlertNotification: Socket ERROR → $e');
    }
  }

  void reconnect() {
    if (_socket != null) {
      if (!_socket!.connected) {
        debugPrint('Socket: Manually triggering reconnect...');
        _socket!.connect();
      }
    } else {
      // If socket was never initialized, try connecting now
      connectSocket();
    }
  }

  void pause() {
    debugPrint('Socket: App backgrounded — disconnecting to save battery');
    _socket?.disconnect();
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }
}

final realTimeNotificationServiceProvider = Provider<RealTimeNotificationService>((ref) {
  return RealTimeNotificationService(ref);
});

