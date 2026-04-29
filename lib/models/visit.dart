import 'lead.dart';
import 'user.dart';
import 'visit_result.dart';

enum VisitStatus { SCHEDULED, COMPLETED, RESCHEDULED, CANCELLED, UNKNOWN }

VisitStatus _parseVisitStatus(String? raw) {
  switch ((raw ?? '').trim().toUpperCase()) {
    case 'SCHEDULED':
      return VisitStatus.SCHEDULED;
    case 'COMPLETED':
      return VisitStatus.COMPLETED;
    case 'RESCHEDULED':
      return VisitStatus.RESCHEDULED;
    case 'CANCELLED':
      return VisitStatus.CANCELLED;
    default:
      return VisitStatus.UNKNOWN;
  }
}

String _visitStatusToString(VisitStatus s) => s.toString().split('.').last;

class Visit {
  Visit({
    required this.id,
    required this.leadId,
    this.lead,
    this.assignedToId,
    this.assignedTo,
    required this.scheduledAt,
    this.visitFee,
    required this.status,
    this.projectSqft,
    this.projectStatus,
    required this.location,
    this.notes,
    required this.createdById,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.result,
  });

  final String id;
  final String leadId;
  final Lead? lead;
  final String? assignedToId;
  final User? assignedTo;
  final DateTime scheduledAt;
  final double? visitFee;
  final VisitStatus status;
  final double? projectSqft;
  final String? projectStatus;
  final String location;
  final String? notes;
  final String createdById;
  final User? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final VisitResult? result;

  factory Visit.fromJson(Map<String, dynamic> json) {
    return Visit(
      id: json['id'] as String,
      leadId: json['leadId'] as String,
      lead: json['lead'] != null && json['lead'] is Map
          ? Lead.fromJson(Map<String, dynamic>.from(json['lead']))
          : null,
      assignedToId: json['assignedToId'] as String?,
      assignedTo: json['assignedTo'] != null && json['assignedTo'] is Map
          ? User.fromJson(Map<String, dynamic>.from(json['assignedTo']))
          : null,
      scheduledAt: DateTime.parse(json['scheduledAt'] as String),
      visitFee: (json['visitFee'] as num?)?.toDouble(),
      status: _parseVisitStatus(json['status'] as String?),
      projectSqft: (json['projectSqft'] as num?)?.toDouble(),
      projectStatus: json['projectStatus'] as String?,
      location: json['location'] as String? ?? '',
      notes: json['notes'] as String?,
      createdById: json['createdById'] as String,
      createdBy: json['createdBy'] != null && json['createdBy'] is Map
          ? User.fromJson(Map<String, dynamic>.from(json['createdBy']))
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      result: json['result'] != null && json['result'] is Map
          ? VisitResult.fromJson(Map<String, dynamic>.from(json['result']))
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'leadId': leadId,
        if (lead != null) 'lead': lead!.toJson(),
        if (assignedToId != null) 'assignedToId': assignedToId,
        if (assignedTo != null) 'assignedTo': assignedTo!.toJson(),
        'scheduledAt': scheduledAt.toIso8601String(),
        if (visitFee != null) 'visitFee': visitFee,
        'status': _visitStatusToString(status),
        if (projectSqft != null) 'projectSqft': projectSqft,
        if (projectStatus != null) 'projectStatus': projectStatus,
        'location': location,
        if (notes != null) 'notes': notes,
        'createdById': createdById,
        if (createdBy != null) 'createdBy': createdBy!.toJson(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        if (result != null) 'result': result!.toJson(),
      };
}
