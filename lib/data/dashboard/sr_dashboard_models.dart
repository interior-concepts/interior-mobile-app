class SrDashboardData {
  final QueueCounts queueCounts;
  final List<UpcomingMeeting> upcomingMeetings;
  final List<BudgetLead> budgetLeads;
  final List<ReviewSubmission> reviewSubmissions;
  final List<DashboardTask> overdueCadTasks;
  final List<DashboardTask> overdueQuotationTasks;
  final List<ReviewSubmission> overdueQuotationReviews;
  final List<ReviewSubmission> overdueDesignReviews;
  final List<VisitItem> visitItems;
  final DesignWatch designWatch;
  final VisitInsights visitInsights;
  final SrPerformance? performance;

  SrDashboardData({
    required this.queueCounts,
    required this.upcomingMeetings,
    required this.budgetLeads,
    required this.reviewSubmissions,
    required this.overdueCadTasks,
    required this.overdueQuotationTasks,
    required this.overdueQuotationReviews,
    required this.overdueDesignReviews,
    required this.visitItems,
    required this.designWatch,
    required this.visitInsights,
    this.performance,
  });

  factory SrDashboardData.fromJson(Map<String, dynamic> json) {
    return SrDashboardData(
      queueCounts: QueueCounts.fromJson(json['queueCounts'] ?? {}),
      upcomingMeetings: (json['upcomingMeetings'] as List?)
              ?.map((e) => UpcomingMeeting.fromJson(e))
              .toList() ??
          [],
      budgetLeads: (json['budgetLeads'] as List?)
              ?.map((e) => BudgetLead.fromJson(e))
              .toList() ??
          [],
      reviewSubmissions: (json['reviewSubmissions'] as List?)
              ?.map((e) => ReviewSubmission.fromJson(e))
              .toList() ??
          [],
      overdueCadTasks: (json['overdueCadTasks'] as List?)
              ?.map((e) => DashboardTask.fromJson(e))
              .toList() ??
          [],
      overdueQuotationTasks: (json['overdueQuotationTasks'] as List?)
              ?.map((e) => DashboardTask.fromJson(e))
              .toList() ??
          [],
      overdueQuotationReviews: (json['overdueQuotationReviews'] as List?)
              ?.map((e) => ReviewSubmission.fromJson(e))
              .toList() ??
          [],
      overdueDesignReviews: (json['overdueDesignReviews'] as List?)
              ?.map((e) => ReviewSubmission.fromJson(e))
              .toList() ??
          [],
      visitItems: (json['visitItems'] as List?)
              ?.map((e) => VisitItem.fromJson(e))
              .toList() ??
          [],
      designWatch: DesignWatch.fromJson(json['designWatch'] ?? {}),
      visitInsights: VisitInsights.fromJson(json['visitInsights'] ?? {}),
      performance: json['performance'] != null
          ? SrPerformance.fromJson(json['performance'])
          : null,
    );
  }
}

class QueueCounts {
  final int cad;
  final int review;
  final int visit;
  final int meeting;
  final int budget;

  QueueCounts({
    required this.cad,
    required this.review,
    required this.visit,
    required this.meeting,
    required this.budget,
  });

  factory QueueCounts.fromJson(Map<String, dynamic> json) {
    return QueueCounts(
      cad: json['cad'] ?? 0,
      review: json['review'] ?? 0,
      visit: json['visit'] ?? 0,
      meeting: json['meeting'] ?? 0,
      budget: json['budget'] ?? 0,
    );
  }
}

class UpcomingMeeting {
  final String id;
  final String type;
  final String title;
  final DateTime startsAt;
  final LeadInfo lead;

  UpcomingMeeting({
    required this.id,
    required this.type,
    required this.title,
    required this.startsAt,
    required this.lead,
  });

  factory UpcomingMeeting.fromJson(Map<String, dynamic> json) {
    return UpcomingMeeting(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      startsAt: DateTime.parse(json['startsAt']),
      lead: LeadInfo.fromJson(json['lead'] ?? {}),
    );
  }
}

class LeadInfo {
  final String id;
  final String name;
  final String? stage;
  final String? subStatus;
  final String? phone;
  final String? location;

  LeadInfo({
    required this.id,
    required this.name,
    this.stage,
    this.subStatus,
    this.phone,
    this.location,
  });

  factory LeadInfo.fromJson(Map<String, dynamic> json) {
    return LeadInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown',
      stage: json['stage'],
      subStatus: json['subStatus'],
      phone: json['phone'],
      location: json['location'],
    );
  }
}

class BudgetLead {
  final String id;
  final String name;
  final double? budget;
  final String? stage;
  final String? subStatus;
  final String? assigneeName;

  BudgetLead({
    required this.id,
    required this.name,
    this.budget,
    this.stage,
    this.subStatus,
    this.assigneeName,
  });

  factory BudgetLead.fromJson(Map<String, dynamic> json) {
    String? assignee;
    if (json['assignments'] != null && (json['assignments'] as List).isNotEmpty) {
      assignee = json['assignments'][0]['user']?['fullName'];
    }
    return BudgetLead(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      budget: json['budget'] != null ? (json['budget'] as num).toDouble() : null,
      stage: json['stage'],
      subStatus: json['subStatus'],
      assigneeName: assignee,
    );
  }
}

class ReviewSubmission {
  final String id;
  final DateTime submittedAt;
  final LeadInfo lead;
  final String submittedBy;
  final int fileCount;

