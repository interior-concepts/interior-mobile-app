enum VisitStatus { scheduled, completed, rescheduled, cancelled, unknown }

VisitStatus parseVisitStatus(String? raw) {
  switch ((raw ?? '').trim().toUpperCase()) {
    case 'SCHEDULED':
      return VisitStatus.scheduled;
    case 'COMPLETED':
      return VisitStatus.completed;
    case 'RESCHEDULED':
      return VisitStatus.rescheduled;
    case 'CANCELLED':
      return VisitStatus.cancelled;
    default:
      return VisitStatus.unknown;
  }
}

class Visit {
  const Visit({
    required this.id,
    required this.leadId,
    this.clientId,
    required this.clientName,
    required this.location,
    required this.scheduledAt,
    required this.status,
    required this.assignedToId,
    required this.projectSqft,
    required this.projectStatus,
    required this.notes,
    required this.createdById,
    required this.createdAt,
    required this.updatedAt,
    required this.lead,
    required this.assignedTo,
    required this.createdBy,
    required this.supportAssignments,
    required this.supportResults,
    required this.result,
    required this.updateRequests,
    required this.visitFee,
  });

  factory Visit.fromJson(Map<String, dynamic> json) {
    final leadJson = (json['lead'] ?? json['client'] ?? json['leadData']) as Map<String, dynamic>?;
    final scheduledAtRaw = json['scheduledAt'] as String?;
    final locationValue = (json['location'] as String?)?.trim();
    final leadName = (leadJson?['name'] as String?)?.trim();
    final rawClientId = json['clientId'] ??
        leadJson?['clientId'] ??
        json['client_id'] ??
        leadJson?['client_id'] ??
        json['leadClientId'] ??
        leadJson?['leadClientId'];

    return Visit(
      id: json['id'] as String? ?? '',
      leadId: json['leadId'] as String?,
      clientId: rawClientId != null ? rawClientId.toString() : null,
      clientName: (leadName?.isNotEmpty ?? false)
          ? leadName!
          : ((locationValue?.isNotEmpty ?? false) ? locationValue! : 'Client'),
      location: (locationValue?.isNotEmpty ?? false)
          ? locationValue!
          : 'Unknown',
      scheduledAt: DateTime.tryParse(scheduledAtRaw ?? ''),
      status: parseVisitStatus(json['status'] as String?),
      assignedToId: json['assignedToId'] as String?,
      projectSqft: _toDouble(json['projectSqft']),
      projectStatus: json['projectStatus'] as String?,
      notes: json['notes'] as String?,
      createdById: json['createdById'] as String?,
      createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? ''),
      updatedAt: DateTime.tryParse((json['updatedAt'] as String?) ?? ''),
      lead: leadJson == null ? null : VisitLead.fromJson(leadJson),
      assignedTo: (json['assignedTo'] as Map<String, dynamic>?) == null
          ? null
          : VisitUser.fromJson(json['assignedTo'] as Map<String, dynamic>),
      createdBy: (json['createdBy'] as Map<String, dynamic>?) == null
          ? null
          : VisitUser.fromJson(json['createdBy'] as Map<String, dynamic>),
      supportAssignments: _parseList(
        json['supportAssignments'],
        (item) => SupportAssignment.fromJson(item),
      ),
      supportResults: _parseList(
        json['supportResults'],
        (item) => SupportResult.fromJson(item),
      ),
      result: (json['result'] as Map<String, dynamic>?) == null
          ? null
          : VisitResult.fromJson(json['result'] as Map<String, dynamic>),
      updateRequests: _parseList(
        json['updateRequests'],
        (item) => VisitUpdateRequest.fromJson(item),
      ),
      visitFee: _toDouble(json['visitFee']) ?? 0,
    );
  }

  final String id;
  final String? leadId;
  final String? clientId;
  final String clientName;
  final String location;
  final DateTime? scheduledAt;
  final VisitStatus status;
  final String? assignedToId;
  final double? projectSqft;
  final String? projectStatus;
  final String? notes;
  final String? createdById;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final VisitLead? lead;
  final VisitUser? assignedTo;
  final VisitUser? createdBy;
  final List<SupportAssignment> supportAssignments;
  final List<SupportResult> supportResults;
  final VisitResult? result;
  final List<VisitUpdateRequest> updateRequests;
  final double visitFee;

  bool isScheduledOn(DateTime day) {
    if (scheduledAt == null) return false;

    final local = scheduledAt!.toLocal();
    return local.year == day.year &&
        local.month == day.month &&
        local.day == day.day;
  }

  String? get clientPhone {
    final p = lead?.phone?.trim();
    if (p != null && p.isNotEmpty) return p;
    return null;
  }

  String? get displayClientId {
    final cid = clientId ?? lead?.clientId;
    if (cid != null && cid.trim().isNotEmpty) {
      final trimmed = cid.trim();
      return trimmed.startsWith('#') ? trimmed : '#$trimmed';
    }
    return null;
  }
}

