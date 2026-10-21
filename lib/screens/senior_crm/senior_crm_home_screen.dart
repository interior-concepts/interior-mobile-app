import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fui_kit/fui_kit.dart';

import '../../theme/crm_colors.dart';
import 'senior_crm_dashboard_screen.dart';
import 'senior_crm_meeting_screen.dart';
import 'senior_crm_review_screen.dart';
import 'senior_crm_profile_screen.dart';

class SeniorCrmHomeScreen extends StatefulWidget {
  const SeniorCrmHomeScreen({super.key});

  @override
  State<SeniorCrmHomeScreen> createState() => _SeniorCrmHomeScreenState();
}

class _SeniorCrmHomeScreenState extends State<SeniorCrmHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const SeniorCrmDashboardScreen(),
      const SeniorCrmMeetingScreen(),
      const SeniorCrmReviewScreen(),
      const SeniorCrmProfileScreen(),
    ];

    final safeIndex = _currentIndex.clamp(0, screens.length - 1);

    return PopScope(
      canPop: safeIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && safeIndex != 0) {
          setState(() => _currentIndex = 0);
        }
      },
      child: Scaffold(
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.02, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: screens[safeIndex],
        ),
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.72),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.4),
                  width: 0.8,
                ),
              ),
            ),
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              indicatorColor: CrmColors.brandPrimary.withValues(alpha: 0.15),
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: CrmColors.brandPrimary,
                  );
                }
                return const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: CrmColors.mutedForeground,
                );
              }),
              iconTheme: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const IconThemeData(color: CrmColors.brandPrimary, size: 30);
                }
                return const IconThemeData(color: CrmColors.mutedForeground, size: 28);
              }),
            ),
            child: NavigationBar(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              shadowColor: Colors.transparent,
              elevation: 0,
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() => _currentIndex = index);
              },
            destinations: [
              NavigationDestination(
                icon: FUI(RegularRounded.home, color: CrmColors.mutedForeground, width: 22, height: 22),
                selectedIcon: FUI(SolidRounded.home, color: CrmColors.brandPrimary, width: 24, height: 24),
                label: 'Home',
              ),
              NavigationDestination(
                icon: FUI(RegularRounded.calendar, color: CrmColors.mutedForeground, width: 22, height: 22),
                selectedIcon: FUI(SolidRounded.calendar, color: CrmColors.brandPrimary, width: 24, height: 24),
                label: 'Meeting',
              ),
              NavigationDestination(
                icon: FUI(RegularRounded.document, color: CrmColors.mutedForeground, width: 22, height: 22),
                selectedIcon: FUI(SolidRounded.document, color: CrmColors.brandPrimary, width: 24, height: 24),
                label: 'Review',
              ),
              NavigationDestination(
                icon: FUI(RegularRounded.user, color: CrmColors.mutedForeground, width: 22, height: 22),
                selectedIcon: FUI(SolidRounded.user, color: CrmColors.brandPrimary, width: 24, height: 24),
                label: 'Profile',
              ),
            ],
          ),
        ),
          ),
        ),
      ),
    ),
    );
  }
}
