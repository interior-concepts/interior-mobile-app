import 'package:flutter/material.dart';
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../data/user/user_api_service.dart';
import '../../theme/crm_colors.dart';
import 'dashboard_screen.dart';
import 'visits_screen.dart';
import 'today_visits_screen.dart';
import 'my_support_screen.dart';
import 'control_visits_screen.dart';

class VisitTeamHomeScreen extends StatefulWidget {
  const VisitTeamHomeScreen({super.key});

  @override
  State<VisitTeamHomeScreen> createState() => _VisitTeamHomeScreenState();
}

class _VisitTeamHomeScreenState extends State<VisitTeamHomeScreen> {
  int _currentIndex = 0;
  bool _roleChecked = false;
  bool _isLeader = false;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    try {
      final authState = ClerkAuth.of(context, listen: false);
      final sessionToken = await authState.sessionToken();
      final token = sessionToken.jwt;
      if (token.isEmpty) {
        if (mounted) setState(() => _roleChecked = true);
        return;
      }
      final user = await UserApiService().fetchMe(token);
      if (!mounted) return;
      final isLeader = user?.isVisitTeamLeader ?? false;
      setState(() {
        _isLeader = isLeader;
        _roleChecked = true;
        // Land leaders directly on the Control tab (index 3)
        if (isLeader) _currentIndex = 3;
      });
    } catch (_) {
      if (mounted) setState(() => _roleChecked = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_roleChecked) {
      return const Scaffold(
        body: Center(
          child: SpinKitFoldingCube(color: CrmColors.brandPrimary, size: 40.0),
        ),
      );
    }

    final screens = [
      const VisitTeamDashboardScreen(),
      const VisitsScreen(),
      const TodayVisitsScreen(),
      if (_isLeader) const ControlVisitsScreen() else const MySupportScreen(),
    ];

    final safeIndex = _currentIndex.clamp(0, screens.length - 1);

    return Scaffold(
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
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
            backgroundColor: Colors.white,
            elevation: 0,
            selectedIndex: safeIndex,
            onDestinationSelected: (index) {
              setState(() => _currentIndex = index);
            },
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              const NavigationDestination(
                icon: Icon(Icons.assignment_outlined),
                selectedIcon: Icon(Icons.assignment),
                label: 'Visits',
              ),
              const NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month),
                label: 'Today Visits',
              ),
              if (_isLeader)
                const NavigationDestination(
                  icon: Icon(Icons.admin_panel_settings_outlined),
                  selectedIcon: Icon(Icons.admin_panel_settings),
                  label: 'Control',
                )
              else
                const NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
            ],
          ),
        ),
      ),
    );
  }
}
