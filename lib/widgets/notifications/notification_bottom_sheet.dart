import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/notifications/notification_item.dart';
import '../../services/notification_manager.dart';
import '../../theme/crm_colors.dart';

class NotificationBottomSheet extends StatefulWidget {
  const NotificationBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const NotificationBottomSheet(),
    );
  }

  @override
  State<NotificationBottomSheet> createState() => _NotificationBottomSheetState();
}

class _NotificationBottomSheetState extends State<NotificationBottomSheet> {
  bool _isMarkingAllRead = false;

  Future<void> _handleMarkAllAsRead() async {
    setState(() => _isMarkingAllRead = true);
    try {
      final success = await NotificationManager.instance.markAllAsRead();
      if (!mounted) return;
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to mark all as read. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isMarkingAllRead = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    
    return Container(
      constraints: BoxConstraints(maxHeight: size.height * 0.85),
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: CrmColors.foreground,
                  ),
                ),
                ListenableBuilder(
                  listenable: NotificationManager.instance,
                  builder: (context, _) {
                    final hasUnread = NotificationManager.instance.unreadCount > 0;
                    if (!hasUnread) return const SizedBox.shrink();
                    
                    return _isMarkingAllRead
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : TextButton(
                            onPressed: _handleMarkAllAsRead,
                            style: TextButton.styleFrom(
                              foregroundColor: CrmColors.brandPrimary,
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Mark all as read'),
                          );
                  },
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // List
          Flexible(
            child: ListenableBuilder(
              listenable: NotificationManager.instance,
              builder: (context, _) {
                final items = NotificationManager.instance.items;
                
                if (items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Center(
                      child: Text(
                        'No notifications yet.',
                        style: TextStyle(
                          color: CrmColors.mutedForeground,
                        ),
                      ),
                    ),
                  );
                }
                
                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _NotificationTile(item: item);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item});

  final NotificationItem item;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, h:mm a');
    final timeString = dateFormat.format(item.createdAt);

    return InkWell(
      onTap: () {
        if (!item.isRead) {
          NotificationManager.instance.markAsRead(item.id);
        }
        // If we want to navigate later, we can check item.type or item.leadId here.
        // For now, tapping marks as read and dismisses the sheet.
        Navigator.of(context).pop();
      },
      child: Container(
        color: item.isRead ? Colors.white : CrmColors.brandPrimary.withValues(alpha: 0.05),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon indicator
            Container(
              margin: const EdgeInsets.only(top: 2, right: 16),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: item.isRead
                    ? Colors.grey.shade100
                    : CrmColors.brandPrimary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIconForType(item.type),
                size: 20,
                color: item.isRead ? Colors.grey.shade600 : CrmColors.brandPrimary,
              ),
            ),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: item.isRead ? FontWeight.w500 : FontWeight.w700,
                            color: CrmColors.foreground,
                          ),
                        ),
                      ),
                      if (!item.isRead)
                        Container(
                          margin: const EdgeInsets.only(left: 8, top: 4),
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: CrmColors.brandPrimary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.message,
                    style: TextStyle(
                      fontSize: 13,
                      color: item.isRead
                          ? CrmColors.mutedForeground
                          : CrmColors.foreground.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    timeString,
                    style: TextStyle(
                      fontSize: 11,
                      color: CrmColors.mutedForeground.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    if (type.contains('FOLLOWUP')) return Icons.schedule_rounded;
    if (type.contains('VISIT')) return Icons.location_on_rounded;
    if (type.contains('SIGNUP')) return Icons.person_add_rounded;
    return Icons.notifications_rounded;
  }
}
