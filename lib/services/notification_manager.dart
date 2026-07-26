import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../data/notifications/notification_api_service.dart';
import '../data/notifications/notification_item.dart';

class NotificationManager extends ChangeNotifier {
  static final NotificationManager instance = NotificationManager._internal();
  NotificationManager._internal();

  final NotificationApiService _apiService = NotificationApiService();
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Timer? _pollingTimer;
  String? _currentToken;

  List<NotificationItem> _items = [];
  int _unreadCount = 0;
  bool _isInitialized = false;

  // Track which notification IDs we have already triggered a local notification for.
  // This is the key fix: we compare IDs not just the count.
  final Set<String> _seenIds = {};
  // Whether this is the very first fetch since polling started.
  bool _isFirstFetch = true;

  List<NotificationItem> get items => _items;
  int get unreadCount => _unreadCount;

  Future<void> initLocalNotifications() async {
    if (_isInitialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _localNotificationsPlugin.initialize(
      settings: initSettings,
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _isInitialized = true;
  }

  void startPolling(String token) {
    _currentToken = token;
    _seenIds.clear();
    _isFirstFetch = true;
    _fetchNow();
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _fetchNow();
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _currentToken = null;
    _items = [];
    _unreadCount = 0;
    _seenIds.clear();
    _isFirstFetch = true;
    notifyListeners();
  }

  void forceFetch() {
    _fetchNow();
  }

  Future<void> _fetchNow() async {
    if (_currentToken == null) return;

    final response = await _apiService.fetchNotifications(_currentToken!);
    if (response == null) return;

    _items = response.items;
    _unreadCount = response.unreadCount;
    notifyListeners();

    if (_isFirstFetch) {
      // On the very first fetch: seed the seen IDs with already-read notifications
      // so we only fire for unread ones the user hasn't been notified about yet.
      for (final item in _items) {
        if (item.isRead) _seenIds.add(item.id);
      }
      _isFirstFetch = false;
    }

    // Find new unread notifications that we haven't triggered a local alert for.
    final newUnread = _items
        .where((item) => !item.isRead && !_seenIds.contains(item.id))
        .toList();

    if (newUnread.isEmpty) return;

    // Mark them as seen so we don't fire again on the next poll.
    for (final item in newUnread) {
      _seenIds.add(item.id);
    }

    // Fire one local notification per new unread item (up to 5 to avoid spam).
    final toFire = newUnread.take(5).toList();
    for (var i = 0; i < toFire.length; i++) {
      await _triggerLocalNotification(toFire[i], notificationId: i);
    }
  }

  Future<void> _triggerLocalNotification(
    NotificationItem item, {
    int notificationId = 0,
  }) async {
    if (!_isInitialized) return;

    final androidDetails = AndroidNotificationDetails(
      'crm_notifications_channel',
      'CRM Notifications',
      channelDescription: 'Updates for CRM events — visits, follow-ups, and more',
      importance: Importance.max,
      priority: Priority.high,
      ticker: item.title,
      playSound: true,
      enableVibration: true,
      // Show a big-text style notification
      styleInformation: BigTextStyleInformation(item.message),
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _localNotificationsPlugin.show(
      id: notificationId,
      title: item.title,
      body: item.message,
      notificationDetails: notificationDetails,
    );
  }

  Future<bool> markAllAsRead() async {
    if (_currentToken == null) return false;
    final success = await _apiService.markAllAsRead(_currentToken!);
    if (success) {
      _unreadCount = 0;
      for (var i = 0; i < _items.length; i++) {
        _seenIds.add(_items[i].id);
        _items[i] = NotificationItem(
          id: _items[i].id,
          type: _items[i].type,
          title: _items[i].title,
          message: _items[i].message,
          isRead: true,
          createdAt: _items[i].createdAt,
          scheduledFor: _items[i].scheduledFor,
          leadId: _items[i].leadId,
          leadName: _items[i].leadName,
          followUpId: _items[i].followUpId,
          visitId: _items[i].visitId,
          subjectUserId: _items[i].subjectUserId,
        );
      }
      notifyListeners();
    }
    return success;
  }

  Future<void> markAsRead(String id) async {
    if (_currentToken == null) return;
    final success = await _apiService.markAsRead(_currentToken!, id);
    if (success) {
      final index = _items.indexWhere((i) => i.id == id);
      if (index != -1 && !_items[index].isRead) {
        _unreadCount = (_unreadCount > 0) ? _unreadCount - 1 : 0;
        _seenIds.add(id);
        _items[index] = NotificationItem(
          id: _items[index].id,
          type: _items[index].type,
          title: _items[index].title,
          message: _items[index].message,
          isRead: true,
          createdAt: _items[index].createdAt,
          scheduledFor: _items[index].scheduledFor,
          leadId: _items[index].leadId,
          leadName: _items[index].leadName,
          followUpId: _items[index].followUpId,
          visitId: _items[index].visitId,
          subjectUserId: _items[index].subjectUserId,
        );
        notifyListeners();
      }
    }
  }
}
