import 'package:flutter/material.dart';
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../data/user/user_api_service.dart';
import '../theme/crm_colors.dart';
import 'visit_team/visit_team_home_screen.dart';
import 'senior_crm/senior_crm_home_screen.dart';
import '../services/notification_manager.dart';
import '../services/fcm_service.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  bool _isLoading = true;
  bool _isSeniorCrm = false;
  bool _isVisitTeam = false;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  @override
  void dispose() {
    NotificationManager.instance.stopPolling();
    super.dispose();
  }

  Future<void> _checkUserRole() async {
    try {
      final authState = ClerkAuth.of(context, listen: false);
      final sessionToken = await authState.sessionToken();
      final token = sessionToken.jwt;
      if (token.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      final user = await UserApiService().fetchMe(token);
      if (!mounted) return;
      setState(() {
        _isSeniorCrm = user?.isSeniorCrm ?? false;
        _isVisitTeam = user?.isVisitTeam ?? false;
        _isLoading = false;
      });

      if (_isSeniorCrm || _isVisitTeam) {
        // Start polling for in-app badge updates.
        // Pass a tokenRefresher so every API call uses a fresh JWT (Clerk JWTs expire ~60s).
        NotificationManager.instance.startPolling(
          token,
          tokenRefresher: () async {
            try {
              final freshSession = await authState.sessionToken();
              return freshSession.jwt.isNotEmpty ? freshSession.jwt : null;
            } catch (_) {
              return null;
            }
          },
        );
        // Register FCM token so backend can send push notifications
        // when the app is in the background or killed.
        FcmService.registerToken(token);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: SpinKitFoldingCube(color: CrmColors.brandPrimary, size: 40.0),
        ),
      );
    }

    if (_isSeniorCrm) {
      return const SeniorCrmHomeScreen();
    }

    if (_isVisitTeam) {
      return const VisitTeamHomeScreen();
    }

    // If they have neither department, block entry.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Access Denied'),
        backgroundColor: Colors.white,
        foregroundColor: CrmColors.foreground,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.block, size: 64, color: CrmColors.error),
            const SizedBox(height: 16),
            const Text(
              'Not Authorized',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'You must be in the SR_CRM or VISIT_TEAM\ndepartment to access this app.',
              textAlign: TextAlign.center,
              style: TextStyle(color: CrmColors.mutedForeground),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ClerkAuth.of(context, listen: false).signOut();
              },
              child: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}
