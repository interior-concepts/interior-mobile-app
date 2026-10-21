class AssignmentUser {
  final String id;
  final String fullName;
  final String email;

  AssignmentUser({
    required this.id,
    required this.fullName,
    required this.email,
  });

  factory AssignmentUser.fromJson(Map<String, dynamic> json) {
    return AssignmentUser(
      id: json['id'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
    );
  }
}

class DepartmentAssignment {
  final String id;
  final AssignmentUser user;

  DepartmentAssignment({
    required this.id,
    required this.user,
  });

  factory DepartmentAssignment.fromJson(Map<String, dynamic> json) {
    return DepartmentAssignment(
      id: json['id'] ?? '',
      user: AssignmentUser.fromJson(json['user'] ?? {}),
    );
  }
}

class LatestCompletedVisit {
  final String id;
  final String scheduledAt;
  final double? projectSqft;
  final AssignmentUser? assignedVisitLead;
  final List<AssignmentUser> supportMembers;

  LatestCompletedVisit({
    required this.id,
    required this.scheduledAt,
    this.projectSqft,
    this.assignedVisitLead,
    required this.supportMembers,
  });

  factory LatestCompletedVisit.fromJson(Map<String, dynamic> json) {
    return LatestCompletedVisit(
      id: json['id'] ?? '',
      scheduledAt: json['scheduledAt'] ?? '',
      projectSqft: json['projectSqft'] != null
          ? (json['projectSqft'] as num).toDouble()
          : null,
      assignedVisitLead: json['assignedVisitLead'] != null
          ? AssignmentUser.fromJson(json['assignedVisitLead'])
          : null,
      supportMembers: (json['supportMembers'] as List<dynamic>?)
              ?.map((e) => AssignmentUser.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class LatestFirstMeeting {
  final String id;
  final String title;
  final String startsAt;
  final String? notes;

  LatestFirstMeeting({
    required this.id,
    required this.title,
    required this.startsAt,
    this.notes,
  });

  factory LatestFirstMeeting.fromJson(Map<String, dynamic> json) {
    return LatestFirstMeeting(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      startsAt: json['startsAt'] ?? '',
      notes: json['notes'],
    );
  }
}

class MeetingQueueLead {
  final String id;
  final String? clientId;
  final String name;
  final String? phone;
  final String? location;
  final String stage;
  final String? subStatus;
  final String updatedAt;
  final double? budget;
  final DepartmentAssignment? jrArchitectAssignment;
  final DepartmentAssignment? srCrmAssignment;
  final DepartmentAssignment? quotationAssignment;
  final LatestCompletedVisit? latestCompletedVisit;
  final LatestFirstMeeting? latestFirstMeeting;
  final bool canSetMeeting;
  final bool canSubmitMeetingData;
  final bool? canReassignJrArchitect;
  final bool? canReassignQuotation;
  String? queueCategory; // Added to track which queue this lead came from

  MeetingQueueLead({
    required this.id,
    this.clientId,
    required this.name,
    this.phone,
    this.location,
    required this.stage,
    this.subStatus,
    required this.updatedAt,
    this.budget,
    this.jrArchitectAssignment,
    this.srCrmAssignment,
    this.quotationAssignment,
    this.latestCompletedVisit,
    this.latestFirstMeeting,
    required this.canSetMeeting,
    required this.canSubmitMeetingData,
    this.canReassignJrArchitect,
    this.canReassignQuotation,
    this.queueCategory,
  });

  String? get displayClientId {
    final cid = clientId;
    if (cid != null && cid.trim().isNotEmpty) {
      final trimmed = cid.trim();
      return trimmed.startsWith('#') ? trimmed : '#$trimmed';
    }
    return null;
  }

  factory MeetingQueueLead.fromJson(Map<String, dynamic> json) {
    final rawClientId = json['clientId'] ?? json['client_id'];
    return MeetingQueueLead(
      id: json['id'] ?? '',
      clientId: rawClientId != null ? rawClientId.toString() : null,
      name: json['name'] ?? '',
      phone: json['phone'],
      location: json['location'],
      stage: json['stage'] ?? '',
      subStatus: json['subStatus'],
      updatedAt: json['updatedAt'] ?? '',
      budget: json['budget'] != null ? (json['budget'] as num).toDouble() : null,
      jrArchitectAssignment: json['jrArchitectAssignment'] != null
          ? DepartmentAssignment.fromJson(json['jrArchitectAssignment'])
          : null,
      srCrmAssignment: json['srCrmAssignment'] != null
          ? DepartmentAssignment.fromJson(json['srCrmAssignment'])
          : null,
      quotationAssignment: json['quotationAssignment'] != null
          ? DepartmentAssignment.fromJson(json['quotationAssignment'])
          : null,
      latestCompletedVisit: json['latestCompletedVisit'] != null
          ? LatestCompletedVisit.fromJson(json['latestCompletedVisit'])
          : null,
      latestFirstMeeting: json['latestFirstMeeting'] != null
          ? LatestFirstMeeting.fromJson(json['latestFirstMeeting'])
          : null,
      canSetMeeting: json['canSetMeeting'] ?? false,
      canSubmitMeetingData: json['canSubmitMeetingData'] ?? false,
      canReassignJrArchitect: json['canReassignJrArchitect'],
      canReassignQuotation: json['canReassignQuotation'],
    );
  }
}
