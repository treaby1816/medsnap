import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:developer' as developer;

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // 1. Request Permissions
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      developer.log('User granted notification permissions', name: 'NotificationService');
    }

    // 2. Initialize Local Notifications (for foreground messages)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    
    // In v21+, initialize REQUIRES named parameters as per diagnostics
    // The specific named parameter required is likely 'initializationSettings' OR 'settings'.
    // Given the error "The named parameter 'settings' is required", I will use 'settings'.
    await _localNotifications.initialize(settings: initializationSettings);

    // 3. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      developer.log('Foreground message received: ${message.notification?.title}', name: 'NotificationService');
      _showLocalNotification(message);
    });

    // 4. Handle Background/Terminated Message Clicks
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      developer.log('Notification clicked!', name: 'NotificationService');
    });

    // 5. Get FCM Token
    String? token = await _messaging.getToken();
    developer.log('FCM Token: $token', name: 'NotificationService');
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'vailmeds_orders',
      'VailMeds Orders',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidDetails);
    
    // In v21+, show REQUIRES named parameters for the core arguments as per diagnostics
    // The specific named parameter required is 'id'.
    await _localNotifications.show(
      id: 0,
      title: message.notification?.title,
      body: message.notification?.body,
      notificationDetails: platformChannelSpecifics,
    );
  }
}
