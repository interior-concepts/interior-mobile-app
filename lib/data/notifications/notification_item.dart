class NotificationItem {
  final String id;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? scheduledFor;

  // Optional associated entities
  final String? leadId;
  final String? leadName;
  final String? followUpId;
  final String? visitId;
  final String? subjectUserId;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.scheduledFor,
    this.leadId,
    this.leadName,
    this.followUpId,
    this.visitId,
    this.subjectUserId,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'UNKNOWN',
      title: json['title'] as String? ?? 'Notification',
      message: json['message'] as String? ?? '',
      isRead: json['isRead'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String).toLocal()
          : DateTime.now(),
      scheduledFor: json['scheduledFor'] != null
          ? DateTime.parse(json['scheduledFor'] as String).toLocal()
          : null,
      leadId: json['leadId'] as String?,
      leadName: json['lead']?['name'] as String?,
      followUpId: json['followUpId'] as String?,
      visitId: json['visitId'] as String?,
      subjectUserId: json['subjectUserId'] as String?,
    );
  }
}