class VisitLead {
  const VisitLead({this.id, this.clientId, this.name, this.phone, this.location});
  factory VisitLead.fromJson(Map<String, dynamic> json) {
    final rawClientId = json['clientId'] ?? json['client_id'] ?? json['leadClientId'];
    return VisitLead(
      id: json['id'] as String?,
      clientId: rawClientId != null ? rawClientId.toString() : null,
      name: json['name'] as String?,
      phone: (json['phone'] as String?) ?? (json['phoneNumber'] as String?) ?? (json['mobile'] as String?),
      location: json['location'] as String?,
    );
  }
  final String? id;
  final String? clientId;
  final String? name;
  final String? phone;
  final String? location;
}

class VisitUser {
  const VisitUser({this.id, this.fullName, this.email, this.phone});
  factory VisitUser.fromJson(Map<String, dynamic> json) => VisitUser(
    id: json['id'] as String?,
    fullName: json['fullName'] as String?,
    email: json['email'] as String?,
    phone: json['phone'] as String?,
  );
  final String? id;
  final String? fullName;
  final String? email;
  final String? phone;
}

class VisitFile {
  const VisitFile({
    this.id,
    this.url,
    this.fileName,
    this.fileType,
    this.createdAt,
  });
  factory VisitFile.fromJson(Map<String, dynamic> json) => VisitFile(
    id: json['id'] as String?,
    url: json['url'] as String?,
    fileName: json['fileName'] as String?,
    fileType: json['fileType'] as String?,
    createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? ''),
  );
  final String? id;
  final String? url;
  final String? fileName;
  final String? fileType;
  final DateTime? createdAt;
}

class SupportAssignmentResult {
  const SupportAssignmentResult({this.id, this.completedAt});
  factory SupportAssignmentResult.fromJson(Map<String, dynamic> json) =>
      SupportAssignmentResult(
        id: json['id'] as String?,
        completedAt: DateTime.tryParse((json['completedAt'] as String?) ?? ''),
      );
  final String? id;
  final DateTime? completedAt;
}

class SupportAssignment {
  const SupportAssignment({
    this.id,
    this.supportUserId,
    this.createdAt,
    this.supportUser,
    this.result,
  });
  factory SupportAssignment.fromJson(Map<String, dynamic> json) =>
      SupportAssignment(
        id: json['id'] as String?,
        supportUserId: json['supportUserId'] as String?,
        createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? ''),
        supportUser: (json['supportUser'] as Map<String, dynamic>?) == null
            ? null
            : VisitUser.fromJson(json['supportUser'] as Map<String, dynamic>),
        result: (json['result'] as Map<String, dynamic>?) == null
            ? null
            : SupportAssignmentResult.fromJson(
                json['result'] as Map<String, dynamic>,
              ),
      );
  final String? id;
  final String? supportUserId;
  final DateTime? createdAt;
  final VisitUser? supportUser;
  final SupportAssignmentResult? result;
}