  ReviewSubmission({
    required this.id,
    required this.submittedAt,
    required this.lead,
    required this.submittedBy,
    required this.fileCount,
  });

  factory ReviewSubmission.fromJson(Map<String, dynamic> json) {
    return ReviewSubmission(
      id: json['id'] ?? '',
      submittedAt: DateTime.parse(json['submittedAt']),
      lead: LeadInfo.fromJson(json['lead'] ?? {}),
      submittedBy: json['submittedBy']?['fullName'] ?? 'Unknown',
      fileCount: (json['files'] as List?)?.length ?? 0,
    );
  }
}

class DashboardTask {
  final String id;
  final DateTime dueAt;
  final String status;
  final LeadInfo lead;
  final String assigneeName;

  DashboardTask({
    required this.id,
    required this.dueAt,
    required this.status,
    required this.lead,
    required this.assigneeName,
  });

  factory DashboardTask.fromJson(Map<String, dynamic> json) {
    return DashboardTask(
      id: json['id'] ?? '',
      dueAt: DateTime.parse(json['dueAt']),
      status: json['status'] ?? '',
      lead: LeadInfo.fromJson(json['lead'] ?? {}),
      assigneeName: json['assignee']?['fullName'] ?? 'Unknown',
    );
  }
}

class VisitItem {
  final String leadId;
  final String leadName;
  final DateTime? latestVisitTime;
  final String? assignedLeadName;

  VisitItem({
    required this.leadId,
    required this.leadName,
    this.latestVisitTime,
    this.assignedLeadName,
  });

  factory VisitItem.fromJson(Map<String, dynamic> json) {
    final visit = json['latestCompletedVisit'];
    return VisitItem(
      leadId: json['leadId'] ?? '',
      leadName: json['leadName'] ?? '',
      latestVisitTime: visit?['completedAt'] != null
          ? DateTime.parse(visit['completedAt'])
          : (visit?['scheduledAt'] != null ? DateTime.parse(visit['scheduledAt']) : null),
      assignedLeadName: visit?['assignedVisitLead']?['fullName'],
    );
  }
}

class DesignWatch {
  final int queueCount;
  final int overdueQueueCount;
  final int reviewPendingCount;
  final int overdueReviewCount;

  DesignWatch({
    required this.queueCount,
    required this.overdueQueueCount,
    required this.reviewPendingCount,
    required this.overdueReviewCount,
  });

  factory DesignWatch.fromJson(Map<String, dynamic> json) {
    return DesignWatch(
      queueCount: json['queueCount'] ?? 0,
      overdueQueueCount: json['overdueQueueCount'] ?? 0,
      reviewPendingCount: json['reviewPendingCount'] ?? 0,
      overdueReviewCount: json['overdueReviewCount'] ?? 0,
    );
  }
}

class VisitInsights {
  final List<VisitStatusData> statusData;
  final int pendingOverdueCount;

  VisitInsights({
    required this.statusData,
    required this.pendingOverdueCount,
  });

  factory VisitInsights.fromJson(Map<String, dynamic> json) {
    return VisitInsights(
      statusData: (json['statusData'] as List?)
              ?.map((e) => VisitStatusData.fromJson(e))
              .toList() ??
          [],
      pendingOverdueCount: json['pendingOverdueCount'] ?? 0,
    );
  }
}

class VisitStatusData {
  final String name;
  final int value;
  final String fill;

  VisitStatusData({
    required this.name,
    required this.value,
    required this.fill,
  });

  factory VisitStatusData.fromJson(Map<String, dynamic> json) {
    return VisitStatusData(
      name: json['name'] ?? '',
      value: json['value'] ?? 0,
      fill: json['fill'] ?? '',
    );
  }
}

class SrPerformance {
  final SrPerformanceMember? current;
  final SrPerformanceMember? top;

  SrPerformance({this.current, this.top});

  factory SrPerformance.fromJson(Map<String, dynamic> json) {
    return SrPerformance(
      current: json['current'] != null
          ? SrPerformanceMember.fromJson(json['current'])
          : null,
      top: json['top'] != null
          ? SrPerformanceMember.fromJson(json['top'])
          : null,
    );
  }
}

class SrPerformanceMember {
  final String userId;
  final String name;
  final int activeProjectSqft;
  final int totalPerformance;
  final int reviewScore;
  final int meetingScore;
  final int conversionScore;
  final int reviewCount;
  final int meetingCount;
  final int conversionCount;

  SrPerformanceMember({
    required this.userId,
    required this.name,
    required this.activeProjectSqft,
    required this.totalPerformance,
    required this.reviewScore,
    required this.meetingScore,
    required this.conversionScore,
    required this.reviewCount,
    required this.meetingCount,
    required this.conversionCount,
  });

  factory SrPerformanceMember.fromJson(Map<String, dynamic> json) {
    return SrPerformanceMember(
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      activeProjectSqft: json['activeProjectSqft'] ?? 0,
      totalPerformance: json['totalPerformance'] ?? 0,
      reviewScore: json['review']?['score'] ?? 0,
      reviewCount: json['review']?['count'] ?? 0,
      meetingScore: json['meeting']?['score'] ?? 0,
      meetingCount: json['meeting']?['count'] ?? 0,
      conversionScore: json['conversion']?['score'] ?? 0,
      conversionCount: json['conversion']?['count'] ?? 0,
    );
  }
}
