import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/visits/visit.dart';
import '../../theme/crm_colors.dart';

class VisitCardWidget extends StatefulWidget {
  const VisitCardWidget({
    super.key,
    required this.visit,
    this.currentUserId,
    this.onTap,
    this.onLongPress,
  });

  final Visit visit;
  final String? currentUserId;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  State<VisitCardWidget> createState() => _VisitCardWidgetState();
}

class _VisitCardWidgetState extends State<VisitCardWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final visit = widget.visit;
    final currentUserId = widget.currentUserId;
    final isSupportMember = currentUserId != null &&
        visit.supportAssignments.any((a) => a.supportUserId == currentUserId) &&
        visit.assignedToId != currentUserId;

    final statusLabel = _statusLabel(visit.status);
    final scheduledDate = _formatDateTime(visit.scheduledAt);
    final assignedName = visit.assignedTo?.fullName ?? 'Unassigned';

    Color statusFg;
    Color statusBg;
    Color statusBorder;
    IconData statusIcon;

    switch (visit.status) {
      case VisitStatus.scheduled:
        statusFg = CrmColors.brandPrimary;
        statusBg = CrmColors.brandPrimary.withValues(alpha: 0.1);
        statusBorder = CrmColors.brandPrimary.withValues(alpha: 0.2);
        statusIcon = Icons.schedule_outlined;
        break;
      case VisitStatus.completed:
        statusFg = const Color(0xFF2E7D32);
        statusBg = const Color(0xFF2E7D32).withValues(alpha: 0.1);
        statusBorder = const Color(0xFF2E7D32).withValues(alpha: 0.2);
        statusIcon = Icons.check_circle_outline;
        break;
      case VisitStatus.rescheduled:
        statusFg = const Color(0xFF1565C0);
        statusBg = const Color(0xFF1565C0).withValues(alpha: 0.1);
        statusBorder = const Color(0xFF1565C0).withValues(alpha: 0.2);
        statusIcon = Icons.event_repeat_outlined;
        break;
      case VisitStatus.cancelled:
        statusFg = CrmColors.error;
        statusBg = CrmColors.error.withValues(alpha: 0.1);
        statusBorder = CrmColors.error.withValues(alpha: 0.2);
        statusIcon = Icons.cancel_outlined;
        break;
      default:
        statusFg = CrmColors.mutedForeground;
        statusBg = CrmColors.mutedForeground.withValues(alpha: 0.1);
        statusBorder = CrmColors.mutedForeground.withValues(alpha: 0.2);
        statusIcon = Icons.help_outline;
    }

    return GestureDetector(
      onLongPress: widget.onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSupportMember 
                ? const Color(0xFFE0B0FF).withValues(alpha: 0.8) 
                : Colors.grey.withValues(alpha: 0.2),
            width: isSupportMember ? 1.5 : 1.0,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isSupportMember 
              ? [
                  const Color(0xFFFDFBFF),
                  const Color(0xFFF3E5F5).withValues(alpha: 0.6),
                ]
              : [
                  Colors.white,
                  const Color(0xFFF8F9FE),
                ],
          ),
          boxShadow: [
            BoxShadow(
              color: isSupportMember 
                  ? const Color(0xFFE0B0FF).withValues(alpha: 0.2) 
                  : Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
              if (widget.onTap != null) widget.onTap!();
            },
            onLongPress: widget.onLongPress,
            borderRadius: BorderRadius.circular(24),
            splashColor: CrmColors.brandPrimary.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isSupportMember)
                        Padding(
                          padding: const EdgeInsets.only(right: 6.0, top: 2.0),
                          child: Icon(Icons.people_alt, size: 16, color: const Color(0xFF8E24AA)),
                        ),
                      Expanded(
                        child: Text(
                          visit.clientName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: CrmColors.foreground,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(color: statusBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 12, color: statusFg),
                            const SizedBox(width: 4),
                            Text(
                              statusLabel.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: statusFg,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  CardRowWidget(
                    iconBg: Colors.white,
                    iconColor: CrmColors.brandPrimary.withValues(alpha: 0.6),
                    icon: Icons.calendar_today_outlined,
                    text: scheduledDate,
                    shadowColor: Colors.black.withValues(alpha: 0.05),
                    bold: true,
                  ),

                  if (_isExpanded) ...[
                    const SizedBox(height: 8),
                    CardRowWidget(
                      iconBg: Colors.white,
                      iconColor: CrmColors.brandPrimary.withValues(alpha: 0.6),
                      icon: Icons.location_on_outlined,
                      text: visit.location,
                      shadowColor: Colors.black.withValues(alpha: 0.05),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.only(top: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: Colors.grey.withValues(alpha: 0.2),
                          ),
                        ),
                      ),
                      child: CardRowWidget(
                        iconBg: CrmColors.brandPrimary.withValues(alpha: 0.05),
                        iconColor: CrmColors.brandPrimary,
                        icon: Icons.person_outline_rounded,
                        text: 'Assigned to: $assignedName',
                        shadowColor: Colors.transparent,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Center(
                    child: Icon(
                      _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: Colors.grey.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _statusLabel(VisitStatus status) {
    switch (status) {
      case VisitStatus.scheduled:
        return 'Pending';
      case VisitStatus.completed:
        return 'Completed';
      case VisitStatus.rescheduled:
        return 'Rescheduled';
      case VisitStatus.cancelled:
        return 'Cancelled';
      case VisitStatus.unknown:
        return 'Unknown';
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Date unavailable';

    final local = dateTime.toLocal();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final month = months[local.month - 1];
    final day = local.day;
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final amPm = local.hour >= 12 ? 'PM' : 'AM';

    return '$month $day • $hour:$minute $amPm';
  }
}

class CardRowWidget extends StatelessWidget {
  const CardRowWidget({
    super.key,
    required this.iconBg,
    required this.iconColor,
    required this.icon,
    required this.text,
    required this.shadowColor,
    this.bold = false,
  });

  final Color iconBg;
  final Color iconColor;
  final IconData icon;
  final String text;
  final Color shadowColor;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: CrmColors.mutedForeground,
              height: 1.4,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

class SupportMemberSheet extends StatelessWidget {
  const SupportMemberSheet({super.key, required this.visit});
  final Visit visit;

  @override
  Widget build(BuildContext context) {
    final assignedName =
        visit.assignedTo?.fullName ?? visit.assignedTo?.email ?? 'the assigned member';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF6C47FF).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_outlined,
              size: 40,
              color: Color(0xFF6C47FF),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Support Member',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: CrmColors.foreground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You are a support member on this visit. Only $assignedName (the assigned member) can take actions.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: CrmColors.mutedForeground,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8FC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.person_outline_rounded, size: 18, color: CrmColors.mutedForeground),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Assigned to: $assignedName',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: CrmColors.foreground,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6C47FF),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
