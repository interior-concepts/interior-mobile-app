import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/crm_colors.dart';
import 'user_button.dart';

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
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      centerTitle: true,
      leadingWidth: 36,
      leading: Padding(
        padding: const EdgeInsets.only(left: 10),
        child: Center(
          child: Image.asset(
            'assets/images/favicon-16x16.png',
            width: 16,
            height: 16,
            fit: BoxFit.contain,
          ),
        ),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: CrmColors.foreground,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
      actions: [
        if (onRefresh != null)
          IconButton(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_none_rounded),
          tooltip: 'Notifications',
        ),
        const Padding(
          padding: EdgeInsets.only(right: 12),
          child: Center(child: UserButton(size: 36)),
        ),
      ],
    );
  }
}
