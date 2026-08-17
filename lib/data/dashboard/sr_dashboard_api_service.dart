import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import 'sr_dashboard_models.dart';

class SrDashboardApiService {
  final String _baseUrl = AppConfig.apiBaseUrl;
  final http.Client _client = http.Client();

  Future<SrDashboardData?> fetchDashboardData(String token) async {
    final uri = Uri.parse(_baseUrl).resolve('/api/sr-dashboard');

    debugPrint('📡 [SR Dashboard] Calling: $uri');
    debugPrint('📡 [SR Dashboard] Base URL: $_baseUrl');
    debugPrint('📡 [SR Dashboard] Token length: ${token.length} chars');

    try {
      final response = await _client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('📡 [SR Dashboard] Status: ${response.statusCode}');
      debugPrint('📡 [SR Dashboard] Response body: ${response.body.substring(0, response.body.length.clamp(0, 500))}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          debugPrint('✅ [SR Dashboard] Data loaded successfully');
          return SrDashboardData.fromJson(body['data']);
        } else {
          final errorMsg = body['error'] ?? 'Unknown error from server';
          debugPrint('❌ [SR Dashboard] Server returned error: $errorMsg');
          throw Exception(errorMsg);
        }
      } else {
        String errorMsg = 'HTTP ${response.statusCode}';
        try {
          final body = jsonDecode(response.body);
          if (body['error'] != null) errorMsg = body['error'];
        } catch (_) {
          errorMsg = 'HTTP ${response.statusCode}: ${response.body.substring(0, response.body.length.clamp(0, 200))}';
        }
        debugPrint('❌ [SR Dashboard] Request failed: $errorMsg');
        throw Exception(errorMsg);
      }
    } catch (e, stack) {
      debugPrint('💥 [SR Dashboard] Exception: $e');
      debugPrint('💥 [SR Dashboard] Stack: $stack');
      rethrow;
    }
  }
}
