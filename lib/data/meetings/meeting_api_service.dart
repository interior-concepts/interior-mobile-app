import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import '../../models/meeting_queue_lead.dart';

class MeetingApiService {
  final http.Client _client = http.Client();

  String get _baseUrl => AppConfig.apiBaseUrl;

  Future<List<MeetingQueueLead>> fetchMeetingQueue(String token, {String? search, String queueType = 'meeting'}) async {
    if (_baseUrl.isEmpty) return [];

    final endpoint = queueType == 'design' ? '/api/cad-work/visualizer-queue' : '/api/cad-work/jr-architect-queue';
    var uri = Uri.parse(_baseUrl).resolve(endpoint);
    
    final queryParams = <String, String>{
      'queueType': queueType,
    };
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    
    uri = uri.replace(queryParameters: queryParams);

    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await _client.get(uri, headers: headers).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['success'] == true && decoded['data'] != null) {
          final dataList = decoded['data'] as List;
          return dataList.map((item) {
            final lead = MeetingQueueLead.fromJson(item);
            lead.queueCategory = queueType;
            return lead;
          }).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchDepartmentMembers(String token, String departmentName) async {
    if (_baseUrl.isEmpty) return [];
    
    final uri = Uri.parse(_baseUrl).resolve('/api/department/available/$departmentName');
    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await _client.get(uri, headers: headers).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['success'] == true && decoded['users'] != null) {
          return List<Map<String, dynamic>>.from(decoded['users']);
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> scheduleMeeting(
    String token, 
    String leadId, 
    String meetingKind, // 'FIRST' or 'BUDGET'
    DateTime startsAt, 
    String mode, // 'ONLINE' or 'OFFLINE'
    String note,
  ) async {
    if (_baseUrl.isEmpty) return false;

    final typeStr = meetingKind == 'FIRST' ? 'FIRST_MEETING' : 'BUDGET_MEETING';
    final notes = ['Meeting mode: $mode', note.trim()].where((s) => s.isNotEmpty).join('\n');

    final meetingUri = Uri.parse(_baseUrl).resolve('/api/lead/$leadId/meetings');
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      // 1. Create meeting
      final meetingRes = await _client.post(
        meetingUri, 
        headers: headers,
        body: json.encode({
          'type': typeStr,
          'startsAt': startsAt.toUtc().toIso8601String(),
          'notes': notes.isNotEmpty ? notes : null,
        }),
      ).timeout(const Duration(seconds: 15));

      final meetingData = json.decode(meetingRes.body);
      if (meetingRes.statusCode != 200 || meetingData['success'] != true) {
        throw Exception(meetingData['error'] ?? 'Failed to schedule meeting');
      }

      // 2. Update Stage
      final stageUri = Uri.parse(_baseUrl).resolve('/api/lead/$leadId/stage');
      final stageRes = await _client.patch(
        stageUri,
        headers: headers,
        body: json.encode({
          'stage': meetingKind == 'FIRST' ? 'DISCOVERY' : 'BUDGET_PHASE',
          'subStatus': meetingKind == 'FIRST' ? 'FIRST_MEETING_SET' : 'BUDGET_MEETING_SET',
          'reason': meetingKind == 'FIRST' 
              ? 'First meeting scheduled from Meeting Queue.' 
              : 'Budget meeting scheduled from Budget Queue.',
        }),
      ).timeout(const Duration(seconds: 15));

      final stageData = json.decode(stageRes.body);
      if (stageRes.statusCode != 200 || stageData['success'] != true) {
        throw Exception(stageData['error'] ?? 'Failed to update stage');
      }

      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> completeFirstMeeting(
    String token, 
    String leadId, 
    String note,
    String? quotationMemberId,
  ) async {
    if (_baseUrl.isEmpty) return false;

    final uri = Uri.parse(_baseUrl).resolve('/api/lead/$leadId/meetings/complete');
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await _client.post(
        uri, 
        headers: headers,
        body: json.encode({
          if (note.trim().isNotEmpty) 'note': note.trim(),
          if (quotationMemberId != null && quotationMemberId.isNotEmpty) 'quotationMemberId': quotationMemberId,
        }),
      ).timeout(const Duration(seconds: 15));

      final data = json.decode(response.body);
      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(data['error'] ?? 'Failed to complete first meeting');
      }

      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> completeBudgetMeeting(
    String token, 
    String leadId, 
    String note,
    String clientApproval, // 'DESIGN_AGREEMENT', 'FITOUT_AGREEMENT', 'NO_APPROVAL'
    String? visualizerMemberId,
  ) async {
    if (_baseUrl.isEmpty) return false;

    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      if (clientApproval != 'NO_APPROVAL' && visualizerMemberId != null) {
        // Assign Visualizer
        final assignUri = Uri.parse(_baseUrl).resolve('/api/lead/$leadId/assignments/VISUALIZER_3D');
        final assignRes = await _client.put(
          assignUri, 
          headers: headers,
          body: json.encode({'userId': visualizerMemberId}),
        ).timeout(const Duration(seconds: 15));
        
        final assignData = json.decode(assignRes.body);
        if (assignRes.statusCode != 200 || assignData['success'] != true) {
          throw Exception(assignData['error'] ?? 'Failed to assign 3D Visualizer');
        }
      }

      // Update Stage
      final isNoApproval = clientApproval == 'NO_APPROVAL';
      final stageUri = Uri.parse(_baseUrl).resolve('/api/lead/$leadId/stage');
      
      final reasonPrefix = isNoApproval 
          ? 'Budget meeting completed: no approval.' 
          : 'Budget meeting completed with ${clientApproval.replaceAll('_', ' ').toLowerCase()} and assigned to 3D Visualizer.';
          
      final stageRes = await _client.patch(
        stageUri,
        headers: headers,
        body: json.encode({
          'stage': isNoApproval ? 'BUDGET_PHASE' : 'VISUALIZATION_PHASE',
          'subStatus': isNoApproval ? 'REJECTED_OFFER' : 'VISUAL_ASSIGNED',
          'reason': '$reasonPrefix ${note.trim()}'.trim(),
        }),
      ).timeout(const Duration(seconds: 15));

      final stageData = json.decode(stageRes.body);
      if (stageRes.statusCode != 200 || stageData['success'] != true) {
        throw Exception(stageData['error'] ?? 'Failed to update stage');
      }

      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> reassignQuotation(
    String token, 
    String leadId, 
    String quotationMemberId,
    bool isNewQuotation, // true if QUOTATION_APPROVED (POST), false otherwise (PUT)
  ) async {
    if (_baseUrl.isEmpty) return false;

    final uri = Uri.parse(_baseUrl).resolve('/api/lead/$leadId/assignments/QUOTATION');
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final request = isNewQuotation 
          ? _client.post(uri, headers: headers, body: json.encode({'userId': quotationMemberId}))
          : _client.put(uri, headers: headers, body: json.encode({'userId': quotationMemberId}));
          
      final response = await request.timeout(const Duration(seconds: 15));

      final data = json.decode(response.body);
      if (response.statusCode != 200 && response.statusCode != 201 || data['success'] != true) {
        throw Exception(data['error'] ?? 'Failed to reassign quotation');
      }

      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> updateProjectSize(String token, String visitId, double sqft) async {
    if (_baseUrl.isEmpty) return false;

    final uri = Uri.parse(_baseUrl).resolve('/api/visit-schedule/$visitId');
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await _client.patch(
        uri,
        headers: headers,
        body: json.encode({'projectSqft': sqft}),
      ).timeout(const Duration(seconds: 15));

      final data = json.decode(response.body);
      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(data['error'] ?? 'Failed to update project size');
      }

      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> dropProject(String token, String leadId, String subStatus, String queueType) async {
    if (_baseUrl.isEmpty) return false;

    final uri = Uri.parse(_baseUrl).resolve('/api/lead/$leadId/stage');
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final readableQueueName = queueType == 'meeting' 
        ? 'Meeting Queue' 
        : queueType == 'budget' 
            ? 'Budget Queue' 
            : 'CAD Queue';

    try {
      final response = await _client.patch(
        uri,
        headers: headers,
        body: json.encode({
          'stage': 'CLOSED',
          'subStatus': subStatus,
          'reason': 'Project dropped from $readableQueueName.',
        }),
      ).timeout(const Duration(seconds: 15));

      final data = json.decode(response.body);
      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(data['error'] ?? 'Failed to drop project');
      }

      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> reassignJrArchitect(String token, String leadId, String userId) async {
    if (_baseUrl.isEmpty) return false;

    final uri = Uri.parse(_baseUrl).resolve('/api/lead/$leadId/assignments/JR_ARCHITECT');
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await _client.put(
        uri,
        headers: headers,
        body: json.encode({'userId': userId}),
      ).timeout(const Duration(seconds: 15));

      final data = json.decode(response.body);
      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(data['error'] ?? 'Failed to reassign JR Architect');
      }

      return true;
    } catch (e) {
      rethrow;
    }
  }
}
