import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/app_config.dart';
import 'visit.dart';
import 'dashboard_performance_data.dart';

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

  /// Fetch all visit team members by pulling all visits and extracting unique assignees.
  /// Used by leaders to pick a user for reassignment.
  Future<List<VisitUser>> fetchVisitTeamMembers({
    String? authTokenOverride,
  }) async {
    // Fetch all visits (leader scope) and collect unique assignedTo users
    final visits = await fetchVisits(
      scope: 'all',
      accessContext: 'queue',
      authTokenOverride: authTokenOverride,
    );
    final seen = <String>{};
    final members = <VisitUser>[];
    for (final v in visits) {
      final u = v.assignedTo;
      if (u?.id != null && seen.add(u!.id!)) {
        members.add(u);
      }
    }
    members.sort((a, b) =>
        (a.fullName ?? '').compareTo(b.fullName ?? ''));
    return members;
  }

  Future<DashboardPerformanceData?> fetchDashboardPerformance({
    String? authTokenOverride,
  }) async {
    final uri = Uri.parse(_baseUrl).resolve('/api/visit-dashboard/performance');
    final effectiveAuthToken = (authTokenOverride ?? _authToken).trim();
    if (effectiveAuthToken.isEmpty) return null;

    final response = await _client.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $effectiveAuthToken',
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return DashboardPerformanceData.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  /// Reassign a visit to a different visit team member (leader only).
  Future<void> reassignVisit(
    String visitId,
    String visitTeamUserId, {
    String? authTokenOverride,
  }) async {
    await _patchVisit(
      visitId,
      {'visitTeamUserId': visitTeamUserId},
      authTokenOverride: authTokenOverride,
    );
  }

  /// Reschedule a visit directly (leader only).
  Future<void> rescheduleVisitByLeader(
    String visitId,
    DateTime newScheduledAt, {
    String? reason,
    String? authTokenOverride,
  }) async {
    await _patchVisit(
      visitId,
      {
        'status': 'RESCHEDULED',
        'scheduledAt': newScheduledAt.toUtc().toIso8601String(),
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
      authTokenOverride: authTokenOverride,
    );
  }

  /// Cancel a visit directly (leader only).
  Future<void> cancelVisit(
    String visitId, {
    String? reason,
    String? authTokenOverride,
  }) async {
    await _patchVisit(
      visitId,
      {
        'status': 'CANCELLED',
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
      authTokenOverride: authTokenOverride,
    );
  }

  Future<void> _patchVisit(
    String visitId,
    Map<String, dynamic> body, {
    String? authTokenOverride,
  }) async {
    final uri = Uri.parse(_baseUrl).resolve('/api/visit-schedule/$visitId');
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    final effectiveAuthToken = (authTokenOverride ?? _authToken).trim();
    if (effectiveAuthToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $effectiveAuthToken';
    }

    late final http.Response response;
    try {
      response = await _client
          .patch(uri, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      throw const VisitApiException('Could not reach the API.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'Request failed (status ${response.statusCode}).';
      try {
        final payload = jsonDecode(response.body);
        if (payload is Map<String, dynamic>) {
          message = (payload['error'] as String?) ??
              (payload['message'] as String?) ??
              message;
        }
      } catch (_) {}
      throw VisitApiException(message, statusCode: response.statusCode);
    }
  }

  Future<void> updateVisitStatus(
    String visitId,
    String status, {
    String? authTokenOverride,
  }) async {
    final normalized = _normalizeStatus(status);
    if (normalized == null) {
      throw const VisitApiException('Invalid status.');
    }

    final uri = Uri.parse(_baseUrl).resolve('/api/visit-schedule/$visitId');
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    final effectiveAuthToken = (authTokenOverride ?? _authToken).trim();
    if (effectiveAuthToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $effectiveAuthToken';
    }

    late final http.Response response;
    try {
      response = await _client.patch(
        uri,
        headers: headers,
        body: jsonEncode({'status': normalized}),
      ).timeout(const Duration(seconds: 15));
    } catch (_) {
      throw const VisitApiException(
        'Could not reach the API to update visit status.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw VisitApiException(
        'Failed to update visit (status ${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }
  }

  Future<void> rescheduleVisit(
    String visitId,
    DateTime scheduledAt, {
    String? authTokenOverride,
  }) async {
    final uri = Uri.parse(_baseUrl)
        .resolve('/api/visit-schedule/$visitId/reschedule');
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    final effectiveAuthToken = (authTokenOverride ?? _authToken).trim();
    if (effectiveAuthToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $effectiveAuthToken';
    }

    late final http.Response response;
    try {
      response = await _client.post(
        uri,
        headers: headers,
        body: jsonEncode({'scheduledAt': scheduledAt.toUtc().toIso8601String()}),
      ).timeout(const Duration(seconds: 15));
    } catch (_) {
      throw const VisitApiException(
        'Could not reach the API to reschedule visit.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw VisitApiException(
        'Failed to reschedule visit (status ${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }
  }

  Future<void> createVisitUpdateRequest(
    String visitId, {
    required String type,
    required String reason,
    DateTime? requestedScheduleAt,
    String? authTokenOverride,
  }) async {
    final normalizedType = type.trim().toUpperCase();
    if (normalizedType != 'RESCHEDULE' && normalizedType != 'CANCEL') {
      throw const VisitApiException(
        'Invalid request type. Use RESCHEDULE or CANCEL.',
        statusCode: 400,
      );
    }
    if (reason.trim().isEmpty) {
      throw const VisitApiException('Reason is required.', statusCode: 400);
    }
    if (normalizedType == 'RESCHEDULE' && requestedScheduleAt == null) {
      throw const VisitApiException(
        'requestedScheduleAt is required for RESCHEDULE.',
        statusCode: 400,
      );
    }

    final uri = Uri.parse(_baseUrl)
        .resolve('/api/visit-schedule/$visitId/update-request');
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    final effectiveAuthToken = (authTokenOverride ?? _authToken).trim();
    if (effectiveAuthToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $effectiveAuthToken';
    }

    final body = <String, dynamic>{
      'type': normalizedType,
      'reason': reason.trim(),
      if (requestedScheduleAt != null)
        'requestedScheduleAt': requestedScheduleAt.toUtc().toIso8601String(),
    };

    late final http.Response response;
    try {
      response = await _client
          .post(uri, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      throw const VisitApiException(
        'Could not reach the API to create update request.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'Failed to create update request (status ${response.statusCode}).';
      try {
        final payload = jsonDecode(response.body);
        if (payload is Map<String, dynamic>) {
          message = (payload['message'] as String?) ??
              (payload['error'] as String?) ??
              message;
        }
      } catch (_) {}
      throw VisitApiException(message, statusCode: response.statusCode);
    }
  }

  Future<void> submitVisitResult(
    String visitId,
    VisitResultSubmission submission, {
    String? authTokenOverride,
    List<http.MultipartFile> files = const [],
  }) async {
    final uri = Uri.parse(_baseUrl).resolve('/api/visit-schedule/$visitId/result');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Accept'] = 'application/json';

    final effectiveAuthToken = (authTokenOverride ?? _authToken).trim();
    if (effectiveAuthToken.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $effectiveAuthToken';
    }

    void addField(String key, String? value) {
      if (value == null) return;
      final trimmed = value.trim();
      if (trimmed.isEmpty) return;
      request.fields[key] = trimmed;
    }

    addField('summary', submission.summary);
    addField('clientMood', submission.clientMood);
    addField('note', submission.note);
    addField('projectStatus', submission.projectStatus);
    addField('resultType', submission.resultType);
    addField('clientPotentiality', submission.clientPotentiality);
    addField('projectType', submission.projectType);
    addField('clientPersonality', submission.clientPersonality);
    addField('budgetRange', submission.budgetRange);
    addField('timelineUrgency', submission.timelineUrgency);
    addField('stylePreference', submission.stylePreference);

    addField('supportClientName', submission.supportClientName);
    if (submission.supportProjectArea != null) {
      request.fields['supportProjectArea'] =
          submission.supportProjectArea!.toString();
    }
    addField('supportProjectStatus', submission.supportProjectStatus);
    addField('supportExtraConcern', submission.supportExtraConcern);

    request.files.addAll(files);

    late final http.StreamedResponse streamed;
    try {
      streamed = await request.send().timeout(const Duration(seconds: 25));
    } catch (_) {
      throw const VisitApiException(
        'Could not reach the API to submit visit result.',
      );
    }

    final response = await http.Response.fromStream(streamed);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'Failed to submit visit result (status ${response.statusCode}).';
      try {
        final payload = jsonDecode(response.body);
        if (payload is Map<String, dynamic>) {
          message = (payload['message'] as String?) ??
              (payload['error'] as String?) ??
              message;
        }
      } catch (_) {}
      throw VisitApiException(message, statusCode: response.statusCode);
    }
  }

  bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

  Future<List<Map<String, dynamic>>> fetchSupportMembers(
    String visitId, {
    String? authTokenOverride,
  }) async {
    final uri = Uri.parse(_baseUrl).resolve('/api/visit-schedule/$visitId/supports');
    final headers = <String, String>{'Accept': 'application/json'};
    final effectiveAuthToken = (authTokenOverride ?? _authToken).trim();
    if (effectiveAuthToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $effectiveAuthToken';
    }

    final response = await _client.get(uri, headers: headers).timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw VisitApiException('Failed to fetch support members', statusCode: response.statusCode);
    }
    final json = jsonDecode(response.body);
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final available = data['availableMembers'] as List<dynamic>? ?? [];
    return available.cast<Map<String, dynamic>>();
  }

  Future<void> addSupportMember(
    String visitId,
    String supportUserId, {
    String? authTokenOverride,
  }) async {
    final uri = Uri.parse(_baseUrl).resolve('/api/visit-schedule/$visitId/supports');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final effectiveAuthToken = (authTokenOverride ?? _authToken).trim();
    if (effectiveAuthToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $effectiveAuthToken';
    }
    
    final response = await _client.post(
      uri,
      headers: headers,
      body: jsonEncode({'supportUserId': supportUserId}),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'Failed to add support member';
      try {
        final payload = jsonDecode(response.body);
        if (payload is Map<String, dynamic> && payload['error'] != null) {
          message = payload['error'];
        }
      } catch (_) {}
      throw VisitApiException(message, statusCode: response.statusCode);
    }
  }

  String? _normalizeStatus(String? value) {
    if (!_hasText(value)) return null;
    final normalized = value!.trim().toUpperCase();
    return _validStatuses.contains(normalized) ? normalized : null;
  }
}

class VisitResultSubmission {
  const VisitResultSubmission({
    required this.summary,
    this.clientMood,
    this.note,
    this.projectStatus,
    this.resultType,
    this.clientPotentiality,
    this.projectType,
    this.clientPersonality,
    this.budgetRange,
    this.timelineUrgency,
    this.stylePreference,
    this.supportClientName,
    this.supportProjectArea,
    this.supportProjectStatus,
    this.supportExtraConcern,
  });

  final String summary;
  final String? clientMood;
  final String? note;
  final String? projectStatus;
  final String? resultType;
  final String? clientPotentiality;
  final String? projectType;
  final String? clientPersonality;
  final String? budgetRange;
  final String? timelineUrgency;
  final String? stylePreference;
  final String? supportClientName;
  final double? supportProjectArea;
  final String? supportProjectStatus;
  final String? supportExtraConcern;
}
