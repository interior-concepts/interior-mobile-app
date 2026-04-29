import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/app_config.dart';
import 'visit.dart';

class VisitApiException implements Exception {
  const VisitApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class VisitApiService {
  static const Set<String> _validStatuses = {
    'SCHEDULED',
    'COMPLETED',
    'RESCHEDULED',
    'CANCELLED',
  };

  VisitApiService({http.Client? client, String? baseUrl, String? authToken})
    : _client = client ?? http.Client(),
      _baseUrl = (baseUrl ?? AppConfig.apiBaseUrl).trim(),
      _authToken = (authToken ?? AppConfig.apiAuthToken).trim();

  final http.Client _client;
  final String _baseUrl;
  final String _authToken;

  Future<List<Visit>> fetchVisits({
    String? leadId,
    String? assignedToId,
    String? mode,
    String? scope,
    String? accessContext,
    String? status,
    String? authTokenOverride,
  }) async {
    if (_baseUrl.isEmpty) {
      throw const VisitApiException(
        'API base URL is empty. Set --dart-define=API_BASE_URL=...',
      );
    }

    final normalizedStatus = _normalizeStatus(status);
    if (status != null && normalizedStatus == null) {
      throw const VisitApiException(
        'Invalid status. Use one of: SCHEDULED, COMPLETED, RESCHEDULED, CANCELLED.',
        statusCode: 400,
      );
    }

    final queryParams = <String, String?>{
      if (_hasText(leadId)) 'leadId': leadId!.trim(),
      if (_hasText(assignedToId)) 'assignedToId': assignedToId!.trim(),
      if (_hasText(mode)) 'mode': mode!.trim(),
      if (_hasText(scope)) 'scope': scope!.trim(),
      if (_hasText(accessContext)) 'accessContext': accessContext!.trim(),
      'status': normalizedStatus,
    }..removeWhere((_, value) => value == null);

    final uri = Uri.parse(_baseUrl)
        .resolve('/api/visit-schedule')
        .replace(queryParameters: queryParams.cast<String, String>());

    final headers = <String, String>{'Accept': 'application/json'};
    final effectiveAuthToken = (authTokenOverride ?? _authToken).trim();
    if (effectiveAuthToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $effectiveAuthToken';
    }

    late final http.Response response;
    try {
      response = await _client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      throw const VisitApiException(
        'Could not reach the API. Check API_BASE_URL and network access.',
      );
    }

    if (response.statusCode == 401) {
      throw const VisitApiException(
        'Unauthorized (401). Mobile must send a valid Clerk-authenticated token/session.',
        statusCode: 401,
      );
    }

    if (response.statusCode == 403) {
      throw const VisitApiException(
        'Forbidden (403). This account is missing VISIT_TEAM / JR_CRM / ADMIN permission.',
        statusCode: 403,
      );
    }

    if (response.statusCode == 400) {
      throw const VisitApiException(
        'Invalid request (400). Check query params like status/mode/scope/accessContext.',
        statusCode: 400,
      );
    }

    if (response.statusCode != 200) {
      throw VisitApiException(
        'Failed to load visits (status ${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }

    final payload = jsonDecode(response.body);
    if (payload is! Map<String, dynamic>) {
      throw const VisitApiException('Invalid API response format.');
    }

    if (payload['success'] != true) {
      throw VisitApiException(
        (payload['error'] as String?) ?? 'API returned unsuccessful response.',
        statusCode: response.statusCode,
      );
    }

    final data = payload['data'];
    if (data is! List) {
      throw const VisitApiException('API data is not a list.');
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(Visit.fromJson)
        .toList(growable: false);
  }

  bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

  String? _normalizeStatus(String? value) {
    if (!_hasText(value)) return null;
    final normalized = value!.trim().toUpperCase();
    return _validStatuses.contains(normalized) ? normalized : null;
  }
}
