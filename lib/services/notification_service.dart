import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

// Top-level background message handler.
// This must be a top-level function (not inside any class) to run when the app is in the background or terminated.
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
  if (message.notification != null) {
    debugPrint("Background Notification Title: ${message.notification!.title}");
    debugPrint("Background Notification Body: ${message.notification!.body}");
  }
}

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  // Initialize notifications
  Future<void> initialize() async {
    // 1. Request Permission (Required for iOS and Android 13+)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      provisional: false,
      sound: true,
    );

    debugPrint(
      'User granted notification permission: ${settings.authorizationStatus}',
    );

    // 2. Register Background Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3. Listen to Foreground Messages (When app is active and in view)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message in the foreground!');
      if (message.notification != null) {
        debugPrint(
          'Foreground Notification Title: ${message.notification!.title}',
        );
        debugPrint(
          'Foreground Notification Body: ${message.notification!.body}',
        );
      }

      // Note: If you want to show a popup or local notification alert in the foreground
      // on Android, you would typically trigger package 'flutter_local_notifications' here.
    });

    // 4. Handle Notification click when app is opened from a background state
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
      // Navigate to a specific screen based on notification data
    });

    // 5. Handle Notification click when app is opened from a terminated state
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('App opened from terminated state via notification!');
      // Navigate to a specific screen based on notification data
    }
  }

  // Get FCM Token to send notifications to this specific device
  Future<String?> getFCMToken() async {
    try {
      String? token = await _fcm.getToken();
      debugPrint("FCM Token: $token");
      return token;
    } catch (e) {
      debugPrint("Error getting FCM Token: $e");
      return null;
    }
  }

  // Monitor token refresh (when token changes, update in database)
  Stream<String> get onTokenRefresh => _fcm.onTokenRefresh;
}
