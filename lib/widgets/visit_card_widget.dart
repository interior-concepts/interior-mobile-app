import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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

  Future<void> _makePhoneCall(BuildContext context, String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleanPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No valid phone number available')),
      );
      return;
    }
    final uri = Uri(scheme: 'tel', path: cleanPhone);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not launch phone call to $phone')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error making phone call: $e')),
        );
      }
    }
  }

  Future<void> _openWhatsApp(BuildContext context, String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No valid phone number for WhatsApp')),
      );
      return;
    }
    final Uri appUri = Uri.parse('whatsapp://send?phone=$cleanPhone');
    final Uri webUri = Uri.parse('https://wa.me/$cleanPhone');

    try {
      if (await canLaunchUrl(appUri)) {
        await launchUrl(appUri);
      } else if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } else {
        final launched = await launchUrl(webUri, mode: LaunchMode.externalApplication);
        if (!launched && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open WhatsApp for $phone')),
          );
        }
      }
    } catch (e) {
      try {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error opening WhatsApp: $e')),
          );
        }
      }
    }
  }

  Future<void> _openFileUrl(BuildContext context, String? url) async {
    if (url == null || url.trim().isEmpty) return;
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return;
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open file: $e')),
        );
      }
    }
  }

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
    final phone = visit.clientPhone;

    final allFiles = <VisitFile>[
      if (visit.result?.files != null) ...visit.result!.files,
      for (final sr in visit.supportResults) ...sr.files,
    ];

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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              visit.clientName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: CrmColors.foreground,
                                letterSpacing: -0.2,
                              ),
                            ),
                            if (visit.displayClientId != null) ...[
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: CrmColors.brandPrimary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Client ID: ${visit.displayClientId}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: CrmColors.brandPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
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
                          if (allFiles.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.attach_file, size: 11, color: Colors.blue),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${allFiles.length} file${allFiles.length > 1 ? 's' : ''}',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
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

                  if (phone != null && phone.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.phone_outlined,
                            size: 16,
                            color: CrmColors.brandPrimary.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              phone,
                              style: const TextStyle(
                                fontSize: 13,
                                color: CrmColors.foreground,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          // Call Button
                          InkWell(
                            onTap: () => _makePhoneCall(context, phone),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.3)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.call, size: 12, color: Color(0xFF16A34A)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Call',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF16A34A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // WhatsApp Button
                          InkWell(
                            onTap: () => _openWhatsApp(context, phone),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF25D366).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF25D366).withValues(alpha: 0.4)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.chat_bubble_outline_rounded, size: 12, color: Color(0xFF25D366)),
                                  SizedBox(width: 4),
                                  Text(
                                    'WhatsApp',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF25D366),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (_isExpanded) ...[
                    if (phone == null || phone.isEmpty) ...[
                      const SizedBox(height: 8),
                      CardRowWidget(
                        iconBg: Colors.white,
                        iconColor: CrmColors.brandPrimary.withValues(alpha: 0.6),
                        icon: Icons.phone_outlined,
                        text: 'Phone: N/A',
                        shadowColor: Colors.black.withValues(alpha: 0.05),
                      ),
                    ],
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
                    if (visit.result != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Visit Outcome',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: CrmColors.foreground,
                              ),
                            ),
                            if (visit.result?.summary != null && visit.result!.summary!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                visit.result!.summary!,
                                style: const TextStyle(fontSize: 12, color: CrmColors.foreground),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                if (visit.result?.clientMood != null && visit.result!.clientMood!.isNotEmpty)
                                  _InfoBadge(label: 'Mood', value: visit.result!.clientMood!),
                                if (visit.result?.clientPersonality != null && visit.result!.clientPersonality!.isNotEmpty)
                                  _InfoBadge(label: 'Personality', value: visit.result!.clientPersonality!),
                                if (visit.result?.projectType != null && visit.result!.projectType!.isNotEmpty)
                                  _InfoBadge(label: 'Type', value: visit.result!.projectType!),
                                if ((visit.projectStatus ?? visit.result?.projectStatus) != null && (visit.projectStatus ?? visit.result?.projectStatus)!.isNotEmpty)
                                  _InfoBadge(label: 'Status', value: (visit.projectStatus ?? visit.result?.projectStatus)!),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (allFiles.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.attach_file, size: 15, color: CrmColors.foreground),
                          const SizedBox(width: 4),
                          Text(
                            'Attachments (${allFiles.length})',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: CrmColors.foreground,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 64,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: allFiles.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final file = allFiles[index];
                            final fileName = file.fileName ?? file.url?.split('/').last ?? 'Attachment ${index + 1}';
                            final url = file.url ?? '';
                            final lowerUrl = url.toLowerCase();
                            final isImage = lowerUrl.endsWith('.jpg') ||
                                lowerUrl.endsWith('.jpeg') ||
                                lowerUrl.endsWith('.png') ||
                                lowerUrl.endsWith('.webp') ||
                                (file.fileType?.startsWith('image') ?? false);

                            return InkWell(
                              onTap: () => _openFileUrl(context, url),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: 140,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Row(
                                  children: [
                                    if (isImage && url.isNotEmpty)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.network(
                                          url,
                                          width: 36,
                                          height: 36,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Icon(
                                            Icons.image_outlined,
                                            size: 24,
                                            color: CrmColors.brandPrimary,
                                          ),
                                        ),
                                      )
                                    else
                                      const Icon(
                                        Icons.insert_drive_file_outlined,
                                        size: 24,
                                        color: CrmColors.brandPrimary,
                                      ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            fileName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const Text(
                                            'Tap to open',
                                            style: TextStyle(
                                              fontSize: 9,
                                              color: CrmColors.mutedForeground,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
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

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: CrmColors.foreground,
        ),
      ),
    );
  }
}
