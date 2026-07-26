class ReviewSubmission {
  final String id;
  final String leadName;
  final String leadPhone;
  final String leadLocation;
  final String stage;
  final String subStatus;
  final String submittedBy;
  final DateTime submittedAt;
  final String? note;
  final int fileCount;
  final String phaseType; // 'cad', 'quotation', or 'visualizer'

  ReviewSubmission({
    required this.id,
    required this.leadName,
    required this.leadPhone,
    required this.leadLocation,
    required this.stage,
    required this.subStatus,
    required this.submittedBy,
    required this.submittedAt,
    this.note,
    required this.fileCount,
    required this.phaseType,
  });

  bool get isPendingReview {
    return (stage == 'CAD_PHASE' && subStatus == 'CAD_COMPLETED') ||
        (stage == 'QUOTATION_PHASE' && subStatus == 'QUOTATION_COMPLETED') ||
        (stage == 'VISUALIZATION_PHASE' && subStatus == 'VISUAL_COMPLETED');
  }

  factory ReviewSubmission.fromJson(Map<String, dynamic> json) {
    final lead = json['lead'] ?? {};
    final submittedByInfo = json['submittedBy'] ?? {};
    final files = json['files'] as List? ?? [];
    
    String stage = lead['stage'] ?? '';
    String phaseType = 'cad';
    if (stage == 'QUOTATION_PHASE') phaseType = 'quotation';
    if (stage == 'VISUALIZATION_PHASE') phaseType = 'visualizer';

    return ReviewSubmission(
      id: json['id']?.toString() ?? '',
      leadName: lead['name']?.toString() ?? 'Unknown Lead',
      leadPhone: lead['phone']?.toString() ?? '',
      leadLocation: lead['location']?.toString() ?? '',
      stage: stage,
      subStatus: lead['subStatus']?.toString() ?? '',
      submittedBy: submittedByInfo['fullName']?.toString() ?? 'Unknown User',
      submittedAt: json['submittedAt'] != null ? DateTime.parse(json['submittedAt'].toString()) : DateTime.now(),
      note: json['note']?.toString(),
      fileCount: files.length,
      phaseType: phaseType,
    );
  }
}
