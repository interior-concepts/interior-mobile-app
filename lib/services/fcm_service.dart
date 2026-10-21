import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'notification_manager.dart';

/// Top-level background message handler — must be a top-level function (not a method).
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundMessageHandler(RemoteMessage message) async {
  final plugin = FlutterLocalNotificationsPlugin();

  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidSettings);
  await plugin.initialize(settings: initSettings);

  // Create channel — required on first run or fresh install.
  await plugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(
        const AndroidNotificationChannel(
          'crm_notifications_channel',
          'CRM Notifications',
          description: 'Updates for CRM events',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );

  final title = message.notification?.title ?? message.data['title'] ?? 'New Notification';
  final body = message.notification?.body ?? message.data['body'] ?? '';

  await plugin.show(
    id: message.hashCode,
    title: title,
    body: body,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        'crm_notifications_channel',
        'CRM Notifications',
        channelDescription: 'Updates for CRM events',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        styleInformation: BigTextStyleInformation(body),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    ),
  );
}

class FcmService {
  FcmService._();

  static final _messaging = FirebaseMessaging.instance;
  static final _localPlugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static String? latestToken;

  static Future<void> initialize() async {
    if (_initialized) return;

    // Register the top-level background handler.
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundMessageHandler);

    // Request permission (iOS + Android 13+).
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Enable foreground notification presentation options
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Set up local notifications plugin for foreground display.
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );
    await _localPlugin.initialize(settings: initSettings);

    // Create the Android notification channel explicitly.
    // This MUST exist before any notification is shown.
    await _localPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'crm_notifications_channel',
            'CRM Notifications',
            description: 'Updates for CRM events — visits, follow-ups, and more',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            showBadge: true,
          ),
        );

    await _localPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Show notification when app is in foreground and trigger a badge update.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final title = message.notification?.title ?? message.data['title'] ?? 'New Notification';
      final body = message.notification?.body ?? message.data['body'] ?? '';
      _showLocalNotification(title, body, id: message.hashCode);
      
      // Instantly refresh the in-app notification bell list
      NotificationManager.instance.forceFetch();
    });

    try {
      final initialToken = await _messaging.getToken();
      if (initialToken != null) {
        debugPrint('🔔 [FCM] App Launch FCM Token: $initialToken');
      }
    } catch (e) {
      debugPrint('🔔 [FCM] Could not fetch initial FCM token on boot: $e');
    }

    _initialized = true;
  }

  static Future<void> _showLocalNotification(String title, String body, {int id = 0}) async {
    await _localPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'crm_notifications_channel',
          'CRM Notifications',
          channelDescription: 'Updates for CRM events',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          styleInformation: BigTextStyleInformation(body),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  /// Gets the FCM token and registers it with the backend.
  static Future<void> registerToken(String authToken) async {
    try {
      debugPrint('🔔 [FCM] registerToken called — requesting FCM token...');

      // On iOS, FCM requires APNs token first. Request it explicitly.
      // On Android this is a no-op.
      await _messaging.getAPNSToken().catchError((_) => null);

      final fcmToken = await _messaging.getToken();
      if (fcmToken == null) {
        debugPrint('🔔 [FCM] ⚠️ getToken() returned null — notifications disabled on this device');
        return;
      }

      latestToken = fcmToken;

      debugPrint('🔔 [FCM] ===================================================');
      debugPrint('🔔 [FCM] FULL FCM TOKEN FOR TESTING:');
      debugPrint('$fcmToken');
      debugPrint('🔔 [FCM] ===================================================');

      final uri = Uri.parse(AppConfig.apiBaseUrl).resolve('/api/device-tokens');
      debugPrint('🔔 [FCM] Registering token at: $uri');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'token': fcmToken,
          'platform': Platform.isIOS ? 'ios' : 'android',
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('🔔 [FCM] ✅ Device token registered successfully (HTTP ${response.statusCode})');
      } else {
        debugPrint('🔔 [FCM] ❌ Failed to register token — HTTP ${response.statusCode}: ${response.body}');
      }

      // Listen for token refreshes and re-register.
      _messaging.onTokenRefresh.listen((newToken) {
        debugPrint('🔔 [FCM] Token refreshed — re-registering...');
        _reRegisterToken(authToken, newToken);
      });
    } catch (e, stack) {
      debugPrint('🔔 [FCM] ❌ registerToken error: $e');
      debugPrint('🔔 [FCM] Stack: $stack');
    }
  }

  static Future<void> _reRegisterToken(String authToken, String fcmToken) async {
    try {
      final uri = Uri.parse(AppConfig.apiBaseUrl).resolve('/api/device-tokens');
      await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'token': fcmToken,
          'platform': Platform.isIOS ? 'ios' : 'android',
        }),
      ).timeout(const Duration(seconds: 15));
    } catch (_) {}
  }

  /// Removes the token when the user signs out.
  static Future<void> unregisterToken(String authToken) async {
    try {
      final fcmToken = await _messaging.getToken();
      if (fcmToken == null) return;

      final uri = Uri.parse(AppConfig.apiBaseUrl).resolve('/api/device-tokens');
      await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'token': fcmToken}),
      ).timeout(const Duration(seconds: 15));

      await _messaging.deleteToken();
    } catch (_) {}
  }
}
