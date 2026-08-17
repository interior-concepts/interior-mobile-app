import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../config/app_config.dart';

class CurrentUser {
  final String id;
  final String fullName;
  final String email;
  final List<String> roles;
  final List<String> departments;

  const CurrentUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.roles,
    required this.departments,
  });

  bool get isVisitTeamLeader {
    return roles.any((r) {
      final normalized = r.toUpperCase().replaceAll(' ', '_').replaceAll('-', '_');
      return normalized == 'VISIT_TEAM_LEADER' ||
          normalized == 'VISIT_TEAM_CO_LEADER';
    });
  }

  bool get isSeniorCrm {
    return departments.any((d) {
      final normalized = d.toUpperCase().replaceAll(' ', '_').replaceAll('-', '_');
      return normalized == 'SR_CRM' || normalized == 'SENIOR_CRM';
    }) || roles.any((r) {
      final normalized = r.toUpperCase().replaceAll(' ', '_').replaceAll('-', '_');
      return normalized == 'SR_CRM' || normalized == 'SENIOR_CRM';
    });
  }

  bool get isVisitTeam {
    return departments.any((d) {
      final normalized = d.toUpperCase().replaceAll(' ', '_').replaceAll('-', '_');
      return normalized == 'VISIT_TEAM';
    }) || roles.any((r) {
      final normalized = r.toUpperCase().replaceAll(' ', '_').replaceAll('-', '_');
      return normalized == 'VISIT_TEAM' || normalized == 'VISIT_TEAM_MEMBER';
    });
  }

  factory CurrentUser.fromJson(Map<String, dynamic> json) {
    final rolesList = <String>[];
    if (json['userRoles'] is List) {
      for (final item in json['userRoles']) {
        if (item['role'] is Map && item['role']['name'] is String) {
          rolesList.add(item['role']['name'] as String);
        }
      }
    }

    final depsList = <String>[];
    if (json['userDepartments'] is List) {
      for (final item in json['userDepartments']) {
        if (item['department'] is Map && item['department']['name'] is String) {
          depsList.add(item['department']['name'] as String);
        }
      }
    }

    return CurrentUser(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      roles: rolesList,
      departments: depsList,
    );
  }
}

class UserApiService {
  UserApiService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = (baseUrl ?? AppConfig.apiBaseUrl).trim();

  final http.Client _client;
  final String _baseUrl;

  Future<CurrentUser?> fetchMe(String token) async {
    if (_baseUrl.isEmpty) return null;

    final uri = Uri.parse(_baseUrl).resolve('/api/me');
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
        if (data is Map<String, dynamic>) {
          return CurrentUser.fromJson(data);
        }
      }
    } catch (_) {}
    return null;
  }
}
