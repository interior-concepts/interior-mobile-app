import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/crm_colors.dart';
import 'user_button.dart';
import '../services/notification_manager.dart';
import 'notifications/notification_bottom_sheet.dart';

class MobileAppHeader extends StatelessWidget implements PreferredSizeWidget {
  const MobileAppHeader({super.key, required this.title, this.onRefresh});

  final String title;
  final VoidCallback? onRefresh;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final foregroundColor = CrmColors.foreground;

    return AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: foregroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.35),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.5),
                  width: 0.8,
                ),
              ),
            ),
          ),
        ),
      ),
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      centerTitle: true,
      leadingWidth: 56,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Center(
          child: Image.asset(
            'assets/icon.png',
            width: 40,
            height: 40,
            fit: BoxFit.contain,
          ),
        ),
      ),
      actions: [
        if (onRefresh != null)
          IconButton(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ListenableBuilder(
          listenable: NotificationManager.instance,
          builder: (context, _) {
            final count = NotificationManager.instance.unreadCount;
            return Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    NotificationBottomSheet.show(context);
                  },
                  icon: const Icon(Icons.notifications_none_rounded),
                  tooltip: 'Notifications',
                ),
                if (count > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: CrmColors.error,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        count > 99 ? '99+' : count.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }
        ),
        const Padding(
          padding: EdgeInsets.only(right: 12),
          child: Center(child: UserButton(size: 36)),
        ),
      ],
    );
  }
}
