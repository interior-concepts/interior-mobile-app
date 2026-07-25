import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../config/app_config.dart';
import 'notification_item.dart';

class NotificationsResponse {
  final List<NotificationItem> items;
  final int unreadCount;

  NotificationsResponse({required this.items, required this.unreadCount});
}

class NotificationApiService {
  NotificationApiService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = (baseUrl ?? AppConfig.apiBaseUrl).trim();

  final http.Client _client;
  final String _baseUrl;

  Future<NotificationsResponse?> fetchNotifications(String token) async {
    if (_baseUrl.isEmpty) return null;

    final uri = Uri.parse(_baseUrl).resolve('/api/notifications');
    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await _client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));
          
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final itemsList = (data['data']['items'] as List?)
                  ?.map((item) => NotificationItem.fromJson(item))
                  .toList() ??
              [];
          final unreadCount = data['data']['unreadCount'] as int? ?? 0;
          return NotificationsResponse(items: itemsList, unreadCount: unreadCount);
        }
      }
    } catch (_) {}
    return null;
  }

  Future<bool> markAllAsRead(String token) async {
    if (_baseUrl.isEmpty) return false;

    final uri = Uri.parse(_baseUrl).resolve('/api/notifications');
    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await _client
          .patch(uri, headers: headers)
          .timeout(const Duration(seconds: 15));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> markAsRead(String token, String id) async {
    if (_baseUrl.isEmpty) return false;

    final uri = Uri.parse(_baseUrl).resolve('/api/notifications/$id/read');
    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await _client
          .patch(uri, headers: headers)
          .timeout(const Duration(seconds: 15));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
