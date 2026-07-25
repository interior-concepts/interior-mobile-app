class VisitTopPerformer {
  final String id;
  final String fullName;
  final int performance;

  VisitTopPerformer({
    required this.id,
    required this.fullName,
    required this.performance,
  });

  factory VisitTopPerformer.fromJson(Map<String, dynamic> json) {
    return VisitTopPerformer(
      id: json['id'] as String,
      fullName: (json['name'] as String?) ?? (json['fullName'] as String?) ?? 'Unknown',
      performance: (json['performance'] as num?)?.toInt() ?? 0,
    );
  }
}

class DashboardPerformanceData {
  final VisitTopPerformer? topPerformer;
  final VisitTopPerformer? currentUserPerformance;
  final int averagePerformance;

  DashboardPerformanceData({
    this.topPerformer,
    this.currentUserPerformance,
    required this.averagePerformance,
  });

  factory DashboardPerformanceData.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return DashboardPerformanceData(
      topPerformer: data['topPerformer'] != null
          ? VisitTopPerformer.fromJson(data['topPerformer'] as Map<String, dynamic>)
          : null,
      currentUserPerformance: data['currentUserPerformance'] != null
          ? VisitTopPerformer.fromJson(data['currentUserPerformance'] as Map<String, dynamic>)
          : null,
      averagePerformance: (data['averagePerformance'] as num?)?.toInt() ?? 0,
    );
  }
}