class SupportResult {
  const SupportResult({
    this.id,
    this.visitId,
    this.supportAssignmentId,
    this.supportUserId,
    this.clientName,
    this.projectArea,
    this.projectStatus,
    this.extraConcern,
    this.completedAt,
    this.supportUser,
    this.files = const [],
  });
  factory SupportResult.fromJson(Map<String, dynamic> json) => SupportResult(
    id: json['id'] as String?,
    visitId: json['visitId'] as String?,
    supportAssignmentId: json['supportAssignmentId'] as String?,
    supportUserId: json['supportUserId'] as String?,
    clientName: json['clientName'] as String?,
    projectArea: json['projectArea'] as String?,
    projectStatus: json['projectStatus'] as String?,
    extraConcern: json['extraConcern'] as String?,
    completedAt: DateTime.tryParse((json['completedAt'] as String?) ?? ''),
    supportUser: (json['supportUser'] as Map<String, dynamic>?) == null
        ? null
        : VisitUser.fromJson(json['supportUser'] as Map<String, dynamic>),
    files: _parseList(json['files'], (item) => VisitFile.fromJson(item)),
  );
  final String? id;
  final String? visitId;
  final String? supportAssignmentId;
  final String? supportUserId;
  final String? clientName;
  final String? projectArea;
  final String? projectStatus;
  final String? extraConcern;
  final DateTime? completedAt;
  final VisitUser? supportUser;
  final List<VisitFile> files;
}

class VisitResult {
  const VisitResult({
    this.id,
    this.visitId,
    this.summary,
    this.measurements,
    this.clientMood,
    this.clientPotentiality,
    this.projectType,
    this.projectStatus,
    this.clientPersonality,
    this.budgetRange,
    this.timelineUrgency,
    this.stylePreference,
    this.completedAt,
    this.files = const [],
  });
  factory VisitResult.fromJson(Map<String, dynamic> json) => VisitResult(
    id: json['id'] as String?,
    visitId: json['visitId'] as String?,
    summary: json['summary'] as String?,
    measurements: json['measurements'],
    clientMood: json['clientMood'] as String?,
    clientPotentiality: json['clientPotentiality'] as String?,
    projectType: json['projectType'] as String?,
    projectStatus: json['projectStatus'] as String?,
    clientPersonality: json['clientPersonality'] as String?,
    budgetRange: json['budgetRange'] as String?,
    timelineUrgency: json['timelineUrgency'] as String?,
    stylePreference: json['stylePreference'] as String?,
    completedAt: DateTime.tryParse((json['completedAt'] as String?) ?? ''),
    files: _parseList(json['files'], (item) => VisitFile.fromJson(item)),
  );
  final String? id;
  final String? visitId;
  final String? summary;
  final dynamic measurements;
  final String? clientMood;
  final String? clientPotentiality;
  final String? projectType;
  final String? projectStatus;
  final String? clientPersonality;
  final String? budgetRange;
  final String? timelineUrgency;
  final String? stylePreference;
  final DateTime? completedAt;
  final List<VisitFile> files;
}

class VisitUpdateRequest {
  const VisitUpdateRequest({
    this.id,
    this.visitId,
    this.type,
    this.status,
    this.reason,
    this.requestedScheduleAt,
    this.requestedById,
    this.resolvedById,
    this.createdAt,
    this.resolvedAt,
    this.requestedBy,
  });
  factory VisitUpdateRequest.fromJson(Map<String, dynamic> json) =>
      VisitUpdateRequest(
        id: json['id'] as String?,
        visitId: json['visitId'] as String?,
        type: json['type'] as String?,
        status: json['status'] as String?,
        reason: json['reason'] as String?,
        requestedScheduleAt: DateTime.tryParse(
          (json['requestedScheduleAt'] as String?) ?? '',
        ),
        requestedById: json['requestedById'] as String?,
        resolvedById: json['resolvedById'] as String?,
        createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? ''),
        resolvedAt: DateTime.tryParse((json['resolvedAt'] as String?) ?? ''),
        requestedBy: (json['requestedBy'] as Map<String, dynamic>?) == null
            ? null
            : VisitUser.fromJson(json['requestedBy'] as Map<String, dynamic>),
      );
  final String? id;
  final String? visitId;
  final String? type;
  final String? status;
  final String? reason;
  final DateTime? requestedScheduleAt;
  final String? requestedById;
  final String? resolvedById;
  final DateTime? createdAt;
  final DateTime? resolvedAt;
  final VisitUser? requestedBy;
}

double? _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

List<T> _parseList<T>(
  dynamic raw,
  T Function(Map<String, dynamic> json) parser,
) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map<String, dynamic>>()
      .map(parser)
      .toList(growable: false);
}
