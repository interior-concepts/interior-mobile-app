class VisitResult {
  VisitResult({
    required this.id,
    required this.visitId,
    required this.summary,
    this.measurements,
    this.clientMood,
    this.clientPotentiality,
    this.projectType,
    this.clientPersonality,
    this.budgetRange,
    this.timelineUrgency,
    this.stylePreference,
    required this.completedAt,
  });

  final String id;
  final String visitId;
  final String summary;
  final Map<String, dynamic>? measurements;
  final String? clientMood;
  final String? clientPotentiality;
  final String? projectType;
  final String? clientPersonality;
  final String? budgetRange;
  final String? timelineUrgency;
  final String? stylePreference;
  final DateTime completedAt;

  factory VisitResult.fromJson(Map<String, dynamic> json) => VisitResult(
        id: json['id'] as String,
        visitId: json['visitId'] as String,
        summary: json['summary'] as String,
        measurements: (json['measurements'] is Map)
            ? Map<String, dynamic>.from(json['measurements'])
            : null,
        clientMood: json['clientMood'] as String?,
        clientPotentiality: json['clientPotentiality'] as String?,
        projectType: json['projectType'] as String?,
        clientPersonality: json['clientPersonality'] as String?,
        budgetRange: json['budgetRange'] as String?,
        timelineUrgency: json['timelineUrgency'] as String?,
        stylePreference: json['stylePreference'] as String?,
        completedAt: DateTime.parse(json['completedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'visitId': visitId,
        'summary': summary,
        if (measurements != null) 'measurements': measurements,
        if (clientMood != null) 'clientMood': clientMood,
        if (clientPotentiality != null) 'clientPotentiality': clientPotentiality,
        if (projectType != null) 'projectType': projectType,
        if (clientPersonality != null) 'clientPersonality': clientPersonality,
        if (budgetRange != null) 'budgetRange': budgetRange,
        if (timelineUrgency != null) 'timelineUrgency': timelineUrgency,
        if (stylePreference != null) 'stylePreference': stylePreference,
        'completedAt': completedAt.toIso8601String(),
      };
}
